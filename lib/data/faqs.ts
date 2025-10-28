import { FAQItem } from '@/lib/types/landing';

// FAQs générales pour la Home
export const homeFAQs: FAQItem[] = [
  {
    question: "Comment VoIPIA fonctionne-t-il ?",
    answer: "VoIPIA s'intègre à votre CRM et déclenche automatiquement des appels selon vos règles. Chaque agent (Louis, Arthur, Alexandra) a une spécialité : rappel de leads, réactivation, réception d'appels.",
  },
  {
    question: "Combien de temps pour déployer un agent ?",
    answer: "Moins de 5 jours ouvrés. Nous configurons l'agent selon vos processus, l'intégrons à vos outils, et vous accompagnons pour les premiers appels.",
  },
  {
    question: "Puis-je personnaliser les scripts ?",
    answer: "Oui, totalement. Chaque agent s'adapte à votre ton, vos arguments commerciaux, et vos processus métier.",
  },
  {
    question: "Comment sont facturés les appels ?",
    answer: "Abonnement mensuel fixe + consommation (0.27€/appel, 0.14€/SMS). Exemple : pour 300 leads/mois avec Louis, comptez ~360€ TTC.",
  },
  {
    question: "Les agents peuvent-ils prendre des RDV ?",
    answer: "Oui, ils se connectent à votre agenda (Google Calendar, Outlook, Calendly) et planifient automatiquement les RDV selon vos disponibilités.",
  },
  {
    question: "Quelle est la qualité vocale ?",
    answer: "Nous utilisons les meilleurs modèles IA du marché (Eleven Labs, Cartesia) pour une voix naturelle et fluide. Écoutez nos démos pour vous faire une idée.",
  },
  {
    question: "Puis-je utiliser plusieurs agents ?",
    answer: "Oui, et c'est recommandé ! Nos clients combinent souvent Louis (rappel leads) + Alexandra (réception) ou Arthur (réactivation) selon leurs besoins.",
  },
];

// FAQs spécifiques à Louis (à remplir dans Phase 3)
export const louisFAQs: FAQItem[] = [];

// FAQs spécifiques à Arthur (à remplir dans Phase 4)
export const arthurFAQs: FAQItem[] = [];

// FAQs spécifiques à Alexandra (à remplir dans Phase 5)
export const alexandraFAQs: FAQItem[] = [];

// Helper pour récupérer les FAQs d'un agent
export const getFAQsByAgent = (agentType: string): FAQItem[] => {
  if (agentType === 'louis') return louisFAQs;
  if (agentType === 'arthur') return arthurFAQs;
  if (agentType === 'alexandra') return alexandraFAQs;
  return homeFAQs;
};
