'use client'

import { motion } from 'framer-motion'
import { ArrowLeft, Phone, Clock, Calendar, Users, CheckCircle, Target, RefreshCw } from 'lucide-react'
import Link from 'next/link'
import Button from '@/components/ui/Button'
import GlassCard from '@/components/ui/GlassCard'
import FadeIn from '@/components/animations/FadeIn'
import ContactModal from '@/components/ui/ContactModal'
import { useState } from 'react'

const pricingTiers = [
  { leads: '200 leads', price: '450 €', unit: '2,25 €/lead' },
  { leads: '250 leads', price: '545 €', unit: '2,18 €/lead' },
  { leads: '500 leads', price: '870 €', unit: '1,74 €/lead' },
  { leads: '900 leads', price: '1 300 €', unit: '1,44 €/lead' },
  { leads: '1 200 leads', price: '1 700 €', unit: '1,42 €/lead' }
]

const features = [
  'Jusqu\'à 9 tentatives par lead (5 appels, 2 SMS, 2 emails)',
  'Qualification personnalisée selon vos critères',
  'Prise de rendez-vous avec intégration calendrier',
  'Transfert direct vers un commercial',
  'Synchronisation CRM en temps réel',
  'Relances multicanales coordonnées'
]

const outputs = [
  'Rendez-vous confirmé',
  'Transfert vers un humain en temps réel',
  'Pas intéressé / hors critères',
  'À recontacter plus tard',
  'Lead mort après 6 tentatives sans succès'
]

const included = [
  'Design des scripts vocaux + rédaction des messages SMS & emails',
  'Paramétrage de scénarios d\'appel IA avec relances programmées',
  'Attribution d\'un numéro mobile dédié (07 inclus)',
  'Connexion CRM (import, mise à jour en temps réel)',
  'Monitoring technique 24/7 + maintenance proactive',
  'Reporting hebdomadaire : RDV pris, désintérêts, objections'
]

export default function ArthurPage() {
  const [isContactModalOpen, setIsContactModalOpen] = useState(false)

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-orange-900 to-red-900">
      <div className="absolute inset-0">
        <div className="absolute top-20 left-20 w-72 h-72 bg-orange-500 rounded-full blur-3xl opacity-20 animate-pulse" />
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-red-500 rounded-full blur-3xl opacity-20 animate-pulse animation-delay-400" />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-20 relative z-10">
        {/* Header */}
        <FadeIn>
          <div className="flex items-center gap-4 mb-8">
            <Link href="/" className="flex items-center gap-2 text-white/80 hover:text-white transition-colors">
              <ArrowLeft className="w-5 h-5" />
              Retour à l'accueil
            </Link>
          </div>

          <div className="flex items-center gap-6 mb-12">
            <motion.div
              className="w-24 h-24 rounded-3xl bg-gradient-to-br from-orange-500 to-orange-600 flex items-center justify-center text-white text-4xl font-bold shadow-lg"
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
              A
            </motion.div>
            <div>
              <h1 className="text-5xl lg:text-6xl font-bold text-white mb-2">Arthur</h1>
              <p className="text-xl text-orange-400 font-medium">Expert prospection</p>
            </div>
          </div>
        </FadeIn>

        {/* Mission */}
        <FadeIn delay={0.1}>
          <GlassCard className="p-8 mb-12">
            <div className="flex items-start gap-4 mb-6">
              <div className="w-12 h-12 rounded-xl bg-orange-500/20 flex items-center justify-center">
                <RefreshCw className="w-6 h-6 text-orange-400" />
              </div>
              <div>
                <h2 className="text-2xl font-bold text-white mb-4">Mission</h2>
                <p className="text-lg text-gray-300 leading-relaxed">
                  Réactiver vos bases de contacts dormants et les travailler jusqu'à obtenir un statut final clair :
                  rendez-vous, à recontacter ou lead mort.
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
                <div className="w-10 h-10 rounded-lg bg-orange-500/20 flex items-center justify-center">
                  <Phone className="w-5 h-5 text-orange-400" />
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
                    <CheckCircle className="w-5 h-5 text-orange-400 flex-shrink-0 mt-0.5" />
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
              <h3 className="text-2xl font-bold text-white">Ce que comprend l'activation d'Arthur</h3>
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

        {/* Processus multicanal */}
        <FadeIn delay={0.45}>
          <GlassCard className="p-8 mb-12">
            <h3 className="text-2xl font-bold text-white mb-6">Processus multicanal intelligent</h3>
            <div className="grid md:grid-cols-3 gap-6">
              <div className="text-center">
                <div className="w-16 h-16 rounded-full bg-orange-500/20 flex items-center justify-center mx-auto mb-4">
                  <Phone className="w-8 h-8 text-orange-400" />
                </div>
                <h4 className="text-lg font-semibold text-white mb-2">5 Appels</h4>
                <p className="text-gray-400 text-sm">Tentatives d'appel personnalisées avec scripts adaptatifs</p>
              </div>
              <div className="text-center">
                <div className="w-16 h-16 rounded-full bg-blue-500/20 flex items-center justify-center mx-auto mb-4">
                  <span className="text-blue-400 font-bold">SMS</span>
                </div>
                <h4 className="text-lg font-semibold text-white mb-2">2 SMS</h4>
                <p className="text-gray-400 text-sm">Messages texte ciblés pour maintenir l'engagement</p>
              </div>
              <div className="text-center">
                <div className="w-16 h-16 rounded-full bg-purple-500/20 flex items-center justify-center mx-auto mb-4">
                  <span className="text-purple-400 font-bold">@</span>
                </div>
                <h4 className="text-lg font-semibold text-white mb-2">2 Emails</h4>
                <p className="text-gray-400 text-sm">Emails de relance professionnels et personnalisés</p>
              </div>
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
              <h3 className="text-2xl font-bold text-white">Tarifs Arthur - Abonnement mensuel</h3>
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
                    <div className="text-2xl font-bold text-orange-400 mb-1">{tier.price}</div>
                    <div className="text-sm text-gray-400">{tier.unit}</div>
                  </div>
                </motion.div>
              ))}
            </div>

            <div className="bg-orange-500/10 border border-orange-500/20 rounded-xl p-4">
              <p className="text-orange-300 font-medium text-center">
                Au-delà de 1000 leads : +1 €/lead supplémentaire
              </p>
            </div>
          </GlassCard>
        </FadeIn>

        {/* Pourquoi Arthur */}
        <FadeIn delay={0.55}>
          <GlassCard className="p-8 mb-12">
            <h3 className="text-2xl font-bold text-white mb-6">Pourquoi chaque action est facturée ?</h3>
            <p className="text-gray-300 mb-4">
              Chaque relance d'un lead dormant active un enchaînement complet :
            </p>
            <div className="grid md:grid-cols-2 gap-4">
              <div className="flex items-center gap-3">
                <CheckCircle className="w-5 h-5 text-orange-400 flex-shrink-0" />
                <span className="text-gray-300">Téléphonie + moteur vocal IA</span>
              </div>
              <div className="flex items-center gap-3">
                <CheckCircle className="w-5 h-5 text-orange-400 flex-shrink-0" />
                <span className="text-gray-300">Génération et envoi des SMS + emails</span>
              </div>
              <div className="flex items-center gap-3">
                <CheckCircle className="w-5 h-5 text-orange-400 flex-shrink-0" />
                <span className="text-gray-300">Workflow de qualification intelligent</span>
              </div>
              <div className="flex items-center gap-3">
                <CheckCircle className="w-5 h-5 text-orange-400 flex-shrink-0" />
                <span className="text-gray-300">Monitoring serveur + supervision humaine</span>
              </div>
            </div>
            <div className="mt-6 p-4 bg-orange-500/10 border border-orange-500/20 rounded-xl">
              <p className="text-orange-300 font-medium">
                Un traitement Arthur = une mini-campagne multicanale complète
              </p>
            </div>
          </GlassCard>
        </FadeIn>

        {/* CTA */}
        <FadeIn delay={0.6}>
          <div className="text-center">
            <h2 className="text-3xl font-bold text-white mb-4">
              Prêt à réactiver vos leads dormants ?
            </h2>
            <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
              Transformez vos bases de données dormantes en nouveaux rendez-vous qualifiés sans effort humain.
            </p>
            <Button
              size="lg"
              onClick={() => setIsContactModalOpen(true)}
              className="group bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600"
            >
              <span className="flex items-center gap-2">
                <RefreshCw className="w-5 h-5 group-hover:animate-spin" />
                Activer Arthur maintenant
              </span>
            </Button>
          </div>
        </FadeIn>
      </div>

      <ContactModal
        isOpen={isContactModalOpen}
        onClose={() => setIsContactModalOpen(false)}
        title="Activer Arthur - Expert prospection"
      />
    </div>
  )
}