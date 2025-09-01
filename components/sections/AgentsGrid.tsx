'use client'

import { motion } from 'framer-motion'
import GlassCard from '@/components/ui/GlassCard'
import FadeIn from '@/components/animations/FadeIn'
import { agents } from '@/lib/constants'
import { CheckCircle } from 'lucide-react'

export default function AgentsGrid() {
  return (
    <section id="agents" className="py-20 lg:py-32 relative">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <FadeIn>
          <div className="text-center mb-16">
            <h2 className="text-4xl lg:text-5xl font-bold text-white mb-4">
              Rencontrez vos nouveaux
              <span className="text-gradient"> agents vocaux</span>
            </h2>
            <p className="text-xl text-gray-300 dark:text-gray-400 max-w-3xl mx-auto">
              Trois personnalités IA spécialisées pour couvrir tous vos besoins téléphoniques
            </p>
          </div>
        </FadeIn>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {agents.map((agent, index) => (
            <FadeIn key={agent.id} delay={index * 0.2}>
              <GlassCard className="p-8 h-full flex flex-col">
                <div className="flex items-start justify-between mb-6">
                  <motion.div 
                    className={`w-20 h-20 rounded-2xl bg-gradient-to-br ${agent.gradient} flex items-center justify-center text-white text-3xl font-bold shadow-lg`}
                    animate={{ 
                      scale: [1, 1.05, 1],
                      rotate: [0, 5, -5, 0]
                    }}
                    transition={{ 
                      duration: 3,
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                  >
                    {agent.name[0]}
                  </motion.div>
                  
                  <motion.div 
                    className="px-3 py-1 rounded-full bg-white/10 backdrop-blur-md border border-white/20"
                    whileHover={{ scale: 1.1 }}
                  >
                    <span className="text-xs font-medium text-white/80">
                      {agent.stats}
                    </span>
                  </motion.div>
                </div>

                <div className="mb-6">
                  <h3 className="text-2xl font-bold text-white mb-2">{agent.name}</h3>
                  <p className="text-sm text-purple-400 font-medium mb-3">{agent.title}</p>
                  <p className="text-gray-300 dark:text-gray-400">{agent.description}</p>
                </div>

                <div className="space-y-3 mb-8 flex-grow">
                  {agent.capabilities.map((capability, capIndex) => (
                    <motion.div 
                      key={capIndex}
                      className="flex items-start gap-3"
                      initial={{ opacity: 0, x: -20 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      transition={{ delay: capIndex * 0.1 }}
                    >
                      <CheckCircle className={`w-5 h-5 text-${agent.color} flex-shrink-0 mt-0.5`} />
                      <span className="text-sm text-gray-300 dark:text-gray-400">
                        {capability}
                      </span>
                    </motion.div>
                  ))}
                </div>
              </GlassCard>
            </FadeIn>
          ))}
        </div>
      </div>
    </section>
  )
}