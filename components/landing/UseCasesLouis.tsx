'use client';

import { Card } from '@/components/shared/Card';
import { Clock, CalendarCheck, TrendingUp, MessageSquare, FileText, BarChart3 } from 'lucide-react';

const useCases = [
  {
    icon: Clock,
    title: 'Qualification des leads entrants 24/7',
    description: 'Louis rappelle instantanément chaque lead généré par vos campagnes (Meta Ads, Google Ads), formulaires ou appels manqués. Weekend, nuit, jours fériés : Louis ne dort jamais et garantit une réponse en moins d\'une minute.',
  },
  {
    icon: CalendarCheck,
    title: 'Prise de rendez-vous automatique',
    description: 'Louis accède à votre agenda en temps réel et réserve directement des créneaux avec vos commerciaux. Plus d\'allers-retours par email : Louis gère tout de bout en bout et confirme chaque rendez-vous.',
  },
  {
    icon: TrendingUp,
    title: 'Scoring avancé des prospects',
    description: 'Chaque conversation est analysée et chaque lead reçoit un score de qualité basé sur vos critères personnalisés. Louis identifie automatiquement vos prospects à forte valeur et priorise les opportunités les plus prometteuses.',
  },
  {
    icon: MessageSquare,
    title: 'Envoi de SMS automatique',
    description: 'Louis envoie un SMS avant l\'appel pour prévenir le prospect (augmente le taux de réponse) ou après l\'appel pour confirmer le rendez-vous. Cette approche multicanal maximise vos chances de contact.',
  },
  {
    icon: FileText,
    title: 'Transcription et analyse des appels',
    description: 'Tous les appels sont enregistrés, transcrits et analysés pour vous fournir des insights précieux sur les objections et besoins récurrents. Vous disposez d\'un historique complet et exploitable, accessible depuis le dashboard VoIPIA.',
  },
  {
    icon: BarChart3,
    title: 'Dashboard & reporting transparent',
    description: 'Suivez les performances en temps réel : nombre d\'appels, durée moyenne, taux de contact, taux de rendez-vous pris, taux de qualification, volume traité. Toutes les statistiques sont accessibles depuis votre espace VoIPIA et synchronisées avec votre CRM.',
  },
];

export function UseCasesLouis() {
  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Ce que Louis fait pour vous
          </h2>
        </div>

        {/* Grid 3x2 */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-7xl mx-auto">
          {useCases.map((useCase, idx) => (
            <Card key={idx} variant="gradient" className="p-6 hover:scale-105 transition-transform duration-300">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center mb-4">
                <useCase.icon className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-lg font-bold text-white mb-3">
                {useCase.title}
              </h3>
              <p className="text-gray-300 text-sm leading-relaxed">
                {useCase.description}
              </p>
            </Card>
          ))}
        </div>

      </div>
    </section>
  );
}
