'use client'

import { useState, useMemo } from 'react'
import { motion } from 'framer-motion'
import { Calculator, TrendingUp } from 'lucide-react'
import FadeIn from '@/components/animations/FadeIn'
import { CalculatorState } from '@/types/calculator'
import { calculateROI } from '@/lib/calculatorUtils'
import { calculatorDefaults } from '@/lib/constants'
import CalculatorInputs from './calculator/CalculatorInputs'
import CalculatorResults from './calculator/CalculatorResults'
import CalculatorCTA from './calculator/CalculatorCTA'

const defaultState: CalculatorState = {
  mode: 'inbound',
  volume: calculatorDefaults.volume,
  averageCallDuration: calculatorDefaults.averageCallDuration,
  pricing: calculatorDefaults.pricing,
  additionalCosts: calculatorDefaults.additionalCosts,
  plannedMode: {
    enabled: false,
    frequency: 5,
    dailySchedule: {
      startTime: '09:00',
      endTime: '18:00'
    },
    activeDays: [true, true, true, true, true, false, false]
  }
}

export default function ROICalculator() {
  const [state, setState] = useState<CalculatorState>(defaultState)
  const results = useMemo(() => calculateROI(state), [state])

  return (
    <section id="roi-calculator" className="py-24 relative overflow-hidden">
      {/* Background gradient similar to Metrics section */}
      <div className="absolute inset-0 bg-gradient-to-br from-purple-900/10 via-blue-900/5 to-pink-900/10" />

      {/* Animated background elements */}
      <motion.div
        animate={{
          scale: [1, 1.2, 1],
          rotate: [0, 180, 360]
        }}
        transition={{
          duration: 20,
          repeat: Infinity,
          repeatType: "loop"
        }}
        className="absolute top-20 right-10 w-96 h-96 bg-purple-500/5 rounded-full blur-3xl"
      />
      <motion.div
        animate={{
          scale: [1, 1.1, 1],
          rotate: [360, 180, 0]
        }}
        transition={{
          duration: 25,
          repeat: Infinity,
          repeatType: "loop"
        }}
        className="absolute bottom-20 left-10 w-80 h-80 bg-blue-500/5 rounded-full blur-3xl"
      />

      <div className="container mx-auto px-6 relative z-10">
        <FadeIn>
          <div className="text-center mb-12">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 200, damping: 20 }}
              className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-purple-500 to-blue-500 mb-6 shadow-xl"
            >
              <Calculator className="w-8 h-8 text-white" />
            </motion.div>
            <h2 className="text-4xl lg:text-5xl font-bold text-white mb-4">
              Calculez votre ROI
            </h2>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Découvrez le coût et le retour sur investissement de nos agents vocaux IA
              adaptés à vos besoins spécifiques
            </p>
          </div>
        </FadeIn>

        <div className="max-w-6xl mx-auto">
          <div className="grid lg:grid-cols-3 gap-8">
            {/* Left: Inputs (2 columns on large screens) */}
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2 }}
              className="lg:col-span-2"
            >
              <CalculatorInputs state={state} onChange={setState} />
            </motion.div>

            {/* Right: Results and CTA (1 column on large screens) */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.3 }}
              className="lg:col-span-1"
            >
              <div className="sticky top-24">
                <CalculatorResults results={results} />
                <CalculatorCTA data={state} results={results} />
              </div>
            </motion.div>
          </div>
        </div>

        {/* Bottom decoration */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="mt-16 text-center"
        >
          <div className="inline-flex items-center px-6 py-3 rounded-full bg-gradient-to-r from-purple-900/30 to-blue-900/30 backdrop-blur-sm border border-purple-500/30">
            <TrendingUp className="w-5 h-5 mr-3 text-purple-400" />
            <span className="text-white font-medium">
              Plus de 500 entreprises font confiance à Voipia
            </span>
          </div>
        </motion.div>
      </div>
    </section>
  )
}