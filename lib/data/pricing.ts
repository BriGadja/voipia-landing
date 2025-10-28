import { PricingTier } from '@/lib/types/landing';
import { agents } from './agents';

export const pricingTiers: PricingTier[] = [
  {
    agentType: 'louis',
    name: 'Louis - Rappel automatique',
    price: 190,
    currency: 'EUR',
    period: 'month',
    color: agents.louis.color,
    included: [
      'Rappel automatique de tous vos leads',
      'Prise de RDV dans votre agenda',
      'Confirmation SMS et email',
      'Intégration CRM complète',
      'Dashboard et reporting',
      'Support prioritaire 24/7',
    ],
    consumption: {
      calls: 0.27,
      sms: 0.14,
      emails: 0,
    },
    example: {
      volume: '300 leads/mois',
      breakdown: {
        subscription: 190,
        calls: 162,
        sms: 5.6,
        total: 357.6,
      },
    },
    badge: 'Populaire',
    cta: {
      text: 'Tester Louis gratuitement',
      action: 'calendar',
    },
  },
  {
    agentType: 'arthur',
    name: 'Arthur - Réactivation de bases',
    price: 490,
    currency: 'EUR',
    period: 'month',
    color: agents.arthur.color,
    included: [
      'Relance automatique de votre base',
      'Séquences multi-canaux progressives',
      'Qualification et scoring',
      'Actions de suivi automatiques',
      'Nettoyage et mise à jour CRM',
      'Dashboard et reporting',
    ],
    consumption: {
      calls: 0.27,
      sms: 0.14,
      emails: 0,
    },
    example: {
      volume: '1000 leads dormants/mois',
      breakdown: {
        subscription: 490,
        calls: 405,
        sms: 28,
        total: 923,
      },
    },
    cta: {
      text: 'Tester Arthur gratuitement',
      action: 'calendar',
    },
  },
  {
    agentType: 'alexandra',
    name: 'Alexandra - Réception 24/7',
    price: 290,
    currency: 'EUR',
    period: 'month',
    color: agents.alexandra.color,
    included: [
      'Réception 24/7 de tous vos appels',
      'Qualification et transfert intelligent',
      'Prise de RDV si nécessaire',
      'Filtrage des appels indésirables',
      'Intégration CRM complète',
      'Dashboard et reporting',
    ],
    consumption: {
      calls: 0.27,
      sms: 0.14,
      emails: 0,
    },
    example: {
      volume: '400 appels/mois',
      breakdown: {
        subscription: 290,
        calls: 324,
        sms: 7,
        total: 621,
      },
    },
    cta: {
      text: 'Tester Alexandra gratuitement',
      action: 'calendar',
    },
  },
];

export const pricing = pricingTiers;

export const getPricingByAgent = (agentType: string): PricingTier | undefined => {
  return pricingTiers.find(tier => tier.agentType === agentType);
};
