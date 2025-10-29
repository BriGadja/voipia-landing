'use client'

import { motion } from 'framer-motion'
import FadeIn from '@/components/animations/FadeIn'
import { howItWorksSteps } from '@/lib/constants'
import { Plug, Settings, Rocket, BarChart, ArrowDown } from 'lucide-react'

const icons = {
  Plug,
  Settings,
  Rocket,
  BarChart
}

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="py-20 lg:py-32 relative">
      <div className="absolute inset-0 bg-gradient-to-br from-purple-900/20 via-transparent to-blue-900/20" />
      
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative">
        <FadeIn>
          <div className="text-center mb-16">
            <h2 className="text-4xl lg:text-5xl font-bold text-white mb-4">
              Comment ça marche ?
            </h2>
            <p className="text-xl text-gray-300 dark:text-gray-400 max-w-2xl mx-auto">
              Déployez vos agents IA en moins de 24h avec notre processus simplifié
            </p>
          </div>
        </FadeIn>

        <div className="max-w-4xl mx-auto">
          {howItWorksSteps.map((step, index) => {
            const Icon = icons[step.icon as keyof typeof icons]
            const isLast = index === howItWorksSteps.length - 1
            
            return (
              <div key={step.number} className="relative">
                <FadeIn delay={index * 0.2}>
                  <div className="flex items-start gap-8 mb-8">
                    <div className="flex flex-col items-center">
                      <motion.div 
                        className="relative z-10 w-20 h-20 rounded-2xl bg-gradient-to-br from-purple-600 to-blue-600 flex items-center justify-center shadow-xl"
                        whileHover={{ scale: 1.1, rotate: 5 }}
                        transition={{ duration: 0.3 }}
                      >
                        <Icon className="w-8 h-8 text-white" />
                      </motion.div>
                      
                      {!isLast && (
                        <div className="w-px h-24 bg-gradient-to-b from-purple-500/50 to-blue-500/50 mt-4 relative">
                          <motion.div
                            className="absolute inset-0 bg-gradient-to-b from-purple-500 to-blue-500 w-full"
                            initial={{ scaleY: 0 }}
                            whileInView={{ scaleY: 1 }}
                            transition={{ duration: 1, delay: index * 0.3 }}
                            style={{ originY: 0 }}
                          />
                        </div>
                      )}
                    </div>

                    <div className="flex-1 pt-4 overflow-hidden">
                      <div className="flex items-start sm:items-center gap-2 sm:gap-4 mb-4">
                        <span className="text-4xl sm:text-6xl font-bold text-white/10 shrink-0">
                          {step.number}
                        </span>
                        <h3 className="text-xl sm:text-2xl font-bold text-white">
                          {step.title}
                        </h3>
                      </div>
                      <p className="text-base sm:text-lg text-gray-300 dark:text-gray-400">
                        {step.description}
                      </p>

                      {index === 0 && (
                        <motion.div 
                          className="mt-6 grid grid-cols-2 sm:grid-cols-3 gap-4"
                          initial={{ opacity: 0, y: 20 }}
                          whileInView={{ opacity: 1, y: 0 }}
                          transition={{ delay: 0.5 }}
                        >
                          {['Salesforce', 'HubSpot', 'Pipedrive'].map((crm) => (
                            <div key={crm} className="px-4 py-2 rounded-lg bg-white/5 backdrop-blur-md border border-white/10 text-center">
                              <span className="text-sm text-white/70">{crm}</span>
                            </div>
                          ))}
                        </motion.div>
                      )}

                      {index === 1 && (
                        <motion.div 
                          className="mt-6 flex flex-wrap gap-3"
                          initial={{ opacity: 0, y: 20 }}
                          whileInView={{ opacity: 1, y: 0 }}
                          transition={{ delay: 0.5 }}
                        >
                          {['Scripts personnalisés', 'Horaires flexibles', 'Critères de qualification'].map((feature, i) => (
                            <motion.div 
                              key={feature}
                              className="px-3 py-1 rounded-full bg-purple-500/20 border border-purple-500/30 text-sm text-purple-300"
                              whileHover={{ scale: 1.05 }}
                              initial={{ opacity: 0, x: -20 }}
                              whileInView={{ opacity: 1, x: 0 }}
                              transition={{ delay: 0.7 + i * 0.1 }}
                            >
                              {feature}
                            </motion.div>
                          ))}
                        </motion.div>
                      )}

                      {index === 2 && (
                        <motion.div 
                          className="mt-6 p-4 rounded-xl bg-gradient-to-r from-green-500/10 to-blue-500/10 border border-green-500/20"
                          initial={{ opacity: 0, scale: 0.95 }}
                          whileInView={{ opacity: 1, scale: 1 }}
                          transition={{ delay: 0.5 }}
                        >
                          <div className="flex items-center gap-2 text-green-400 font-medium">
                            <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                            Vos agents sont maintenant actifs !
                          </div>
                        </motion.div>
                      )}

                      {index === 3 && (
                        <motion.div 
                          className="mt-6 flex flex-wrap gap-3"
                          initial={{ opacity: 0, y: 20 }}
                          whileInView={{ opacity: 1, y: 0 }}
                          transition={{ delay: 0.5 }}
                        >
                          {['Analytics en temps réel', 'Tableaux de bord KPI', 'Rapports exportables'].map((feature, i) => (
                            <motion.div 
                              key={feature}
                              className="px-3 py-1 rounded-full bg-blue-500/20 border border-blue-500/30 text-sm text-blue-300"
                              whileHover={{ scale: 1.05 }}
                              initial={{ opacity: 0, x: -20 }}
                              whileInView={{ opacity: 1, x: 0 }}
                              transition={{ delay: 0.7 + i * 0.1 }}
                            >
                              {feature}
                            </motion.div>
                          ))}
                        </motion.div>
                      )}
                    </div>
                  </div>
                </FadeIn>

                {!isLast && (
                  <motion.div 
                    className="flex justify-center mb-8"
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    transition={{ delay: index * 0.3 + 0.8 }}
                  >
                    <motion.div
                      animate={{ y: [0, 10, 0] }}
                      transition={{ duration: 2, repeat: Infinity }}
                    >
                      <ArrowDown className="w-6 h-6 text-purple-400" />
                    </motion.div>
                  </motion.div>
                )}
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}