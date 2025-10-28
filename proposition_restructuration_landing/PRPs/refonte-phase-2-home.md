# PRP - PHASE 2 : PAGE HOME (RESTRUCTURÉE)

## 🎯 Purpose & Goal

**Objectif Principal** : Créer la nouvelle page d'accueil sur `/landingv2` qui servira de "router principal" vers les 3 landing pages dédiées.

**Impact Business** :
- Point d'entrée principal pour tous les visiteurs
- Présentation équitable des 3 agents (Louis, Arthur, Alexandra)
- Guidage intelligent vers les LP appropriées
- Conversion des visiteurs indécis avec message global fort
- Inclusion d'un comparatif SDR vs VoIPIA pour faciliter la décision

**Stratégie** :
- ⚠️ Développement sur `/landingv2` pour NE PAS impacter la home actuelle (`/`)
- 9 sections structurées pour un parcours de conversion optimal
- Réutilisation maximale des composants et données créés en Phase 1

**Durée estimée** : 3-4 jours
**Priorité** : 🔴 HAUTE (point d'entrée principal du funnel)

---

## 📚 Context & References

### Documentation Projet

```yaml
- file: C:\Users\pc\Documents\Projets\voipia-landing\CLAUDE.md
  why: Règles du projet, conventions, workflow PRP, design system

- file: C:\Users\pc\Documents\Projets\voipia-landing\proposition_restructuration_landing\INITIAL\INITIAL_refonte_02_home.md
  why: Spécifications détaillées de la Phase 2 avec code pseudocode

- file: C:\Users\pc\Documents\Projets\voipia-landing\proposition_restructuration_landing\Home.txt
  why: Contenu exact de la nouvelle Home (titres, descriptions, statistiques)
```

### Fichiers Sources de la Phase 1

```yaml
- file: lib/data/agents.ts
  why: Données des 3 agents à afficher dans les cartes

- file: lib/data/pricing.ts
  why: Tarifs des 3 agents pour la section pricing

- file: lib/data/integrations.ts
  why: Logos tech pour la barre "Propulsé par"

- file: lib/data/faqs.ts
  why: 7 FAQs générales de la Home (déjà définies)

- file: lib/types/landing.ts
  why: Types TypeScript pour les composants

- file: components/shared/Button/index.tsx
  why: Composant Button réutilisable

- file: components/shared/Card/index.tsx
  why: Composant Card réutilisable

- file: app/(marketing)/landingv2/page.tsx
  why: Page placeholder à remplacer avec le vrai contenu
```

### Structure Actuelle de la Home (`/`)

La home actuelle a déjà plusieurs sections similaires dans `components/sections/`. Nous devons :
- **S'inspirer** de leur structure et design
- **Créer de nouveaux composants** dans `components/landing/` pour la refonte
- **Ne pas modifier** les composants existants dans `components/sections/`

---

## 🏗️ Implementation Blueprint

### Architecture de la Nouvelle Home

```
app/(marketing)/landingv2/page.tsx
├── HeroHome                    (components/landing/HeroHome.tsx)
├── IntegrationBar              (components/landing/IntegrationBar.tsx)
├── AgentsGridHome              (components/landing/AgentsGridHome.tsx)
├── HowItWorksHome              (components/landing/HowItWorksHome.tsx)
├── PricingCardsHome            (components/landing/PricingCardsHome.tsx)
├── SDRComparison               (components/landing/SDRComparison.tsx)
├── CustomDevelopment           (components/landing/CustomDevelopment.tsx)
├── FAQAccordion                (components/landing/FAQAccordion.tsx)
└── CTAFinal                    (components/landing/CTAFinal.tsx)
```

### Structure des 9 Sections

**Section 1 : Hero**
- Titre principal avec gradient animé
- Présentation des 3 agents en liste
- 2 CTAs (Tester gratuitement + Écouter exemple)

**Section 2 : Barre "Propulsé par"**
- Logos tech en défilement horizontal animé
- Credibility boost avec les grandes marques IA

**Section 3 : Les 3 Agents**
- 3 cartes cliquables (Louis, Arthur, Alexandra)
- Stats par agent
- Audio player + lien vers LP dédiée

**Section 4 : Comment ça marche**
- 3 étapes visuelles
- Timeline ou processus simplifié

**Section 5 : Tarifs**
- 3 cartes de pricing
- Inclusions + consommation
- CTA "Tester gratuitement"

**Section 6 : Comparatif SDR vs VoIPIA**
- Tableau comparatif
- Avantages IA vs humain

**Section 7 : Développements sur-mesure**
- Call-out pour les besoins spécifiques
- CTA "Nous contacter"

**Section 8 : FAQ**
- 7 questions accordéon
- Réponses détaillées

**Section 9 : CTA Final**
- Dernier push avant footer
- CTA principal + arguments clés

---

## 📋 Task Breakdown

### Task 2.1 : Hero Section

**Objectif** : Présenter la value proposition principale avec les 3 agents.

**Fichier** : `components/landing/HeroHome.tsx`

**Implémentation** :
```typescript
import { Button } from '@/components/shared/Button';

export function HeroHome() {
  return (
    <section className="relative min-h-[90vh] flex items-center justify-center py-20">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-black via-purple-950/20 to-black" />

      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-4xl mx-auto text-center space-y-8">
          {/* Badge animé */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-violet-500/10 to-purple-500/10 border border-violet-500/20 animate-pulse">
            <span className="text-sm font-medium">🤖 Agents IA Vocaux</span>
          </div>

          {/* Titre principal */}
          <h1 className="text-5xl md:text-7xl font-bold leading-tight">
            <span className="bg-gradient-to-r from-white via-violet-200 to-purple-200 bg-clip-text text-transparent">
              Déléguez le traitement de vos prospects à nos agents IA
            </span>
          </h1>

          {/* Sous-titre avec 3 agents */}
          <div className="space-y-3 text-lg md:text-xl text-gray-300">
            <p className="flex items-center justify-center gap-3">
              <span className="text-blue-400 font-semibold">📞 Louis</span>
              <span>rappelle chaque nouveau lead</span>
            </p>
            <p className="flex items-center justify-center gap-3">
              <span className="text-green-400 font-semibold">☎️ Alexandra</span>
              <span>répond à chaque appel</span>
            </p>
            <p className="flex items-center justify-center gap-3">
              <span className="text-orange-400 font-semibold">🔄 Arthur</span>
              <span>relance chaque prospect dormant</span>
            </p>
          </div>

          {/* Résultat */}
          <p className="text-xl md:text-2xl text-gray-400 font-medium">
            → Résultat : votre agenda se remplit de RDV qualifiés
          </p>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center pt-4">
            <Button size="lg" variant="primary">
              Tester nos agents gratuitement
            </Button>
            <Button size="lg" variant="outline">
              🎧 Écouter un exemple d&apos;appel
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Composant créé et importé dans `/landingv2/page.tsx`
- [ ] Responsive (mobile, tablet, desktop)
- [ ] CTAs fonctionnels
- [ ] Badge animé avec pulse
- [ ] Gradient sur titre

---

### Task 2.2 : Barre "Propulsé par"

**Objectif** : Montrer la crédibilité avec les logos des tech partners.

**Fichier** : `components/landing/IntegrationBar.tsx`

**Implémentation** :
```typescript
import { integrations } from '@/lib/data/integrations';
import Image from 'next/image';

export function IntegrationBar() {
  const aiLogos = integrations.filter(i => i.category === 'ai');

  return (
    <section className="py-16 border-y border-white/10 bg-gradient-to-r from-black via-purple-950/5 to-black">
      <div className="container mx-auto px-4">
        <p className="text-center text-gray-400 mb-8 text-sm uppercase tracking-wider">
          Propulsé par les meilleures technologies IA
        </p>

        {/* Logos avec défilement */}
        <div className="relative overflow-hidden">
          <div className="flex gap-12 items-center justify-center flex-wrap md:flex-nowrap">
            {aiLogos.map((logo) => (
              <div
                key={logo.name}
                className="flex-shrink-0 transition-all hover:scale-110"
              >
                <Image
                  src={logo.logo}
                  alt={logo.name}
                  width={120}
                  height={40}
                  className="opacity-50 hover:opacity-100 transition-opacity grayscale hover:grayscale-0"
                />
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Logos affichés et centrés
- [ ] Effet grayscale par défaut, couleur au hover
- [ ] Responsive (wrap sur mobile, horizontal sur desktop)

---

### Task 2.3 : Section "Les 3 Agents"

**Objectif** : Présenter les 3 agents avec cartes cliquables vers leurs LP dédiées.

**Fichier** : `components/landing/AgentsGridHome.tsx`

**Implémentation** :
```typescript
import { getAllAgents } from '@/lib/data/agents';
import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';
import { AudioPlayer } from '@/components/shared/AudioPlayer';
import Link from 'next/link';

export function AgentsGridHome() {
  const agents = getAllAgents();

  // Stats par agent (depuis Home.txt)
  const stats = {
    louis: [
      { label: '< 60 secondes', description: 'Délai de rappel' },
      { label: '+72%', description: 'Taux de contact' },
      { label: 'x3', description: 'Rendez-vous qualifiés' },
    ],
    arthur: [
      { label: '+40k€', description: 'CA moyen généré/mois' },
      { label: '+65%', description: 'Taux de réactivation' },
      { label: '15 jours', description: 'Temps de retour sur investissement' },
    ],
    alexandra: [
      { label: '100%', description: 'Taux de réponse' },
      { label: '< 3 sonneries', description: 'Temps de décrochage' },
      { label: '+45%', description: 'Satisfaction client' },
    ],
  };

  return (
    <section className="py-24 bg-gradient-to-b from-black via-purple-950/10 to-black">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            <span className="bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
              Rencontrez votre nouvelle équipe commerciale
            </span>
          </h2>
          <p className="text-xl text-gray-400">
            Louis, Alexandra et Arthur travaillent 24/7 pour traiter vos leads.
            <br />
            Sans vacances. Sans turnover. Sans oubli.
          </p>
        </div>

        {/* Grid 3 agents */}
        <div className="grid md:grid-cols-3 gap-8 max-w-7xl mx-auto">
          {agents.map((agent) => (
            <Card
              key={agent.id}
              variant="gradient"
              className="p-8 hover:scale-105 transition-transform duration-300"
            >
              {/* Badge */}
              <div
                className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium mb-4 bg-gradient-to-r ${agent.color.gradient} bg-opacity-10 border border-current border-opacity-20`}
              >
                <span>{agent.icon}</span>
                <span>{agent.badge}</span>
              </div>

              {/* Titre */}
              <h3 className={`text-2xl font-bold mb-3 bg-gradient-to-r ${agent.color.gradient} bg-clip-text text-transparent`}>
                {agent.displayName}
              </h3>

              {/* Description */}
              <p className="text-gray-400 mb-6">
                {agent.description}
              </p>

              {/* Stats */}
              <div className="space-y-3 mb-6">
                {stats[agent.id as keyof typeof stats].map((stat, idx) => (
                  <div key={idx} className="flex items-center gap-3">
                    <span className="text-xl">✓</span>
                    <div>
                      <span className="font-semibold text-white">{stat.label}</span>
                      <span className="text-gray-400 text-sm ml-2">{stat.description}</span>
                    </div>
                  </div>
                ))}
              </div>

              {/* Audio Player */}
              <div className="mb-6">
                <AudioPlayer
                  audioSrc={`/audio/demo-${agent.id}.mp3`}
                  agentColor={agent.color.primary.includes('blue') ? 'blue' : agent.color.primary.includes('orange') ? 'orange' : 'green'}
                />
              </div>

              {/* CTA vers LP dédiée */}
              <Link href={`/${agent.id}`}>
                <Button variant="outline" className="w-full">
                  En savoir plus sur {agent.displayName}
                </Button>
              </Link>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] 3 cartes affichées avec bon spacing
- [ ] Cartes cliquables vers les LP dédiées
- [ ] Audio players fonctionnels
- [ ] Stats affichées correctement
- [ ] Responsive grid (1 col mobile, 3 cols desktop)

---

### Task 2.4 : Comment ça marche

**Objectif** : Expliquer le processus en 3 étapes simples.

**Fichier** : `components/landing/HowItWorksHome.tsx`

**Implémentation** :
```typescript
export function HowItWorksHome() {
  const steps = [
    {
      number: '01',
      title: 'Connectez vos outils',
      description: 'Intégrez VoIPIA à votre CRM et votre téléphonie en quelques clics',
      icon: '🔗',
    },
    {
      number: '02',
      title: 'Configurez vos agents',
      description: 'Personnalisez le comportement de chaque agent selon vos processus',
      icon: '⚙️',
    },
    {
      number: '03',
      title: 'Laissez-les travailler',
      description: 'Vos agents traitent tous vos prospects 24/7 pendant que vous vous concentrez sur les RDV',
      icon: '🚀',
    },
  ];

  return (
    <section className="py-24 bg-black">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Comment ça marche ?
          </h2>
          <p className="text-xl text-gray-400">
            Déployez vos agents IA en moins de 5 jours
          </p>
        </div>

        {/* Steps */}
        <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {steps.map((step) => (
            <div key={step.number} className="relative text-center">
              {/* Number badge */}
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-r from-violet-600 to-purple-600 text-2xl font-bold mb-6">
                {step.number}
              </div>

              {/* Icon */}
              <div className="text-5xl mb-4">{step.icon}</div>

              {/* Title */}
              <h3 className="text-2xl font-bold mb-3">{step.title}</h3>

              {/* Description */}
              <p className="text-gray-400">{step.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] 3 étapes affichées en grid
- [ ] Numbers badges avec gradient
- [ ] Responsive (1 col mobile, 3 cols desktop)

---

### Task 2.5 : Tarifs

**Objectif** : Afficher les 3 pricing tiers avec détails.

**Fichier** : `components/landing/PricingCardsHome.tsx`

**Implémentation** :
```typescript
import { pricingTiers } from '@/lib/data/pricing';
import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';

export function PricingCardsHome() {
  return (
    <section className="py-24 bg-gradient-to-b from-black via-violet-950/10 to-black">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Tarifs transparents
          </h2>
          <p className="text-xl text-gray-400">
            Choisissez l&apos;agent qui correspond à vos besoins
          </p>
        </div>

        {/* Pricing cards */}
        <div className="grid md:grid-cols-3 gap-8 max-w-7xl mx-auto">
          {pricingTiers.map((tier) => (
            <Card
              key={tier.agentType}
              variant="gradient"
              className={`p-8 relative ${tier.badge ? 'border-violet-500' : ''}`}
            >
              {/* Badge "Le plus populaire" */}
              {tier.badge && (
                <div className="absolute -top-4 left-1/2 -translate-x-1/2 px-4 py-1 bg-gradient-to-r from-violet-600 to-purple-600 rounded-full text-sm font-medium">
                  {tier.badge}
                </div>
              )}

              {/* Header */}
              <div className="text-center mb-6">
                <h3 className="text-2xl font-bold mb-2">{tier.name}</h3>
                <div className="flex items-baseline justify-center gap-2">
                  <span className="text-5xl font-bold">{tier.price}€</span>
                  <span className="text-gray-400">/{tier.period === 'month' ? 'mois' : 'an'}</span>
                </div>
              </div>

              {/* Included */}
              <ul className="space-y-3 mb-6">
                {tier.included.map((item, idx) => (
                  <li key={idx} className="flex items-start gap-2">
                    <span className="text-green-400 mt-1">✓</span>
                    <span className="text-gray-300 text-sm">{item}</span>
                  </li>
                ))}
              </ul>

              {/* Consumption */}
              <div className="border-t border-white/10 pt-4 mb-6">
                <p className="text-sm text-gray-400 mb-2">+ Consommation :</p>
                <ul className="text-sm text-gray-500 space-y-1">
                  <li>{tier.consumption.calls}€ / appel</li>
                  <li>{tier.consumption.sms}€ / SMS</li>
                </ul>
              </div>

              {/* CTA */}
              <Button variant="primary" className="w-full">
                {tier.cta.text}
              </Button>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] 3 cartes affichées
- [ ] Badge "Le plus populaire" sur Louis
- [ ] Prix et inclusions affichés
- [ ] CTAs fonctionnels
- [ ] Responsive grid

---

### Task 2.6 : Comparatif SDR vs VoIPIA

**Objectif** : Montrer les avantages de l'IA vs un SDR humain.

**Fichier** : `components/landing/SDRComparison.tsx`

**Implémentation** :
```typescript
import { Card } from '@/components/shared/Card';

export function SDRComparison() {
  const comparison = [
    {
      feature: 'Disponibilité',
      sdr: '8h/jour (40h/semaine)',
      voipia: '24/7 sans interruption',
      advantage: 'voipia',
    },
    {
      feature: 'Coût mensuel',
      sdr: '3 000€ - 5 000€',
      voipia: '190€ - 490€',
      advantage: 'voipia',
    },
    {
      feature: 'Délai de rappel',
      sdr: '2-24 heures',
      voipia: '< 60 secondes',
      advantage: 'voipia',
    },
    {
      feature: 'Congés / Turnover',
      sdr: 'Oui, impact sur continuité',
      voipia: 'Aucun',
      advantage: 'voipia',
    },
    {
      feature: 'Formation nécessaire',
      sdr: '2-3 mois',
      voipia: '5 jours',
      advantage: 'voipia',
    },
    {
      feature: 'Capacité simultanée',
      sdr: '1 appel à la fois',
      voipia: 'Illimité',
      advantage: 'voipia',
    },
  ];

  return (
    <section className="py-24 bg-black">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            SDR humain vs VoIPIA
          </h2>
          <p className="text-xl text-gray-400">
            Pourquoi l&apos;IA conversationnelle surpasse l&apos;humain pour le traitement de prospects
          </p>
        </div>

        {/* Table */}
        <Card variant="gradient" className="max-w-5xl mx-auto overflow-hidden">
          <div className="grid grid-cols-3 gap-4 p-6 border-b border-white/10 bg-white/5">
            <div className="font-bold">Critère</div>
            <div className="font-bold text-center">SDR humain</div>
            <div className="font-bold text-center">VoIPIA</div>
          </div>

          {comparison.map((row, idx) => (
            <div
              key={idx}
              className="grid grid-cols-3 gap-4 p-6 border-b border-white/10 hover:bg-white/5 transition-colors"
            >
              <div className="font-medium">{row.feature}</div>
              <div className="text-center text-gray-400">{row.sdr}</div>
              <div className="text-center text-green-400 font-semibold">
                {row.voipia}
              </div>
            </div>
          ))}
        </Card>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Tableau comparatif affiché
- [ ] Colonnes alignées correctement
- [ ] VoIPIA en vert pour marquer l'avantage
- [ ] Responsive (peut nécessiter scroll horizontal sur mobile)

---

### Task 2.7 : Développements sur-mesure

**Objectif** : Call-out pour les besoins spécifiques non couverts.

**Fichier** : `components/landing/CustomDevelopment.tsx`

**Implémentation** :
```typescript
import { Button } from '@/components/shared/Button';
import { Card } from '@/components/shared/Card';

export function CustomDevelopment() {
  return (
    <section className="py-24 bg-gradient-to-b from-black via-purple-950/20 to-black">
      <div className="container mx-auto px-4">
        <Card
          variant="gradient"
          className="max-w-4xl mx-auto p-12 text-center border-violet-500/30"
        >
          <div className="text-5xl mb-6">🛠️</div>

          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Besoin d&apos;un agent sur-mesure ?
          </h2>

          <p className="text-xl text-gray-400 mb-8">
            Vous avez un use case spécifique ? Une intégration particulière ?
            <br />
            Nous développons votre agent IA personnalisé en moins de 3 semaines.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" variant="primary">
              Discuter de mon projet
            </Button>
            <Button size="lg" variant="outline">
              Voir des exemples
            </Button>
          </div>

          <p className="text-sm text-gray-500 mt-6">
            Déjà réalisé : Agent de prise de commande, Agent SAV, Agent de qualification technique
          </p>
        </Card>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Card centrée avec bon spacing
- [ ] CTAs fonctionnels
- [ ] Responsive

---

### Task 2.8 : FAQ Accordéon

**Objectif** : Répondre aux 7 questions fréquentes.

**Fichier** : `components/landing/FAQAccordion.tsx`

**Implémentation** :
```typescript
'use client';

import { useState } from 'react';
import { homeFAQs } from '@/lib/data/faqs';
import { ChevronDown } from 'lucide-react';
import { cn } from '@/lib/utils';

export function FAQAccordion() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <section className="py-24 bg-black">
      <div className="container mx-auto px-4">
        {/* Header */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Questions fréquentes
          </h2>
          <p className="text-xl text-gray-400">
            Tout ce que vous devez savoir sur nos agents IA
          </p>
        </div>

        {/* FAQ Items */}
        <div className="max-w-3xl mx-auto space-y-4">
          {homeFAQs.map((faq, index) => (
            <div
              key={index}
              className="border border-white/10 rounded-xl overflow-hidden bg-white/5"
            >
              {/* Question */}
              <button
                onClick={() => setOpenIndex(openIndex === index ? null : index)}
                className="w-full px-6 py-5 flex items-center justify-between text-left hover:bg-white/5 transition-colors"
              >
                <span className="font-semibold text-lg pr-8">{faq.question}</span>
                <ChevronDown
                  className={cn(
                    'w-5 h-5 text-gray-400 transition-transform flex-shrink-0',
                    openIndex === index && 'rotate-180'
                  )}
                />
              </button>

              {/* Answer */}
              {openIndex === index && (
                <div className="px-6 pb-5 text-gray-400 border-t border-white/10 pt-4">
                  {faq.answer}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] 7 questions affichées
- [ ] Accordéon fonctionnel (open/close)
- [ ] Animation smooth sur chevron
- [ ] Un seul item ouvert à la fois

---

### Task 2.9 : CTA Final

**Objectif** : Dernier push avant le footer.

**Fichier** : `components/landing/CTAFinal.tsx`

**Implémentation** :
```typescript
import { Button } from '@/components/shared/Button';

export function CTAFinal() {
  return (
    <section className="py-24 bg-gradient-to-t from-purple-950/20 to-black">
      <div className="container mx-auto px-4">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Prêt à déléguer vos prospects à l&apos;IA ?
          </h2>

          <p className="text-xl text-gray-400 mb-10">
            Rejoignez les 500+ entreprises qui font confiance à VoIPIA
            <br />
            pour traiter 100% de leurs prospects 24/7
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-12">
            <Button size="lg" variant="primary">
              Tester gratuitement
            </Button>
            <Button size="lg" variant="outline">
              Réserver une démo
            </Button>
          </div>

          <div className="flex flex-wrap justify-center gap-8 text-sm text-gray-500">
            <span>✓ Déploiement en 5 jours</span>
            <span>✓ Sans engagement</span>
            <span>✓ Support dédié</span>
          </div>
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Section affichée avant footer
- [ ] CTAs fonctionnels
- [ ] Arguments clés visibles

---

### Task 2.10 : Assembler la page complète

**Objectif** : Importer tous les composants dans `/landingv2/page.tsx`.

**Fichier** : `app/(marketing)/landingv2/page.tsx`

**Implémentation** :
```typescript
import { HeroHome } from '@/components/landing/HeroHome';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { AgentsGridHome } from '@/components/landing/AgentsGridHome';
import { HowItWorksHome } from '@/components/landing/HowItWorksHome';
import { PricingCardsHome } from '@/components/landing/PricingCardsHome';
import { SDRComparison } from '@/components/landing/SDRComparison';
import { CustomDevelopment } from '@/components/landing/CustomDevelopment';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { CTAFinal } from '@/components/landing/CTAFinal';

export default function LandingV2Page() {
  return (
    <>
      <HeroHome />
      <IntegrationBar />
      <AgentsGridHome />
      <HowItWorksHome />
      <PricingCardsHome />
      <SDRComparison />
      <CustomDevelopment />
      <FAQAccordion />
      <CTAFinal />
    </>
  );
}
```

**Validation** :
- [ ] Tous les composants importés
- [ ] Ordre correct des sections
- [ ] Pas d'erreur TypeScript

---

## ✅ Validation Loops

### 1. Build Check

```bash
npm run build
```

**Critères** :
- [ ] Build réussi sans erreur
- [ ] Pas d'erreur TypeScript
- [ ] Warnings acceptables uniquement

---

### 2. Development Server

```bash
npm run dev
```

**Critères** :
- [ ] Serveur démarre sans erreur
- [ ] Page `/landingv2` accessible

---

### 3. Browser Visual Testing

**Utiliser MCP Playwright** :

```typescript
// Naviguer vers /landingv2
mcp__playwright__browser_navigate({ url: 'http://localhost:3000/landingv2' })

// Prendre snapshot
mcp__playwright__browser_snapshot()

// Vérifier chaque section :
// 1. Hero avec 3 agents
// 2. Barre logos tech
// 3. Grid 3 agents avec audio players
// 4. Comment ça marche (3 steps)
// 5. Pricing (3 cards)
// 6. Comparatif SDR vs VoIPIA
// 7. Custom dev call-out
// 8. FAQ accordéon
// 9. CTA final
```

**Critères** :
- [ ] Toutes les 9 sections visibles
- [ ] Spacing cohérent entre sections
- [ ] Pas d'erreur visuelle

---

### 4. Responsive Testing

**Tester aux breakpoints** :
- Mobile : 375px
- Tablet : 768px
- Desktop : 1440px

**Critères** :
- [ ] Grids s'adaptent (1 col mobile, 3 cols desktop)
- [ ] Textes lisibles sur mobile
- [ ] CTAs accessibles et cliquables

---

### 5. Interactive Elements

**Tester** :
- [ ] Tous les boutons cliquables
- [ ] Audio players fonctionnels
- [ ] FAQ accordéon ouvre/ferme
- [ ] Liens vers LP dédiées fonctionnels

---

### 6. TypeScript & Lint

```bash
npx tsc --noEmit
npm run lint
```

**Critères** :
- [ ] Aucune erreur TypeScript
- [ ] Aucune erreur ESLint
- [ ] Warnings minimes

---

## 🚫 Anti-patterns

### ❌ NE PAS FAIRE

1. **Modifier la home actuelle** :
   - ❌ Ne JAMAIS toucher à `app/(marketing)/page.tsx`
   - ❌ Ne JAMAIS modifier `components/sections/`
   - ✅ Créer de nouveaux composants dans `components/landing/`

2. **Créer des composants non réutilisables** :
   - ❌ Hardcoder les données dans les composants
   - ✅ Importer depuis `lib/data/`

3. **Oublier le responsive** :
   - ❌ Tester uniquement sur desktop
   - ✅ Tester sur 3 breakpoints (mobile, tablet, desktop)

4. **Ignorer les audio players** :
   - ❌ Mettre des chemins d'audio inexistants
   - ✅ Utiliser le composant AudioPlayer de Phase 1

5. **Dupliquer du code** :
   - ❌ Copier-coller le même code dans plusieurs composants
   - ✅ Utiliser Button, Card, AudioPlayer de `components/shared/`

---

## 📊 Success Criteria

### Critères Techniques

- [ ] Build Next.js réussi
- [ ] TypeScript compilation sans erreur
- [ ] ESLint sans erreur
- [ ] 9 composants créés dans `components/landing/`
- [ ] Page `/landingv2` complète et fonctionnelle

### Critères Fonctionnels

- [ ] Toutes les 9 sections présentes
- [ ] Cartes agents cliquables vers LP dédiées
- [ ] Audio players fonctionnels
- [ ] FAQ accordéon interactif
- [ ] CTAs présents sur chaque section

### Critères Visuels

- [ ] Design cohérent avec glassmorphism
- [ ] Gradients violets/pourpres
- [ ] Spacing consistant (py-24 entre sections)
- [ ] Responsive sur tous breakpoints
- [ ] Animations smooth

### Critères de Performance

- [ ] Pas d'erreur console
- [ ] Images optimisées avec Next/Image
- [ ] Lazy loading si nécessaire

---

## 🎯 Prochaine Étape

Après validation de la Phase 2 :
- **Phase 3** : Landing Page Louis sur `/louis`
- Utiliser les mêmes composants et patterns
- Contenu détaillé dans `LP Louis.txt`

---

**Créé le** : 2025-10-28
**Auteur** : Claude Code
**Version** : 1.0
**Statut** : ✅ Prêt pour exécution
