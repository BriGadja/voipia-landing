# PRP - PHASE 1 : FONDATIONS ET ARCHITECTURE

## 🎯 Purpose & Goal

**Objectif Principal** : Créer l'infrastructure technique complète pour supporter la nouvelle architecture Home + 3 Landing Pages dédiées (Louis, Arthur, Alexandra).

**Impact Business** :
- Permettre le développement parallèle de 4 pages indépendantes
- Faciliter la maintenance avec des composants réutilisables
- Accélérer les phases suivantes grâce à une base solide
- Éviter le duplicate code et les incohérences

**Stratégie de Développement Critique** :
- ⚠️ La nouvelle Home sera développée sur `/landingv2` pour NE PAS impacter la home actuelle (`/`)
- Les pages agents seront créées directement à la racine : `/louis`, `/arthur`, `/alexandra`
- Migration finale : `/landingv2` → `/` uniquement après validation complète

**Durée estimée** : 2-3 jours
**Priorité** : 🔴 CRITIQUE (bloquante pour toutes les phases suivantes)

---

## 📚 Context & References

### Documentation Projet

```yaml
- file: C:\Users\pc\Documents\Projets\voipia-landing\CLAUDE.md
  why: Règles du projet, conventions, workflow PRP
  sections: [Project Architecture, Design System, Styling Conventions]

- file: C:\Users\pc\Documents\Projets\voipia-landing\proposition_restructuration_landing\INITIAL\INITIAL_refonte_OVERVIEW.md
  why: Vue d'ensemble de la refonte, architecture cible, dépendances entre phases

- file: C:\Users\pc\Documents\Projets\voipia-landing\proposition_restructuration_landing\INITIAL\INITIAL_refonte_01_fondations.md
  why: Spécifications détaillées de la Phase 1
```

### Fichiers Sources à Référencer

```yaml
- file: lib/constants.ts
  why: Structure de données actuelle des agents à migrer vers lib/data/

- file: components/sections/
  why: Patterns de composants existants à adapter

- file: tailwind.config.ts
  why: Animations custom, couleurs, configuration theme

- file: app/(marketing)/layout.tsx
  why: Layout actuel à conserver et adapter
```

### Structure Actuelle

```
app/
├── (marketing)/
│   ├── layout.tsx           # Layout actuel (Header + Footer)
│   ├── page.tsx             # Home actuelle (⚠️ NE PAS TOUCHER)
│   └── dashboard/           # Dashboard admin existant

components/
├── sections/                # Sections actuelles de la home
│   ├── Hero.tsx
│   ├── AgentsGrid.tsx
│   ├── HowItWorks.tsx
│   └── ...
└── ui/                      # Composants UI existants

lib/
├── constants.ts             # Données agents actuelles
└── utils.ts                 # Utilities (cn, etc.)
```

### Technologies

- **Next.js 15** - App Router avec TypeScript
- **Tailwind CSS** - Styling avec custom animations
- **Framer Motion** - Animations (à intégrer dans phases suivantes)
- **TypeScript** - Mode strict activé

---

## 🏗️ Implementation Blueprint

### Vue d'Ensemble de l'Architecture Cible

```
app/
├── (marketing)/
│   ├── layout.tsx           # Layout commun (Header + Footer) - EXISTANT
│   ├── page.tsx             # Home actuelle - ⚠️ NE PAS TOUCHER
│   ├── landingv2/           # ✅ NOUVEAU - Nouvelle Home en développement
│   │   └── page.tsx
│   ├── louis/               # ✅ NOUVEAU - LP Louis
│   │   └── page.tsx
│   ├── arthur/              # ✅ NOUVEAU - LP Arthur
│   │   └── page.tsx
│   └── alexandra/           # ✅ NOUVEAU - LP Alexandra
│       └── page.tsx

components/
├── landing/                 # ✅ NOUVEAU - Composants spécifiques LP
│   ├── Hero/
│   ├── IntegrationBar/
│   ├── HowItWorks/
│   ├── UseCases/
│   ├── Benefits/
│   ├── Comparison/
│   ├── Testimonial/
│   ├── Pricing/
│   ├── FAQ/
│   └── CTAFinal/
├── shared/                  # ✅ NOUVEAU - Composants partagés
│   ├── Header/              # Migrer depuis existant si besoin
│   ├── Footer/              # Migrer depuis existant si besoin
│   ├── Button/
│   ├── Card/
│   └── AudioPlayer/
├── sections/                # EXISTANT - Sections actuelles (conserver)
└── ui/                      # EXISTANT - UI components (conserver)

lib/
├── data/                    # ✅ NOUVEAU - Données centralisées
│   ├── agents.ts            # Migration depuis lib/constants.ts
│   ├── pricing.ts
│   ├── testimonials.ts
│   ├── integrations.ts
│   └── faqs.ts
├── types/                   # ✅ NOUVEAU - Types TypeScript
│   └── landing.ts
├── constants.ts             # EXISTANT - Conserver pour compatibilité
└── utils.ts                 # EXISTANT - Conserver
```

---

## 📋 Task Breakdown with Pseudocode

### Task 1.1 : Créer la structure de dossiers

**Objectif** : Créer tous les dossiers nécessaires pour la nouvelle architecture.

**Commandes** :
```bash
# Créer les nouvelles routes
mkdir -p app/(marketing)/landingv2
mkdir -p app/(marketing)/louis
mkdir -p app/(marketing)/arthur
mkdir -p app/(marketing)/alexandra

# Créer les dossiers de composants
mkdir -p components/landing/Hero
mkdir -p components/landing/IntegrationBar
mkdir -p components/landing/HowItWorks
mkdir -p components/landing/UseCases
mkdir -p components/landing/Benefits
mkdir -p components/landing/Comparison
mkdir -p components/landing/Testimonial
mkdir -p components/landing/Pricing
mkdir -p components/landing/FAQ
mkdir -p components/landing/CTAFinal

mkdir -p components/shared/Header
mkdir -p components/shared/Footer
mkdir -p components/shared/Button
mkdir -p components/shared/Card
mkdir -p components/shared/AudioPlayer

# Créer les dossiers de données
mkdir -p lib/data
mkdir -p lib/types
```

**Validation** :
- [ ] Tous les dossiers créés
- [ ] Pas d'erreur dans la console
- [ ] Structure visible dans l'explorateur de fichiers

---

### Task 1.2 : Créer les types TypeScript

**Objectif** : Définir tous les types nécessaires pour les landing pages.

**Fichier** : `lib/types/landing.ts`

**Pseudocode** :
```typescript
// Définir les types de base pour les agents
export type AgentType = 'louis' | 'arthur' | 'alexandra';

// Interface Agent avec toutes les propriétés nécessaires
export interface Agent {
  id: AgentType;
  name: string;
  displayName: string;
  tagline: string;
  description: string;
  color: {
    primary: string;      // Couleur Tailwind ex: '#3B82F6'
    secondary: string;    // Couleur secondaire
    gradient: string;     // Classes Tailwind gradient ex: 'from-blue-600 to-cyan-500'
  };
  icon: string;           // Emoji ou icon name
  badge: string;          // Texte du badge
}

// Types pour les sections Hero
export interface HeroSection {
  title: string;          // Titre principal H1
  subtitle: string;       // Sous-titre
  description: string;    // Paragraphe descriptif
  ctaPrimary: CTAButton;  // Bouton principal
  ctaSecondary?: CTAButton; // Bouton secondaire (optionnel)
}

// Types pour les CTA buttons
export interface CTAButton {
  text: string;                                    // Texte du bouton
  action: 'calendar' | 'audio' | 'link' | 'modal'; // Type d'action
  href?: string;                                   // URL si action = link
  variant?: 'primary' | 'secondary' | 'outline';   // Variante visuelle
}

// Types pour les use cases
export interface UseCaseCard {
  title: string;          // Titre du use case
  description: string;    // Description
  icon: string;           // Emoji ou icon
}

// Types pour les bénéfices/métriques
export interface BenefitMetric {
  label: string;          // Label de la métrique ex: "Taux de contact"
  value: string;          // Valeur ex: "+72%"
  icon: string;           // Emoji ou icon
}

// Types pour les témoignages
export interface TestimonialData {
  quote: string;          // Citation complète
  author: string;         // Nom de l'auteur
  role: string;           // Poste/fonction
  company: string;        // Entreprise
  metrics?: {             // Métriques optionnelles
    label: string;
    value: string;
  }[];
}

// Types pour les tarifs
export interface PricingTier {
  agentType: AgentType;   // Type d'agent
  name: string;           // Nom du plan
  price: number;          // Prix mensuel
  currency: 'EUR' | 'USD';
  period: 'month' | 'year';
  included: string[];     // Liste des inclusions
  consumption: {          // Coûts à la consommation
    calls: number;        // Prix par appel (EUR)
    sms: number;          // Prix par SMS (EUR)
    emails: number;       // Prix par email (EUR)
  };
  example?: {             // Exemple de facturation
    volume: string;
    breakdown: {
      subscription: number;
      calls: number;
      sms: number;
      total: number;
    };
  };
  badge?: string;         // Badge optionnel ex: "Le plus populaire"
  cta: CTAButton;         // Bouton CTA
}

// Types pour les FAQs
export interface FAQItem {
  question: string;       // Question
  answer: string;         // Réponse (peut contenir du HTML)
  icon?: string;          // Icon optionnel
}

// Types pour les intégrations/logos
export interface IntegrationLogo {
  name: string;           // Nom de l'intégration
  logo: string;           // Chemin vers le logo SVG
  category: 'crm' | 'calendar' | 'automation' | 'communication' | 'ai';
}
```

**Validation** :
- [ ] Fichier `lib/types/landing.ts` créé
- [ ] Tous les types exportés
- [ ] Pas d'erreur TypeScript dans VSCode
- [ ] `npm run build` réussi

---

### Task 1.3 : Créer le système de données centralisé

**Objectif** : Centraliser toutes les données dans `lib/data/` pour éviter la duplication.

#### Fichier 1 : `lib/data/agents.ts`

**Pseudocode** :
```typescript
import { Agent } from '@/lib/types/landing';

// Créer un objet Record avec les 3 agents
export const agents: Record<string, Agent> = {
  louis: {
    id: 'louis',
    name: 'louis',
    displayName: 'Louis',
    tagline: 'Rappel automatique de leads',
    description: 'Louis rappelle tous vos nouveaux prospects, les qualifie et les dispatch en moins de 60 secondes.',
    color: {
      primary: '#3B82F6',      // blue-500
      secondary: '#60A5FA',    // blue-400
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
    description: 'Arthur relance chaque prospect dormant avec une approche douce et progressive.',
    color: {
      primary: '#F59E0B',      // amber-500
      secondary: '#FBBF24',    // amber-400
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
    description: 'Alexandra répond à tous vos appels entrants. Même à 3h du matin.',
    color: {
      primary: '#10B981',      // green-500
      secondary: '#34D399',    // green-400
      gradient: 'from-green-600 to-emerald-500',
    },
    icon: '☎️',
    badge: 'Alexandra - Réception 24/7',
  },
};

// Helper pour récupérer un agent par type
export const getAgent = (agentType: string): Agent | undefined => {
  return agents[agentType];
};

// Helper pour récupérer tous les agents
export const getAllAgents = (): Agent[] => {
  return Object.values(agents);
};
```

#### Fichier 2 : `lib/data/pricing.ts`

**Pseudocode** :
```typescript
import { PricingTier } from '@/lib/types/landing';

// Tableau des 3 plans tarifaires
export const pricingTiers: PricingTier[] = [
  {
    agentType: 'louis',
    name: 'Louis - Rappel automatique',
    price: 190,
    currency: 'EUR',
    period: 'month',
    included: [
      'Rappel automatique de tous vos leads',
      'Prise de RDV dans votre agenda',
      'Confirmation SMS et email',
      'Intégration CRM complète',
      'Dashboard et reporting',
      'Support prioritaire 24/7',
    ],
    consumption: {
      calls: 0.27,    // 0.27€ par appel
      sms: 0.14,      // 0.14€ par SMS
      emails: 0,      // Gratuit
    },
    example: {
      volume: '300 leads/mois',
      breakdown: {
        subscription: 190,
        calls: 162,        // 300 × 2 appels × 0.27
        sms: 5.6,          // 40 × 0.14
        total: 357.6,
      },
    },
    badge: 'Le plus populaire',
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
        calls: 405,        // 1500 × 0.27
        sms: 28,           // 200 × 0.14
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
        calls: 324,        // 1200 × 0.27
        sms: 7,            // 50 × 0.14
        total: 621,
      },
    },
    cta: {
      text: 'Tester Alexandra gratuitement',
      action: 'calendar',
    },
  },
];

// Helper pour récupérer le pricing d'un agent
export const getPricingByAgent = (agentType: string): PricingTier | undefined => {
  return pricingTiers.find(tier => tier.agentType === agentType);
};
```

#### Fichier 3 : `lib/data/integrations.ts`

**Pseudocode** :
```typescript
import { IntegrationLogo } from '@/lib/types/landing';

// Liste de toutes les intégrations supportées
export const integrations: IntegrationLogo[] = [
  // CRM
  { name: 'Pipedrive', logo: '/logos/pipedrive.svg', category: 'crm' },
  { name: 'HubSpot', logo: '/logos/hubspot.svg', category: 'crm' },
  { name: 'Salesforce', logo: '/logos/salesforce.svg', category: 'crm' },

  // Calendar
  { name: 'Google Calendar', logo: '/logos/google-calendar.svg', category: 'calendar' },
  { name: 'Outlook', logo: '/logos/outlook.svg', category: 'calendar' },
  { name: 'Calendly', logo: '/logos/calendly.svg', category: 'calendar' },

  // Automation
  { name: 'Make', logo: '/logos/make.svg', category: 'automation' },
  { name: 'Zapier', logo: '/logos/zapier.svg', category: 'automation' },
  { name: 'n8n', logo: '/logos/n8n.svg', category: 'automation' },

  // AI
  { name: 'Eleven Labs', logo: '/logos/elevenlabs.svg', category: 'ai' },
  { name: 'Cartesia', logo: '/logos/cartesia.svg', category: 'ai' },
  { name: 'Mistral AI', logo: '/logos/mistral.svg', category: 'ai' },
  { name: 'Claude', logo: '/logos/claude.svg', category: 'ai' },
  { name: 'OpenAI', logo: '/logos/openai.svg', category: 'ai' },
];

// Helper pour filtrer par catégorie
export const getIntegrationsByCategory = (category: string): IntegrationLogo[] => {
  return integrations.filter(integration => integration.category === category);
};
```

#### Fichier 4 : `lib/data/testimonials.ts`

**Pseudocode** :
```typescript
import { TestimonialData } from '@/lib/types/landing';

// Témoignages clients par agent
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

// Helper pour récupérer un témoignage par agent
export const getTestimonialByAgent = (agentType: string): TestimonialData | undefined => {
  return testimonials[agentType];
};
```

#### Fichier 5 : `lib/data/faqs.ts`

**Pseudocode** :
```typescript
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
```

**Validation** :
- [ ] Tous les fichiers de données créés
- [ ] Imports TypeScript corrects
- [ ] Données complètes et cohérentes
- [ ] Helpers fonctionnels
- [ ] Pas d'erreur TypeScript

---

### Task 1.4 : Créer les composants de base partagés

**Objectif** : Créer les composants réutilisables Button, Card, et AudioPlayer.

#### Composant 1 : `components/shared/Button/index.tsx`

**Pseudocode** :
```typescript
import { cn } from '@/lib/utils';
import { ButtonHTMLAttributes, forwardRef } from 'react';

// Props du bouton avec variants et sizes
interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'sm' | 'md' | 'lg';
}

// Composant Button avec forwardRef pour la compatibilité
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          // Classes de base
          'inline-flex items-center justify-center rounded-lg font-semibold transition-all',
          'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-violet-500',

          // Variants
          {
            // Primary : gradient violet-purple
            'bg-gradient-to-r from-violet-600 to-purple-600 hover:from-violet-700 hover:to-purple-700 text-white shadow-lg shadow-violet-500/50':
              variant === 'primary',

            // Secondary : fond blanc semi-transparent
            'bg-white/10 hover:bg-white/20 text-white backdrop-blur-sm':
              variant === 'secondary',

            // Outline : bordure uniquement
            'border-2 border-white/20 hover:border-white/40 text-white bg-transparent':
              variant === 'outline',
          },

          // Sizes
          {
            'px-4 py-2 text-sm': size === 'sm',
            'px-6 py-3 text-base': size === 'md',
            'px-8 py-4 text-lg': size === 'lg',
          },

          // Classes additionnelles
          className
        )}
        {...props}
      >
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
```

#### Composant 2 : `components/shared/Card/index.tsx`

**Pseudocode** :
```typescript
import { cn } from '@/lib/utils';
import { HTMLAttributes } from 'react';

// Props de la carte avec variants
interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'gradient' | 'hover';
}

// Composant Card avec glassmorphism
export function Card({ className, variant = 'default', children, ...props }: CardProps) {
  return (
    <div
      className={cn(
        // Classes de base
        'rounded-2xl border backdrop-blur-sm transition-all duration-300',

        // Variants
        {
          // Default : fond blanc semi-transparent
          'bg-white/5 border-white/10': variant === 'default',

          // Gradient : fond avec gradient subtil
          'bg-gradient-to-br from-white/10 to-white/5 border-white/20':
            variant === 'gradient',

          // Hover : effet au survol
          'bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20 hover:scale-105 cursor-pointer':
            variant === 'hover',
        },

        // Classes additionnelles
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}
```

#### Composant 3 : `components/shared/AudioPlayer/index.tsx`

**Pseudocode** :
```typescript
'use client';

import { useState, useRef } from 'react';
import { Play, Pause } from 'lucide-react';
import { cn } from '@/lib/utils';

// Props de l'audio player
interface AudioPlayerProps {
  audioSrc: string;          // URL de l'audio
  agentColor?: string;       // Couleur de l'agent (ex: 'blue', 'orange', 'green')
  className?: string;
}

// Composant AudioPlayer avec contrôles
export function AudioPlayer({ audioSrc, agentColor = 'violet', className }: AudioPlayerProps) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const audioRef = useRef<HTMLAudioElement>(null);

  // Toggle play/pause
  const togglePlay = () => {
    if (!audioRef.current) return;

    if (isPlaying) {
      audioRef.current.pause();
    } else {
      audioRef.current.play();
    }

    setIsPlaying(!isPlaying);
  };

  // Update current time
  const handleTimeUpdate = () => {
    if (!audioRef.current) return;
    setCurrentTime(audioRef.current.currentTime);
  };

  // Update duration
  const handleLoadedMetadata = () => {
    if (!audioRef.current) return;
    setDuration(audioRef.current.duration);
  };

  // Seek to position
  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!audioRef.current) return;
    const newTime = parseFloat(e.target.value);
    audioRef.current.currentTime = newTime;
    setCurrentTime(newTime);
  };

  // Format time (seconds to mm:ss)
  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className={cn('flex items-center gap-4 p-4 rounded-xl bg-white/5 border border-white/10', className)}>
      {/* Play/Pause Button */}
      <button
        onClick={togglePlay}
        className={cn(
          'flex items-center justify-center w-12 h-12 rounded-full transition-all',
          'bg-gradient-to-r shadow-lg',
          {
            'from-blue-600 to-cyan-500 hover:from-blue-700 hover:to-cyan-600': agentColor === 'blue',
            'from-orange-600 to-amber-500 hover:from-orange-700 hover:to-amber-600': agentColor === 'orange',
            'from-green-600 to-emerald-500 hover:from-green-700 hover:to-emerald-600': agentColor === 'green',
            'from-violet-600 to-purple-600 hover:from-violet-700 hover:to-purple-700': agentColor === 'violet',
          }
        )}
      >
        {isPlaying ? (
          <Pause className="w-5 h-5 text-white" />
        ) : (
          <Play className="w-5 h-5 text-white ml-0.5" />
        )}
      </button>

      {/* Progress Bar */}
      <div className="flex-1 flex flex-col gap-2">
        <input
          type="range"
          min="0"
          max={duration || 0}
          value={currentTime}
          onChange={handleSeek}
          className="w-full h-1 bg-white/10 rounded-full appearance-none cursor-pointer"
          style={{
            background: `linear-gradient(to right, rgba(139, 92, 246, 0.5) 0%, rgba(139, 92, 246, 0.5) ${(currentTime / duration) * 100}%, rgba(255, 255, 255, 0.1) ${(currentTime / duration) * 100}%, rgba(255, 255, 255, 0.1) 100%)`,
          }}
        />

        {/* Time Display */}
        <div className="flex justify-between text-xs text-gray-400">
          <span>{formatTime(currentTime)}</span>
          <span>{formatTime(duration)}</span>
        </div>
      </div>

      {/* Hidden Audio Element */}
      <audio
        ref={audioRef}
        src={audioSrc}
        onTimeUpdate={handleTimeUpdate}
        onLoadedMetadata={handleLoadedMetadata}
        onEnded={() => setIsPlaying(false)}
      />
    </div>
  );
}
```

**Validation** :
- [ ] Button créé avec 3 variants et 3 sizes
- [ ] Card créé avec 3 variants
- [ ] AudioPlayer créé avec contrôles fonctionnels
- [ ] Composants utilisent `cn()` utility
- [ ] Pas d'erreur TypeScript

---

### Task 1.5 : Créer les pages de base

**Objectif** : Créer les 4 pages avec contenu placeholder.

#### Page 1 : `app/(marketing)/landingv2/page.tsx`

**⚠️ IMPORTANT** : Nouvelle Home sur `/landingv2` (ne pas toucher à `page.tsx`)

**Pseudocode** :
```typescript
export default function LandingV2Page() {
  return (
    <div className="container mx-auto px-4 py-20 min-h-[70vh] flex flex-col items-center justify-center">
      <div className="text-center space-y-4">
        <h1 className="text-5xl font-bold bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
          Nouvelle Home Page Voipia (v2)
        </h1>
        <p className="text-xl text-gray-400 max-w-2xl mx-auto">
          Structure en cours de construction - Phase 1 : Fondations
        </p>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-violet-500/10 border border-violet-500/20">
          <span className="text-2xl">📍</span>
          <span className="text-violet-400 font-mono text-sm">
            URL de développement : /landingv2
          </span>
        </div>
        <p className="text-sm text-gray-500 mt-8">
          La home actuelle sur "/" reste inchangée jusqu'à validation complète.
        </p>
      </div>
    </div>
  );
}
```

#### Page 2 : `app/(marketing)/louis/page.tsx`

**Pseudocode** :
```typescript
import { agents } from '@/lib/data/agents';

export default function LouisPage() {
  const louis = agents.louis;

  return (
    <div className="container mx-auto px-4 py-20 min-h-[70vh] flex flex-col items-center justify-center">
      <div className="text-center space-y-4">
        <div className="text-6xl mb-4">{louis.icon}</div>
        <h1 className={`text-5xl font-bold bg-gradient-to-r ${louis.color.gradient} bg-clip-text text-transparent`}>
          Landing Page {louis.displayName}
        </h1>
        <p className="text-xl text-gray-400">
          {louis.tagline}
        </p>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-blue-500/10 border border-blue-500/20 mt-4">
          <span className="text-blue-400 font-mono text-sm">
            En construction - Phase 3
          </span>
        </div>
      </div>
    </div>
  );
}
```

#### Page 3 : `app/(marketing)/arthur/page.tsx`

**Pseudocode** :
```typescript
import { agents } from '@/lib/data/agents';

export default function ArthurPage() {
  const arthur = agents.arthur;

  return (
    <div className="container mx-auto px-4 py-20 min-h-[70vh] flex flex-col items-center justify-center">
      <div className="text-center space-y-4">
        <div className="text-6xl mb-4">{arthur.icon}</div>
        <h1 className={`text-5xl font-bold bg-gradient-to-r ${arthur.color.gradient} bg-clip-text text-transparent`}>
          Landing Page {arthur.displayName}
        </h1>
        <p className="text-xl text-gray-400">
          {arthur.tagline}
        </p>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-orange-500/10 border border-orange-500/20 mt-4">
          <span className="text-orange-400 font-mono text-sm">
            En construction - Phase 4
          </span>
        </div>
      </div>
    </div>
  );
}
```

#### Page 4 : `app/(marketing)/alexandra/page.tsx`

**Pseudocode** :
```typescript
import { agents } from '@/lib/data/agents';

export default function AlexandraPage() {
  const alexandra = agents.alexandra;

  return (
    <div className="container mx-auto px-4 py-20 min-h-[70vh] flex flex-col items-center justify-center">
      <div className="text-center space-y-4">
        <div className="text-6xl mb-4">{alexandra.icon}</div>
        <h1 className={`text-5xl font-bold bg-gradient-to-r ${alexandra.color.gradient} bg-clip-text text-transparent`}>
          Landing Page {alexandra.displayName}
        </h1>
        <p className="text-xl text-gray-400">
          {alexandra.tagline}
        </p>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-green-500/10 border border-green-500/20 mt-4">
          <span className="text-green-400 font-mono text-sm">
            En construction - Phase 5
          </span>
        </div>
      </div>
    </div>
  );
}
```

**Validation** :
- [ ] 4 pages créées avec contenu placeholder
- [ ] Imports des données depuis `lib/data/agents.ts`
- [ ] Styles cohérents avec le design system
- [ ] Pas d'erreur TypeScript

---

## ✅ Validation Loops

### 1. Build Check

```bash
# Vérifier que le projet compile sans erreur
npm run build
```

**Critères de succès** :
- [ ] Build réussi (exit code 0)
- [ ] Pas d'erreur TypeScript
- [ ] Pas d'erreur de module non trouvé
- [ ] Warnings acceptables uniquement

---

### 2. Development Server Check

```bash
# Lancer le serveur de développement
npm run dev
```

**Critères de succès** :
- [ ] Serveur démarre sans erreur
- [ ] Accessible sur `http://localhost:3000`
- [ ] Pas d'erreur dans la console Node.js

---

### 3. Route Accessibility Check

**Tester manuellement chaque route** :

```bash
# Routes à tester
http://localhost:3000/                # Home actuelle (ne doit PAS être modifiée)
http://localhost:3000/landingv2       # Nouvelle Home (placeholder)
http://localhost:3000/louis           # LP Louis (placeholder)
http://localhost:3000/arthur          # LP Arthur (placeholder)
http://localhost:3000/alexandra       # LP Alexandra (placeholder)
```

**Critères de succès** :
- [ ] Toutes les routes sont accessibles (status 200)
- [ ] Pas d'erreur 404
- [ ] Contenu placeholder s'affiche correctement
- [ ] `/` reste inchangée (contenu original)

---

### 4. Browser Visual Verification

**Utiliser MCP Playwright pour vérifier visuellement chaque page** :

```typescript
// Étapes à suivre :

// 1. Naviguer vers landingv2
mcp__playwright__browser_navigate({ url: 'http://localhost:3000/landingv2' })

// 2. Prendre un snapshot
mcp__playwright__browser_snapshot()

// 3. Vérifier visuellement :
// - Titre "Nouvelle Home Page Voipia (v2)" visible
// - Badge "URL de développement : /landingv2" visible
// - Design cohérent (fond noir, texte blanc, gradient violet)
// - Pas d'erreur visuelle

// 4. Répéter pour chaque page :
//    - /louis (texte bleu, icon 📞)
//    - /arthur (texte orange, icon 🔄)
//    - /alexandra (texte vert, icon ☎️)
//    - / (doit rester inchangée, home originale)
```

**Critères de succès** :
- [ ] Toutes les pages se chargent visuellement
- [ ] Couleurs des agents respectées (Louis: bleu, Arthur: orange, Alexandra: vert)
- [ ] Pas d'erreur de layout
- [ ] Responsive fonctionne (tester en redimensionnant)

---

### 5. TypeScript Check

```bash
# Vérifier les erreurs TypeScript
npx tsc --noEmit
```

**Critères de succès** :
- [ ] Aucune erreur TypeScript
- [ ] Types correctement importés et utilisés
- [ ] Pas de `any` implicite

---

### 6. Lint Check

```bash
# Vérifier la qualité du code
npm run lint
```

**Critères de succès** :
- [ ] Aucune erreur ESLint
- [ ] Warnings minimes et acceptables
- [ ] Code suit les conventions du projet

---

### 7. Component Testing

**Créer une page de test temporaire** : `app/(marketing)/test-components/page.tsx`

```typescript
import { Button } from '@/components/shared/Button';
import { Card } from '@/components/shared/Card';
import { AudioPlayer } from '@/components/shared/AudioPlayer';

export default function TestComponentsPage() {
  return (
    <div className="container mx-auto px-4 py-20 space-y-8">
      <h1 className="text-4xl font-bold">Test des Composants</h1>

      {/* Test Button */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Button</h2>
        <div className="flex gap-4">
          <Button variant="primary" size="sm">Primary Small</Button>
          <Button variant="primary" size="md">Primary Medium</Button>
          <Button variant="primary" size="lg">Primary Large</Button>
        </div>
        <div className="flex gap-4">
          <Button variant="secondary">Secondary</Button>
          <Button variant="outline">Outline</Button>
        </div>
      </section>

      {/* Test Card */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Card</h2>
        <div className="grid grid-cols-3 gap-4">
          <Card variant="default" className="p-6">
            <h3 className="font-semibold">Default Card</h3>
            <p className="text-gray-400">Content here</p>
          </Card>
          <Card variant="gradient" className="p-6">
            <h3 className="font-semibold">Gradient Card</h3>
            <p className="text-gray-400">Content here</p>
          </Card>
          <Card variant="hover" className="p-6">
            <h3 className="font-semibold">Hover Card</h3>
            <p className="text-gray-400">Hover me!</p>
          </Card>
        </div>
      </section>

      {/* Test AudioPlayer */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">AudioPlayer</h2>
        <AudioPlayer
          audioSrc="/audio/demo-louis.mp3"
          agentColor="blue"
        />
      </section>
    </div>
  );
}
```

**Tester avec browser** :
```typescript
// Naviguer vers la page de test
mcp__playwright__browser_navigate({ url: 'http://localhost:3000/test-components' })

// Snapshot
mcp__playwright__browser_snapshot()

// Vérifier visuellement tous les composants
```

**Critères de succès** :
- [ ] Button affiche correctement tous les variants
- [ ] Card affiche correctement tous les variants
- [ ] AudioPlayer s'affiche (fonctionnalité complète en Phase 3)
- [ ] Hover effects fonctionnent
- [ ] Responsive fonctionne

**Après validation, supprimer la page de test** :
```bash
rm app/(marketing)/test-components/page.tsx
```

---

### 8. Console Error Check

**Ouvrir les DevTools du navigateur et vérifier** :

```typescript
// Après avoir navigué vers chaque page
mcp__playwright__browser_console_messages()
```

**Critères de succès** :
- [ ] Aucune erreur dans la console
- [ ] Aucun warning critique
- [ ] Pas d'erreur de module non chargé
- [ ] Pas d'erreur réseau (images, fonts, etc.)

---

### 9. Data System Check

**Créer un script de test** : `scripts/test-data.ts`

```typescript
import { agents, getAgent, getAllAgents } from '@/lib/data/agents';
import { pricingTiers, getPricingByAgent } from '@/lib/data/pricing';
import { integrations, getIntegrationsByCategory } from '@/lib/data/integrations';
import { testimonials, getTestimonialByAgent } from '@/lib/data/testimonials';
import { homeFAQs, getFAQsByAgent } from '@/lib/data/faqs';

// Test agents
console.log('✅ Test Agents');
console.log('- Louis:', getAgent('louis')?.displayName);
console.log('- Arthur:', getAgent('arthur')?.displayName);
console.log('- Alexandra:', getAgent('alexandra')?.displayName);
console.log('- All agents:', getAllAgents().length, 'agents');

// Test pricing
console.log('\n✅ Test Pricing');
console.log('- Louis pricing:', getPricingByAgent('louis')?.price, '€');
console.log('- Arthur pricing:', getPricingByAgent('arthur')?.price, '€');
console.log('- Alexandra pricing:', getPricingByAgent('alexandra')?.price, '€');

// Test integrations
console.log('\n✅ Test Integrations');
console.log('- Total integrations:', integrations.length);
console.log('- CRM integrations:', getIntegrationsByCategory('crm').length);
console.log('- AI integrations:', getIntegrationsByCategory('ai').length);

// Test testimonials
console.log('\n✅ Test Testimonials');
console.log('- Louis testimonial:', getTestimonialByAgent('louis')?.author);
console.log('- Arthur testimonial:', getTestimonialByAgent('arthur')?.author);

// Test FAQs
console.log('\n✅ Test FAQs');
console.log('- Home FAQs:', homeFAQs.length, 'questions');

console.log('\n🎉 All data tests passed!');
```

**Exécuter** :
```bash
npx tsx scripts/test-data.ts
```

**Critères de succès** :
- [ ] Script s'exécute sans erreur
- [ ] Tous les helpers retournent les bonnes données
- [ ] Aucune valeur undefined inattendue

---

### 10. Final Git Commit

**Après validation complète** :

```bash
# Vérifier le statut
git status

# Ajouter tous les nouveaux fichiers
git add .

# Commit avec message descriptif
git commit -m "feat(phase-1): Add routing structure and reusable components

- Create /landingv2 route for new home (dev only)
- Create /louis, /arthur, /alexandra routes with placeholders
- Add centralized data system in lib/data/
- Add TypeScript types in lib/types/landing.ts
- Create shared components (Button, Card, AudioPlayer)
- Set up foundation for Phase 2-5

Architecture: Home actuelle (/) reste inchangée jusqu'à validation finale"
```

**Critères de succès** :
- [ ] Commit créé avec message descriptif
- [ ] Tous les fichiers pertinents inclus
- [ ] Pas de fichiers temporaires committés

---

## 🚫 Anti-patterns

### ❌ NE PAS FAIRE

1. **Modifier la home actuelle** :
   - ❌ Ne JAMAIS toucher à `app/(marketing)/page.tsx`
   - ❌ Ne JAMAIS modifier les composants utilisés par la home actuelle
   - ✅ Développer uniquement sur `/landingv2`

2. **Créer des fichiers hors structure** :
   - ❌ Ne pas créer de fichiers dans la racine du projet
   - ❌ Ne pas créer de dossiers temporaires
   - ✅ Suivre strictement la structure définie dans Task 1.1

3. **Dupliquer des données** :
   - ❌ Ne pas hardcoder les données agents dans les composants
   - ❌ Ne pas copier-coller les données entre fichiers
   - ✅ Toujours importer depuis `lib/data/`

4. **Oublier les types TypeScript** :
   - ❌ Ne pas utiliser `any` pour éviter les erreurs
   - ❌ Ne pas ignorer les erreurs TypeScript
   - ✅ Définir tous les types dans `lib/types/landing.ts`

5. **Ignorer la validation visuelle** :
   - ❌ Ne pas se fier uniquement au build réussi
   - ❌ Ne pas skip les tests MCP Playwright
   - ✅ TOUJOURS vérifier visuellement chaque page avec browser snapshots

6. **Créer trop de fichiers** :
   - ❌ Ne pas créer de fichiers "pour plus tard"
   - ❌ Ne pas créer de composants non utilisés
   - ✅ Créer uniquement ce qui est nécessaire pour la Phase 1

7. **Oublier le rangement** :
   - ❌ Ne pas sauvegarder ce PRP n'importe où
   - ✅ Ce PRP doit être dans `proposition_restructuration_landing/PRPs/`

---

## 📊 Success Criteria

### Critères Techniques

- [ ] **Build Next.js réussi** : `npm run build` sans erreur
- [ ] **Types TypeScript complets** : `npx tsc --noEmit` sans erreur
- [ ] **Lint réussi** : `npm run lint` sans erreur critique
- [ ] **4 routes accessibles** : `/landingv2`, `/louis`, `/arthur`, `/alexandra`
- [ ] **Route `/` inchangée** : Home actuelle reste identique

### Critères Fonctionnels

- [ ] **Système de données opérationnel** : Tous les helpers fonctionnent
- [ ] **Composants réutilisables** : Button, Card, AudioPlayer créés
- [ ] **Layout marketing appliqué** : Header et Footer sur toutes les pages
- [ ] **Placeholder pages** : Contenu temporaire avec design cohérent

### Critères Visuels

- [ ] **Couleurs des agents respectées** : Louis (bleu), Arthur (orange), Alexandra (vert)
- [ ] **Design cohérent** : Fond noir, glassmorphism, gradients
- [ ] **Responsive** : Fonctionne sur mobile/tablet/desktop
- [ ] **Pas d'erreur visuelle** : Vérification avec MCP Playwright

### Critères de Documentation

- [ ] **PROGRESS_REFONTE.md mis à jour** :
  - Date de début et de fin renseignées
  - Livrables listés
  - Tests validés cochés
  - Commit Git référencé
  - Screenshots ajoutés

- [ ] **Git commit créé** : Message descriptif avec liste des changements

---

## 🔄 Workflow d'Exécution

### Étape par Étape

1. **Lecture de ce PRP** : Comprendre l'objectif et la structure
2. **Exécution Task 1.1** : Créer la structure de dossiers
3. **Exécution Task 1.2** : Créer les types TypeScript
4. **Exécution Task 1.3** : Créer le système de données
5. **Exécution Task 1.4** : Créer les composants partagés
6. **Exécution Task 1.5** : Créer les pages de base
7. **Validation 1-6** : Build, dev server, routes, browser, TypeScript, lint
8. **Validation 7-8** : Component testing, console errors
9. **Validation 9** : Data system check
10. **Validation 10** : Git commit
11. **Mise à jour PROGRESS_REFONTE.md** : Documenter la completion de la phase

### Commandes Résumées

```bash
# 1. Créer la structure
mkdir -p app/(marketing)/landingv2 app/(marketing)/louis app/(marketing)/arthur app/(marketing)/alexandra
mkdir -p components/landing components/shared lib/data lib/types

# 2. Créer tous les fichiers (voir tasks détaillées)

# 3. Valider
npm run build
npm run dev

# 4. Tester visuellement
# Utiliser MCP Playwright pour naviguer et prendre des snapshots

# 5. Commit
git add .
git commit -m "feat(phase-1): Add routing structure and reusable components"
```

---

## 📝 Notes Finales

- **Phase critique** : Cette phase est bloquante pour toutes les suivantes
- **Pas de contenu réel** : Phase 1 = infrastructure uniquement, contenu en Phase 2-5
- **Home actuelle protégée** : `/` reste inchangée pendant tout le développement
- **Migration finale** : `/landingv2` → `/` uniquement après validation de toutes les phases

**Durée estimée** : 2-3 jours
**Prochaine phase** : Phase 2 - Page Home sur `/landingv2`

---

**Créé le** : 2025-10-28
**Auteur** : Claude Code
**Version** : 1.0
**Statut** : ✅ Prêt pour exécution
