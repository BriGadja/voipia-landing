'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Send, Download, ArrowRight } from 'lucide-react'
import { CalculatorState, CalculatorResults } from '@/types/calculator'
import { formatCurrency } from '@/lib/calculatorUtils'

interface CalculatorCTAProps {
  data: CalculatorState
  results: CalculatorResults
}

export default function CalculatorCTA({ data, results }: CalculatorCTAProps) {
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleGetQuote = async () => {
    setIsSubmitting(true)

    const formData = {
      mode: data.mode,
      volume: data.volume,
      averageCallDuration: data.averageCallDuration,
      pricing: data.pricing,
      additionalCosts: data.additionalCosts,
      results: {
        costPerCall: results.costPerCall,
        monthlyTotal: results.monthlyTotal,
        firstYearTotal: results.firstYearTotal
      },
      timestamp: new Date().toISOString()
    }

    const subject = `Demande de devis - Agent ${data.mode === 'inbound' ? 'Inbound' : 'Outbound'}`
    const body = `
Bonjour,

Je souhaite obtenir un devis personnalisé pour un agent vocal ${data.mode === 'inbound' ? 'Inbound' : 'Outbound'}.

Voici ma configuration:
- Volume d'appels: ${data.volume.perMonth} appels/mois
- Durée moyenne: ${data.averageCallDuration} minutes
- Coût mensuel estimé: ${formatCurrency(results.monthlyTotal)}

Cordialement
    `.trim()

    const mailtoLink = `mailto:brice@sablia.io?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`
    window.location.href = mailtoLink

    setTimeout(() => setIsSubmitting(false), 2000)
  }

  const handleDownloadReport = () => {
    const report = {
      ...data,
      results,
      generatedAt: new Date().toISOString()
    }

    const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `voipia-roi-calculator-${new Date().toISOString().split('T')[0]}.json`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  return (
    <div className="mt-6 space-y-3">
      <motion.button
        onClick={handleGetQuote}
        disabled={isSubmitting}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        className="w-full py-4 px-6 rounded-lg bg-gradient-to-r from-purple-500 to-blue-500 text-white font-semibold shadow-lg hover:shadow-xl transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <span className="flex items-center justify-center">
          {isSubmitting ? (
            <>
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
                className="w-5 h-5 mr-2 border-2 border-white border-t-transparent rounded-full"
              />
              Envoi...
            </>
          ) : (
            <>
              <Send className="w-5 h-5 mr-2" />
              Obtenir un devis personnalisé
            </>
          )}
        </span>
      </motion.button>

      <motion.button
        onClick={handleDownloadReport}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        className="w-full py-3 px-6 rounded-lg bg-gray-800/50 backdrop-blur-sm border border-gray-700 text-white font-medium hover:bg-gray-800/70 transition-all duration-300"
      >
        <span className="flex items-center justify-center">
          <Download className="w-4 h-4 mr-2" />
          Télécharger le rapport
        </span>
      </motion.button>

      <div className="pt-4 border-t border-gray-800/50">
        <a
          href="#agents"
          className="flex items-center justify-center text-sm text-purple-400 hover:text-purple-300 transition-colors"
        >
          <span>Découvrir nos agents</span>
          <ArrowRight className="w-4 h-4 ml-1" />
        </a>
      </div>
    </div>
  )
}