export const agents = [
  {
    id: 'louis',
    name: 'Louis',
    title: 'Spécialiste rappel & RDV',
    color: 'louis',
    gradient: 'from-blue-500 to-blue-600',
    description: 'Votre expert en qualification de leads et prise de rendez-vous',
    capabilities: [
      'Rappel automatique des leads en moins de 5 minutes',
      'Qualification intelligente selon vos critères',
      'Prise de RDV directement dans votre agenda',
      'Relance automatique des prospects tièdes'
    ],
    stats: '500+ appels/jour',
    audioDemo: '/demos/louis-demo.mp3'
  },
  {
    id: 'arthur',
    name: 'Arthur',
    title: 'Expert prospection',
    color: 'arthur',
    gradient: 'from-arthur to-orange-600',
    description: 'Réveillez votre base dormante et générez de nouvelles opportunités',
    capabilities: [
      'Réactivation de votre base clients dormante',
      'Prospection ciblée selon votre ICP',
      'Scripts personnalisés et adaptatifs',
      'Détection des signaux d\'achat'
    ],
    stats: '31% de contacts réactivés',
    audioDemo: '/demos/arthur-demo.mp3'
  },
  {
    id: 'alexandra',
    name: 'Alexandra',
    title: 'Standardiste IA',
    color: 'alexandra',
    gradient: 'from-alexandra to-green-600',
    description: 'Votre réceptionniste virtuelle disponible 24/7',
    capabilities: [
      'Accueil professionnel de tous vos appels',
      'Transfert intelligent vers le bon interlocuteur',
      'Prise de messages détaillés',
      'Gestion des urgences selon vos protocoles'
    ],
    stats: '24/7 disponibilité',
    audioDemo: '/demos/alexandra-demo.mp3'
  }
]

export const metrics = [
  {
    value: '+31%',
    label: 'de contacts qualifiés',
    description: 'Augmentation moyenne constatée',
    gradient: 'from-purple-500 to-blue-500'
  },
  {
    value: '24/7',
    label: 'Disponibilité totale',
    description: 'Vos agents ne dorment jamais',
    gradient: 'from-blue-500 to-cyan-500'
  },
  {
    value: '500ms',
    label: 'Temps de latence',
    description: 'Conversation naturelle et fluide',
    gradient: 'from-green-500 to-emerald-500'
  },
  {
    value: '100%',
    label: 'Des appels traités',
    description: 'Aucun appel manqué',
    gradient: 'from-orange-500 to-red-500'
  }
]

export const howItWorksSteps = [
  {
    number: '01',
    title: 'Connexion instantanée',
    description: 'Connectez votre CRM et votre téléphonie en quelques clics',
    icon: 'Plug'
  },
  {
    number: '02',
    title: 'Configuration sur-mesure',
    description: 'Personnalisez vos agents selon vos besoins et objectifs',
    icon: 'Settings'
  },
  {
    number: '03',
    title: 'Lancement automatique',
    description: 'Vos agents commencent à travailler immédiatement',
    icon: 'Rocket'
  },
  {
    number: '04',
    title: 'Reporting avancé',
    description: 'Suivez les performances de chaque agent avec des rapports détaillés en temps réel',
    icon: 'BarChart'
  }
]

export const chatbotConfig = {
  webhookUrl: 'https://n8n.voipia.fr/webhook/chatbot-iapreneurs',
  welcomeMessage: 'Bonjour ! Je suis l\'assistant IA de Voipia. Comment puis-je vous aider aujourd\'hui ?',
  placeholder: 'Écrivez votre message...',
  maxMessages: 100,
  timeoutMs: 10000,
  title: 'Assistant Voipia',
  subtitle: 'Découvrez nos agents IA'
}