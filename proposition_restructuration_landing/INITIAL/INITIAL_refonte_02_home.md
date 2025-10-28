# PHASE 2 : PAGE HOME (RESTRUCTURÉE)

## 🎯 Objectif de la Phase

Créer la nouvelle page d'accueil qui servira de "router principal" vers les 3 landing pages dédiées.

**⚠️ IMPORTANT** : La nouvelle Home sera développée sur **`/landingv2`** pour ne pas impacter la home actuelle (`/`) jusqu'à validation complète.

**Durée estimée** : 3-4 jours
**Priorité** : 🔴 HAUTE (point d'entrée principal)

---

## 📋 Contexte

La nouvelle Home doit :
- Présenter les 3 agents de manière équitable
- Guider les visiteurs vers la LP appropriée
- Convertir les visiteurs indécis avec un message global
- Inclure un comparatif SDR vs VoIPIA
- Proposer des développements sur-mesure

**Source** : `proposition_restructuration_landing/Home.txt`

---

## 🎯 Structure de la Page

```
Home (/landingv2)
├── 1. Hero
├── 2. Barre "Propulsé par" (logos tech)
├── 3. Les 3 Agents (cartes cliquables)
├── 4. Comment ça marche (3 étapes)
├── 5. Tarifs (3 cartes)
├── 6. Comparatif SDR vs VoIPIA
├── 7. Développements sur-mesure
├── 8. FAQ (7 questions)
└── 9. CTA Final
```

**Route Next.js** : `app/(marketing)/landingv2/page.tsx`

---

## 📦 Micro-tâches Détaillées

### Tâche 2.1 : Hero Section

**Objectif** : Présenter la value proposition principale

**Contenu** :
- **Titre** : "Déléguez le traitement de vos prospects à nos agents IA"
- **Sous-titre** :
  - Louis rappelle chaque nouveau lead
  - Alexandra répond à chaque appel
  - Arthur relance chaque prospect dormant
  - → Résultat : votre agenda se remplit de RDV qualifiés
- **CTA Principal** : "Tester nos agents gratuitement"
- **CTA Secondaire** : "Écouter un exemple d'appel"

**Composant** : `components/landing/HeroHome.tsx`

```typescript
export function HeroHome() {
  return (
    <section className="relative min-h-[90vh] flex items-center justify-center">
      <div className="container mx-auto px-4">
        <div className="max-w-4xl mx-auto text-center">
          {/* Badge animé */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-violet-500/10 to-purple-500/10 border border-violet-500/20 mb-8">
            <span className="text-sm font-medium">🤖 Agents IA Voix</span>
          </div>

          {/* Titre principal */}
          <h1 className="text-5xl md:text-7xl font-bold mb-6 bg-gradient-to-r from-white via-violet-200 to-purple-200 bg-clip-text text-transparent">
            Déléguez le traitement de vos prospects à nos agents IA
          </h1>

          {/* Sous-titre avec 3 agents */}
          <div className="space-y-2 mb-8 text-lg md:text-xl text-gray-300">
            <p className="flex items-center justify-center gap-2">
              <span className="text-blue-400">📞 Louis</span> rappelle chaque nouveau lead
            </p>
            <p className="flex items-center justify-center gap-2">
              <span className="text-green-400">☎️ Alexandra</span> répond à chaque appel
            </p>
            <p className="flex items-center justify-center gap-2">
              <span className="text-orange-400">🔄 Arthur</span> relance chaque prospect dormant
            </p>
          </div>

          {/* Résultat */}
          <p className="text-xl text-gray-400 mb-10">
            → Résultat : votre agenda se remplit de RDV qualifiés, tous vos prospects sont traités
          </p>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" variant="primary">
              Tester nos agents gratuitement
            </Button>
            <Button size="lg" variant="outline">
              🎧 Écouter un exemple d'appel
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Composant créé et stylisé
- [ ] Responsive (mobile, tablet, desktop)
- [ ] CTAs fonctionnels
- [ ] Gradient animé sur le titre

---

### Tâche 2.2 : Barre "Propulsé par"

**Objectif** : Montrer la crédibilité avec les logos tech

**Contenu** :
- Texte : "Propulsé par les meilleures technologies IA"
- Logos : Eleven Labs, Cartesia, Mistral AI, Claude, OpenAI, n8n, Make, Twilio

**Composant** : `components/landing/IntegrationBar.tsx`

```typescript
import { integrations } from '@/lib/data/integrations';
import Image from 'next/image';

export function IntegrationBar() {
  // Filtrer seulement les logos AI
  const aiLogos = integrations.filter(i => i.category === 'ai');

  return (
    <section className="py-16 border-y border-white/10">
      <div className="container mx-auto px-4">
        <p className="text-center text-gray-400 mb-8">
          Propulsé par les meilleures technologies IA
        </p>

        {/* Défilement horizontal avec animation */}
        <div className="relative overflow-hidden">
          <div className="flex gap-12 animate-scroll">
            {aiLogos.map((logo) => (
              <div key={logo.name} className="flex-shrink-0">
                <Image
                  src={logo.logo}
                  alt={logo.name}
                  width={120}
                  height={40}
                  className="opacity-60 hover:opacity-100 transition-opacity grayscale hover:grayscale-0"
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

**Animation CSS** (dans `globals.css`) :
```css
@keyframes scroll {
  0% { transform: translateX(0); }
  100% { transform: translateX(-50%); }
}

.animate-scroll {
  animation: scroll 30s linear infinite;
}
```

**Validation** :
- [ ] Logos affichés en défilement
- [ ] Animation fluide
- [ ] Logos en grayscale par défaut, couleur au hover

---

### Tâche 2.3 : Section "Les 3 Agents"

**Objectif** : Présenter les 3 agents avec cartes cliquables

**Contenu** :
- Titre : "Rencontrez votre nouvelle équipe commerciale"
- Sous-titre : "Louis, Alexandra et Arthur travaillent 24/7 pour traiter vos leads. Sans vacances. Sans turnover. Sans oubli."
- 3 cartes agents (Louis, Arthur, Alexandra)

**Composant** : `components/landing/AgentsGrid.tsx`

```typescript
import { getAllAgents } from '@/lib/data/agents';
import { Card } from '@/components/shared/Card';
import Link from 'next/link';

export function AgentsGrid() {
  const agents = getAllAgents();

  return (
    <section className="py-20">
      <div className="container mx-auto px-4">
        {/* En-tête */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            Rencontrez votre nouvelle équipe commerciale
          </h2>
          <p className="text-xl text-gray-400">
            Louis, Alexandra et Arthur travaillent 24/7 pour traiter vos leads.
            <br />
            Sans vacances. Sans turnover. Sans oubli.
          </p>
        </div>

        {/* Grille des agents */}
        <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {agents.map((agent) => (
            <Link href={`/${agent.id}`} key={agent.id}>
              <Card variant="hover" className="p-8 h-full">
                {/* Badge */}
                <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium mb-4 bg-gradient-to-r ${agent.color.gradient} bg-opacity-10`}>
                  <span>{agent.icon}</span>
                  <span>{agent.badge}</span>
                </div>

                {/* Titre */}
                <h3 className="text-2xl font-bold mb-4">
                  {agent.displayName}
                </h3>

                {/* Description */}
                <p className="text-gray-400 mb-6">
                  {agent.description}
                </p>

                {/* Statistiques mockées pour Home */}
                <div className="space-y-2 mb-6">
                  {agent.id === 'louis' && (
                    <>
                      <p className="text-sm">⚡ &lt; 60 secondes de délai</p>
                      <p className="text-sm">📈 +72% taux de contact</p>
                      <p className="text-sm">📅 x3 rendez-vous qualifiés</p>
                    </>
                  )}
                  {agent.id === 'arthur' && (
                    <>
                      <p className="text-sm">🔄 +65% taux de réactivation</p>
                      <p className="text-sm">💰 +40 000€ CA/mois en moyenne</p>
                      <p className="text-sm">⏰ +40h gagnées/semaine</p>
                    </>
                  )}
                  {agent.id === 'alexandra' && (
                    <>
                      <p className="text-sm">✅ 100% taux de réponse</p>
                      <p className="text-sm">⚡ &lt; 3 sonneries</p>
                      <p className="text-sm">😊 +45% satisfaction client</p>
                    </>
                  )}
                </div>

                {/* CTA */}
                <div className="flex flex-col gap-2">
                  <button className="text-sm font-medium hover:underline">
                    🎧 Écouter {agent.displayName} en action
                  </button>
                  <button className="text-sm text-gray-400 hover:text-white transition">
                    En savoir plus sur {agent.displayName} →
                  </button>
                </div>
              </Card>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] 3 cartes affichées en grille
- [ ] Cartes cliquables (navigation vers LP)
- [ ] Hover effect sur les cartes
- [ ] Responsive (1 col mobile, 3 cols desktop)

---

### Tâche 2.4 : Section "Comment ça marche"

**Objectif** : Expliquer le processus en 3 étapes

**Contenu** :
1. Connexion instantanée
2. Qualification automatique
3. Agenda rempli

**Composant** : `components/landing/HowItWorks.tsx`

```typescript
export function HowItWorks() {
  const steps = [
    {
      icon: '🔗',
      title: 'Connexion instantanée',
      description: 'Connectez VoIPIA à votre CRM, votre agenda et vos sources de leads en quelques clics. Aucun développement nécessaire.',
    },
    {
      icon: '🎯',
      title: 'Qualification automatique',
      description: 'Nos agents traitent chaque prospect selon vos critères : budget, besoin, urgence. Seuls les leads qualifiés arrivent à votre équipe.',
    },
    {
      icon: '📅',
      title: 'Agenda rempli',
      description: 'Les RDV sont planifiés directement dans votre agenda. SMS et emails de confirmation automatiques. Vous arrivez préparé.',
    },
  ];

  return (
    <section className="py-20 bg-gradient-to-b from-black to-violet-950/20">
      <div className="container mx-auto px-4">
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            Découvrez comment nos agents s'occupent de vos opportunités
          </h2>
          <p className="text-xl text-gray-400">
            De la génération de leads à la prise de rendez-vous, VoIPIA s'intègre parfaitement dans votre workflow.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          {steps.map((step, index) => (
            <div key={index} className="text-center">
              <div className="text-6xl mb-4">{step.icon}</div>
              <h3 className="text-2xl font-bold mb-3">{step.title}</h3>
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
- [ ] 3 étapes affichées
- [ ] Icônes visibles
- [ ] Layout responsive

---

### Tâche 2.5 : Section Tarifs (cartes)

**Objectif** : Présenter les 3 formules tarifaires

**Source** : `lib/data/pricing.ts`

**Composant** : `components/landing/PricingCards.tsx`

```typescript
import { pricingTiers } from '@/lib/data/pricing';
import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';

export function PricingCards() {
  return (
    <section className="py-20">
      <div className="container mx-auto px-4">
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            Tarification simple. Sans engagement.
          </h2>
          <p className="text-xl text-gray-400">
            Payez uniquement ce que vous consommez. Aucun coût caché, aucun engagement de durée.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {pricingTiers.map((tier) => (
            <Card key={tier.agentType} variant="gradient" className="p-8 relative">
              {/* Badge "Le plus populaire" pour Louis */}
              {tier.badge && (
                <div className="absolute -top-4 left-1/2 -translate-x-1/2 px-4 py-1 bg-gradient-to-r from-violet-600 to-purple-600 rounded-full text-sm font-medium">
                  {tier.badge}
                </div>
              )}

              {/* Nom */}
              <h3 className="text-2xl font-bold mb-4">{tier.name}</h3>

              {/* Prix */}
              <div className="mb-6">
                <span className="text-5xl font-bold">{tier.price} €</span>
                <span className="text-gray-400"> HT/mois</span>
              </div>

              {/* Inclus */}
              <div className="space-y-3 mb-6">
                <p className="font-semibold text-sm text-gray-300">Inclus dans l'abonnement :</p>
                {tier.included.map((item, index) => (
                  <p key={index} className="text-sm text-gray-400 flex items-start gap-2">
                    <span className="text-green-400">✓</span>
                    <span>{item}</span>
                  </p>
                ))}
              </div>

              {/* Consommation */}
              <div className="border-t border-white/10 pt-6 mb-6">
                <p className="font-semibold text-sm text-gray-300 mb-2">+ Consommation au réel</p>
                <p className="text-sm text-gray-400">📞 Appels : {tier.consumption.calls} €/minute</p>
                <p className="text-sm text-gray-400">📱 SMS : {tier.consumption.sms} €/message</p>
                <p className="text-sm text-gray-400">📧 Emails : gratuits</p>
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
- [ ] Prix et inclusions visibles
- [ ] CTAs fonctionnels

---

### Tâche 2.6 : Comparatif SDR vs VoIPIA

**Objectif** : Montrer le ROI avec un tableau comparatif

**Composant** : `components/landing/SDRComparison.tsx`

```typescript
export function SDRComparison() {
  const comparisons = [
    { label: 'Coût mensuel', sdr: '3 000 €', voipia: '500 €' },
    { label: 'Heures travaillées', sdr: '35h/semaine', voipia: '168h/semaine' },
    { label: 'Disponibilité', sdr: 'Jours ouvrables', voipia: '24/7 365j' },
    { label: 'Vacances', sdr: '5 semaines/an', voipia: 'Jamais' },
    { label: 'Turnover', sdr: 'Élevé (20-30%/an)', voipia: 'Zéro' },
    { label: 'Formation', sdr: '2-3 mois', voipia: 'Immédiate' },
    { label: 'Déploiement', sdr: '3-6 mois', voipia: '5 jours' },
  ];

  return (
    <section className="py-20 bg-gradient-to-b from-violet-950/20 to-black">
      <div className="container mx-auto px-4">
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            Un SDR humain vs VoIPIA
          </h2>
        </div>

        {/* Tableau comparatif */}
        <div className="max-w-4xl mx-auto">
          <Card variant="gradient" className="overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/10">
                  <th className="text-left p-4 font-semibold">Critère</th>
                  <th className="text-left p-4 font-semibold">SDR HUMAIN</th>
                  <th className="text-left p-4 font-semibold text-violet-400">VOIPIA</th>
                </tr>
              </thead>
              <tbody>
                {comparisons.map((row, index) => (
                  <tr key={index} className="border-b border-white/5">
                    <td className="p-4 text-gray-300">{row.label}</td>
                    <td className="p-4 text-gray-400">{row.sdr}</td>
                    <td className="p-4 font-semibold text-violet-400">{row.voipia}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>

          {/* ROI Box */}
          <Card variant="gradient" className="p-8 mt-8 text-center bg-gradient-to-r from-violet-600/20 to-purple-600/20">
            <h3 className="text-2xl font-bold mb-4">💰 ÉCONOMIE ANNUELLE AVEC VOIPIA</h3>
            <div className="space-y-2 text-lg">
              <p className="text-gray-300">SDR humain : <span className="font-bold">36 000 €/an</span></p>
              <p className="text-gray-300">VoIPIA (3 agents) : <span className="font-bold">6 000 €/an</span></p>
              <p className="text-3xl font-bold text-green-400 mt-4">= 30 000 € économisés par an</p>
              <p className="text-gray-400 mt-2">Soit 5 à 6 fois moins cher avec une disponibilité 24/7</p>
            </div>
            <Button variant="primary" size="lg" className="mt-6">
              Je veux tester mon futur agent
            </Button>
          </Card>
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Tableau comparatif affiché
- [ ] ROI Box mise en valeur
- [ ] Responsive sur mobile
- [ ] Couleurs violet pour VoIPIA

---

### Tâche 2.7 : Section Développements sur-mesure

**Objectif** : Proposer des agents custom

**Composant** : `components/landing/CustomDevelopment.tsx`

```typescript
export function CustomDevelopment() {
  const examples = [
    {
      icon: '🏥',
      title: 'Secteur médical',
      description: 'Agent de prise de RDV pour cabinets médicaux avec gestion des urgences, rappels automatiques et intégration dossiers patients.',
    },
    {
      icon: '🏗️',
      title: 'BTP & artisans',
      description: 'Agent de gestion de chantiers avec prise de RDV pour devis, relance automatique des prospects et coordination avec planning chantiers.',
    },
    {
      icon: '🛍️',
      title: 'E-commerce',
      description: 'Agent de support client 24/7 avec gestion des retours, suivi de commandes et upsell intelligent selon l\'historique d\'achat.',
    },
  ];

  return (
    <section className="py-20">
      <div className="container mx-auto px-4">
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            Votre besoin est unique ?<br />
            On construit l'agent qu'il vous faut.
          </h2>
          <p className="text-xl text-gray-400">
            Louis, Alexandra et Arthur couvrent 90% des besoins commerciaux.
            Mais votre entreprise a peut-être un processus spécifique, un secteur particulier, ou un workflow unique.
            Nous développons des agents vocaux sur-mesure pour répondre exactement à votre besoin.
          </p>
        </div>

        {/* Exemples */}
        <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto mb-12">
          {examples.map((example, index) => (
            <Card key={index} variant="hover" className="p-6">
              <div className="text-5xl mb-4">{example.icon}</div>
              <h3 className="text-xl font-bold mb-3">{example.title}</h3>
              <p className="text-gray-400">{example.description}</p>
            </Card>
          ))}
        </div>

        {/* CTA */}
        <div className="text-center">
          <p className="text-xl text-gray-300 mb-4">Vous avez un besoin spécifique ?</p>
          <Button variant="primary" size="lg">
            Discuter de mon projet
          </Button>
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] 3 exemples affichés
- [ ] CTA visible
- [ ] Cartes hover effect

---

### Tâche 2.8 : FAQ (7 questions)

**Fichier** : `lib/data/faqs.ts` (ajout des FAQs Home)

```typescript
export const homeFAQs: FAQItem[] = [
  {
    question: 'Les prospects vont-ils sentir que c\'est un robot ?',
    answer: 'Non. Nos agents utilisent des voix naturelles de dernière génération (Eleven Labs, Cartesia), ultra-rapides et sans délai audible. La conversation est fluide et la plupart des prospects ne remarquent pas la différence. Et même s\'ils le remarquent, ils apprécient d\'être rappelés en 30 secondes plutôt que de ne jamais l\'être.',
  },
  {
    question: 'Et si un lead pose une question complexe ?',
    answer: 'Nos agents sont configurés pour identifier les questions complexes ou hors périmètre. Dans ce cas, ils transfèrent automatiquement l\'appel vers votre équipe ou proposent un rappel avec un conseiller humain. Vous gardez toujours le contrôle sur les situations critiques.',
  },
  // ... autres FAQs
];
```

**Composant** : `components/landing/FAQAccordion.tsx`

```typescript
'use client';

import { useState } from 'react';
import { FAQItem } from '@/lib/types/landing';

interface FAQAccordionProps {
  faqs: FAQItem[];
}

export function FAQAccordion({ faqs }: FAQAccordionProps) {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <section className="py-20">
      <div className="container mx-auto px-4">
        <div className="max-w-3xl mx-auto">
          <h2 className="text-4xl md:text-5xl font-bold mb-12 text-center">
            Questions fréquentes
          </h2>

          <div className="space-y-4">
            {faqs.map((faq, index) => (
              <div key={index} className="border border-white/10 rounded-lg overflow-hidden">
                <button
                  onClick={() => setOpenIndex(openIndex === index ? null : index)}
                  className="w-full p-6 text-left flex items-center justify-between hover:bg-white/5 transition"
                >
                  <span className="font-semibold text-lg">{faq.question}</span>
                  <span className="text-2xl">{openIndex === index ? '−' : '+'}</span>
                </button>
                {openIndex === index && (
                  <div className="p-6 pt-0 text-gray-400">
                    {faq.answer}
                  </div>
                )}
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
- [ ] 7 questions affichées
- [ ] Accordion fonctionnel (open/close)
- [ ] Animation smooth

---

### Tâche 2.9 : CTA Final

**Composant** : `components/landing/CTAFinal.tsx`

```typescript
export function CTAFinal() {
  return (
    <section className="py-20 bg-gradient-to-b from-black to-violet-950/30">
      <div className="container mx-auto px-4">
        <div className="max-w-3xl mx-auto text-center">
          <h2 className="text-4xl md:text-5xl font-bold mb-4">
            Prêt à déléguer vos prospects à l'IA ?
          </h2>
          <p className="text-xl text-gray-400 mb-8">
            Louis, Alexandra et Arthur sont prêts à travailler pour vous dès aujourd'hui.
            <br />
            Aucun engagement. Déploiement en 5 jours.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" variant="primary">
              🚀 Tester nos agents gratuitement
            </Button>
            <Button size="lg" variant="outline">
              🔧 Besoin d'un agent spécifique ?
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] CTA visible et attractif
- [ ] 2 boutons fonctionnels
- [ ] Gradient background

---

### Tâche 2.10 : Assembler la page Home

**Fichier** : `app/(marketing)/landingv2/page.tsx`

```typescript
import { HeroHome } from '@/components/landing/HeroHome';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { AgentsGrid } from '@/components/landing/AgentsGrid';
import { HowItWorks } from '@/components/landing/HowItWorks';
import { PricingCards } from '@/components/landing/PricingCards';
import { SDRComparison } from '@/components/landing/SDRComparison';
import { CustomDevelopment } from '@/components/landing/CustomDevelopment';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { CTAFinal } from '@/components/landing/CTAFinal';
import { homeFAQs } from '@/lib/data/faqs';

export default function HomePage() {
  return (
    <>
      <HeroHome />
      <IntegrationBar />
      <AgentsGrid />
      <HowItWorks />
      <PricingCards />
      <SDRComparison />
      <CustomDevelopment />
      <FAQAccordion faqs={homeFAQs} />
      <CTAFinal />
    </>
  );
}
```

**Validation** :
- [ ] Toutes les sections affichées dans l'ordre
- [ ] Scrolling fluide
- [ ] Pas d'espace vide ou de chevauchement

---

## ✅ Validation de la Phase

### Tests Visuels (MCP Playwright)
```bash
npm run dev
```
- [ ] Navigate to `http://localhost:3000/landingv2`
- [ ] Take browser snapshot
- [ ] Vérifier : toutes les sections présentes
- [ ] Vérifier : responsive sur mobile (resize browser)
- [ ] Vérifier : CTAs cliquables

### Tests de Performance
```bash
npm run build
npm run start
```
- [ ] Lighthouse score > 85
- [ ] Time to Interactive < 3s
- [ ] Pas d'erreur console

### Tests de Navigation
- [ ] Clic sur carte Louis → navigue vers `/louis`
- [ ] Clic sur carte Arthur → navigue vers `/arthur`
- [ ] Clic sur carte Alexandra → navigue vers `/alexandra`
- [ ] CTAs "Tester gratuitement" → action définie

---

## 📊 Critères de Succès

1. ✅ Toutes les 9 sections présentes et fonctionnelles
2. ✅ Design cohérent avec la charte Voipia
3. ✅ Navigation vers les 3 LP dédiées
4. ✅ Responsive parfait (mobile, tablet, desktop)
5. ✅ Pas d'erreur TypeScript ou console
6. ✅ Build Next.js réussi

---

## 🔗 Dépendances

**Avant cette phase** :
- Phase 1 : Fondations (structure, types, composants de base)

**Après cette phase** :
- Phase 3 : Louis (LP dédiée)
- Phase 4 : Arthur (LP dédiée)
- Phase 5 : Alexandra (LP dédiée)
- Phase 6 : Navigation (liens croisés)

---

**Dernière mise à jour** : 2025-10-28
**Auteur** : Claude Code
**Statut** : 📋 Prêt pour génération PRP
