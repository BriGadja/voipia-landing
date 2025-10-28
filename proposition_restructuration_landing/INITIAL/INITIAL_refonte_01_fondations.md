# PHASE 1 : FONDATIONS ET ARCHITECTURE

## 🎯 Objectif de la Phase

Créer l'infrastructure technique nécessaire pour supporter la nouvelle architecture Home + 3 LP dédiées.

**⚠️ IMPORTANT - Conventions** :
- La nouvelle Home sera sur **`/landingv2`** (ne touche pas à `/` actuellement)
- Les pages agents seront à la racine : `/louis`, `/arthur`, `/alexandra`
- **Tous les fichiers générés** (PRPs, docs, notes) doivent être rangés dans `C:\Users\pc\Documents\Projets\voipia-landing\proposition_restructuration_landing\`

**Durée estimée** : 2-3 jours
**Priorité** : 🔴 CRITIQUE (bloquante pour toutes les autres phases)

---

## 📋 Contexte

Actuellement, le site Voipia a :
- Une page unique avec toutes les sections
- Composants dans `components/sections/`
- Données dans `lib/constants.ts`
- Style system avec Tailwind CSS

**Besoin** : Restructurer pour supporter 4 pages indépendantes avec composants partagés.

---

## 🎯 Livrables de la Phase

### 1. Structure de Routing Next.js
- ✅ Route `/landingv2` (Nouvelle Home - en développement)
- ✅ Route `/louis` (Landing Page Louis)
- ✅ Route `/arthur` (Landing Page Arthur)
- ✅ Route `/alexandra` (Landing Page Alexandra)

**Note** : La route `/` actuelle reste inchangée jusqu'à la validation finale

### 2. Système de Composants Réutilisables
- ✅ `components/landing/` - Composants spécifiques aux LP
- ✅ `components/shared/` - Composants partagés entre toutes les pages
- ✅ Architecture claire et maintenable

### 3. Système de Données Centralisé
- ✅ `lib/data/agents.ts` - Données des 3 agents
- ✅ `lib/data/pricing.ts` - Tarifs et formules
- ✅ `lib/data/testimonials.ts` - Témoignages clients
- ✅ `lib/data/integrations.ts` - Logos et intégrations
- ✅ `lib/data/faqs.ts` - FAQs par agent

### 4. Types TypeScript
- ✅ `lib/types/landing.ts` - Types pour les LP
- ✅ Types complets et réutilisables

---

## 📦 Micro-tâches Détaillées

### Tâche 1.1 : Créer la structure de dossiers

```bash
app/
├── (marketing)/          # Layout group pour les pages marketing
│   ├── layout.tsx       # Layout commun (Header + Footer)
│   ├── page.tsx         # Home actuelle (ne pas toucher)
│   ├── landingv2/
│   │   └── page.tsx     # Nouvelle Home (en développement)
│   ├── louis/
│   │   └── page.tsx     # LP Louis
│   ├── arthur/
│   │   └── page.tsx     # LP Arthur
│   └── alexandra/
│       └── page.tsx     # LP Alexandra

components/
├── landing/              # Composants spécifiques aux LP
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
├── shared/               # Composants partagés
│   ├── Header/
│   ├── Footer/
│   ├── Button/
│   ├── Card/
│   └── AudioPlayer/

lib/
├── data/
│   ├── agents.ts
│   ├── pricing.ts
│   ├── testimonials.ts
│   ├── integrations.ts
│   └── faqs.ts
└── types/
    └── landing.ts
```

**Validation** :
- [ ] Structure créée avec `mkdir`
- [ ] Fichiers `.gitkeep` dans dossiers vides si nécessaire

---

### Tâche 1.2 : Créer les types TypeScript

**Fichier** : `lib/types/landing.ts`

```typescript
// Types pour les agents
export type AgentType = 'louis' | 'arthur' | 'alexandra';

export interface Agent {
  id: AgentType;
  name: string;
  displayName: string;
  tagline: string;
  description: string;
  color: {
    primary: string;
    secondary: string;
    gradient: string;
  };
  icon: string;
  badge: string;
}

// Types pour les sections
export interface HeroSection {
  title: string;
  subtitle: string;
  description: string;
  ctaPrimary: CTAButton;
  ctaSecondary?: CTAButton;
}

export interface CTAButton {
  text: string;
  action: 'calendar' | 'audio' | 'link' | 'modal';
  href?: string;
  variant?: 'primary' | 'secondary' | 'outline';
}

export interface UseCaseCard {
  title: string;
  description: string;
  icon: string;
}

export interface BenefitMetric {
  label: string;
  value: string;
  icon: string;
}

export interface TestimonialData {
  quote: string;
  author: string;
  role: string;
  company: string;
  metrics?: {
    label: string;
    value: string;
  }[];
}

export interface PricingTier {
  agentType: AgentType;
  name: string;
  price: number;
  currency: 'EUR' | 'USD';
  period: 'month' | 'year';
  included: string[];
  consumption: {
    calls: number;
    sms: number;
    emails: number;
  };
  example?: {
    volume: string;
    breakdown: {
      subscription: number;
      calls: number;
      sms: number;
      total: number;
    };
  };
  badge?: string;
  cta: CTAButton;
}

export interface FAQItem {
  question: string;
  answer: string;
  icon?: string;
}

export interface IntegrationLogo {
  name: string;
  logo: string;
  category: 'crm' | 'calendar' | 'automation' | 'communication' | 'ai';
}
```

**Validation** :
- [ ] Fichier créé avec tous les types
- [ ] Pas d'erreur TypeScript
- [ ] Types exportés correctement

---

### Tâche 1.3 : Créer le système de données centralisé

**Fichier** : `lib/data/agents.ts`

```typescript
import { Agent } from '@/lib/types/landing';

export const agents: Record<string, Agent> = {
  louis: {
    id: 'louis',
    name: 'louis',
    displayName: 'Louis',
    tagline: 'Rappel automatique de leads',
    description: 'Louis rappelle tous vos nouveaux prospects, les qualifie et les dispatch en moins de 60 secondes.',
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
    description: 'Arthur relance chaque prospect dormant avec une approche douce et progressive.',
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
    description: 'Alexandra répond à tous vos appels entrants. Même à 3h du matin.',
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
```

**Fichier** : `lib/data/pricing.ts`

```typescript
import { PricingTier } from '@/lib/types/landing';

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

export const getPricingByAgent = (agentType: string): PricingTier | undefined => {
  return pricingTiers.find(tier => tier.agentType === agentType);
};
```

**Fichier** : `lib/data/integrations.ts`

```typescript
import { IntegrationLogo } from '@/lib/types/landing';

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

export const getIntegrationsByCategory = (category: string): IntegrationLogo[] => {
  return integrations.filter(integration => integration.category === category);
};
```

**Validation** :
- [ ] Tous les fichiers de données créés
- [ ] Données complètes et cohérentes
- [ ] Fonctions helper exportées
- [ ] Pas d'erreur TypeScript

---

### Tâche 1.4 : Créer le layout marketing commun

**Fichier** : `app/(marketing)/layout.tsx`

```typescript
import { Inter } from 'next/font/google';
import { Header } from '@/components/shared/Header';
import { Footer } from '@/components/shared/Footer';

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' });

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className={`${inter.variable} font-sans min-h-screen bg-black text-white`}>
      <Header />
      <main>{children}</main>
      <Footer />
    </div>
  );
}
```

**Validation** :
- [ ] Layout créé et fonctionnel
- [ ] Header et Footer importés correctement
- [ ] Styles appliqués (font, bg, text)

---

### Tâche 1.5 : Créer les composants de base partagés

**Fichier** : `components/shared/Button.tsx`

```typescript
import { cn } from '@/lib/utils';
import { ButtonHTMLAttributes, forwardRef } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'sm' | 'md' | 'lg';
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center rounded-lg font-semibold transition-all',
          'focus:outline-none focus:ring-2 focus:ring-offset-2',
          {
            'bg-gradient-to-r from-violet-600 to-purple-600 hover:from-violet-700 hover:to-purple-700 text-white':
              variant === 'primary',
            'bg-white/10 hover:bg-white/20 text-white backdrop-blur-sm':
              variant === 'secondary',
            'border-2 border-white/20 hover:border-white/40 text-white bg-transparent':
              variant === 'outline',
            'px-4 py-2 text-sm': size === 'sm',
            'px-6 py-3 text-base': size === 'md',
            'px-8 py-4 text-lg': size === 'lg',
          },
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

**Fichier** : `components/shared/Card.tsx`

```typescript
import { cn } from '@/lib/utils';
import { HTMLAttributes } from 'react';

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'gradient' | 'hover';
}

export function Card({ className, variant = 'default', children, ...props }: CardProps) {
  return (
    <div
      className={cn(
        'rounded-2xl border backdrop-blur-sm transition-all',
        {
          'bg-white/5 border-white/10': variant === 'default',
          'bg-gradient-to-br from-white/10 to-white/5 border-white/20':
            variant === 'gradient',
          'bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20 hover:scale-105':
            variant === 'hover',
        },
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}
```

**Validation** :
- [ ] Composants Button et Card créés
- [ ] Variants fonctionnels
- [ ] Styles avec Tailwind CSS
- [ ] Types TypeScript corrects

---

### Tâche 1.6 : Créer les pages de base

**⚠️ IMPORTANT** : Ne pas modifier `app/(marketing)/page.tsx` (home actuelle)

**Fichier** : `app/(marketing)/landingv2/page.tsx` (Nouvelle Home temporaire)

```typescript
export default function LandingV2Page() {
  return (
    <div className="container mx-auto px-4 py-20">
      <h1 className="text-4xl font-bold text-center">
        Nouvelle Home Page Voipia (v2)
      </h1>
      <p className="text-center text-gray-400 mt-4">
        Structure en cours de construction - Phase 1 : Fondations
      </p>
      <p className="text-center text-violet-400 mt-2 text-sm">
        📍 URL de développement : /landingv2
      </p>
    </div>
  );
}
```

**Fichier** : `app/(marketing)/louis/page.tsx`

```typescript
export default function LouisPage() {
  return (
    <div className="container mx-auto px-4 py-20">
      <h1 className="text-4xl font-bold text-center text-blue-500">
        Landing Page Louis
      </h1>
      <p className="text-center text-gray-400 mt-4">
        En construction - Phase 3
      </p>
    </div>
  );
}
```

**Fichier** : `app/(marketing)/arthur/page.tsx`

```typescript
export default function ArthurPage() {
  return (
    <div className="container mx-auto px-4 py-20">
      <h1 className="text-4xl font-bold text-center text-orange-500">
        Landing Page Arthur
      </h1>
      <p className="text-center text-gray-400 mt-4">
        En construction - Phase 4
      </p>
    </div>
  );
}
```

**Fichier** : `app/(marketing)/alexandra/page.tsx`

```typescript
export default function AlexandraPage() {
  return (
    <div className="container mx-auto px-4 py-20">
      <h1 className="text-4xl font-bold text-center text-green-500">
        Landing Page Alexandra
      </h1>
      <p className="text-center text-gray-400 mt-4">
        En construction - Phase 5
      </p>
    </div>
  );
}
```

**Validation** :
- [ ] Toutes les pages créées
- [ ] Routes accessibles
- [ ] Pas d'erreur de build

---

## ✅ Validation de la Phase

### Tests de Build
```bash
npm run build
```
- [ ] Build réussi sans erreur
- [ ] Pas de warning TypeScript critique

### Tests de Navigation
```bash
npm run dev
```
- [ ] `http://localhost:3000/landingv2` accessible (Nouvelle Home)
- [ ] `http://localhost:3000/louis` accessible
- [ ] `http://localhost:3000/arthur` accessible
- [ ] `http://localhost:3000/alexandra` accessible
- [ ] `http://localhost:3000/` reste inchangée (Home actuelle)

### Tests de Composants
- [ ] Button s'affiche correctement
- [ ] Card s'affiche correctement
- [ ] Layout appliqué sur toutes les pages

### Vérification MCP Playwright
- [ ] `browser_navigate` vers chaque page
- [ ] `browser_snapshot` de chaque page
- [ ] Vérification visuelle : pas d'erreur, pages chargent

---

## 📊 Critères de Succès

1. ✅ Structure de routing fonctionnelle (4 pages)
2. ✅ Types TypeScript complets et sans erreur
3. ✅ Système de données centralisé opérationnel
4. ✅ Composants de base réutilisables créés
5. ✅ Layout marketing commun appliqué
6. ✅ Build Next.js réussi
7. ✅ Toutes les routes accessibles

---

## 🔗 Dépendances

**Avant cette phase** :
- Aucune (phase fondatrice)

**Après cette phase** :
- Phase 2 : Home (dépend de la structure)
- Phase 3 : Louis (dépend de la structure)
- Phase 4 : Arthur (dépend de la structure)
- Phase 5 : Alexandra (dépend de la structure)

---

## 📝 Notes Techniques

- Utiliser Next.js 15 App Router
- Layout groups avec `(marketing)` pour isolation
- Tailwind CSS pour tous les styles
- Framer Motion pour animations (à ajouter dans phases suivantes)
- Composants TypeScript stricts (`noImplicitAny`)

---

**Dernière mise à jour** : 2025-10-28
**Auteur** : Claude Code
**Statut** : 📋 Prêt pour génération PRP
