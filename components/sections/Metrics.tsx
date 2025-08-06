'use client'

import { useState, useEffect, useRef } from 'react'
import { motion, useInView } from 'framer-motion'
import FadeIn from '@/components/animations/FadeIn'
import GlassCard from '@/components/ui/GlassCard'
import { metrics } from '@/lib/constants'
import { TrendingUp, Clock, Zap, CheckCircle } from 'lucide-react'

const icons = [TrendingUp, Clock, Zap, CheckCircle]

export default function Metrics() {
  const ref = useRef(null)
  const isInView = useInView(ref, { once: true })
  const [animatedValues, setAnimatedValues] = useState<string[]>(['0', '0', '0', '0'])

  useEffect(() => {
    if (isInView) {
      const timers = metrics.map((metric, index) => {
        return setTimeout(() => {
          setAnimatedValues(prev => {
            const newValues = [...prev]
            newValues[index] = metric.value
            return newValues
          })
        }, index * 200)
      })

      return () => timers.forEach(timer => clearTimeout(timer))
    }
  }, [isInView])

  return (
    <section id="metrics" className="py-20 lg:py-32 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-br from-blue-900/10 via-purple-900/5 to-pink-900/10" />
      
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative" ref={ref}>
        <FadeIn>
          <div className="text-center mb-16">
            <h2 className="text-4xl lg:text-5xl font-bold text-white mb-4">
              Des résultats qui parlent
            </h2>
            <p className="text-xl text-gray-300 dark:text-gray-400 max-w-3xl mx-auto">
              Nos clients observent des améliorations significatives dès les premières semaines
            </p>
          </div>
        </FadeIn>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
          {metrics.map((metric, index) => {
            const Icon = icons[index]
            
            return (
              <FadeIn key={metric.label} delay={index * 0.1}>
                <GlassCard className="p-6 text-center group">
                  <motion.div
                    className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${metric.gradient} flex items-center justify-center mx-auto mb-4 shadow-lg`}
                    whileHover={{ 
                      scale: 1.1,
                      rotate: [0, -10, 10, 0],
                      transition: { duration: 0.5 }
                    }}
                  >
                    <Icon className="w-8 h-8 text-white" />
                  </motion.div>

                  <motion.div
                    className="text-4xl lg:text-5xl font-bold text-white mb-2"
                    initial={{ scale: 0.5, opacity: 0 }}
                    animate={isInView ? { scale: 1, opacity: 1 } : {}}
                    transition={{ delay: index * 0.2, duration: 0.6 }}
                  >
                    {animatedValues[index] || metric.value}
                  </motion.div>

                  <h3 className="text-lg font-semibold text-white mb-2">
                    {metric.label}
                  </h3>

                  <p className="text-sm text-gray-400 group-hover:text-gray-300 transition-colors">
                    {metric.description}
                  </p>

                  <motion.div
                    className="mt-4 h-1 bg-gradient-to-r from-transparent via-white/20 to-transparent rounded-full"
                    initial={{ scaleX: 0 }}
                    whileInView={{ scaleX: 1 }}
                    transition={{ delay: index * 0.1 + 0.5, duration: 0.8 }}
                  />
                </GlassCard>
              </FadeIn>
            )
          })}
        </div>

        <FadeIn delay={0.8}>
          <div className="text-center">
            <motion.div 
              className="inline-block p-8 rounded-2xl bg-gradient-to-r from-purple-600/20 to-blue-600/20 backdrop-blur-md border border-white/20"
              whileHover={{ scale: 1.02 }}
              transition={{ duration: 0.3 }}
            >
              <div className="flex flex-col sm:flex-row items-center justify-center gap-6">
                <div className="text-center">
                  <motion.div 
                    className="text-3xl font-bold text-white mb-1"
                    animate={{ 
                      color: ['#ffffff', '#a855f7', '#3b82f6', '#ffffff'],
                    }}
                    transition={{ duration: 3, repeat: Infinity }}
                  >
                    98.7%
                  </motion.div>
                  <p className="text-sm text-gray-400">Taux de satisfaction</p>
                </div>
                <div className="hidden sm:block w-px h-12 bg-white/20" />
                <div className="text-center">
                  <motion.div 
                    className="text-3xl font-bold text-white mb-1"
                    animate={{ 
                      color: ['#ffffff', '#10b981', '#f59e0b', '#ffffff'],
                    }}
                    transition={{ duration: 3, repeat: Infinity, delay: 0.5 }}
                  >
                    2.1s
                  </motion.div>
                  <p className="text-sm text-gray-400">Latence moyenne</p>
                </div>
                <div className="hidden sm:block w-px h-12 bg-white/20" />
                <div className="text-center">
                  <motion.div 
                    className="text-3xl font-bold text-white mb-1"
                    animate={{ 
                      color: ['#ffffff', '#ef4444', '#8b5cf6', '#ffffff'],
                    }}
                    transition={{ duration: 3, repeat: Infinity, delay: 1 }}
                  >
                    500K+
                  </motion.div>
                  <p className="text-sm text-gray-400">Appels traités/mois</p>
                </div>
              </div>
            </motion.div>
          </div>
        </FadeIn>
      </div>

      <motion.div
        className="absolute -top-40 -right-40 w-80 h-80 bg-purple-500 rounded-full blur-3xl opacity-10"
        animate={{
          x: [0, 50, 0],
          y: [0, -30, 0],
          scale: [1, 1.1, 1],
        }}
        transition={{ duration: 8, repeat: Infinity }}
      />
      <motion.div
        className="absolute -bottom-40 -left-40 w-96 h-96 bg-blue-500 rounded-full blur-3xl opacity-10"
        animate={{
          x: [0, -30, 0],
          y: [0, 40, 0],
          scale: [1, 0.9, 1],
        }}
        transition={{ duration: 10, repeat: Infinity }}
      />
    </section>
  )
}