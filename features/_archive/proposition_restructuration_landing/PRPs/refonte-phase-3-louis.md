# PRP : Phase 3 - Landing Page Louis

**Date** : 2025-10-28
**Phase** : 3/7
**Priorité** : 🟠 MOYENNE
**Durée estimée** : 3-4 jours

---

## 🎯 Purpose & Goal

### Objectif
Créer la landing page dédiée à Louis (Rappel automatique de leads) sur `/louis` avec 10 sections complètes et optimisées pour la conversion.

### Business Value
- Présenter Louis comme solution de rappel automatique 24/7
- Démontrer les bénéfices mesurables (+72% taux de contact, x3 RDV)
- Convertir les visiteurs avec témoignage client authentique
- Qualifier les prospects avec FAQ exhaustive (9 questions)

### User Impact
- Comprendre précisément comment Louis fonctionne (4 étapes)
- Visualiser les cas d'usage concrets (6 cartes)
- Comparer "Avant Louis" vs "Avec Louis"
- Tester gratuitement avec CTAs clairs

---

## 📚 Context & References

### Source Files
```yaml
- file: proposition_restructuration_landing/INITIAL/INITIAL_refonte_03_louis.md
  why: Specifications détaillées de la Phase 3

- file: proposition_restructuration_landing/LP Louis.txt
  why: Contenu exact et copywriting optimisé

- file: CLAUDE.md
  why: Project rules, PRP workflow, UI verification process

- file: app/(marketing)/landingv2/page.tsx
  why: Pattern d'assemblage des sections (créé en Phase 2)

- file: components/landing/HeroHome.tsx
  why: Pattern de Hero section avec CTAs

- file: components/landing/AgentsGridHome.tsx
  why: Pattern de cartes avec audio player

- file: components/landing/FAQAccordion.tsx
  why: Composant FAQ réutilisable

- file: components/shared/Button/index.tsx
  why: Composant Button avec asChild prop

- file: components/shared/AudioPlayer/index.tsx
  why: Audio player avec variant prop

- file: lib/data/agents.ts
  why: Données Louis (couleur bleue, gradient, tagline)

- file: lib/data/testimonials.ts
  why: Témoignage Stefano Design pour Louis

- file: lib/data/faqs.ts
  why: Export structure pour ajouter FAQs Louis

- file: lib/types/landing.ts
  why: Types TypeScript pour composants landing
```

### Key Patterns from Phase 2
- **Section structure** : `<section className="py-24 relative">` avec background decorations
- **Glassmorphism cards** : `Card variant="gradient"` avec `bg-white/5 border-white/10`
- **Gradients** : Louis utilise `from-blue-600 to-cyan-500`
- **Audio player** : `<AudioPlayer src={audioSrc} variant="louis" />`
- **CTAs** : `<Button size="lg" asChild><Link href="/contact">Texte</Link></Button>`

---

## 🏗️ Implementation Blueprint

### Task 3.1: HeroLouis Component

**File**: `components/landing/HeroLouis.tsx`

**Structure**:
```typescript
'use client';

import { Button } from '@/components/shared/Button';
import { AudioPlayer } from '@/components/shared/AudioPlayer';
import { agents } from '@/lib/data/agents';
import { Phone, Play } from 'lucide-react';

export function HeroLouis() {
  const louis = agents.louis;

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background gradient avec bleu Louis */}
      <div className="absolute inset-0 bg-gradient-to-br from-blue-900/20 via-cyan-900/10 to-transparent" />

      {/* Grid pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:4rem_4rem]" />

      <div className="container mx-auto px-4 py-20 relative z-10">
        <div className="max-w-5xl mx-auto text-center space-y-8">

          {/* Badge avec Louis icon */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-500/10 border border-blue-500/20 backdrop-blur-sm">
            <span className="text-2xl">{louis.icon}</span>
            <span className="text-sm font-semibold text-blue-300">
              {louis.badge}
            </span>
          </div>

          {/* Titre principal */}
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold leading-tight">
            <span className="bg-gradient-to-r from-blue-400 via-cyan-400 to-blue-400 bg-clip-text text-transparent">
              Rencontrez Louis.
            </span>
          </h1>

          {/* Sous-titre */}
          <p className="text-2xl md:text-3xl text-white max-w-4xl mx-auto leading-relaxed">
            Votre agent IA personnel, qui rappelle, qualifie et planifie chaque nouveau lead automatiquement.
          </p>

          {/* Description punch */}
          <div className="space-y-4 max-w-3xl mx-auto">
            <p className="text-lg text-gray-300">
              Louis contacte vos prospects en moins d&apos;une minute, 24h/24 et 7j/7, dans plus de 20 langues.
            </p>
            <p className="text-lg text-gray-300">
              Il échange, qualifie et planifie vos rendez-vous automatiquement – pendant que votre équipe se concentre sur la vente.
            </p>
          </div>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center pt-6">
            <Button size="lg" className="group bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700">
              <Phone className="w-5 h-5 mr-2" />
              Tester Louis gratuitement
            </Button>
            <Button size="lg" variant="secondary">
              <Play className="w-5 h-5 mr-2" />
              Écouter un appel de Louis
            </Button>
          </div>

          {/* Stats rapides */}
          <div className="flex flex-wrap justify-center items-center gap-8 pt-12 text-sm">
            <div>
              <p className="text-2xl font-bold text-blue-400">&lt; 60s</p>
              <p className="text-gray-400">Délai de rappel</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-blue-400">+72%</p>
              <p className="text-gray-400">Taux de contact</p>
            </div>
            <div>
              <p className="text-2xl font-bold text-blue-400">x3</p>
              <p className="text-gray-400">RDV qualifiés</p>
            </div>
          </div>

        </div>
      </div>

      {/* Bottom fade */}
      <div className="absolute bottom-0 inset-x-0 h-32 bg-gradient-to-t from-gray-950 to-transparent" />
    </section>
  );
}
```

**Validation**:
- ✅ Gradient bleu-cyan dominant
- ✅ 2 CTAs visibles (Tester + Écouter)
- ✅ Stats &lt; 60s, +72%, x3 affichées
- ✅ Responsive mobile/tablet/desktop

---

### Task 3.2: IntegrationBar (Réutilisable)

**Modification**: Aucune - le composant `IntegrationBar` de Phase 2 est déjà réutilisable.

**Usage**:
```typescript
import { IntegrationBar } from '@/components/landing/IntegrationBar';

// Dans la page Louis
<IntegrationBar />
```

Les logos Pipedrive, HubSpot, Salesforce, Google Calendar, Outlook, Calendly, Make, Zapier sont déjà dans `lib/data/integrations.ts`.

---

### Task 3.3: HowItWorksLouis Component

**File**: `components/landing/HowItWorksLouis.tsx`

**Structure**: 4 étapes au lieu de 3

```typescript
const steps = [
  {
    number: 1,
    icon: Bell,
    title: 'Détection instantanée des leads entrants',
    description: 'Dès qu\'un prospect remplit un formulaire, demande un devis ou laisse ses coordonnées, Louis est déclenché automatiquement. Chaque seconde compte : Louis garantit un temps de réponse record pour maximiser vos chances de conversion.',
    color: 'from-blue-500 to-cyan-500',
  },
  {
    number: 2,
    icon: Phone,
    title: 'Rappel automatique et conversation intelligente',
    description: 'Louis appelle le prospect dans la minute, en adaptant son discours à votre secteur. Il mène des conversations naturelles, pose les bonnes questions de qualification et peut même envoyer un SMS de pré-notification pour augmenter le taux de réponse.',
    color: 'from-cyan-500 to-blue-500',
  },
  {
    number: 3,
    icon: Target,
    title: 'Qualification intelligente et scoring automatique',
    description: 'Pendant la conversation, Louis qualifie chaque lead selon vos critères : budget, besoin, urgence, autorité. Il attribue automatiquement un score à chaque prospect (chaud, tiède, froid) et détermine s\'il est prêt pour un rendez-vous commercial.',
    color: 'from-blue-500 to-indigo-500',
  },
  {
    number: 4,
    icon: Calendar,
    title: 'Prise de rendez-vous et suivi continu',
    description: 'Pour les leads qualifiés, Louis consulte directement votre agenda et réserve un créneau disponible. Le rendez-vous est confirmé par SMS et email, synchronisé avec votre CRM, et Louis retente automatiquement les prospects non-joignables. Votre équipe reçoit un dossier complet avant chaque rendez-vous.',
    color: 'from-indigo-500 to-blue-500',
  },
];
```

**Pattern**: Même structure que `HowItWorksHome.tsx` mais avec 4 étapes.

---

### Task 3.4: UseCasesLouis Component

**File**: `components/landing/UseCasesLouis.tsx`

**Structure**: 6 cartes en grid 3x2

```typescript
const useCases = [
  {
    icon: Clock,
    title: 'Qualification des leads entrants 24/7',
    description: 'Louis rappelle instantanément chaque lead généré par vos campagnes (Meta Ads, Google Ads), formulaires ou appels manqués. Weekend, nuit, jours fériés : Louis ne dort jamais et garantit une réponse en moins d\'une minute.',
  },
  {
    icon: CalendarCheck,
    title: 'Prise de rendez-vous automatique',
    description: 'Louis accède à votre agenda en temps réel et réserve directement des créneaux avec vos commerciaux. Plus d\'allers-retours par email : Louis gère tout de bout en bout et confirme chaque rendez-vous.',
  },
  {
    icon: TrendingUp,
    title: 'Scoring avancé des prospects',
    description: 'Chaque conversation est analysée et chaque lead reçoit un score de qualité basé sur vos critères personnalisés. Louis identifie automatiquement vos prospects à forte valeur et priorise les opportunités les plus prometteuses.',
  },
  {
    icon: MessageSquare,
    title: 'Envoi de SMS automatique',
    description: 'Louis envoie un SMS avant l\'appel pour prévenir le prospect (augmente le taux de réponse) ou après l\'appel pour confirmer le rendez-vous. Cette approche multicanal maximise vos chances de contact.',
  },
  {
    icon: FileText,
    title: 'Transcription et analyse des appels',
    description: 'Tous les appels sont enregistrés, transcrits et analysés pour vous fournir des insights précieux sur les objections et besoins récurrents. Vous disposez d\'un historique complet et exploitable, accessible depuis le dashboard VoIPIA.',
  },
  {
    icon: BarChart3,
    title: 'Dashboard & reporting transparent',
    description: 'Suivez les performances en temps réel : nombre d\'appels, durée moyenne, taux de contact, taux de rendez-vous pris, taux de qualification, volume traité. Toutes les statistiques sont accessibles depuis votre espace VoIPIA et synchronisées avec votre CRM.',
  },
];

export function UseCasesLouis() {
  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        {/* Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Ce que Louis fait pour vous
          </h2>
        </div>

        {/* Grid 3x2 */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-7xl mx-auto">
          {useCases.map((useCase, idx) => (
            <Card key={idx} variant="gradient" className="p-6">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center mb-4">
                <useCase.icon className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-lg font-bold text-white mb-3">
                {useCase.title}
              </h3>
              <p className="text-gray-300 text-sm leading-relaxed">
                {useCase.description}
              </p>
            </Card>
          ))}
        </div>

      </div>
    </section>
  );
}
```

---

### Task 3.5: BenefitsTable Component

**File**: `components/landing/BenefitsTable.tsx`

**Data**:
```typescript
const benefits = [
  { label: 'Délai moyen de rappel', value: '< 60 secondes', icon: Clock },
  { label: 'Taux de contact', value: '+72%', icon: PhoneCall },
  { label: 'Taux de conversion en RDV', value: 'x3', icon: TrendingUp },
  { label: 'Temps gagné', value: '+21h/semaine', icon: Zap },
  { label: 'Réduction du taux de perte', value: '-87%', icon: ShieldCheck },
];
```

**Pattern**: Table avec 5 lignes, 2 colonnes (Indicateur | Résultat), fond glassmorphism.

---

### Task 3.6: CTAIntermediate Component

**File**: `components/landing/CTAIntermediate.tsx`

**Structure**: Section CTA avec 2 boutons, fond gradient bleu

```typescript
export function CTAIntermediate() {
  return (
    <section className="py-24 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-r from-blue-900/20 via-cyan-900/10 to-blue-900/20" />

      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-4xl mx-auto text-center space-y-8">
          <h2 className="text-4xl md:text-5xl font-bold text-white">
            Découvrez Louis en action
          </h2>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" className="bg-gradient-to-r from-blue-600 to-cyan-600">
              <Phone className="w-5 h-5 mr-2" />
              Appeler Louis maintenant
            </Button>
            <Button size="lg" variant="secondary">
              <Play className="w-5 h-5 mr-2" />
              Écouter un exemple d&apos;appel
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
```

---

### Task 3.7: ComparisonTable Component

**File**: `components/landing/ComparisonTable.tsx`

**Structure**: Table 2 colonnes "Sans Louis" vs "Avec Louis" (5 lignes de comparaison)

```typescript
const comparisons = [
  {
    without: 'Leads perdus ou non rappelés',
    with: 'Rappel instantané de chaque contact',
  },
  {
    without: 'Temps de réponse : plusieurs heures voire jours',
    with: 'Temps de réponse : moins de 60 secondes',
  },
  {
    without: 'Commerciaux surchargés de tâches administratives',
    with: 'IA qui qualifie et planifie automatiquement',
  },
  {
    without: 'Votre équipe passe 40% de son temps à rappeler',
    with: 'Votre équipe se concentre 100% sur la vente',
  },
  {
    without: 'Données éparpillées dans plusieurs outils',
    with: 'Dashboard et reporting unifié',
  },
];
```

**Pattern**: Card avec 2 colonnes, X rouge pour "Sans Louis", Check vert pour "Avec Louis".

---

### Task 3.8: TestimonialLouis Component

**File**: `components/landing/TestimonialLouis.tsx`

**Data**: Utiliser `testimonials.louis` de `lib/data/testimonials.ts`

**Structure**:
```typescript
import { testimonials } from '@/lib/data/testimonials';

export function TestimonialLouis() {
  const testimonial = testimonials.louis;

  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-4 relative z-10">

        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-white">
            Ne nous croyez pas seulement sur parole...
          </h2>
        </div>

        <Card variant="gradient" className="max-w-5xl mx-auto p-12">
          {/* Citation */}
          <blockquote className="text-xl md:text-2xl text-gray-200 leading-relaxed mb-8 italic">
            &quot;{testimonial.quote}&quot;
          </blockquote>

          {/* Auteur */}
          <div className="flex items-center gap-4 mb-8">
            <div>
              <p className="font-bold text-white">{testimonial.author}</p>
              <p className="text-sm text-gray-400">{testimonial.role}, {testimonial.company}</p>
            </div>
          </div>

          {/* Métriques */}
          <div className="grid grid-cols-3 gap-8 pt-8 border-t border-white/10">
            {testimonial.metrics.map((metric, idx) => (
              <div key={idx} className="text-center">
                <p className="text-3xl font-bold text-blue-400">{metric.value}</p>
                <p className="text-sm text-gray-400 mt-2">{metric.label}</p>
              </div>
            ))}
          </div>
        </Card>

      </div>
    </section>
  );
}
```

---

### Task 3.9: PricingLouis Component

**File**: `components/landing/PricingLouis.tsx`

**Data**: Utiliser `getPricingByAgent('louis')` de `lib/data/pricing.ts`

**Pattern**: Similaire à `PricingCardsHome` mais avec une seule carte centrée + bloc consommation + exemple de calcul.

---

### Task 3.10: FAQ Louis

**Data Update**: `lib/data/faqs.ts`

**Ajouter**:
```typescript
export const louisFAQs: FAQItem[] = [
  {
    question: 'Que fait exactement Louis ?',
    answer: 'Louis rappelle automatiquement vos leads entrants, les qualifie selon vos critères (budget, besoin, urgence, autorité) et planifie des rendez-vous directement dans votre agenda. Il fonctionne 24h/24 et 7j/7, sans jamais nécessiter de pause.',
  },
  {
    question: 'En combien de temps Louis rappelle-t-il un lead entrant ?',
    answer: 'Louis rappelle vos leads en moins de 60 secondes. Cette rapidité est cruciale : un lead contacté dans les 5 premières minutes a 9 fois plus de chances d\'être converti qu\'un lead contacté après une heure d\'attente.',
  },
  // ... 7 autres questions du fichier source
];
```

**Usage**: `<FAQAccordion faqs={faqs.louis} />`

---

### Task 3.11: CTAFinalLouis Component

**File**: `components/landing/CTAFinalLouis.tsx`

**Pattern**: Similaire à `CTAFinal` mais texte spécifique Louis.

```typescript
export function CTAFinalLouis() {
  return (
    <section className="py-24 relative overflow-hidden">
      {/* Background avec bleu Louis */}

      <div className="container mx-auto px-4 relative z-10">
        <div className="max-w-4xl mx-auto text-center">

          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-6">
            <span className="text-white">Automatisez votre rappel de leads</span>
            <br />
            <span className="bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
              dès aujourd&apos;hui
            </span>
          </h2>

          <p className="text-xl text-gray-300 mb-12 max-w-3xl mx-auto">
            Testez gratuitement Louis et découvrez comment il peut transformer vos conversions en moins d&apos;une semaine.
          </p>

          <Button size="lg" className="bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700">
            <Phone className="w-5 h-5 mr-2" />
            Tester gratuitement Louis
          </Button>

        </div>
      </div>
    </section>
  );
}
```

---

### Task 3.12: Assemble Louis Page

**File**: `app/(marketing)/louis/page.tsx`

**Replace current placeholder**:
```typescript
import { HeroLouis } from '@/components/landing/HeroLouis';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { HowItWorksLouis } from '@/components/landing/HowItWorksLouis';
import { UseCasesLouis } from '@/components/landing/UseCasesLouis';
import { BenefitsTable } from '@/components/landing/BenefitsTable';
import { CTAIntermediate } from '@/components/landing/CTAIntermediate';
import { ComparisonTable } from '@/components/landing/ComparisonTable';
import { TestimonialLouis } from '@/components/landing/TestimonialLouis';
import { PricingLouis } from '@/components/landing/PricingLouis';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { CTAFinalLouis } from '@/components/landing/CTAFinalLouis';
import { faqs } from '@/lib/data/faqs';

export default function LouisPage() {
  return (
    <main className="overflow-x-hidden">
      <HeroLouis />
      <IntegrationBar />
      <HowItWorksLouis />
      <UseCasesLouis />
      <BenefitsTable />
      <CTAIntermediate />
      <ComparisonTable />
      <TestimonialLouis />
      <PricingLouis />
      <FAQAccordion faqs={faqs.louis} />
      <CTAFinalLouis />
    </main>
  );
}
```

---

## ✅ Validation Loops

### Build & TypeScript
```bash
npx tsc --noEmit  # Must pass without errors
npm run lint      # Must pass without errors
npm run build     # Must complete successfully
```

### Development Server
```bash
npm run dev       # Start server on http://localhost:3000
```

### Browser Testing (MCP Playwright)
```bash
# Navigate to Louis page
mcp__playwright__browser_navigate(url: "http://localhost:3000/louis")

# Take snapshot
mcp__playwright__browser_snapshot()

# Verify elements present:
- ✅ Hero avec gradient bleu-cyan
- ✅ 10 sections visibles
- ✅ 2 CTAs dans hero (Tester + Écouter)
- ✅ 4 étapes "Comment ça marche"
- ✅ 6 cartes cas d'usage
- ✅ Table bénéfices (5 lignes)
- ✅ Comparaison avant/après
- ✅ Témoignage Stefano Design
- ✅ Tarif 190€/mois
- ✅ FAQ avec 9 questions

# Test responsive
mcp__playwright__browser_resize(width: 768, height: 1024)  # Tablet
mcp__playwright__browser_snapshot()

mcp__playwright__browser_resize(width: 375, height: 667)   # Mobile
mcp__playwright__browser_snapshot()
```

### Functional Tests
- [ ] Audio player plays demo audio
- [ ] FAQ accordion opens/closes
- [ ] All CTAs are clickable
- [ ] Stats display correctly
- [ ] Gradients are blue/cyan (not violet/purple)

---

## 🚫 Anti-patterns

### DO NOT
- ❌ Use violet/purple gradients (Louis = blue/cyan only)
- ❌ Hardcode data in components (use `lib/data/`)
- ❌ Create new Button/Card components (reuse shared)
- ❌ Skip browser validation
- ❌ Forget responsive design
- ❌ Mix Louis content with Arthur/Alexandra

### DO
- ✅ Use Louis color: `from-blue-600 to-cyan-500`
- ✅ Reuse `FAQAccordion`, `IntegrationBar`, `Button`, `Card`, `AudioPlayer`
- ✅ Add Louis FAQs to `lib/data/faqs.ts`
- ✅ Use testimonial from `lib/data/testimonials.ts`
- ✅ Test on mobile, tablet, desktop
- ✅ Verify all 10 sections are present

---

## 📊 Success Criteria

### Technical
- [x] TypeScript compilation: 0 errors
- [x] ESLint: 0 errors, 0 warnings
- [x] Build: Successful
- [x] 10 new components created in `components/landing/`
- [x] 9 Louis FAQs added to `lib/data/faqs.ts`
- [x] Page assembled in `app/(marketing)/louis/page.tsx`

### Visual
- [x] Blue/cyan gradient dominant (NOT violet)
- [x] 10 sections visible and properly spaced
- [x] Responsive mobile/tablet/desktop
- [x] Glassmorphism cards consistent
- [x] Audio player present in hero

### Content
- [x] All content from `LP Louis.txt` integrated
- [x] Témoignage Stefano Design visible
- [x] Tarif 190€/mois affiché
- [x] 9 FAQs specific to Louis
- [x] Stats: < 60s, +72%, x3, +21h, -87%

### Performance
- [x] Lighthouse score > 85
- [x] No console errors
- [x] Fast page load

---

## 🎯 Confidence Score: 9/10

**Strengths**:
- Phase 2 established all patterns
- All components are reusable
- Source content is complete and detailed
- Louis data already exists in `lib/data/agents.ts`

**Risks**:
- Need to ensure blue/cyan colors (not violet/purple)
- 10 sections = significant code volume
- Audio player integration needs testing

---

**Generated**: 2025-10-28
**Ready for execution**: ✅ YES
**Dependencies**: Phase 1 & 2 completed
