'use client';

import { Card } from '@/components/shared/Card';
import { Database, MessageCircle, Target, Users, ArrowRightLeft, BarChart3 } from 'lucide-react';

const useCases = [
  {
    icon: Database,
    title: 'Réactivation automatique des bases dormantes',
    description:
      "Arthur relance vos leads oubliés et redonne vie à votre CRM. Il prend en charge tous vos prospects jamais contactés, contacts sans réponse (NRP), opportunités en attente ou anciens leads froids. Chaque opportunité inexploitée devient un potentiel de CA.",
  },
  {
    icon: MessageCircle,
    title: 'Approche naturelle et personnalisée',
    description:
      "Arthur combine intelligemment les appels téléphoniques, SMS et emails pour maximiser le taux de réponse. Son approche est progressive et non intrusive : il adapte sa stratégie de relance selon la réaction de chaque prospect pour ne jamais être perçu comme intrusif ou agressif.",
  },
  {
    icon: Target,
    title: 'Priorisation des leads chauds',
    description:
      "À chaque point de contact, Arthur qualifie et met à jour le statut du lead : chaud (prêt pour RDV commercial), tiède (intéressé mais pas encore prêt), ou froid (à recontacter plus tard). Votre équipe ne traite que les leads réactivés à forte valeur ajoutée.",
  },
  {
    icon: Users,
    title: 'Vos commerciaux ne gèrent plus les rappels manuels',
    description:
      "Dès qu'un lead dormant montre des signes d'intérêt, Arthur propose immédiatement un rendez-vous directement dans votre agenda. Le rendez-vous est confirmé par SMS et email avec rappels automatiques. Vos commerciaux arrivent préparés avec tout l'historique de réactivation.",
  },
  {
    icon: ArrowRightLeft,
    title: 'Handover fluide vers votre équipe',
    description:
      "Si un lead réactivé nécessite une conversation humaine approfondie, Arthur transfère intelligemment l'opportunité vers un commercial disponible avec tout le contexte et l'historique complet des interactions. Le passage de relais est transparent et professionnel.",
  },
  {
    icon: BarChart3,
    title: 'Reporting simple et transparent',
    description:
      "Arthur fournit un reporting simple et transparent pour suivre le ROI de vos campagnes : nombre de leads traités, taux de réactivation, rendez-vous pris, CA généré. Toutes les statistiques sont accessibles depuis votre espace VoIPIA et synchronisées avec votre CRM.",
  },
];

export function UseCasesArthur() {
  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">
        {/* Section header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Ce qu&apos;</span>
            <span className="bg-gradient-to-r from-orange-400 to-amber-400 bg-clip-text text-transparent">
              Arthur fait pour vous
            </span>
          </h2>
        </div>

        {/* Use cases grid (3x2) */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-7xl mx-auto">
          {useCases.map((useCase, index) => {
            const Icon = useCase.icon;
            return (
              <Card key={index} variant="gradient" className="p-6">
                {/* Icon */}
                <div className="w-12 h-12 rounded-lg bg-orange-500/10 flex items-center justify-center mb-4">
                  <Icon className="w-6 h-6 text-orange-400" />
                </div>

                {/* Title */}
                <h3 className="text-lg font-bold text-white mb-3">
                  {useCase.title}
                </h3>

                {/* Description */}
                <p className="text-gray-300 text-sm leading-relaxed">
                  {useCase.description}
                </p>
              </Card>
            );
          })}
        </div>
      </div>
    </section>
  );
}
