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
    quote: "Depuis qu'Alexandra gère notre accueil téléphonique, nous avons 100% de taux de réponse même pendant nos pics d'activité. Nos clients sont ravis de ne plus tomber sur un répondeur, et mon équipe peut enfin se concentrer sur son travail sans être interrompue toutes les 10 minutes. Alexandra a transformé notre relation client : elle répond avec précision grâce à notre base de connaissances et prend des rendez-vous comme une vraie professionnelle. Nous avons économisé l'équivalent d'un poste de réceptionniste à temps plein.",
    author: 'Valentin',
    role: 'Dirigeant',
    company: 'Stefano Design',
    metrics: [
      { label: 'De taux de réponse sans appels manqués', value: '100%' },
      { label: 'Augmentation de la satisfaction client', value: '+45%' },
      { label: 'Économisées par semaine sur l\'accueil téléphonique', value: '+30H' },
    ],
  },
};

export const getTestimonialByAgent = (agentType: string): TestimonialData | undefined => {
  return testimonials[agentType];
};
