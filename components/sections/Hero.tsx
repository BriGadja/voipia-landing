'use client'

import { useState } from 'react'
import Button from '@/components/ui/Button'
import ContactModal from '@/components/ui/ContactModal'
import FadeIn from '@/components/animations/FadeIn'
import { motion } from 'framer-motion'
import { Phone, Sparkles } from 'lucide-react'

export default function Hero() {
  const [isContactModalOpen, setIsContactModalOpen] = useState(false)
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      <div className="absolute inset-0 gradient-mesh opacity-30 dark:opacity-20" />
      
      <div className="absolute inset-0">
        <div className="absolute top-20 left-20 w-72 h-72 bg-purple-500 rounded-full blur-3xl opacity-20 animate-pulse" />
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-blue-500 rounded-full blur-3xl opacity-20 animate-pulse animation-delay-400" />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="text-center max-w-5xl mx-auto">
          <FadeIn delay={0.1}>
            <motion.div 
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ duration: 0.5 }}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 backdrop-blur-md border border-white/20 mb-8"
            >
              <Sparkles className="w-4 h-4 text-yellow-400" />
              <span className="text-sm font-medium text-white">Intelligence artificielle de pointe</span>
            </motion.div>
          </FadeIn>

          <FadeIn delay={0.2}>
            <h1 className="text-5xl sm:text-6xl lg:text-7xl font-bold text-white mb-6">
              Vos agents vocaux IA
              <span className="block text-gradient mt-2">disponibles 24/7</span>
            </h1>
          </FadeIn>

          <FadeIn delay={0.3}>
            <p className="text-xl sm:text-2xl text-gray-300 dark:text-gray-400 mb-12 max-w-3xl mx-auto">
              Louis et Arthur transforment vos appels en opportunités.
              Augmentez votre performance commerciale avec l&apos;IA conversationnelle.
            </p>
          </FadeIn>

          <FadeIn delay={0.4}>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button 
                size="lg" 
                className="group"
                onClick={() => setIsContactModalOpen(true)}
              >
                <span className="flex items-center gap-2">
                  <Phone className="w-5 h-5 group-hover:animate-pulse" />
                  Je veux une démo
                </span>
              </Button>
              <Button 
                variant="secondary" 
                size="lg"
                onClick={() => document.getElementById('agents')?.scrollIntoView({ behavior: 'smooth' })}
              >
                Découvrir nos agents
              </Button>
            </div>
          </FadeIn>

          <FadeIn delay={0.5} className="mt-16">
            <div className="flex flex-wrap justify-center gap-8 text-white/60">
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                <span>Latence &lt; 2 secondes</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                <span>100% en français</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                <span>Intégration CRM native</span>
              </div>
            </div>
          </FadeIn>
        </div>
      </div>

      <motion.div
        className="absolute bottom-10 left-1/2 transform -translate-x-1/2"
        animate={{ y: [0, 10, 0] }}
        transition={{ duration: 2, repeat: Infinity }}
      >
        <div className="w-6 h-10 border-2 border-white/30 rounded-full flex justify-center">
          <div className="w-1 h-3 bg-white/60 rounded-full mt-2 animate-bounce" />
        </div>
      </motion.div>

      <ContactModal 
        isOpen={isContactModalOpen}
        onClose={() => setIsContactModalOpen(false)}
        title="Demander une démo gratuite"
      />
    </section>
  )
}