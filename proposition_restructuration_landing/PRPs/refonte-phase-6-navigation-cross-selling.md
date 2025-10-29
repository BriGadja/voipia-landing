# PRP : Phase 6 - Navigation et Cross-Selling

**Date** : 2025-10-29
**Statut** : 📋 Prêt pour exécution
**Priorité** : 🟡 IMPORTANTE
**Durée estimée** : 2-3 jours
**Confidence Score** : 9/10

---

## 🎯 Purpose & Goal

### What We're Building
Implémenter la **navigation inter-pages** et le **système de cross-selling** pour connecter toutes les landing pages créées dans les phases 1-5 et maximiser la découverte des agents et les conversions.

### Business Value
- **Augmenter le taux de découverte** : Les visiteurs découvrent tous les agents, pas seulement celui de leur page d'atterrissage
- **Améliorer les conversions** : Quiz de qualification pour orienter vers la bonne solution
- **Maximiser l'ARPU** : Promotion des bundles (Pack Complet 3 agents) avec réduction de 8%
- **Fluidifier le parcours** : Navigation cohérente et intuitive entre toutes les pages

### Current State (After Phase 5)
- ✅ 4 pages indépendantes : `/landingv2`, `/louis`, `/arthur`, `/alexandra`
- ✅ 30 composants landing créés
- ✅ Système de données centralisé
- ❌ Pas de navigation inter-pages
- ❌ Pas de suggestions d'autres agents
- ❌ Pas de quiz de qualification
- ❌ Pas d'offre bundle

---

## 📋 Context & References

### Essential Files to Understand

```yaml
- file: lib/data/agents.ts
  why: Structure des données agents (icon, tagline, colors, description)

- file: lib/data/pricing.ts
  why: Tarifs individuels pour calculer les bundles

- file: lib/types/landing.ts
  why: Types TypeScript (Agent, PricingTier, etc.)

- file: components/shared/Button.tsx
  why: Composant Button réutilisable avec variants

- file: components/shared/Card.tsx
  why: Composant Card avec glassmorphism

- file: app/(marketing)/louis/page.tsx
  why: Structure de page LP à compléter avec OtherAgents

- file: proposition_restructuration_landing/INITIAL/INITIAL_refonte_06_navigation.md
  why: Spécifications détaillées de la phase
```

### Existing Patterns to Follow

**Design System** :
- Dark theme avec glassmorphism
- Gradients personnalisés par agent (blue/cyan, orange/amber, green/emerald)
- Spacing : `py-20` ou `py-24` pour les sections
- Container : `container mx-auto px-4`
- Cards : `border border-white/10 backdrop-blur-lg bg-black/40`

**Agent Colors** :
- Louis : `from-blue-600 to-cyan-500`
- Arthur : `from-orange-600 to-amber-500`
- Alexandra : `from-green-600 to-emerald-500`

**Navigation Patterns** :
- Next.js `<Link>` pour navigation côté client
- `useRouter()` pour redirections programmatiques
- Hover states : `hover:bg-white/5 transition`

---

## 🏗️ Implementation Blueprint

### Task 6.1 : Header avec Dropdown "Solutions"

**Goal** : Créer un header fixe avec menu dropdown listant les 3 agents

**Component** : `components/shared/Header.tsx` (à créer)

```typescript
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ChevronDown } from 'lucide-react';

const agents = [
  { id: 'louis', icon: '📞', name: 'Louis', tagline: 'Rappel automatique de leads' },
  { id: 'arthur', icon: '🔄', name: 'Arthur', tagline: 'Réactivation de bases dormantes' },
  { id: 'alexandra', icon: '☎️', name: 'Alexandra', tagline: 'Réception d\'appels 24/7' },
];

export function Header() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-lg border-b border-white/10">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/landingv2" className="text-2xl font-bold bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent hover:from-violet-300 hover:to-purple-300 transition">
            VoIPIA
          </Link>

          {/* Navigation Desktop */}
          <nav className="hidden md:flex items-center gap-8">
            {/* Dropdown Solutions */}
            <div
              className="relative"
              onMouseEnter={() => setIsOpen(true)}
              onMouseLeave={() => setIsOpen(false)}
            >
              <button className="flex items-center gap-2 text-gray-300 hover:text-white transition-colors">
                <span>Solutions</span>
                <ChevronDown className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
              </button>

              {/* Dropdown Menu */}
              {isOpen && (
                <div className="absolute top-full left-0 mt-2 w-80 bg-black/95 backdrop-blur-xl border border-white/10 rounded-lg p-4 shadow-2xl">
                  <div className="space-y-2">
                    {agents.map((agent) => (
                      <Link
                        key={agent.id}
                        href={`/${agent.id}`}
                        className="flex items-start gap-3 p-3 rounded-lg hover:bg-white/5 transition-colors group"
                      >
                        <span className="text-3xl">{agent.icon}</span>
                        <div className="flex-1">
                          <p className="font-semibold text-white group-hover:text-violet-400 transition-colors">
                            {agent.name}
                          </p>
                          <p className="text-sm text-gray-400">
                            {agent.tagline}
                          </p>
                        </div>
                      </Link>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <Link href="/landingv2#tarifs" className="text-gray-300 hover:text-white transition-colors">
              Tarifs
            </Link>
            <Link href="/landingv2#faq" className="text-gray-300 hover:text-white transition-colors">
              FAQ
            </Link>
          </nav>

          {/* CTAs */}
          <div className="flex items-center gap-4">
            <Link
              href="/login"
              className="text-sm text-gray-300 hover:text-white transition-colors"
            >
              Connexion
            </Link>
            <Link
              href="/landingv2#contact"
              className="px-4 py-2 bg-gradient-to-r from-violet-600 to-purple-600 rounded-lg text-sm font-semibold hover:from-violet-700 hover:to-purple-700 transition-all hover:shadow-lg hover:shadow-violet-500/20"
            >
              Tester gratuitement
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
}
```

**Integration** :
- Ajouter `<Header />` dans `app/(marketing)/layout.tsx`
- Ajouter `pt-16` sur le `<main>` pour compenser le header fixe

---

### Task 6.2 : Quiz de Qualification

**Goal** : Quiz interactif sur la Home pour orienter vers la bonne LP

**Component** : `components/landing/QualificationQuiz.tsx`

```typescript
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { Sparkles } from 'lucide-react';

const questions = [
  {
    id: 1,
    question: 'Quel est votre principal défi commercial ?',
    options: [
      {
        label: 'Rappeler rapidement mes nouveaux leads',
        description: 'Vous générez des leads mais perdez du temps à les rappeler',
        value: 'louis',
        icon: '📞',
      },
      {
        label: 'Réactiver mes prospects dormants',
        description: 'Vous avez une base de contacts inexploitée',
        value: 'arthur',
        icon: '🔄',
      },
      {
        label: 'Répondre à tous mes appels entrants',
        description: 'Vous manquez des appels importants',
        value: 'alexandra',
        icon: '☎️',
      },
    ],
  },
];

export function QualificationQuiz() {
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [isAnimating, setIsAnimating] = useState(false);

  const handleAnswer = (value: string) => {
    setIsAnimating(true);

    // Animation + redirection
    setTimeout(() => {
      router.push(`/${value}`);
    }, 300);
  };

  const currentQuestion = questions[step];

  return (
    <section className="py-20 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-violet-900/10 to-transparent" />

      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-3xl mx-auto">
          {/* Header */}
          <div className="text-center mb-12">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-violet-500/10 border border-violet-500/20 backdrop-blur-sm mb-6">
              <Sparkles className="w-4 h-4 text-violet-400" />
              <span className="text-sm font-semibold text-violet-300">
                Orientation personnalisée
              </span>
            </div>
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              <span className="text-white">Quel agent IA</span>
              <br />
              <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
                répond le mieux à votre besoin ?
              </span>
            </h2>
            <p className="text-lg text-gray-300">
              Répondez en 1 clic pour découvrir la solution idéale
            </p>
          </div>

          {/* Quiz Card */}
          <Card variant="gradient" className="p-8">
            <div className="mb-8">
              <p className="text-xl font-semibold text-white mb-2">
                {currentQuestion.question}
              </p>
              <p className="text-sm text-gray-400">
                Choisissez l'option qui correspond le mieux à votre situation
              </p>
            </div>

            <div className="space-y-4">
              {currentQuestion.options.map((option) => (
                <button
                  key={option.value}
                  onClick={() => handleAnswer(option.value)}
                  disabled={isAnimating}
                  className="w-full p-6 text-left rounded-lg border border-white/20 hover:border-white/40 hover:bg-white/5 transition-all group disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <div className="flex items-start gap-4">
                    <span className="text-4xl">{option.icon}</span>
                    <div className="flex-1">
                      <p className="font-semibold text-lg text-white mb-1 group-hover:text-violet-400 transition-colors">
                        {option.label}
                      </p>
                      <p className="text-sm text-gray-400">
                        {option.description}
                      </p>
                    </div>
                    <span className="text-violet-400 opacity-0 group-hover:opacity-100 transition-opacity">
                      →
                    </span>
                  </div>
                </button>
              ))}
            </div>
          </Card>

          {/* Footer */}
          <p className="text-center text-sm text-gray-400 mt-6">
            Pas sûr de votre choix ? <button className="text-violet-400 hover:underline">Découvrez tous nos agents</button>
          </p>
        </div>
      </div>
    </section>
  );
}
```

**Integration** :
- Ajouter dans `app/(marketing)/landingv2/page.tsx` après la section AgentsGridHome

---

### Task 6.3 : Section "Découvrez nos autres agents"

**Goal** : Suggérer les 2 autres agents en bas de chaque LP

**Component** : `components/landing/OtherAgents.tsx`

```typescript
import Link from 'next/link';
import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { Sparkles, ArrowRight } from 'lucide-react';

interface OtherAgentsProps {
  currentAgent: 'louis' | 'arthur' | 'alexandra';
}

const allAgents = {
  louis: {
    id: 'louis',
    icon: '📞',
    name: 'Louis',
    tagline: 'Rappel automatique',
    description: 'Louis rappelle tous vos nouveaux prospects en moins de 60 secondes et planifie automatiquement vos rendez-vous.',
    gradient: 'from-blue-600 to-cyan-500',
  },
  arthur: {
    id: 'arthur',
    icon: '🔄',
    name: 'Arthur',
    tagline: 'Réactivation de bases',
    description: 'Arthur relance intelligemment vos prospects dormants avec une approche douce et progressive.',
    gradient: 'from-orange-600 to-amber-500',
  },
  alexandra: {
    id: 'alexandra',
    icon: '☎️',
    name: 'Alexandra',
    tagline: 'Réception 24/7',
    description: 'Alexandra répond à 100% de vos appels entrants, même en dehors de vos horaires d\'ouverture.',
    gradient: 'from-green-600 to-emerald-500',
  },
};

export function OtherAgents({ currentAgent }: OtherAgentsProps) {
  const otherAgentIds = (['louis', 'arthur', 'alexandra'] as const).filter(
    (id) => id !== currentAgent
  );

  const otherAgents = otherAgentIds.map((id) => allAgents[id]);

  return (
    <section className="py-24 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-black via-violet-950/20 to-black" />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(139,92,246,0.1),transparent_50%)]" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Header */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-violet-500/10 border border-violet-500/20 backdrop-blur-sm mb-6">
            <Sparkles className="w-4 h-4 text-violet-400" />
            <span className="text-sm font-semibold text-violet-300">
              Découvrez nos autres solutions
            </span>
          </div>
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Vous avez d'autres défis ?</span>
            <br />
            <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
              Découvrez nos autres agents IA
            </span>
          </h2>
          <p className="text-xl text-gray-300">
            Maximisez votre efficacité commerciale avec une équipe complète d'agents IA spécialisés.
          </p>
        </div>

        {/* Agents Grid */}
        <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto mb-12">
          {otherAgents.map((agent) => (
            <Link key={agent.id} href={`/${agent.id}`}>
              <Card variant="hover" className="p-8 h-full group">
                {/* Badge */}
                <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium mb-6 bg-gradient-to-r ${agent.gradient} bg-opacity-10`}>
                  <span className="text-2xl">{agent.icon}</span>
                  <span className="text-white">{agent.tagline}</span>
                </div>

                {/* Content */}
                <h3 className="text-2xl font-bold text-white mb-4 group-hover:text-violet-400 transition-colors">
                  {agent.name}
                </h3>
                <p className="text-gray-400 mb-6 leading-relaxed">
                  {agent.description}
                </p>

                {/* CTA */}
                <div className="flex items-center gap-2 text-violet-400 font-semibold group-hover:gap-4 transition-all">
                  <span>En savoir plus</span>
                  <ArrowRight className="w-5 h-5" />
                </div>
              </Card>
            </Link>
          ))}
        </div>

        {/* Bundle CTA */}
        <div className="max-w-3xl mx-auto">
          <Card variant="gradient" className="p-8 text-center bg-gradient-to-r from-violet-600/20 via-purple-600/20 to-pink-600/20 border-violet-500/30">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-500/20 text-green-400 font-semibold mb-6">
              💰 Économisez 8% avec le Pack Complet
            </div>
            <h3 className="text-3xl font-bold text-white mb-4">
              Combinez les 3 agents pour une couverture totale
            </h3>
            <p className="text-lg text-gray-300 mb-8">
              Offre Bundle : <span className="line-through text-gray-500">970€</span> <span className="text-3xl font-bold text-white">890€</span> HT/mois
            </p>
            <Button variant="primary" size="lg">
              Découvrir le Pack Complet →
            </Button>
          </Card>
        </div>
      </div>
    </section>
  );
}
```

**Integration** :
- Ajouter avant le `<CTAFinalLouis />` dans `app/(marketing)/louis/page.tsx`
- Ajouter avant le `<CTAFinalArthur />` dans `app/(marketing)/arthur/page.tsx`
- Ajouter avant le `<CTAFinalAlexandra />` dans `app/(marketing)/alexandra/page.tsx`

---

### Task 6.4 : Bundle Pricing

**Goal** : Section dédiée au Pack Complet sur la Home

**Component** : `components/landing/BundlePricing.tsx`

```typescript
import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { Check, TrendingDown } from 'lucide-react';

export function BundlePricing() {
  const bundle = {
    name: 'Pack Complet',
    tagline: 'Les 3 agents IA pour une couverture commerciale totale',
    agents: [
      { name: 'Louis', icon: '📞', description: 'Rappel automatique de leads' },
      { name: 'Arthur', icon: '🔄', description: 'Réactivation de bases dormantes' },
      { name: 'Alexandra', icon: '☎️', description: 'Réception d\'appels 24/7' },
    ],
    normalPrice: 970,
    bundlePrice: 890,
    savings: 80,
    savingsPercent: 8,
  };

  const benefits = [
    'Couverture complète : leads neufs, dormants et appels entrants',
    'Intégration CRM unifiée pour les 3 agents',
    'Dashboard consolidé avec reporting global',
    'Économie de 80€/mois par rapport aux abonnements séparés',
    'Support prioritaire dédié',
    'Onboarding accéléré (tous les agents configurés ensemble)',
  ];

  return (
    <section className="py-24 relative">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-purple-900/10 to-transparent" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Header */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-500/10 border border-green-500/20 backdrop-blur-sm mb-6">
            <TrendingDown className="w-4 h-4 text-green-400" />
            <span className="text-sm font-semibold text-green-400">
              Économisez {bundle.savingsPercent}% avec le Pack Complet
            </span>
          </div>
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="text-white">Une équipe IA complète</span>
            <br />
            <span className="bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
              pour maximiser vos conversions
            </span>
          </h2>
          <p className="text-xl text-gray-300">
            Combinez les 3 agents et bénéficiez d'une réduction immédiate
          </p>
        </div>

        {/* Bundle Card */}
        <div className="max-w-4xl mx-auto">
          <Card variant="gradient" className="p-10 bg-gradient-to-br from-violet-600/20 via-purple-600/20 to-pink-600/20 border-violet-500/30">
            <div className="grid md:grid-cols-2 gap-12">
              {/* Left: Pricing */}
              <div>
                <h3 className="text-3xl font-bold text-white mb-4">
                  {bundle.name}
                </h3>
                <p className="text-gray-300 mb-8">
                  {bundle.tagline}
                </p>

                {/* Prix */}
                <div className="mb-8">
                  <p className="text-gray-400 line-through text-xl mb-2">
                    {bundle.normalPrice}€ HT/mois
                  </p>
                  <div className="flex items-baseline gap-2 mb-2">
                    <span className="text-6xl font-bold text-white">
                      {bundle.bundlePrice}€
                    </span>
                    <span className="text-xl text-gray-400">
                      HT/mois
                    </span>
                  </div>
                  <p className="text-green-400 font-semibold text-lg">
                    💰 Économisez {bundle.savings}€ par mois
                  </p>
                </div>

                {/* Agents inclus */}
                <div className="space-y-3 mb-8">
                  <p className="text-sm font-semibold text-gray-400 uppercase tracking-wide">
                    Agents inclus
                  </p>
                  {bundle.agents.map((agent) => (
                    <div key={agent.name} className="flex items-center gap-3">
                      <span className="text-2xl">{agent.icon}</span>
                      <div>
                        <p className="font-semibold text-white">{agent.name}</p>
                        <p className="text-sm text-gray-400">{agent.description}</p>
                      </div>
                    </div>
                  ))}
                </div>

                <Button variant="primary" size="lg" className="w-full">
                  Démarrer avec le Pack Complet
                </Button>
              </div>

              {/* Right: Benefits */}
              <div className="space-y-4">
                <p className="text-sm font-semibold text-gray-400 uppercase tracking-wide mb-6">
                  Avantages du Pack
                </p>
                {benefits.map((benefit) => (
                  <div key={benefit} className="flex items-start gap-3">
                    <div className="flex-shrink-0 w-6 h-6 rounded-full bg-green-500/20 flex items-center justify-center">
                      <Check className="w-4 h-4 text-green-400" />
                    </div>
                    <p className="text-gray-300 leading-relaxed">{benefit}</p>
                  </div>
                ))}
              </div>
            </div>
          </Card>
        </div>

        {/* Footer Note */}
        <p className="text-center text-sm text-gray-400 mt-8">
          💡 Le Pack Complet inclut les 3 abonnements + consommation au réel (appels, SMS)
        </p>
      </div>
    </section>
  );
}
```

**Integration** :
- Ajouter dans `app/(marketing)/landingv2/page.tsx` après la section PricingCardsHome

---

### Task 6.5 : Liens Croisés Intelligents

**Goal** : Ajouter des suggestions contextuelles dans le contenu des LP

**Implementation** : Créer un composant réutilisable pour les suggestions

**Component** : `components/landing/CrossSellHint.tsx`

```typescript
import Link from 'next/link';
import { Lightbulb, ArrowRight } from 'lucide-react';

interface CrossSellHintProps {
  text: string;
  agentName: string;
  agentLink: string;
}

export function CrossSellHint({ text, agentName, agentLink }: CrossSellHintProps) {
  return (
    <Link href={agentLink}>
      <div className="group inline-flex items-start gap-3 p-4 rounded-lg bg-violet-500/10 border border-violet-500/20 hover:border-violet-500/40 hover:bg-violet-500/20 transition-all">
        <Lightbulb className="w-5 h-5 text-violet-400 flex-shrink-0 mt-0.5" />
        <div className="flex-1">
          <p className="text-sm text-gray-300 group-hover:text-white transition-colors">
            {text}{' '}
            <span className="font-semibold text-violet-400 group-hover:underline">
              {agentName}
            </span>
          </p>
        </div>
        <ArrowRight className="w-5 h-5 text-violet-400 opacity-0 group-hover:opacity-100 transition-all -translate-x-2 group-hover:translate-x-0" />
      </div>
    </Link>
  );
}
```

**Usage Examples** :

Dans `app/(marketing)/louis/page.tsx`, ajouter après la section BenefitsTable :
```tsx
<div className="container mx-auto px-4 py-8">
  <CrossSellHint
    text="Vous avez aussi une base de leads dormants ?"
    agentName="Découvrez Arthur"
    agentLink="/arthur"
  />
</div>
```

Dans `app/(marketing)/arthur/page.tsx`, ajouter après la section TestimonialArthur :
```tsx
<div className="container mx-auto px-4 py-8">
  <CrossSellHint
    text="Besoin de traiter vos nouveaux leads rapidement ?"
    agentName="Rencontrez Louis"
    agentLink="/louis"
  />
</div>
```

Dans `app/(marketing)/alexandra/page.tsx`, ajouter après la section FAQ :
```tsx
<div className="container mx-auto px-4 py-8">
  <CrossSellHint
    text="Vous générez beaucoup de leads sortants ?"
    agentName="Laissez Louis les rappeler automatiquement"
    agentLink="/louis"
  />
</div>
```

---

### Task 6.6 : Update Agents Data

**Goal** : Ajouter fonction helper dans `lib/data/agents.ts`

```typescript
// Ajouter cette fonction à la fin du fichier
export const getAllAgents = (): Agent[] => {
  return Object.values(agents);
};

export const getOtherAgents = (currentAgentId: string): Agent[] => {
  return Object.values(agents).filter(agent => agent.id !== currentAgentId);
};
```

---

### Task 6.7 : Layout Update

**Goal** : Intégrer le Header dans le layout marketing

**File** : `app/(marketing)/layout.tsx`

```typescript
import type { Metadata } from 'next';
import { Header } from '@/components/shared/Header';

export const metadata: Metadata = {
  title: 'Voipia - Agents Vocaux IA 24/7',
  description: 'Automatisez vos appels sortants et entrants avec des agents IA ultra-réalistes.',
};

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <Header />
      <main className="pt-16">{children}</main>
    </>
  );
}
```

---

## ✅ Validation Loops

### Build & Lint Checks

```bash
# 1. TypeScript compilation
npm run build

# Expected: ✓ Compiled successfully
# Check: No type errors, all new components compile

# 2. Linting
npm run lint

# Expected: No errors or warnings
# Check: Code quality standards maintained
```

### Development Testing

```bash
# 1. Start dev server
npm run dev

# 2. Test navigation flow
# - Visit http://localhost:3000/landingv2
# - Hover over "Solutions" in header → dropdown should appear
# - Click on each agent → should navigate to correct LP
# - Scroll down → Quiz should be visible
# - Click quiz option → should redirect to agent LP

# 3. Test cross-selling on each LP
# - Visit /louis → scroll to bottom → should see Arthur + Alexandra cards
# - Visit /arthur → scroll to bottom → should see Louis + Alexandra cards
# - Visit /alexandra → scroll to bottom → should see Louis + Arthur cards
# - Check that "Pack Complet" CTA is visible on all LP
```

### Browser Visual Testing (MCP Playwright)

```javascript
// Test Header Dropdown
await page.goto('http://localhost:3000/landingv2');
await page.hover('nav >> text=Solutions');
// Take snapshot of dropdown
await page.screenshot({ path: 'header-dropdown.png' });

// Test Quiz
await page.goto('http://localhost:3000/landingv2');
await page.locator('text=Quel agent IA').scrollIntoViewIfNeeded();
// Take snapshot of quiz section
await page.screenshot({ path: 'quiz-section.png' });

// Test OtherAgents on Louis
await page.goto('http://localhost:3000/louis');
await page.locator('text=Découvrez nos autres agents').scrollIntoViewIfNeeded();
// Take snapshot
await page.screenshot({ path: 'louis-other-agents.png' });

// Test Bundle Pricing on Home
await page.goto('http://localhost:3000/landingv2');
await page.locator('text=Pack Complet').scrollIntoViewIfNeeded();
// Take snapshot
await page.screenshot({ path: 'bundle-pricing.png' });
```

### Functional Validation Checklist

Navigation :
- [ ] Header visible sur toutes les pages
- [ ] Dropdown "Solutions" s'ouvre au hover
- [ ] 3 agents listés avec icon + tagline
- [ ] Clic sur agent → navigation correcte
- [ ] Logo "VoIPIA" → retour Home

Quiz :
- [ ] Quiz visible sur Home après AgentsGridHome
- [ ] 3 options cliquables
- [ ] Clic → redirection vers LP correspondante
- [ ] Animation smooth

Cross-Selling :
- [ ] Section "Autres agents" visible sur chaque LP
- [ ] 2 agents alternatifs affichés
- [ ] Cards cliquables → navigation correcte
- [ ] CTA "Pack Complet" visible

Bundle Pricing :
- [ ] Section visible sur Home
- [ ] Prix bundle (890€) et économies (80€) affichés
- [ ] 3 agents listés avec descriptions
- [ ] CTA "Démarrer" cliquable

Liens Croisés :
- [ ] Au moins 1 CrossSellHint par LP
- [ ] Suggestions contextuelles pertinentes
- [ ] Hover effect fonctionnel
- [ ] Navigation correcte

Responsive :
- [ ] Header responsive (mobile hamburger menu)
- [ ] Quiz responsive (cards empilées)
- [ ] OtherAgents responsive (grid 1 col mobile)
- [ ] Bundle responsive

---

## ⚠️ Anti-patterns to Avoid

### Don't
- ❌ Hardcoder les données d'agents (utiliser `lib/data/agents.ts`)
- ❌ Créer des duplications de composants (réutiliser Card, Button)
- ❌ Oublier les états hover/active
- ❌ Négliger le mobile (test responsive obligatoire)
- ❌ Sauter la vérification visuelle MCP Playwright
- ❌ Utiliser des images au lieu de gradients CSS
- ❌ Ignorer les transitions/animations

### Do
- ✅ Utiliser les helpers `getAllAgents()`, `getOtherAgents()`
- ✅ Suivre les patterns de gradient par agent
- ✅ Ajouter des transitions sur les hover states
- ✅ Tester sur mobile ET desktop
- ✅ Utiliser `<Link>` Next.js pour navigation
- ✅ Garder les espacements cohérents (`py-20`, `py-24`)
- ✅ Réutiliser les composants partagés (Card, Button)

---

## 🎯 Success Criteria

Cette phase est considérée comme réussie quand :

### Fonctionnel
1. ✅ Header avec dropdown visible sur toutes les pages
2. ✅ Dropdown liste les 3 agents avec navigation fonctionnelle
3. ✅ Quiz de qualification sur Home avec redirection
4. ✅ Section "Autres agents" sur chaque LP (2 agents alternatifs)
5. ✅ Bundle Pricing visible sur Home
6. ✅ Liens croisés intelligents sur chaque LP (min 1 par page)

### Technique
1. ✅ Build Next.js sans erreur
2. ✅ Aucune erreur TypeScript
3. ✅ ESLint sans warning
4. ✅ Navigation côté client (pas de rechargement full page)

### Visuel
1. ✅ Design cohérent avec les phases précédentes
2. ✅ Animations smooth sur hover/click
3. ✅ Responsive sur mobile/tablet/desktop
4. ✅ Gradients et glassmorphism respectés

### Business
1. ✅ Taux de découverte des autres agents augmenté
2. ✅ Parcours utilisateur fluide et intuitif
3. ✅ Bundle mis en avant pour maximiser ARPU
4. ✅ Suggestions contextuelles pertinentes

---

## 📊 Metrics to Track (Post-Implementation)

### Navigation
- Taux de clic sur le dropdown "Solutions"
- Parcours inter-pages (Home → LP → autre LP)
- Taux de rebond par page

### Quiz
- Taux de complétion du quiz
- Distribution des choix (Louis vs Arthur vs Alexandra)
- Taux de conversion post-quiz

### Cross-Selling
- Taux de clic sur "Autres agents"
- Taux de clic sur les CrossSellHints
- Pages vues par session (avant/après)

### Bundle
- Taux de clic sur "Pack Complet"
- Conversions Bundle vs Agents individuels
- ARPU moyen (avant/après Phase 6)

---

## 🔗 Dependencies

### Required Before Starting
- ✅ Phase 1 : Fondations (routing, composants partagés)
- ✅ Phase 2 : Home (`/landingv2`)
- ✅ Phase 3 : Louis (`/louis`)
- ✅ Phase 4 : Arthur (`/arthur`)
- ✅ Phase 5 : Alexandra (`/alexandra`)

### Blocks
- Phase 7 : SEO & Analytics (peut commencer après Phase 6)

---

## 📝 Implementation Order

**Ordre recommandé d'exécution** :

1. **Task 6.6** : Update agents.ts (helpers `getAllAgents`, `getOtherAgents`)
2. **Task 6.1** : Header avec dropdown
3. **Task 6.7** : Layout update (intégrer Header)
4. **Task 6.3** : OtherAgents component
5. **Task 6.5** : CrossSellHint component
6. **Task 6.4** : BundlePricing component
7. **Task 6.2** : QualificationQuiz component
8. **Integration** : Ajouter tous les composants dans les pages
9. **Validation** : Build, tests visuels, tests fonctionnels

**Rationale** : Commencer par les données et le header (visible partout), puis les composants de cross-selling, et terminer par le quiz (plus complexe).

---

## 🚀 Next Steps After Phase 6

Une fois cette phase validée :
- ✅ Navigation inter-pages opérationnelle
- ✅ Cross-selling actif
- ✅ Bundle visible
- ✅ Parcours utilisateur optimisé

**Phase 7** : SEO, Analytics et Optimisations
- Meta descriptions uniques par page
- Structured data (JSON-LD)
- Sitemap.xml et robots.txt
- Google Analytics 4 tracking
- Performance optimizations (Lighthouse > 90)

---

**Dernière mise à jour** : 2025-10-29
**Auteur** : Claude Code
**Confidence Score** : 9/10

**Raisons du score** :
- ✅ Context complet (agents data, pricing, composants existants)
- ✅ Patterns Voipia bien documentés
- ✅ Validation loops détaillés
- ✅ Code examples complets et testables
- ⚠️ Hamburger menu mobile non détaillé (peut nécessiter ajustements)
