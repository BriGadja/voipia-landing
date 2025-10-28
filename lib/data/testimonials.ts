import { TestimonialData } from '@/lib/types/landing';

export const testimonials: Record<string, TestimonialData> = {
  louis: {
    quote: "Louis a transformé notre process de qualification. Avant, on perdait 60% des leads par manque de réactivité. Maintenant, chaque lead est rappelé en moins d'une minute. Notre taux de prise de RDV a été multiplié par 3.",
    author: 'Stefano Valentino',
    role: 'CEO',
    company: 'Stefano Design',
    metrics: [
      { label: 'Taux de contact', value: '+72%' },
      { label: 'RDV qualifiés', value: 'x3' },
      { label: 'Temps de réponse', value: '<60s' },
    ],
  },
  arthur: {
    quote: "On avait 12 000 leads dormants dans notre CRM. Arthur a généré 40k€ de CA additionnel en 2 mois en les réactivant progressivement. Un ROI de 800%.",
    author: 'Thomas Dubois',
    role: 'Directeur Commercial',
    company: 'Norloc',
    metrics: [
      { label: 'CA généré', value: '+40k€' },
      { label: 'Leads réactivés', value: '780' },
      { label: 'ROI', value: '800%' },
    ],
  },
  alexandra: {
    quote: "Alexandra nous a permis de passer de 65% à 100% de taux de réponse. Plus aucun appel manqué, même le week-end. Nos clients adorent.",
    author: 'Stefano Valentino',
    role: 'CEO',
    company: 'Stefano Design',
    metrics: [
      { label: 'Taux de réponse', value: '100%' },
      { label: 'Satisfaction client', value: '+45%' },
      { label: 'Disponibilité', value: '24/7' },
    ],
  },
};

export const getTestimonialByAgent = (agentType: string): TestimonialData | undefined => {
  return testimonials[agentType];
};
