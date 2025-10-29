'use client'

import { motion } from 'framer-motion'
import { TrendingUp, Euro, Calendar, CheckCircle } from 'lucide-react'
import GlassCard from '@/components/ui/GlassCard'
import { CalculatorResults as Results } from '@/types/calculator'
import { formatCurrency, formatNumber } from '@/lib/calculatorUtils'

interface CalculatorResultsProps {
  results: Results
}

export default function CalculatorResults({ results }: CalculatorResultsProps) {
  const isPositiveROI = results.roi && results.roi.monthlyProfit > 0

  return (
    <motion.div
      key={JSON.stringify(results)}
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.3 }}
    >
      <GlassCard className="p-6">
        <h3 className="text-xl font-bold text-white mb-6 flex items-center">
          <TrendingUp className="w-5 h-5 mr-2 text-purple-400" />
          Résultats
        </h3>

        {/* Coûts unitaires */}
        <div className="space-y-4 mb-6">
          <div className="flex justify-between items-center py-2 border-b border-gray-800/50">
            <span className="text-gray-400 text-sm">Coût par appel</span>
            <motion.span
              key={results.costPerCall}
              initial={{ opacity: 0, x: 10 }}
              animate={{ opacity: 1, x: 0 }}
              className="text-white font-semibold"
            >
              {formatCurrency(results.costPerCall)}
            </motion.span>
          </div>
        </div>

        {/* Coûts mensuels */}
        <div className="bg-gradient-to-br from-purple-900/20 to-blue-900/20 rounded-lg p-4 mb-6">
          <div className="flex items-center mb-3">
            <Calendar className="w-4 h-4 mr-2 text-purple-400" />
            <span className="text-sm font-medium text-gray-300">Coûts mensuels</span>
          </div>
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="text-gray-400 text-xs">Opérationnel</span>
              <span className="text-white text-sm">{formatCurrency(results.monthlyOperational)}</span>
            </div>
            <div className="flex justify-between items-center pt-2 border-t border-gray-700/50">
              <span className="text-white font-medium">Total mensuel</span>
              <motion.span
                key={results.monthlyTotal}
                initial={{ scale: 0.9 }}
                animate={{ scale: 1 }}
                className="text-xl font-bold bg-gradient-to-r from-purple-400 to-blue-400 text-transparent bg-clip-text"
              >
                {formatCurrency(results.monthlyTotal)}
              </motion.span>
            </div>
          </div>
        </div>

        {/* Première année */}
        <div className="bg-gradient-to-br from-blue-900/20 to-purple-900/20 rounded-lg p-4 mb-6">
          <div className="flex items-center mb-3">
            <Euro className="w-4 h-4 mr-2 text-blue-400" />
            <span className="text-sm font-medium text-gray-300">Première année</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-white font-medium">Total année 1</span>
            <motion.span
              key={results.firstYearTotal}
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              className="text-lg font-bold text-white"
            >
              {formatCurrency(results.firstYearTotal, 0)}
            </motion.span>
          </div>
          <div className="flex justify-between items-center mt-2 pt-2 border-t border-gray-700/50">
            <span className="text-gray-400 text-xs">Années suivantes</span>
            <span className="text-white text-sm">{formatCurrency(results.recurringAnnual, 0)}/an</span>
          </div>
        </div>

        {/* ROI si disponible */}
        {results.roi && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className={`rounded-lg p-4 ${
              isPositiveROI
                ? 'bg-gradient-to-br from-green-900/30 to-emerald-900/20 border border-green-500/30'
                : 'bg-gradient-to-br from-red-900/30 to-orange-900/20 border border-red-500/30'
            }`}
          >
            <div className="flex items-center mb-3">
              <CheckCircle className={`w-4 h-4 mr-2 ${isPositiveROI ? 'text-green-400' : 'text-red-400'}`} />
              <span className="text-sm font-medium text-gray-300">ROI Estimé</span>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-gray-400 text-xs">Conversions/mois</span>
                <span className="text-white text-sm">{formatNumber(Math.round(results.roi.monthlyConversions))}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-400 text-xs">Revenus/mois</span>
                <span className="text-white text-sm">{formatCurrency(results.roi.monthlyRevenue)}</span>
              </div>
              <div className="flex justify-between items-center pt-2 border-t border-gray-700/50">
                <span className="text-white font-medium">ROI mensuel</span>
                <motion.span
                  key={results.roi.monthlyProfit}
                  initial={{ scale: 0.9 }}
                  animate={{ scale: 1 }}
                  className={`text-lg font-bold ${
                    isPositiveROI ? 'text-green-400' : 'text-red-400'
                  }`}
                >
                  {isPositiveROI ? '+' : ''}{formatCurrency(results.roi.monthlyProfit)}
                </motion.span>
              </div>
            </div>
          </motion.div>
        )}

        {/* Indicateur de rentabilité */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="mt-6 text-center"
        >
          <div className="inline-flex items-center px-3 py-1 rounded-full bg-purple-900/30 border border-purple-500/30">
            <div className="w-2 h-2 rounded-full bg-purple-400 mr-2 animate-pulse" />
            <span className="text-xs text-purple-300">Calcul en temps réel</span>
          </div>
        </motion.div>
      </GlassCard>
    </motion.div>
  )
}