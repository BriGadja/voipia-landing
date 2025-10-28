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

// FAQs spécifiques à Louis
export const louisFAQs: FAQItem[] = [
  {
    question: 'Que fait exactement Louis ?',
    answer: 'Louis rappelle automatiquement vos leads entrants, les qualifie selon vos critères (budget, besoin, urgence, autorité) et planifie des rendez-vous directement dans votre agenda. Il fonctionne 24h/24 et 7j/7, sans jamais nécessiter de pause.',
  },
  {
    question: 'En combien de temps Louis rappelle-t-il un lead entrant ?',
    answer: 'Louis rappelle vos leads en moins de 60 secondes. Cette rapidité est cruciale : un lead contacté dans les 5 premières minutes a 9 fois plus de chances d\'être converti qu\'un lead contacté après une heure d\'attente.',
  },
  {
    question: 'En combien de temps peut-on déployer Louis ?',
    answer: 'Louis est opérationnel en moins de 5 jours ouvrés. Ce délai inclut la configuration complète, l\'intégration avec votre CRM, la personnalisation du script vocal et les tests avant mise en production.',
  },
  {
    question: 'Quels outils sont compatibles avec Louis ?',
    answer: 'Louis s\'intègre nativement avec tous les principaux outils : Pipedrive, HubSpot, Salesforce, Google Calendar, Outlook, Calendly, Monday.com, Make, Zapier. Si vous utilisez un outil spécifique, contactez-nous pour confirmer la compatibilité.',
  },
  {
    question: 'Louis parle-t-il plusieurs langues ?',
    answer: 'Oui, Louis mène des conversations fluides dans plus de 20 langues (français, anglais, espagnol, allemand, italien, portugais...). Il adapte automatiquement son ton et son approche culturelle selon le pays de votre prospect.',
  },
  {
    question: 'Peut-on écouter les appels passés par Louis ?',
    answer: 'Oui, chaque appel est enregistré, transcrit et accessible depuis le dashboard VoIPIA. Vous pouvez les écouter, les analyser et les utiliser pour former votre équipe commerciale.',
  },
  {
    question: 'Que se passe-t-il si un prospect ne répond pas ?',
    answer: 'Louis envoie automatiquement un SMS de relance et retente l\'appel selon la séquence définie (par exemple : rappel après 2h, puis le lendemain). Vous configurez la fréquence et le nombre de tentatives.',
  },
  {
    question: 'Louis est-il conforme RGPD ?',
    answer: 'Oui, absolument. Données hébergées en Europe, chiffrement de bout en bout, conformité RGPD totale. Vos données prospects sont protégées avec le même niveau de sécurité que les institutions bancaires.',
  },
  {
    question: 'Que se passe-t-il si un lead pose une question complexe ?',
    answer: 'Louis gère des conversations sophistiquées, mais si une question dépasse son périmètre, il sait le reconnaître et peut soit prendre un rendez-vous pour que votre équipe réponde, soit transférer l\'appel vers un commercial disponible.',
  },
];

// FAQs spécifiques à Arthur (à remplir dans Phase 4)
export const arthurFAQs: FAQItem[] = [];

// FAQs spécifiques à Alexandra (à remplir dans Phase 5)
export const alexandraFAQs: FAQItem[] = [];

// Export FAQs object for easy access
export const faqs = {
  home: homeFAQs,
  louis: louisFAQs,
  arthur: arthurFAQs,
  alexandra: alexandraFAQs,
};

// Helper pour récupérer les FAQs d'un agent
export const getFAQsByAgent = (agentType: string): FAQItem[] => {
  if (agentType === 'louis') return louisFAQs;
  if (agentType === 'arthur') return arthurFAQs;
  if (agentType === 'alexandra') return alexandraFAQs;
  return homeFAQs;
};
