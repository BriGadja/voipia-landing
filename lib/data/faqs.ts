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

// FAQs spécifiques à Arthur
export const arthurFAQs: FAQItem[] = [
  {
    question: 'Que fait exactement Arthur ?',
    answer: 'Arthur réactive automatiquement tous vos leads dormants avec une approche douce et progressive. Il combine appels, SMS et emails de manière personnalisée, qualifie chaque lead, prend des rendez-vous directement dans votre agenda et transfère les opportunités chaudes à votre équipe commerciale. Il fonctionne 24h/24 et 7j/7.',
  },
  {
    question: 'Qu\'est-ce qu\'un "lead dormant" exactement ?',
    answer: 'Un lead dormant est un contact dans votre base de données qui n\'a pas été rappelé, qui n\'a jamais répondu (NRP), qui est resté en attente, ou qui a été contacté il y a plusieurs mois sans suite. Ce sont toutes ces opportunités inexploitées qui représentent un potentiel de CA énorme pour votre entreprise.',
  },
  {
    question: 'Arthur peut-il gérer ma base de données Excel ou mon fichier CRM ?',
    answer: 'Oui, absolument. Vous nous fournissez votre fichier Excel ou votre export CRM, et Arthur intègre automatiquement tous les contacts dans son système de relance. Il peut traiter des bases de 1 000 à 50 000 contacts sans aucun problème.',
  },
  {
    question: 'Arthur peut-il s\'adapter à notre ton ou notre marque ?',
    answer: 'Oui, totalement. Les relances d\'Arthur utilisent votre identité verbale et vos arguments commerciaux, pour que chaque message reste fidèle à votre image de marque. Arthur s\'adapte à votre secteur, votre vocabulaire et votre approche commerciale.',
  },
  {
    question: 'Combien de leads Arthur peut-il traiter par mois ?',
    answer: 'Arthur peut gérer des volumes massifs : de 500 à 10 000+ leads par mois selon votre abonnement. Il orchestre des campagnes parallèles sur plusieurs segments et peut traiter simultanément des centaines de relances progressives.',
  },
  {
    question: 'Que se passe-t-il si un lead répond positivement ?',
    answer: 'Si un lead montre des signes d\'intérêt, Arthur propose immédiatement un rendez-vous dans votre agenda. Si le lead a besoin d\'une conversation humaine approfondie, Arthur transfère intelligemment vers un commercial disponible avec tout l\'historique complet des interactions.',
  },
  {
    question: 'Arthur est-il intrusif ou agressif dans ses relances ?',
    answer: 'Non, au contraire. Arthur déploie une approche douce et progressive qui respecte vos prospects. Ses relances sont espacées intelligemment, personnalisées selon la réaction du lead, et toujours professionnelles. L\'objectif est de réactiver sans agacer.',
  },
  {
    question: 'Peut-on personnaliser la stratégie de relance ?',
    answer: 'Oui, totalement. Vous définissez avec nous la stratégie idéale pour votre secteur : nombre de tentatives, délais entre chaque relance, contenu des messages, règles de priorisation. Arthur exécute ensuite cette stratégie à la perfection.',
  },
  {
    question: 'Quel ROI puis-je espérer avec Arthur ?',
    answer: 'Nos clients génèrent en moyenne 40 000€ de CA supplémentaire par mois en réactivant leur base dormante avec Arthur. Pour un investissement moyen de 900-1500€/mois, Arthur se rentabilise généralement dès la première campagne.',
  },
];

// FAQs spécifiques à Alexandra
export const alexandraFAQs: FAQItem[] = [
  {
    question: 'Que fait exactement Alexandra ?',
    answer: 'Alexandra répond automatiquement à tous vos appels entrants, 24h/24 et 7j/7. Elle répond aux questions de vos clients grâce à votre base de connaissances, filtre les appels indésirables, prend des rendez-vous directement dans votre agenda et transfère les appels importants vers le bon interlocuteur.',
  },
  {
    question: 'Comment Alexandra répond-elle aux questions spécifiques sur mon entreprise ?',
    answer: 'Alexandra utilise une base de connaissances personnalisée que vous alimentez avec toutes les informations sur votre entreprise : produits, services, tarifs, FAQ, processus internes. Plus vous lui donnez d\'informations, plus elle devient experte et précise dans ses réponses.',
  },
  {
    question: 'Alexandra peut-elle vraiment filtrer les appels indésirables ?',
    answer: 'Oui, Alexandra identifie automatiquement les appels de démarchage commercial, les sollicitations non pertinentes et les spams téléphoniques. Vous configurez les règles de filtrage selon vos besoins, et Alexandra ne transfère à votre équipe que les appels à forte valeur ajoutée.',
  },
  {
    question: 'En combien de temps peut-on déployer Alexandra ?',
    answer: 'Alexandra est opérationnelle en moins de 5 jours ouvrés. Ce délai inclut : la configuration complète, la création de votre base de connaissances personnalisée, l\'intégration avec votre CRM et vos outils, les tests et la mise en production.',
  },
  {
    question: 'Quels outils sont compatibles avec Alexandra ?',
    answer: 'Alexandra s\'intègre nativement avec tous les principaux outils : Pipedrive, HubSpot, Salesforce, Google Calendar, Outlook, Calendly, Notion, Slack, Make, Zapier. Si vous utilisez un outil spécifique, contactez-nous pour confirmer la compatibilité.',
  },
  {
    question: 'Alexandra parle-t-elle plusieurs langues ?',
    answer: 'Oui, Alexandra mène des conversations fluides dans plus de 20 langues (français, anglais, espagnol, allemand, italien, portugais...). Elle adapte automatiquement son ton et son approche selon la langue et le pays de votre appelant.',
  },
  {
    question: 'Peut-on écouter les appels traités par Alexandra ?',
    answer: 'Oui, chaque appel est enregistré, transcrit et accessible depuis le dashboard VoIPIA. Vous pouvez les écouter, les analyser et les utiliser pour améliorer continuellement votre base de connaissances et votre service client.',
  },
  {
    question: 'Que se passe-t-il quand Alexandra ne peut pas répondre à une question ?',
    answer: 'Si une question dépasse sa base de connaissances, Alexandra le reconnaît immédiatement. Elle peut soit prendre les coordonnées du client pour qu\'un expert le rappelle, soit transférer l\'appel directement vers un membre disponible de votre équipe avec tout le contexte de la conversation.',
  },
  {
    question: 'Alexandra est-elle conforme RGPD ?',
    answer: 'Oui, absolument. Données hébergées en Europe, chiffrement de bout en bout, conformité RGPD totale. Toutes vos données d\'appels et conversations sont protégées avec le même niveau de sécurité que les institutions bancaires.',
  },
];

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
