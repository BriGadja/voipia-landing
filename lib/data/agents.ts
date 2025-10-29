import { Agent } from '@/lib/types/landing';

export const agents: Record<string, Agent> = {
  louis: {
    id: 'louis',
    name: 'louis',
    displayName: 'Louis',
    tagline: 'Rappel automatique de leads',
    description: 'Louis rappelle tous vos nouveaux prospects, les qualifie et les dispatch en moins de 60 secondes. Dès qu\'un lead remplit un formulaire ou laisse ses coordonnées, Louis l\'appelle immédiatement. Il qualifie le besoin, propose un créneau disponible et planifie le RDV directement dans votre agenda. Confirmation automatique par SMS et email. Vos commerciaux arrivent préparés avec tout l\'historique du prospect.',
    color: {
      primary: '#3B82F6', // blue-500
      secondary: '#60A5FA', // blue-400
      gradient: 'from-blue-600 to-cyan-500',
    },
    icon: '📞',
    badge: 'Louis - Rappel automatique',
  },
  arthur: {
    id: 'arthur',
    name: 'arthur',
    displayName: 'Arthur',
    tagline: 'Réactivation de bases dormantes',
    description: 'Arthur relance chaque prospect dormant avec une approche douce et progressive. Vous avez une base de contacts inexploitée ? Arthur la transforme en pipeline actif. Séquences multicanales (appels, SMS, emails), qualification automatique, et relance jusqu\'à conversion. Arthur identifie les meilleurs moments pour recontacter, s\'adapte aux réponses et ne lâche jamais un prospect potentiel.',
    color: {
      primary: '#F59E0B', // amber-500
      secondary: '#FBBF24', // amber-400
      gradient: 'from-orange-600 to-amber-500',
    },
    icon: '🔄',
    badge: 'Arthur - Réactivation de bases',
  },
  alexandra: {
    id: 'alexandra',
    name: 'alexandra',
    displayName: 'Alexandra',
    tagline: 'Réception d\'appels 24/7',
    description: 'Alexandra répond à tous vos appels entrants. Même à 3h du matin. Plus aucun appel manqué. Alexandra décroche en moins de 3 sonneries, filtre les appels indésirables, qualifie les demandes urgentes et planifie des RDV pour les prospects qualifiés. Elle transfère les appels prioritaires à votre équipe en temps réel. Vos clients ont toujours une réponse immédiate.',
    color: {
      primary: '#10B981', // green-500
      secondary: '#34D399', // green-400
      gradient: 'from-green-600 to-emerald-500',
    },
    icon: '☎️',
    badge: 'Alexandra - Réception 24/7',
  },
};

export const getAgent = (agentType: string): Agent | undefined => {
  return agents[agentType];
};

export const getAllAgents = (): Agent[] => {
  return Object.values(agents);
};

export const getOtherAgents = (currentAgentId: string): Agent[] => {
  return Object.values(agents).filter(agent => agent.id !== currentAgentId);
};
