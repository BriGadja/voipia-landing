'use client'

import { motion } from 'framer-motion'
import { ArrowLeft, Phone, Clock, Calendar, Users, CheckCircle, Target } from 'lucide-react'
import Link from 'next/link'
import Button from '@/components/ui/AnimatedButton'
import GlassCard from '@/components/ui/GlassCard'
import FadeIn from '@/components/animations/FadeIn'
import ContactModal from '@/components/ui/ContactModal'
import { useState } from 'react'

const pricingTiers = [
  { leads: '200 leads', price: '300 €', unit: '1,50 €/lead' },
  { leads: '250 leads', price: '367,50 €', unit: '1,47 €/lead' },
  { leads: '500 leads', price: '690 €', unit: '1,38 €/lead' },
  { leads: '900 leads', price: '1 110 €', unit: '1,23 €/lead' },
  { leads: '1 000 leads', price: '1 200 €', unit: '1,20 €/lead' },
  { leads: '1 200 leads', price: '1 350 €', unit: '1,13 €/lead' }
]

const features = [
  'Appel IA immédiat (<1 minute)',
  'Qualification via questions configurées',
  'Prise de rendez-vous dans le calendrier',
  'Transfert direct vers un commercial',
  'Mise à jour automatique du CRM',
  'Notification SMS au prospect',
  'Message vocal en cas de non-réponse'
]

const outputs = [
  'Rendez-vous confirmé',
  'Transfert direct vers un humain',
  'Message vocal laissé',
  'Prospect non qualifié ou non intéressé'
]

const included = [
  'Design des scripts de qualification',
  'Paramétrage du scénario d\'appel IA',
  'Attribution d\'un numéro mobile dédié (07 inclus)',
  'Connexion au calendrier (Google, Outlook)',
  'Connexion CRM (mise à jour en temps réel)',
  'Monitoring technique 24/7 + maintenance proactive',
  'Reporting des RDV pris, objections et non-réponses'
]

export default function LouisPage() {
  const [isContactModalOpen, setIsContactModalOpen] = useState(false)

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-violet-900">
      <div className="absolute inset-0">
        <div className="absolute top-20 left-20 w-72 h-72 bg-blue-500 rounded-full blur-3xl opacity-20 animate-pulse" />
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-purple-500 rounded-full blur-3xl opacity-20 animate-pulse animation-delay-400" />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-20 relative z-10">
        {/* Header */}
        <FadeIn>
          <div className="flex items-center gap-4 mb-8">
            <Link href="/" className="flex items-center gap-2 text-white/80 hover:text-white transition-colors">
              <ArrowLeft className="w-5 h-5" />
              Retour à l&apos;accueil
            </Link>
          </div>

          <div className="flex items-center gap-6 mb-12">
            <motion.div
              className="w-24 h-24 rounded-3xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center text-white text-4xl font-bold shadow-lg"
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
              L
            </motion.div>
            <div>
              <h1 className="text-5xl lg:text-6xl font-bold text-white mb-2">Louis</h1>
              <p className="text-xl text-blue-400 font-medium">Spécialiste rappel & RDV</p>
            </div>
          </div>
        </FadeIn>

        {/* Mission */}
        <FadeIn delay={0.1}>
          <GlassCard className="p-8 mb-12">
            <div className="flex items-start gap-4 mb-6">
              <div className="w-12 h-12 rounded-xl bg-blue-500/20 flex items-center justify-center">
                <Target className="w-6 h-6 text-blue-400" />
              </div>
              <div>
                <h2 className="text-2xl font-bold text-white mb-4">Mission</h2>
                <p className="text-lg text-gray-300 leading-relaxed">
                  Rappeler instantanément (&lt;1 min) chaque lead entrant issu d&apos;un formulaire, d&apos;une publicité
                  ou d&apos;une landing page, et transformer ce contact en rendez-vous confirmé.
                </p>
              </div>
            </div>
          </GlassCard>
        </FadeIn>

        <div className="grid lg:grid-cols-2 gap-8 mb-12">
          {/* Fonctionnalités */}
          <FadeIn delay={0.2}>
            <GlassCard className="p-8">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-10 h-10 rounded-lg bg-blue-500/20 flex items-center justify-center">
                  <Phone className="w-5 h-5 text-blue-400" />
                </div>
                <h3 className="text-2xl font-bold text-white">Fonctionnalités</h3>
              </div>
              <div className="space-y-4">
                {features.map((feature, index) => (
                  <motion.div
                    key={index}
                    className="flex items-start gap-3"
                    initial={{ opacity: 0, x: -20 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                  >
                    <CheckCircle className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
                    <span className="text-gray-300">{feature}</span>
                  </motion.div>
                ))}
              </div>
            </GlassCard>
          </FadeIn>

          {/* Sorties */}
          <FadeIn delay={0.3}>
            <GlassCard className="p-8">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-10 h-10 rounded-lg bg-green-500/20 flex items-center justify-center">
                  <Users className="w-5 h-5 text-green-400" />
                </div>
                <h3 className="text-2xl font-bold text-white">Sorties possibles</h3>
              </div>
              <div className="space-y-4">
                {outputs.map((output, index) => (
                  <motion.div
                    key={index}
                    className="flex items-start gap-3"
                    initial={{ opacity: 0, x: -20 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                  >
                    <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0 mt-0.5" />
                    <span className="text-gray-300">{output}</span>
                  </motion.div>
                ))}
              </div>
            </GlassCard>
          </FadeIn>
        </div>

        {/* Ce qui est inclus */}
        <FadeIn delay={0.4}>
          <GlassCard className="p-8 mb-12">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-lg bg-purple-500/20 flex items-center justify-center">
                <Calendar className="w-5 h-5 text-purple-400" />
              </div>
              <h3 className="text-2xl font-bold text-white">Ce que comprend l&apos;activation de Louis</h3>
            </div>
            <div className="grid md:grid-cols-2 gap-4">
              {included.map((item, index) => (
                <motion.div
                  key={index}
                  className="flex items-start gap-3"
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                >
                  <CheckCircle className="w-5 h-5 text-purple-400 flex-shrink-0 mt-0.5" />
                  <span className="text-gray-300">{item}</span>
                </motion.div>
              ))}
            </div>
          </GlassCard>
        </FadeIn>

        {/* Tarification */}
        <FadeIn delay={0.5}>
          <GlassCard className="p-8 mb-12">
            <div className="flex items-center gap-3 mb-8">
              <div className="w-10 h-10 rounded-lg bg-yellow-500/20 flex items-center justify-center">
                <Clock className="w-5 h-5 text-yellow-400" />
              </div>
              <h3 className="text-2xl font-bold text-white">Tarifs Louis - Abonnement mensuel</h3>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
              {pricingTiers.map((tier, index) => (
                <motion.div
                  key={index}
                  className="p-4 rounded-xl border border-white/20 bg-white/5"
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                >
                  <div className="text-center">
                    <div className="text-lg font-semibold text-white mb-1">{tier.leads}</div>
                    <div className="text-2xl font-bold text-blue-400 mb-1">{tier.price}</div>
                    <div className="text-sm text-gray-400">{tier.unit}</div>
                  </div>
                </motion.div>
              ))}
            </div>

            <div className="bg-blue-500/10 border border-blue-500/20 rounded-xl p-4">
              <p className="text-blue-300 font-medium text-center">
                Au-delà de 1000 leads : +0,75 €/lead supplémentaire
              </p>
            </div>
          </GlassCard>
        </FadeIn>

        {/* CTA */}
        <FadeIn delay={0.6}>
          <div className="text-center">
            <h2 className="text-3xl font-bold text-white mb-4">
              Prêt à automatiser vos rappels de leads ?
            </h2>
            <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
              Transformez vos leads entrants en rendez-vous confirmés sans effort humain.
            </p>
            <Button
              size="lg"
              onClick={() => setIsContactModalOpen(true)}
              className="group"
            >
              <span className="flex items-center gap-2">
                <Phone className="w-5 h-5 group-hover:animate-pulse" />
                Activer Louis maintenant
              </span>
            </Button>
          </div>
        </FadeIn>
      </div>

      <ContactModal
        isOpen={isContactModalOpen}
        onClose={() => setIsContactModalOpen(false)}
        title="Activer Louis - Spécialiste rappel & RDV"
      />
    </div>
  )
}