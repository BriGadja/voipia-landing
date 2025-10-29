import type { BenefitItem } from '@/components/landing/BenefitsTable';

// Benefits for Louis (Rappel automatique)
export const louisBenefits: BenefitItem[] = [
  { label: 'Délai moyen de rappel', value: '< 60 secondes', icon: 'Clock' },
  { label: 'Taux de contact', value: '+72%', icon: 'PhoneCall' },
  { label: 'Taux de conversion en RDV', value: 'x3', icon: 'TrendingUp' },
  { label: 'Temps gagné', value: '+21h/semaine', icon: 'Zap' },
  { label: 'Réduction du taux de perte', value: '-87%', icon: 'ShieldCheck' },
];

// Benefits for Arthur (Réactivation)
export const arthurBenefits: BenefitItem[] = [
  { label: 'Taux de réactivation', value: '+65%', icon: 'Target' },
  { label: 'Leads qualifiés générés', value: '+180%', icon: 'TrendingUp' },
  { label: 'CA généré sur base dormante', value: '+40 000€/mois', icon: 'DollarSign' },
  { label: 'Temps gagné', value: '+40h/semaine', icon: 'Zap' },
  { label: 'Leads traités par commercial', value: 'x3 par semaine', icon: 'Users' },
];

// Benefits for Alexandra (Réception 24/7)
export const alexandraBenefits: BenefitItem[] = [
  { label: 'Taux de réponse', value: '100%', icon: 'PhoneIncoming' },
  { label: 'Temps de réponse', value: '<3 sonneries', icon: 'Clock' },
  { label: 'Appels manqués éliminés', value: '-100%', icon: 'PhoneOff' },
  { label: 'Temps gagné', value: '+30h/semaine', icon: 'Zap' },
  { label: 'Satisfaction client', value: '+45%', icon: 'Heart' },
];
