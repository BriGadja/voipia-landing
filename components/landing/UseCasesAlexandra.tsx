'use client';

import { Card } from '@/components/shared/Card';
import { Clock, BookOpen, Shield, CalendarCheck, ArrowRightLeft, BarChart3 } from 'lucide-react';

const useCases = [
  {
    icon: Clock,
    title: 'Réception d\'appels 24/7 sans interruption',
    description: 'Alexandra répond instantanément à chaque appel, même en dehors de vos horaires d\'ouverture. Weekend, nuit, jours fériés, période de forte affluence : Alexandra ne dort jamais et garantit que vos clients ne tombent plus jamais sur un répondeur.',
  },
  {
    icon: BookOpen,
    title: 'Réponse aux questions grâce à votre base de connaissances',
    description: 'Alimentez Alexandra avec toutes les informations sur votre entreprise : produits, services, tarifs, FAQ, processus. Elle devient votre expert interne et répond précisément aux questions de vos appelants, réduisant drastiquement les demandes répétitives pour votre équipe.',
  },
  {
    icon: Shield,
    title: 'Filtrage automatique des appels',
    description: 'Alexandra identifie et filtre les appels indésirables (démarchage commercial, spam, sollicitations). Elle ne transfère à votre équipe que les appels à forte valeur ajoutée, vous faisant gagner un temps précieux et améliorant votre concentration.',
  },
  {
    icon: CalendarCheck,
    title: 'Prise de rendez-vous automatique',
    description: 'Alexandra accède à votre agenda en temps réel et réserve directement des créneaux selon vos disponibilités. Elle confirme le rendez-vous par SMS et email, et envoie des rappels automatiques pour réduire le no-show.',
  },
  {
    icon: ArrowRightLeft,
    title: 'Transfert et dispatch des appels',
    description: 'Selon la nature de la demande et vos règles de routage, Alexandra peut transférer l\'appel vers le bon service ou la bonne personne (commercial, support, direction). Le destinataire reçoit instantanément le contexte complet de l\'appel avant de décrocher.',
  },
  {
    icon: BarChart3,
    title: 'Dashboard & reporting transparent',
    description: 'Suivez les performances en temps réel : nombre d\'appels reçus, durée moyenne, taux de réponse, motifs d\'appels, rendez-vous pris, appels transférés. Toutes les statistiques sont accessibles depuis votre espace VoIPIA et synchronisées avec votre CRM.',
  },
];

export function UseCasesAlexandra() {
  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Ce qu&apos;Alexandra fait pour vous
          </h2>
        </div>

        {/* Grid 3x2 */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-7xl mx-auto">
          {useCases.map((useCase, idx) => (
            <Card key={idx} variant="gradient" className="p-6 hover:scale-105 transition-transform duration-300">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-green-500 to-emerald-500 flex items-center justify-center mb-4">
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
