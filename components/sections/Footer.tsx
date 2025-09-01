'use client'

import { motion } from 'framer-motion'
import FadeIn from '@/components/animations/FadeIn'
import Button from '@/components/ui/Button'
import { Phone, Calendar, ArrowRight } from 'lucide-react'
import { useState } from 'react'
import ContactModal from '@/components/ui/ContactModal'

export default function Footer() {
  const [isContactModalOpen, setIsContactModalOpen] = useState(false)

  return (
    <>
      <section className="py-20 lg:py-32 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-purple-600 via-blue-600 to-indigo-600" />
        <div className="absolute inset-0 gradient-mesh opacity-30" />
        
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative">
          <FadeIn>
            <div className="text-center mb-12">
              <h2 className="text-4xl lg:text-6xl font-bold text-white mb-6">
                Prêt à transformer
                <span className="block">vos appels ?</span>
              </h2>
              <p className="text-xl text-white/80 max-w-3xl mx-auto mb-8">
                Rejoignez les 500+ entreprises qui font confiance à nos agents IA pour améliorer leur performance commerciale
              </p>
            </div>
          </FadeIn>

          <FadeIn delay={0.2}>
            <div className="flex justify-center mb-16">
              <Button 
                size="lg" 
                variant="secondary" 
                className="group"
                onClick={() => setIsContactModalOpen(true)}
              >
                <span className="flex items-center gap-2">
                  <Phone className="w-5 h-5 group-hover:animate-pulse" />
                  Être contacté sous 24h
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                </span>
              </Button>
            </div>
          </FadeIn>

          <FadeIn delay={0.4}>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center text-white/80">
              <div className="flex flex-col items-center">
                <motion.div
                  whileHover={{ scale: 1.1, rotate: 5 }}
                  className="w-12 h-12 rounded-xl bg-white/10 backdrop-blur-md flex items-center justify-center mb-4"
                >
                  <Phone className="w-6 h-6" />
                </motion.div>
                <h3 className="font-semibold mb-2">Support dédié</h3>
                <p className="text-sm">Accompagnement personnalisé pour votre mise en place</p>
              </div>
              <div className="flex flex-col items-center">
                <motion.div
                  whileHover={{ scale: 1.1, rotate: -5 }}
                  className="w-12 h-12 rounded-xl bg-white/10 backdrop-blur-md flex items-center justify-center mb-4"
                >
                  <Calendar className="w-6 h-6" />
                </motion.div>
                <h3 className="font-semibold mb-2">Déploiement rapide</h3>
                <p className="text-sm">Vos agents actifs en moins de 48h</p>
              </div>
              <div className="flex flex-col items-center">
                <motion.div
                  whileHover={{ scale: 1.1, rotate: 5 }}
                  className="w-12 h-12 rounded-xl bg-white/10 backdrop-blur-md flex items-center justify-center mb-4"
                >
                  <ArrowRight className="w-6 h-6" />
                </motion.div>
                <h3 className="font-semibold mb-2">Résultats garantis</h3>
                <p className="text-sm">ROI positif dès le premier mois</p>
              </div>
            </div>
          </FadeIn>
        </div>

        <motion.div
          className="absolute top-10 left-10 w-32 h-32 bg-white/10 rounded-full blur-2xl"
          animate={{
            scale: [1, 1.2, 1],
            opacity: [0.3, 0.6, 0.3],
          }}
          transition={{ duration: 4, repeat: Infinity }}
        />
        <motion.div
          className="absolute bottom-10 right-10 w-40 h-40 bg-white/10 rounded-full blur-2xl"
          animate={{
            scale: [1, 0.8, 1],
            opacity: [0.2, 0.5, 0.2],
          }}
          transition={{ duration: 6, repeat: Infinity }}
        />
      </section>
      <ContactModal 
        isOpen={isContactModalOpen} 
        onClose={() => setIsContactModalOpen(false)} 
      />
    </>
  )
}