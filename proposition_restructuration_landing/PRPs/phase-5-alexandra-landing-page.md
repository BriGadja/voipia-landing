# PRP: Phase 5 - Landing Page Alexandra (Réception 24/7)

## 🎯 Purpose & Goal

Create a complete, conversion-optimized landing page for Alexandra, Voipia's AI receptionist agent, that handles incoming calls 24/7. This page will showcase Alexandra's capabilities in answering, filtering, and routing all incoming calls automatically, positioning her as the ultimate automated reception solution.

### Business Value
- Dedicated URL (`/alexandra`) for targeted marketing campaigns
- Clear positioning distinct from Louis (call-back) and Arthur (reactivation)
- Optimized conversion funnel for businesses needing 24/7 call coverage
- SEO-optimized content for "AI receptionist" and "automated phone answering" keywords

### User Impact
- Immediate understanding of Alexandra's call reception capabilities
- Clear ROI demonstration (vs human receptionist: €2500/month)
- Proof of 100% call answer rate with customer testimonials
- Simple, transparent pricing model

## 📋 Context & References

### Essential Files to Review
```yaml
- file: CLAUDE.md
  why: Project architecture, workflows, and validation requirements

- file: proposition_restructuration_landing/LP Alexandra.txt
  why: Complete copywriting and content source for all 10 sections

- file: proposition_restructuration_landing/INITIAL/INITIAL_refonte_05_alexandra.md
  why: Phase breakdown with 12 micro-tasks and validation criteria

- file: app/(marketing)/louis/page.tsx
  why: Reference structure for agent landing pages (10-section pattern)

- file: app/(marketing)/arthur/page.tsx
  why: Alternative agent page structure for comparison

- file: components/landing/HeroLouis.tsx
  why: Hero component pattern to replicate with green theme

- file: components/landing/BenefitsTable.tsx
  why: Reusable statistics table component (with icon mapping)

- file: components/landing/ComparisonTable.tsx
  why: Before/After comparison component to reuse

- file: components/landing/FAQAccordion.tsx
  why: Reusable FAQ component with accordion interaction

- file: components/landing/IntegrationBar.tsx
  why: Integration logos bar (add Notion + Slack for Alexandra)

- file: lib/data/benefits.ts
  why: Where to add Alexandra's 5 statistics with Lucide icon names

- file: lib/data/faqs.ts
  why: Where to add Alexandra's 9 FAQ questions

- file: lib/data/testimonials.ts
  why: Where to add Stefano Design testimonial for Alexandra

- file: tailwind.config.ts
  why: Custom animations and green theme colors for Alexandra
```

### Key Design Patterns
- **Agent color**: Alexandra uses **green** theme (`green-400`, `emerald-500`, `teal-600`)
- **Section spacing**: Consistent `py-24` between major sections
- **Container pattern**: `container mx-auto px-4 relative z-10`
- **Dark theme**: Black/gray background with glassmorphism cards
- **Icon system**: Pass Lucide icon names as strings, map in client components

## 🏗️ Implementation Blueprint

### 1. Data Layer Setup

#### 1.1 Update `lib/data/benefits.ts`
```typescript
// Add Alexandra benefits (Phase 5)
export const alexandraBenefits: BenefitItem[] = [
  { label: 'Taux de réponse', value: '100%', icon: 'PhoneIncoming' },
  { label: 'Temps de réponse', value: '<3 sonneries', icon: 'Clock' },
  { label: 'Appels manqués éliminés', value: '-100%', icon: 'PhoneOff' },
  { label: 'Temps gagné', value: '+30h/semaine', icon: 'Zap' },
  { label: 'Satisfaction client', value: '+45%', icon: 'Heart' },
];
```

**Icons to add to BenefitsTable.tsx icon map**:
- `PhoneIncoming` (for call reception)
- `PhoneOff` (for missed calls eliminated)
- `Heart` (for customer satisfaction)

#### 1.2 Update `lib/data/faqs.ts`
```typescript
export const faqs = {
  louis: [...],
  arthur: [...],
  alexandra: [
    {
      question: "Que fait exactement Alexandra ?",
      answer: "Alexandra répond automatiquement à tous vos appels entrants, 24h/24 et 7j/7. Elle répond aux questions de vos clients grâce à votre base de connaissances, filtre les appels indésirables, prend des rendez-vous directement dans votre agenda et transfère les appels importants vers le bon interlocuteur."
    },
    {
      question: "Comment Alexandra répond-elle aux questions spécifiques sur mon entreprise ?",
      answer: "Alexandra utilise une base de connaissances personnalisée que vous alimentez avec toutes les informations sur votre entreprise : produits, services, tarifs, FAQ, processus internes. Plus vous lui donnez d'informations, plus elle devient experte et précise dans ses réponses."
    },
    {
      question: "Alexandra peut-elle vraiment filtrer les appels indésirables ?",
      answer: "Oui, Alexandra identifie automatiquement les appels de démarchage commercial, les sollicitations non pertinentes et les spams téléphoniques. Vous configurez les règles de filtrage selon vos besoins, et Alexandra ne transfère à votre équipe que les appels à forte valeur ajoutée."
    },
    {
      question: "En combien de temps peut-on déployer Alexandra ?",
      answer: "Alexandra est opérationnelle en moins de 5 jours ouvrés. Ce délai inclut : la configuration complète, la création de votre base de connaissances personnalisée, l'intégration avec votre CRM et vos outils, les tests et la mise en production."
    },
    {
      question: "Quels outils sont compatibles avec Alexandra ?",
      answer: "Alexandra s'intègre nativement avec tous les principaux outils : Pipedrive, HubSpot, Salesforce, Google Calendar, Outlook, Calendly, Notion, Slack, Make, Zapier. Si vous utilisez un outil spécifique, contactez-nous pour confirmer la compatibilité."
    },
    {
      question: "Alexandra parle-t-elle plusieurs langues ?",
      answer: "Oui, Alexandra mène des conversations fluides dans plus de 20 langues (français, anglais, espagnol, allemand, italien, portugais...). Elle adapte automatiquement son ton et son approche selon la langue et le pays de votre appelant."
    },
    {
      question: "Peut-on écouter les appels traités par Alexandra ?",
      answer: "Oui, chaque appel est enregistré, transcrit et accessible depuis le dashboard VoIPIA. Vous pouvez les écouter, les analyser et les utiliser pour améliorer continuellement votre base de connaissances et votre service client."
    },
    {
      question: "Que se passe-t-il quand Alexandra ne peut pas répondre à une question ?",
      answer: "Si une question dépasse sa base de connaissances, Alexandra le reconnaît immédiatement. Elle peut soit prendre les coordonnées du client pour qu'un expert le rappelle, soit transférer l'appel directement vers un membre disponible de votre équipe avec tout le contexte de la conversation."
    },
    {
      question: "Alexandra est-elle conforme RGPD ?",
      answer: "Oui, absolument. Données hébergées en Europe, chiffrement de bout en bout, conformité RGPD totale. Toutes vos données d'appels et conversations sont protégées avec le même niveau de sécurité que les institutions bancaires."
    }
  ]
};
```

#### 1.3 Update `lib/data/testimonials.ts`
```typescript
export const testimonials = {
  louis: {...},
  arthur: {...},
  alexandra: {
    quote: "Depuis qu'Alexandra gère notre accueil téléphonique, nous avons 100% de taux de réponse même pendant nos pics d'activité. Nos clients sont ravis de ne plus tomber sur un répondeur, et mon équipe peut enfin se concentrer sur son travail sans être interrompue toutes les 10 minutes. Alexandra a transformé notre relation client : elle répond avec précision grâce à notre base de connaissances et prend des rendez-vous comme une vraie professionnelle. Nous avons économisé l'équivalent d'un poste de réceptionniste à temps plein.",
    author: {
      name: "Valentin",
      role: "Dirigeant",
      company: "Stefano Design"
    },
    stats: [
      { label: "De taux de réponse sans appels manqués", value: "100%" },
      { label: "Augmentation de la satisfaction client", value: "+45%" },
      { label: "Économisées par semaine sur l'accueil téléphonique", value: "+30H" }
    ],
    image: "/testimonials/stefano-design-alexandra.jpg"
  }
};
```

### 2. Component Creation (10 New Components)

#### 2.1 `components/landing/HeroAlexandra.tsx`
```typescript
'use client';

import { Button } from '@/components/shared/Button';
import { Phone, Play } from 'lucide-react';
import { motion } from 'framer-motion';

export function HeroAlexandra() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Gradient Background */}
      <div className="absolute inset-0 bg-gradient-to-b from-black via-gray-900 to-black" />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-green-900/20 via-transparent to-transparent" />

      <div className="container mx-auto px-4 relative z-10 text-center">
        {/* Badge */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-500/10 border border-green-500/20 mb-8"
        >
          <Phone className="w-5 h-5 text-green-400" />
          <span className="text-green-400 font-medium">Alexandra - Réception 24/7</span>
        </motion.div>

        {/* Main Heading */}
        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className="text-5xl md:text-7xl font-bold mb-6"
        >
          Rencontrez <span className="text-transparent bg-clip-text bg-gradient-to-r from-green-400 to-emerald-400">Alexandra.</span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="text-xl md:text-2xl text-gray-300 mb-8 max-w-3xl mx-auto"
        >
          Votre agent de réception IA qui répond, filtre et oriente chaque appel entrant automatiquement.
        </motion.p>

        {/* Description */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="max-w-4xl mx-auto space-y-4 mb-12"
        >
          <p className="text-lg text-gray-400">
            Alexandra décroche chaque appel en moins de 3 sonneries, 24h/24 et 7j/7, dans plusieurs langues.
          </p>
          <p className="text-lg text-gray-400">
            Elle répond aux questions, filtre les demandes, prend des rendez-vous et transfère les appels pendant que votre équipe se concentre sur son cœur de métier.
          </p>
        </motion.div>

        {/* CTAs */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="flex flex-col sm:flex-row gap-4 justify-center mb-16"
        >
          <Button size="lg" className="bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600">
            <Phone className="w-5 h-5" />
            Tester gratuitement Alexandra
          </Button>
          <Button size="lg" variant="outline" className="border-green-500/20 hover:bg-green-500/10">
            <Play className="w-5 h-5" />
            Écouter un appel d'Alexandra
          </Button>
        </motion.div>

        {/* Quick Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.5 }}
          className="flex flex-wrap gap-8 justify-center text-center"
        >
          <div>
            <p className="text-3xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-green-400 to-emerald-400">< 3 sonneries</p>
            <p className="text-sm text-gray-400 mt-1">Temps de réponse</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-green-400 to-emerald-400">100%</p>
            <p className="text-sm text-gray-400 mt-1">Taux de réponse</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-green-400 to-emerald-400">24/7</p>
            <p className="text-sm text-gray-400 mt-1">Disponibilité</p>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
```

#### 2.2 `components/landing/HowItWorksAlexandra.tsx`
4-step process with green theme, icons, and animations. Pattern from HowItWorksLouis.tsx but adapted for reception workflow.

#### 2.3 `components/landing/UseCasesAlexandra.tsx`
6 cards grid showcasing:
1. Réception 24/7
2. Base de connaissances
3. Filtrage intelligent
4. Prise de rendez-vous
5. Transfert intelligent
6. Dashboard & reporting

#### 2.4 `components/landing/TestimonialAlexandra.tsx`
Testimonial card with Stefano Design quote, author info, stats badges, and optional company logo.

#### 2.5 `components/landing/PricingAlexandra.tsx`
Pricing section with:
- Main price: 290€ HT/mois
- Inclusions list (6 items)
- Consumption pricing (calls, SMS, emails)
- Example calculation (400 calls/month = 621€ HT/mois)
- Comparison: vs receptionist (€2500/month)

#### 2.6 `components/landing/CTAFinalAlexandra.tsx`
Final CTA with green gradient, two buttons, and baseline text.

### 3. Page Assembly

#### 3.1 Create `app/(marketing)/alexandra/page.tsx`
```typescript
import { HeroAlexandra } from '@/components/landing/HeroAlexandra';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { HowItWorksAlexandra } from '@/components/landing/HowItWorksAlexandra';
import { UseCasesAlexandra } from '@/components/landing/UseCasesAlexandra';
import { BenefitsTable } from '@/components/landing/BenefitsTable';
import { CTAIntermediate } from '@/components/landing/CTAIntermediate';
import { ComparisonTable } from '@/components/landing/ComparisonTable';
import { TestimonialAlexandra } from '@/components/landing/TestimonialAlexandra';
import { PricingAlexandra } from '@/components/landing/PricingAlexandra';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { CTAFinalAlexandra } from '@/components/landing/CTAFinalAlexandra';
import { faqs } from '@/lib/data/faqs';
import { alexandraBenefits } from '@/lib/data/benefits';

export default function AlexandraPage() {
  return (
    <main className="overflow-x-hidden">
      <HeroAlexandra />
      <IntegrationBar variant="alexandra" />
      <HowItWorksAlexandra />
      <UseCasesAlexandra />
      <BenefitsTable
        benefits={alexandraBenefits}
        title="Des résultats qui parlent d'eux-mêmes"
        subtitle="Chaque appel est traité. Chaque opportunité est saisie."
        gradientFrom="from-green-400"
        gradientTo="to-emerald-400"
      />
      <CTAIntermediate
        agent="alexandra"
        title="Découvrez Alexandra en action"
      />
      <ComparisonTable agent="alexandra" />
      <TestimonialAlexandra />
      <PricingAlexandra />
      <FAQAccordion
        faqs={faqs.alexandra}
        gradientFrom="from-green-400"
        gradientTo="to-emerald-400"
      />
      <CTAFinalAlexandra />
    </main>
  );
}

export const metadata = {
  title: 'Alexandra - Réception d\'appels IA 24/7 | Voipia',
  description: 'Alexandra, votre agent de réception IA qui répond, filtre et oriente chaque appel entrant automatiquement. Disponible 24/7, multilingue, intégré à votre CRM.',
};
```

### 4. Component Props & Reusability

#### IntegrationBar Component Update
Add `variant` prop to support agent-specific integrations:
```typescript
interface IntegrationBarProps {
  variant?: 'louis' | 'arthur' | 'alexandra';
}
```

For Alexandra, add Notion and Slack logos to the integration list.

#### ComparisonTable Component Update
Add `agent` prop to support agent-specific comparisons:
```typescript
interface ComparisonTableProps {
  agent: 'louis' | 'arthur' | 'alexandra';
}
```

Add Alexandra comparison data:
- Sans Alexandra: Appels manqués, équipe interrompue, 40% temps au téléphone, infos perdues, notes papier
- Avec Alexandra: 100% décrochés, disponibilité 24/7, filtrage intelligent, équipe concentrée, dashboard unifié

#### CTAIntermediate Component Update
Add `agent` prop to customize CTA text and colors:
```typescript
interface CTAIntermediateProps {
  agent: 'louis' | 'arthur' | 'alexandra';
  title?: string;
}
```

## ✅ Validation Loops

### Development Server
```bash
# Start dev server
npm run dev

# Expected: Server starts on http://localhost:3000
# Expected: No TypeScript errors
# Expected: No console errors
```

### Visual Verification (MCP Playwright)
```bash
# Navigate to Alexandra page
mcp__playwright__browser_navigate("http://localhost:3000/alexandra")

# Take full page screenshot
mcp__playwright__browser_take_screenshot({ fullPage: true })

# Check sections present:
# 1. Hero with green gradient
# 2. Integration bar (with Notion + Slack)
# 3. How it works (4 steps)
# 4. Use cases (6 cards)
# 5. Benefits table (5 stats with icons)
# 6. CTA Intermediate
# 7. Comparison table (before/after)
# 8. Testimonial (Stefano Design)
# 9. Pricing (290€/mois)
# 10. FAQ (9 questions)
# 11. Final CTA

# Test responsive
mcp__playwright__browser_resize({ width: 375, height: 667 }) # Mobile
mcp__playwright__browser_take_screenshot()

mcp__playwright__browser_resize({ width: 768, height: 1024 }) # Tablet
mcp__playwright__browser_take_screenshot()
```

### Functional Tests
```bash
# Test FAQ accordion
mcp__playwright__browser_click({ selector: 'button:has-text("Que fait exactement Alexandra")' })
# Expected: FAQ item opens

# Test CTA buttons
mcp__playwright__browser_click({ selector: 'button:has-text("Tester gratuitement Alexandra")' })
# Expected: Calendar or form opens

# Test audio player
mcp__playwright__browser_click({ selector: 'button:has-text("Écouter un appel d\'Alexandra")' })
# Expected: Audio player appears
```

### Build Verification
```bash
npm run build

# Expected: Build succeeds
# Expected: Page /alexandra generated
# Expected: No TypeScript errors
# Expected: No lint errors
```

### Performance Check
```bash
# Run Lighthouse in browser DevTools
# Expected scores:
# - Performance: > 85
# - Accessibility: > 90
# - Best Practices: > 90
# - SEO: > 90
```

## 🚫 Anti-patterns to Avoid

### Code Anti-patterns
- ❌ **Hardcoding colors**: Use Tailwind green theme classes consistently
- ❌ **Passing icon components**: Pass icon names as strings, map in client
- ❌ **Creating duplicate components**: Reuse BenefitsTable, FAQAccordion, ComparisonTable
- ❌ **Inconsistent spacing**: Use `py-24` for section spacing
- ❌ **Missing responsive design**: Test all breakpoints (mobile, tablet, desktop)

### Content Anti-patterns
- ❌ **Mixing agent messaging**: Keep Alexandra's positioning clear (reception ≠ callback)
- ❌ **Inconsistent pricing format**: Use same structure as Louis/Arthur
- ❌ **Missing statistics**: All 5 benefits must have icon + value + label
- ❌ **Incomplete FAQ**: All 9 questions must be present and accurate

### Workflow Anti-patterns
- ❌ **Skipping browser verification**: Always test with MCP Playwright before committing
- ❌ **Not testing responsive**: Desktop-only testing misses mobile issues
- ❌ **Ignoring build errors**: Fix TypeScript/lint errors immediately
- ❌ **Forgetting metadata**: Add proper title/description for SEO

## 📊 Success Criteria

### Must Have (P0)
- ✅ Page `/alexandra` accessible and loads without errors
- ✅ All 10 sections present and rendering correctly
- ✅ Green theme applied consistently throughout
- ✅ All 5 statistics visible with correct icons
- ✅ All 9 FAQ questions functional (accordion opens/closes)
- ✅ Testimonial from Stefano Design displays correctly
- ✅ Pricing section shows 290€/mois with calculation example
- ✅ Responsive design works on mobile, tablet, desktop
- ✅ Build succeeds without errors

### Should Have (P1)
- ✅ Lighthouse score > 85 on all metrics
- ✅ Smooth scroll animations between sections
- ✅ Hover effects on all interactive elements
- ✅ Integration bar shows Notion + Slack logos
- ✅ Comparison table shows 6 before/after rows
- ✅ Audio player component functional (if implemented)

### Nice to Have (P2)
- ✅ Custom green gradient animations
- ✅ Interactive call flow diagram
- ✅ Video testimonial (future enhancement)
- ✅ Live chat integration
- ✅ A/B testing variants

## 🔗 Integration Points

### With Existing System
1. **Navigation**: Add Alexandra link to main header dropdown "Solutions"
2. **Home page**: Update AgentsGridHome to include clickable Alexandra card
3. **Cross-selling**: Add "Découvrez nos autres agents" section on Louis/Arthur pages
4. **Analytics**: Track `/alexandra` page views and conversion events

### With Phase 6 (Navigation)
- Alexandra page will receive cross-selling section to Louis/Arthur
- Home page quiz will route to Alexandra for "réception 24/7" needs
- Bundle pricing will include Alexandra in 3-agent pack

## 📈 Confidence Score

**Overall Confidence: 9/10**

### Breakdown
- **Context completeness**: 10/10 - Full source content + existing patterns
- **Implementation clarity**: 9/10 - Clear component structure, some details TBD
- **Validation coverage**: 9/10 - Comprehensive testing with MCP Playwright
- **Pattern consistency**: 10/10 - Follows Louis/Arthur structure exactly

### Risks & Mitigations
1. **Risk**: Icon mapping for new icons (PhoneIncoming, PhoneOff, Heart)
   - **Mitigation**: Add to BenefitsTable.tsx iconMap immediately

2. **Risk**: Testimonial image not available
   - **Mitigation**: Use placeholder or company logo initially

3. **Risk**: Integration logos (Notion, Slack) missing
   - **Mitigation**: Download from official brand assets or use placeholder

## 📝 Implementation Checklist

### Data Layer (30 min)
- [ ] Add `alexandraBenefits` to `lib/data/benefits.ts`
- [ ] Add `alexandra` FAQ section to `lib/data/faqs.ts`
- [ ] Add `alexandra` testimonial to `lib/data/testimonials.ts`
- [ ] Update `BenefitsTable.tsx` iconMap with 3 new icons

### Components (4-5 hours)
- [ ] Create `HeroAlexandra.tsx` (1h)
- [ ] Create `HowItWorksAlexandra.tsx` (1h)
- [ ] Create `UseCasesAlexandra.tsx` (1h)
- [ ] Create `TestimonialAlexandra.tsx` (30min)
- [ ] Create `PricingAlexandra.tsx` (1h)
- [ ] Create `CTAFinalAlexandra.tsx` (30min)

### Component Updates (1 hour)
- [ ] Update `IntegrationBar.tsx` with variant prop
- [ ] Update `ComparisonTable.tsx` with Alexandra data
- [ ] Update `CTAIntermediate.tsx` with agent prop

### Page Assembly (30 min)
- [ ] Create `app/(marketing)/alexandra/page.tsx`
- [ ] Add metadata (title, description)
- [ ] Import all components

### Testing (1 hour)
- [ ] Run dev server and navigate to `/alexandra`
- [ ] Take browser snapshots (desktop, tablet, mobile)
- [ ] Test all interactive elements (FAQ, CTAs, audio)
- [ ] Run build and verify no errors
- [ ] Check Lighthouse scores

### Total Estimated Time: 7-8 hours

---

**Document Version**: 1.0
**Created**: 2025-10-28
**Status**: ✅ Ready for execution
**Next Step**: Execute with `/execute-prp proposition_restructuration_landing/PRPs/phase-5-alexandra-landing-page.md`
