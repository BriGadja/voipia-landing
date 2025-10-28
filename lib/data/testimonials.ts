import { TestimonialData } from '@/lib/types/landing';

export const testimonials: Record<string, TestimonialData> = {
  louis: {
    quote: "Depuis que nous avons intégré Louis, 100 % de nos leads sont rappelés dans la minute. Le nombre de rendez-vous pris a triplé et nous n'avons plus besoin de rappeler manuellement. Cela a complètement transformé notre approche de la gestion des leads : mon équipe peut enfin se concentrer uniquement sur les rendez-vous qualifiés. Louis nous a fait économiser un temps colossal et nous a évité d'embaucher 2 SDR supplémentaires.",
    author: 'Valentin',
    role: 'Dirigeant',
    company: 'Stefano Design',
    metrics: [
      { label: 'Réduction du taux de perte de leads', value: '87%' },
      { label: 'Augmentation des rendez-vous qualifiés', value: 'x3' },
      { label: 'Économisées par semaine sur le rappel manuel', value: '+21H' },
    ],
  },
  arthur: {
    quote: "Grâce à VoIPIA et à l'agent Arthur, nous avons réussi à relancer une grande partie de nos leads que nous n'aurions jamais recontactés sans lui. Les séquences de relance ont été personnalisées selon notre activité, et nous avons généré un volume important d'opportunités qualifiées sans effort supplémentaire pour nos équipes. Arthur a réactivé notre base et nous a fait gagner plusieurs semaines de prospection.",
    author: 'Yassine',
    role: 'Fondateur',
    company: 'Norloc',
    metrics: [
      { label: 'De la base dormante réactivée', value: '+65%' },
      { label: 'Leads traités par commercial par semaine', value: 'x3' },
      { label: 'Économisées par semaine sur les relances manuelles', value: '40H' },
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
