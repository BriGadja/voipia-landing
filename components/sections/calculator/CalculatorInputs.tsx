'use client'

import { useState, useCallback, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Phone, Calendar, Clock, Euro, Settings, ChevronRight } from 'lucide-react'
import GlassCard from '@/components/ui/GlassCard'
import { Slider } from '@/components/ui/slider'
import { cn } from '@/lib/utils'
import { CalculatorState } from '@/types/calculator'
import {
  syncVolumeFromDay,
  syncVolumeFromWeek,
  syncVolumeFromMonth,
  calculatePlannedVolume
} from '@/lib/calculatorUtils'
import { calculatorLimits } from '@/lib/constants'

interface CalculatorInputsProps {
  state: CalculatorState
  onChange: (state: CalculatorState) => void
}

export default function CalculatorInputs({ state, onChange }: CalculatorInputsProps) {
  const [activeVolumeField, setActiveVolumeField] = useState<'day' | 'week' | 'month'>('month')

  const handleVolumeChange = useCallback((field: 'day' | 'week' | 'month', value: string) => {
    const numValue = Math.max(0, Math.min(parseInt(value) || 0, calculatorLimits.volume.max))

    let newVolume
    if (field === 'day') {
      newVolume = syncVolumeFromDay(numValue)
    } else if (field === 'week') {
      newVolume = syncVolumeFromWeek(numValue)
    } else {
      newVolume = syncVolumeFromMonth(numValue)
    }

    setActiveVolumeField(field)
    onChange({ ...state, volume: newVolume })
  }, [state, onChange])

  const handleDurationChange = useCallback((value: number[]) => {
    onChange({ ...state, averageCallDuration: value[0] })
  }, [state, onChange])

  const handlePricingChange = useCallback((field: 'perProcessing' | 'perMinute', value: string) => {
    const numValue = Math.max(0, parseFloat(value) || 0)
    onChange({
      ...state,
      pricing: {
        ...state.pricing,
        [field]: numValue
      }
    })
  }, [state, onChange])

  const handleCostChange = useCallback((field: 'integration' | 'monthlyFee', value: string) => {
    const numValue = Math.max(0, parseFloat(value) || 0)
    onChange({
      ...state,
      additionalCosts: {
        ...state.additionalCosts,
        [field]: numValue
      }
    })
  }, [state, onChange])

  const handleModeChange = useCallback((mode: 'inbound' | 'outbound') => {
    onChange({ ...state, mode })
  }, [state, onChange])

  const togglePlannedMode = useCallback(() => {
    const newPlannedMode = state.plannedMode || {
      enabled: false,
      frequency: 5,
      dailySchedule: {
        startTime: '09:00',
        endTime: '18:00'
      },
      activeDays: [true, true, true, true, true, false, false]
    }

    onChange({
      ...state,
      plannedMode: { ...newPlannedMode, enabled: !newPlannedMode.enabled }
    })
  }, [state, onChange])

  useEffect(() => {
    if (state.mode === 'outbound' && state.plannedMode?.enabled) {
      const newVolume = calculatePlannedVolume(
        state.plannedMode.frequency,
        state.plannedMode.dailySchedule.startTime,
        state.plannedMode.dailySchedule.endTime,
        state.plannedMode.activeDays
      )
      if (newVolume.perMonth !== state.volume.perMonth) {
        onChange({ ...state, volume: newVolume })
      }
    }
  }, [state.plannedMode, state.mode, state.volume.perMonth, onChange, state])

  const daysOfWeek = ['L', 'M', 'M', 'J', 'V', 'S', 'D']

  return (
    <div className="space-y-6">
      {/* Mode Selection */}
      <GlassCard className="p-6">
        <div className="flex space-x-4 mb-6">
          <button
            onClick={() => handleModeChange('inbound')}
            className={cn(
              "flex-1 py-3 px-6 rounded-lg transition-all duration-300",
              state.mode === 'inbound'
                ? "bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg"
                : "bg-gray-800/50 text-gray-400 hover:bg-gray-800/70"
            )}
          >
            <Phone className="w-5 h-5 inline-block mr-2" />
            Inbound
          </button>
          <button
            onClick={() => handleModeChange('outbound')}
            className={cn(
              "flex-1 py-3 px-6 rounded-lg transition-all duration-300",
              state.mode === 'outbound'
                ? "bg-gradient-to-r from-purple-500 to-blue-500 text-white shadow-lg"
                : "bg-gray-800/50 text-gray-400 hover:bg-gray-800/70"
            )}
          >
            <Phone className="w-5 h-5 inline-block mr-2 rotate-180" />
            Outbound
          </button>
        </div>

        {/* Volume d'appels */}
        <div className="mb-6">
          <label className="text-sm font-medium text-gray-300 mb-4 block">
            <Calendar className="w-4 h-4 inline-block mr-2" />
            Volume d&apos;appels
          </label>

          {state.mode === 'outbound' && (
            <div className="mb-4">
              <button
                onClick={togglePlannedMode}
                className={cn(
                  "w-full py-2 px-4 rounded-lg text-left transition-all duration-300",
                  "bg-gray-800/30 hover:bg-gray-800/50",
                  "border border-gray-700/50 hover:border-purple-500/50"
                )}
              >
                <ChevronRight
                  className={cn(
                    "w-4 h-4 inline-block mr-2 transition-transform",
                    state.plannedMode?.enabled && "rotate-90"
                  )}
                />
                Mode planifié
              </button>
            </div>
          )}

          <AnimatePresence mode="wait">
            {state.mode === 'outbound' && state.plannedMode?.enabled ? (
              <motion.div
                key="planned"
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="space-y-4 mb-4"
              >
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-xs text-gray-400">Fréquence (minutes)</label>
                    <input
                      type="number"
                      min="1"
                      max="1440"
                      value={state.plannedMode.frequency}
                      onChange={(e) => onChange({
                        ...state,
                        plannedMode: {
                          ...state.plannedMode!,
                          frequency: parseInt(e.target.value) || 1
                        }
                      })}
                      className="w-full px-3 py-2 bg-gray-800/50 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="text-xs text-gray-400">Début</label>
                      <input
                        type="time"
                        value={state.plannedMode.dailySchedule.startTime}
                        onChange={(e) => onChange({
                          ...state,
                          plannedMode: {
                            ...state.plannedMode!,
                            dailySchedule: {
                              ...state.plannedMode!.dailySchedule,
                              startTime: e.target.value
                            }
                          }
                        })}
                        className="w-full px-2 py-2 bg-gray-800/50 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
                      />
                    </div>
                    <div>
                      <label className="text-xs text-gray-400">Fin</label>
                      <input
                        type="time"
                        value={state.plannedMode.dailySchedule.endTime}
                        onChange={(e) => onChange({
                          ...state,
                          plannedMode: {
                            ...state.plannedMode!,
                            dailySchedule: {
                              ...state.plannedMode!.dailySchedule,
                              endTime: e.target.value
                            }
                          }
                        })}
                        className="w-full px-2 py-2 bg-gray-800/50 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
                      />
                    </div>
                  </div>
                </div>
                <div>
                  <label className="text-xs text-gray-400 block mb-2">Jours actifs</label>
                  <div className="flex space-x-1">
                    {daysOfWeek.map((day, index) => (
                      <button
                        key={day}
                        onClick={() => {
                          const newDays = [...state.plannedMode!.activeDays]
                          newDays[index] = !newDays[index]
                          onChange({
                            ...state,
                            plannedMode: {
                              ...state.plannedMode!,
                              activeDays: newDays
                            }
                          })
                        }}
                        className={cn(
                          "w-8 h-8 rounded text-sm font-medium transition-all duration-300",
                          state.plannedMode?.activeDays[index]
                            ? "bg-purple-500 text-white"
                            : "bg-gray-800/50 text-gray-500"
                        )}
                      >
                        {day}
                      </button>
                    ))}
                  </div>
                </div>
              </motion.div>
            ) : null}
          </AnimatePresence>

          <div className="grid grid-cols-3 gap-3">
            <div className="relative">
              <input
                type="number"
                min="0"
                max={calculatorLimits.volume.max}
                value={state.volume.perDay}
                onChange={(e) => handleVolumeChange('day', e.target.value)}
                className={cn(
                  "w-full px-3 py-2 bg-gray-800/50 border rounded-lg text-white focus:outline-none transition-all duration-300",
                  activeVolumeField === 'day'
                    ? "border-purple-500 bg-gray-800/70"
                    : "border-gray-700"
                )}
                disabled={state.mode === 'outbound' && state.plannedMode?.enabled}
              />
              <span className="text-xs text-gray-400 mt-1 block">par jour</span>
            </div>
            <div className="relative">
              <input
                type="number"
                min="0"
                max={calculatorLimits.volume.max}
                value={state.volume.perWeek}
                onChange={(e) => handleVolumeChange('week', e.target.value)}
                className={cn(
                  "w-full px-3 py-2 bg-gray-800/50 border rounded-lg text-white focus:outline-none transition-all duration-300",
                  activeVolumeField === 'week'
                    ? "border-purple-500 bg-gray-800/70"
                    : "border-gray-700"
                )}
                disabled={state.mode === 'outbound' && state.plannedMode?.enabled}
              />
              <span className="text-xs text-gray-400 mt-1 block">par semaine</span>
            </div>
            <div className="relative">
              <input
                type="number"
                min="0"
                max={calculatorLimits.volume.max}
                value={state.volume.perMonth}
                onChange={(e) => handleVolumeChange('month', e.target.value)}
                className={cn(
                  "w-full px-3 py-2 bg-gray-800/50 border rounded-lg text-white focus:outline-none transition-all duration-300",
                  activeVolumeField === 'month'
                    ? "border-purple-500 bg-gray-800/70"
                    : "border-gray-700"
                )}
                disabled={state.mode === 'outbound' && state.plannedMode?.enabled}
              />
              <span className="text-xs text-gray-400 mt-1 block">par mois</span>
            </div>
          </div>
        </div>

        {/* Durée moyenne */}
        <div className="mb-6">
          <label className="text-sm font-medium text-gray-300 mb-2 block">
            <Clock className="w-4 h-4 inline-block mr-2" />
            Durée moyenne d&apos;appel : <span className="text-purple-400">{state.averageCallDuration} minutes</span>
          </label>
          <Slider
            value={[state.averageCallDuration]}
            onValueChange={handleDurationChange}
            min={calculatorLimits.duration.min}
            max={calculatorLimits.duration.max}
            step={calculatorLimits.duration.step}
            className="mt-3"
          />
        </div>

        {/* Modèle de coût */}
        <div className="mb-6">
          <label className="text-sm font-medium text-gray-300 mb-4 block">
            <Euro className="w-4 h-4 inline-block mr-2" />
            Modèle de coût
          </label>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs text-gray-400">Coût par traitement (€)</label>
              <input
                type="number"
                min="0"
                max={calculatorLimits.pricing.maxPerCall}
                step={calculatorLimits.pricing.step}
                value={state.pricing.perProcessing}
                onChange={(e) => handlePricingChange('perProcessing', e.target.value)}
                className="w-full px-3 py-2 bg-gray-800/50 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
              />
            </div>
            <div>
              <label className="text-xs text-gray-400">Coût à la minute (€)</label>
              <input
                type="number"
                min="0"
                max={calculatorLimits.pricing.maxPerMinute}
                step={calculatorLimits.pricing.step}
                value={state.pricing.perMinute}
                onChange={(e) => handlePricingChange('perMinute', e.target.value)}
                className="w-full px-3 py-2 bg-gray-800/50 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
              />
            </div>
          </div>
        </div>

        {/* Coûts additionnels */}
        <div>
          <label className="text-sm font-medium text-gray-300 mb-4 block">
            <Settings className="w-4 h-4 inline-block mr-2" />
            Coûts additionnels
          </label>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs text-gray-400">Intégration (one-shot) (€)</label>
              <input
                type="number"
                min="0"
                max={calculatorLimits.costs.maxIntegration}
                step="100"
                value={state.additionalCosts.integration}
                onChange={(e) => handleCostChange('integration', e.target.value)}
                className="w-full px-3 py-2 bg-gray-800/50 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
              />
            </div>
            <div>
              <label className="text-xs text-gray-400">Location mensuelle (€)</label>
              <input
                type="number"
                min="0"
                max={calculatorLimits.costs.maxMonthly}
                step="10"
                value={state.additionalCosts.monthlyFee}
                onChange={(e) => handleCostChange('monthlyFee', e.target.value)}
                className="w-full px-3 py-2 bg-gray-800/50 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-purple-500"
              />
            </div>
          </div>
        </div>
      </GlassCard>
    </div>
  )
}