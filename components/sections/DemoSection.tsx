'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import FadeIn from '@/components/animations/FadeIn'
import GlassCard from '@/components/ui/GlassCard'
import Button from '@/components/ui/Button'
import { agents } from '@/lib/constants'
import { Play, Pause, Phone, MessageCircle, Volume2 } from 'lucide-react'

const scenarios = [
  {
    id: 'lead-callback',
    name: 'Rappel de lead',
    description: 'Qualification d\'un prospect entrant'
  },
  {
    id: 'dormant-reactivation', 
    name: 'Réactivation client',
    description: 'Réveil d\'un client dormant'
  },
  {
    id: 'appointment-booking',
    name: 'Prise de RDV',
    description: 'Booking d\'un rendez-vous commercial'
  }
]

const conversationSteps = [
  { speaker: 'agent', text: 'Bonjour, je suis Louis de Voipia. J\'aimerais vous parler de votre demande d\'information.' },
  { speaker: 'prospect', text: 'Ah oui, bonjour. J\'avais effectivement fait une demande.' },
  { speaker: 'agent', text: 'Parfait ! Pouvez-vous me dire quel est votre principal défi actuellement ?' },
  { speaker: 'prospect', text: 'Nous avons du mal à suivre tous nos prospects qui nous contactent.' },
  { speaker: 'agent', text: 'Je comprends parfaitement. Combien de leads recevez-vous par mois environ ?' }
]

export default function DemoSection() {
  const [selectedAgent, setSelectedAgent] = useState(agents[0])
  const [selectedScenario, setSelectedScenario] = useState(scenarios[0])
  const [isPlaying, setIsPlaying] = useState(false)
  const [conversationStep, setConversationStep] = useState(0)

  const handlePlayDemo = () => {
    if (isPlaying) {
      setIsPlaying(false)
      setConversationStep(0)
    } else {
      setIsPlaying(true)
      playConversation()
    }
  }

  const playConversation = () => {
    let step = 0
    const interval = setInterval(() => {
      if (step < conversationSteps.length) {
        setConversationStep(step)
        step++
      } else {
        clearInterval(interval)
        setIsPlaying(false)
        setConversationStep(0)
      }
    }, 2500)
  }

  return (
    <section id="demo" className="py-20 lg:py-32 relative">
      <div className="absolute inset-0 bg-gradient-to-br from-indigo-900/10 via-purple-900/5 to-pink-900/10" />
      
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative">
        <FadeIn>
          <div className="text-center mb-16">
            <h2 className="text-4xl lg:text-5xl font-bold text-white mb-4">
              Testez nos agents
              <span className="text-gradient"> en action</span>
            </h2>
            <p className="text-xl text-gray-300 dark:text-gray-400 max-w-3xl mx-auto">
              Découvrez comment nos agents IA gèrent différents scénarios d&apos;appels
            </p>
          </div>
        </FadeIn>

        <div className="grid lg:grid-cols-2 gap-12 items-start">
          <FadeIn delay={0.2}>
            <div className="space-y-6">
              <div>
                <h3 className="text-2xl font-bold text-white mb-4">
                  Choisissez votre agent
                </h3>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  {agents.map((agent) => (
                    <motion.button
                      key={agent.id}
                      onClick={() => setSelectedAgent(agent)}
                      className={`p-4 rounded-xl border transition-all duration-300 ${
                        selectedAgent.id === agent.id
                          ? 'border-purple-500 bg-purple-500/10'
                          : 'border-white/20 bg-white/5 hover:bg-white/10'
                      }`}
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${agent.gradient} flex items-center justify-center text-white font-bold mb-2 mx-auto`}>
                        {agent.name[0]}
                      </div>
                      <div className="text-white font-medium text-sm">{agent.name}</div>
                      <div className={`text-xs mt-1 ${selectedAgent.id === agent.id ? 'text-purple-300' : 'text-gray-400'}`}>
                        {agent.title}
                      </div>
                    </motion.button>
                  ))}
                </div>
              </div>

              <div>
                <h3 className="text-2xl font-bold text-white mb-4">
                  Sélectionnez un scénario
                </h3>
                <div className="space-y-3">
                  {scenarios.map((scenario) => (
                    <motion.button
                      key={scenario.id}
                      onClick={() => setSelectedScenario(scenario)}
                      className={`w-full p-4 rounded-xl border text-left transition-all duration-300 ${
                        selectedScenario.id === scenario.id
                          ? 'border-blue-500 bg-blue-500/10'
                          : 'border-white/20 bg-white/5 hover:bg-white/10'
                      }`}
                      whileHover={{ scale: 1.01 }}
                      whileTap={{ scale: 0.99 }}
                    >
                      <div className="text-white font-medium">{scenario.name}</div>
                      <div className={`text-sm mt-1 ${selectedScenario.id === scenario.id ? 'text-blue-300' : 'text-gray-400'}`}>
                        {scenario.description}
                      </div>
                    </motion.button>
                  ))}
                </div>
              </div>

              <Button
                onClick={handlePlayDemo}
                size="lg"
                className="w-full"
                disabled={isPlaying}
              >
                <span className="flex items-center gap-2">
                  {isPlaying ? (
                    <>
                      <Pause className="w-5 h-5" />
                      Conversation en cours...
                    </>
                  ) : (
                    <>
                      <Play className="w-5 h-5" />
                      Lancer la démo
                    </>
                  )}
                </span>
              </Button>
            </div>
          </FadeIn>

          <FadeIn delay={0.4}>
            <GlassCard className="p-6 lg:p-8">
              <div className="flex items-center gap-4 mb-6">
                <div className="relative">
                  <motion.div 
                    className="w-16 h-16 rounded-2xl bg-black/30 backdrop-blur-md border border-white/20 flex items-center justify-center"
                    animate={isPlaying ? {
                      scale: [1, 1.05, 1],
                      boxShadow: ['0 0 0 rgba(59, 130, 246, 0)', '0 0 20px rgba(59, 130, 246, 0.5)', '0 0 0 rgba(59, 130, 246, 0)']
                    } : {}}
                    transition={{ duration: 2, repeat: isPlaying ? Infinity : 0 }}
                  >
                    <Phone className="w-8 h-8 text-white" />
                  </motion.div>
                  {isPlaying && (
                    <motion.div
                      className="absolute -top-1 -right-1 w-6 h-6 bg-green-500 rounded-full flex items-center justify-center"
                      animate={{ scale: [1, 1.2, 1] }}
                      transition={{ duration: 1, repeat: Infinity }}
                    >
                      <div className="w-2 h-2 bg-white rounded-full" />
                    </motion.div>
                  )}
                </div>
                
                <div>
                  <h4 className="text-xl font-bold text-white">
                    Conversation en direct
                  </h4>
                  <p className="text-gray-400">
                    {selectedAgent.name} • {selectedScenario.name}
                  </p>
                </div>

                {isPlaying && (
                  <motion.div
                    className="ml-auto flex gap-1"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                  >
                    {[...Array(4)].map((_, i) => (
                      <motion.div
                        key={i}
                        className="w-1 h-8 bg-gradient-to-t from-blue-500 to-purple-500 rounded-full"
                        animate={{
                          scaleY: [0.3, 1, 0.3],
                          opacity: [0.5, 1, 0.5]
                        }}
                        transition={{
                          duration: 0.8,
                          repeat: Infinity,
                          delay: i * 0.1
                        }}
                      />
                    ))}
                  </motion.div>
                )}
              </div>

              <div className="h-96 overflow-y-auto space-y-4">
                <AnimatePresence>
                  {conversationSteps.slice(0, isPlaying ? conversationStep + 1 : 1).map((step, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      className={`flex ${step.speaker === 'agent' ? 'justify-start' : 'justify-end'}`}
                    >
                      <div className={`max-w-xs lg:max-w-sm p-4 rounded-2xl ${
                        step.speaker === 'agent'
                          ? 'bg-purple-600 text-white rounded-bl-sm'
                          : 'bg-white/10 backdrop-blur-md border border-white/20 text-white rounded-br-sm'
                      }`}>
                        <div className="flex items-start gap-2">
                          {step.speaker === 'agent' && (
                            <div className={`w-6 h-6 rounded-full bg-gradient-to-br ${selectedAgent.gradient} flex items-center justify-center text-white text-xs font-bold flex-shrink-0 mt-0.5`}>
                              {selectedAgent.name[0]}
                            </div>
                          )}
                          <div>
                            <div className="text-xs opacity-70 mb-1">
                              {step.speaker === 'agent' ? selectedAgent.name : 'Prospect'}
                            </div>
                            <p className="text-sm leading-relaxed">{step.text}</p>
                          </div>
                          {step.speaker === 'prospect' && (
                            <MessageCircle className="w-4 h-4 opacity-60 flex-shrink-0 mt-0.5" />
                          )}
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>

                {!isPlaying && (
                  <div className="text-center py-12">
                    <Volume2 className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-400">
                      Cliquez sur &quot;Lancer la démo&quot; pour voir la conversation
                    </p>
                  </div>
                )}
              </div>

              {isPlaying && (
                <motion.div
                  className="mt-4 pt-4 border-t border-white/10 flex items-center justify-between text-sm text-gray-400"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                >
                  <span>Latence: 1.8s</span>
                  <span>Confiance: 94%</span>
                  <span>Sentiment: Positif</span>
                </motion.div>
              )}
            </GlassCard>
          </FadeIn>
        </div>
      </div>
    </section>
  )
}