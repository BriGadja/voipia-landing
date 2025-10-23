'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Phone, XCircle, CheckCircle, TrendingUp, Zap } from 'lucide-react';

export default function ROICalculator() {
  // States
  const [calls, setCalls] = useState(200);
  const [missedPercentage, setMissedPercentage] = useState(40);
  const [clientValue, setClientValue] = useState(2000);
  const [showResults, setShowResults] = useState(false);

  // === CALCULS CRITIQUES ===

  // Situation actuelle
  const missedCalls = Math.floor(calls * (missedPercentage / 100));
  const answeredCalls = calls - missedCalls;

  const currentConversionRate = 0.30; // 30% taux conversion moyen
  const currentClients = Math.floor(answeredCalls * currentConversionRate);
  const currentRevenue = currentClients * clientValue;
  const currentRevenueAnnual = currentRevenue * 12;

  // Appels manqués = opportunités perdues
  const lostClients = Math.floor(missedCalls * currentConversionRate);
  const lostRevenueMonthly = lostClients * clientValue;
  const lostRevenueAnnual = lostRevenueMonthly * 12;

  // Avec VoIPIA
  const voipiaResponseRate = 0.95; // 95% taux réponse
  const voipiaConversionRate = 0.37; // 37% conversion (amélioration)
  const voipiaCallsAnswered = Math.floor(calls * voipiaResponseRate);
  const voipiaClients = Math.floor(voipiaCallsAnswered * voipiaConversionRate);
  const voipiaRevenue = voipiaClients * clientValue;
  const voipiaRevenueAnnual = voipiaRevenue * 12;

  // ROI
  const monthlyInvestment = 290; // Pack de base
  const annualInvestment = monthlyInvestment * 12;
  const additionalRevenueMonthly = voipiaRevenue - currentRevenue;
  const additionalRevenueAnnual = additionalRevenueMonthly * 12;
  const roi = Math.floor((additionalRevenueAnnual / annualInvestment) * 100);
  const paybackDays = Math.ceil((monthlyInvestment / additionalRevenueMonthly) * 30);

  const handleCalculate = () => {
    setShowResults(true);

    // Track analytics
    if (typeof window !== 'undefined' && (window as any).plausible) {
      (window as any).plausible('ROI Calculator Used', {
        props: {
          calls,
          missedPercentage,
          clientValue,
          roi,
          lostRevenueAnnual
        }
      });
    }
  };

  return (
    <section id="roi-calculator" className="py-20 bg-gradient-to-b from-black to-red-950/10">
      <div className="max-w-5xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-12">
          <h2 className="text-5xl font-bold mb-4">
            Combien d&apos;appels perdez-vous chaque mois ?
          </h2>
          <p className="text-xl text-gray-300">
            Calculez le coût réel de vos appels manqués en 30 secondes
          </p>
        </div>

        {/* Inputs Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white/10 backdrop-blur-lg border border-white/20 rounded-3xl p-10 mb-8"
        >
          <div className="space-y-8">
            {/* Input 1 : Appels par mois */}
            <div>
              <div className="flex justify-between items-center mb-3">
                <label className="text-lg font-medium flex items-center gap-2">
                  <Phone className="w-5 h-5 text-blue-500" />
                  Combien d&apos;appels recevez-vous par mois ?
                </label>
                <div className="text-3xl font-bold text-blue-500">{calls}</div>
              </div>
              <input
                type="range"
                min="50"
                max="1000"
                step="10"
                value={calls}
                onChange={(e) => setCalls(Number(e.target.value))}
                className="w-full h-3 bg-white/10 rounded-lg appearance-none cursor-pointer slider-blue"
              />
              <div className="flex justify-between text-sm text-gray-400 mt-2">
                <span>50</span>
                <span>1000</span>
              </div>
            </div>

            {/* Input 2 : % appels manqués */}
            <div>
              <div className="flex justify-between items-center mb-3">
                <label className="text-lg font-medium flex items-center gap-2">
                  <XCircle className="w-5 h-5 text-red-400" />
                  Quel % d&apos;appels sont manqués actuellement ?
                </label>
                <div className="text-3xl font-bold text-red-400">{missedPercentage}%</div>
              </div>
              <input
                type="range"
                min="10"
                max="80"
                step="5"
                value={missedPercentage}
                onChange={(e) => setMissedPercentage(Number(e.target.value))}
                className="w-full h-3 bg-white/10 rounded-lg appearance-none cursor-pointer slider-red"
              />
              <div className="flex justify-between text-sm text-gray-400 mt-2">
                <span>10%</span>
                <span>80%</span>
              </div>
              <p className="text-sm text-gray-400 mt-2">
                💡 Moyenne PME : 30-50% d&apos;appels manqués
              </p>
            </div>

            {/* Input 3 : Valeur client */}
            <div>
              <div className="flex justify-between items-center mb-3">
                <label className="text-lg font-medium flex items-center gap-2">
                  <TrendingUp className="w-5 h-5 text-green-400" />
                  Valeur moyenne d&apos;un client (€)
                </label>
                <div className="text-3xl font-bold text-green-400">{clientValue.toLocaleString()}€</div>
              </div>
              <input
                type="range"
                min="500"
                max="10000"
                step="100"
                value={clientValue}
                onChange={(e) => setClientValue(Number(e.target.value))}
                className="w-full h-3 bg-white/10 rounded-lg appearance-none cursor-pointer slider-green"
              />
              <div className="flex justify-between text-sm text-gray-400 mt-2">
                <span>500€</span>
                <span>10 000€</span>
              </div>
            </div>

            {/* Bouton Calculer */}
            <button
              onClick={handleCalculate}
              className="w-full py-4 bg-gradient-to-r from-blue-500 to-violet-500 rounded-xl font-bold text-lg hover:opacity-90 transition-opacity flex items-center justify-center gap-2"
            >
              <Zap className="w-6 h-6" />
              Calculer mes pertes →
            </button>
          </div>
        </motion.div>

        {/* Results Cards */}
        <AnimatePresence>
          {showResults && (
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 40 }}
              className="grid md:grid-cols-2 gap-6"
            >
              {/* Card 1 : Situation actuelle */}
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.1 }}
                className="bg-white/10 backdrop-blur-lg border border-white/20 rounded-2xl p-6"
              >
                <h3 className="text-xl font-bold mb-4 flex items-center gap-2">
                  📊 VOTRE SITUATION ACTUELLE
                </h3>
                <div className="space-y-2 text-gray-300">
                  <div className="flex justify-between">
                    <span>Appels/mois</span>
                    <span className="font-semibold">{calls}</span>
                  </div>
                  <div className="flex justify-between text-red-400">
                    <span>Appels manqués ({missedPercentage}%)</span>
                    <span className="font-semibold">{missedCalls}</span>
                  </div>
                  <div className="flex justify-between text-green-400">
                    <span>Appels traités</span>
                    <span className="font-semibold">{answeredCalls}</span>
                  </div>
                  <div className="flex justify-between border-t border-white/10 pt-2 mt-2">
                    <span>CA actuel/an</span>
                    <span className="font-bold">{currentRevenueAnnual.toLocaleString()}€</span>
                  </div>
                </div>
              </motion.div>

              {/* Card 2 : Appels manqués = CA perdu */}
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.2 }}
                className="bg-gradient-to-br from-red-950/40 to-red-900/20 backdrop-blur-lg border border-red-500/30 rounded-2xl p-6"
              >
                <h3 className="text-xl font-bold mb-4 flex items-center gap-2 text-red-400">
                  🔥 APPELS MANQUÉS = CA PERDU
                </h3>
                <div className="space-y-2 text-gray-300">
                  <div className="flex justify-between text-sm">
                    <span>{missedCalls} appels manqués/mois</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span>× {(currentConversionRate * 100).toFixed(0)}% taux conversion moyen</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span>× {clientValue.toLocaleString()}€ valeur client</span>
                  </div>
                  <div className="border-t border-red-500/30 pt-3 mt-3">
                    <div className="text-center">
                      <div className="text-3xl font-bold text-red-400 mb-1">
                        {lostRevenueAnnual.toLocaleString()}€
                      </div>
                      <div className="text-sm text-red-300">PERDUS PAR AN</div>
                    </div>
                  </div>
                </div>
                <div className="mt-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-center text-sm text-red-300">
                  ⚠️ Vous laissez {(lostRevenueAnnual / 1000).toFixed(0)}k€ sur la table chaque année
                </div>
              </motion.div>

              {/* Card 3 : Avec VoIPIA */}
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.3 }}
                className="bg-gradient-to-br from-green-950/40 to-green-900/20 backdrop-blur-lg border border-green-500/30 rounded-2xl p-6"
              >
                <h3 className="text-xl font-bold mb-4 flex items-center gap-2 text-green-400">
                  ✅ AVEC VOIPIA
                </h3>
                <div className="space-y-2 text-gray-300">
                  <div className="flex justify-between">
                    <span>Appels/mois (100% traités)</span>
                    <span className="font-semibold">{calls}</span>
                  </div>
                  <div className="flex justify-between text-green-400">
                    <span>Appels manqués</span>
                    <span className="font-semibold">0</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Taux réponse</span>
                    <span className="font-semibold">{(voipiaResponseRate * 100).toFixed(0)}% <span className="text-sm text-gray-400">(vs {((answeredCalls / calls) * 100).toFixed(0)}%)</span></span>
                  </div>
                  <div className="border-t border-green-500/30 pt-3 mt-3">
                    <div className="flex justify-between">
                      <span>CA potentiel/an</span>
                      <span className="font-bold text-green-400">{voipiaRevenueAnnual.toLocaleString()}€</span>
                    </div>
                    <div className="flex justify-between mt-2 text-lg">
                      <span className="text-green-300">CA ADDITIONNEL</span>
                      <span className="font-bold text-green-400">+{additionalRevenueAnnual.toLocaleString()}€/an</span>
                    </div>
                  </div>
                </div>
              </motion.div>

              {/* Card 4 : ROI VoIPIA */}
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.4 }}
                className="bg-gradient-to-br from-violet-950/40 to-violet-900/20 backdrop-blur-lg border border-violet-500/30 rounded-2xl p-6"
              >
                <h3 className="text-xl font-bold mb-4 flex items-center gap-2 text-violet-400">
                  💎 ROI VOIPIA
                </h3>
                <div className="space-y-3 text-gray-300">
                  <div className="flex justify-between">
                    <span>Investissement/an</span>
                    <span className="font-semibold">{annualInvestment.toLocaleString()}€ <span className="text-sm text-gray-400">({monthlyInvestment}€/mois)</span></span>
                  </div>
                  <div className="flex justify-between">
                    <span>CA récupéré/an</span>
                    <span className="font-semibold text-violet-400">{additionalRevenueAnnual.toLocaleString()}€</span>
                  </div>
                  <div className="border-t border-violet-500/30 pt-3 mt-3">
                    <div className="text-center mb-3">
                      <div className="text-4xl font-bold text-violet-400 mb-1">
                        {roi.toLocaleString()}%
                      </div>
                      <div className="text-sm text-violet-300">ROI</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-violet-400 mb-1">
                        {paybackDays} jours
                      </div>
                      <div className="text-sm text-violet-300">Payback</div>
                    </div>
                  </div>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* CTA XXL */}
        {showResults && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
            className="mt-8 text-center"
          >
            <a
              href="#demo"
              className="inline-block px-12 py-5 bg-gradient-to-r from-blue-500 via-violet-500 to-pink-500 rounded-xl font-bold text-xl hover:scale-105 transition-transform"
            >
              🚀 Je récupère mes {(lostRevenueAnnual / 1000).toFixed(0)}k€ perdus →
            </a>
          </motion.div>
        )}
      </div>

      {/* Custom slider styles */}
      <style dangerouslySetInnerHTML={{__html: `
        .slider-blue::-webkit-slider-thumb {
          appearance: none;
          width: 24px;
          height: 24px;
          border-radius: 50%;
          background: #3B82F6;
          cursor: pointer;
        }
        .slider-red::-webkit-slider-thumb {
          appearance: none;
          width: 24px;
          height: 24px;
          border-radius: 50%;
          background: #EF4444;
          cursor: pointer;
        }
        .slider-green::-webkit-slider-thumb {
          appearance: none;
          width: 24px;
          height: 24px;
          border-radius: 50%;
          background: #10B981;
          cursor: pointer;
        }
      `}} />
    </section>
  );
}
