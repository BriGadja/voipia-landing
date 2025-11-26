# Refonte Landing Page - Vue d'Ensemble Complète

Ce document fournit une vue d'ensemble détaillée de la refonte du site Voipia, qui passe d'une page unique à une architecture **Home + 3 Landing Pages dédiées** (une pour chaque agent).

---

## Objectifs de la Refonte

### Business Objectives

1. **Améliorer les conversions** (+30-50% vs landing actuelle)
2. **Réduire le coût d'acquisition client** (-20%)
3. **Optimiser le SEO** (+40% trafic organique sur 3 mois)
4. **Faciliter les campagnes publicitaires ciblées** (tracking précis par agent)
5. **Améliorer l'attribution** (ROI publicitaire +25%)

### Technical Objectives

1. **URLs dédiées** pour chaque agent (`/louis`, `/arthur`, `/alexandra`)
2. **Pages optimisées** pour des requêtes spécifiques par agent
3. **Tracking granulaire** par source/agent/campagne
4. **Performance technique** (Lighthouse > 90)
5. **SEO structuré** (structured data, sitemap, meta descriptions uniques)

---

## Architecture Cible

### Vue d'Ensemble

```
/                    → Home actuelle (ne pas toucher pendant la refonte)
/landingv2           → Nouvelle Home (en développement, remplacera / après validation)
/louis               → Landing Page Louis (Rappel automatique)
/arthur              → Landing Page Arthur (Réactivation)
/alexandra           → Landing Page Alexandra (Réception 24/7)
/dashboard           → Dashboard global (existant, ne pas toucher)
```

### Stratégie de Développement

**⚠️ IMPORTANT**: Pour ne pas impacter la home actuelle, la nouvelle Home sera développée sur `/landingv2` jusqu'à validation complète.

**Plan de migration**:
1. **Phases 1-7** : Développer sur `/landingv2` + pages agents (`/louis`, `/arthur`, `/alexandra`)
2. **Validation complète** : Tests A/B, validation des conversions, feedback utilisateurs
3. **Migration finale** : `/landingv2` → `/` (remplace la home actuelle)
4. **Nettoyage** : Suppression de `/landingv2`, redirection 301 si nécessaire

---

## Plan de Refonte en 7 Phases

Le projet est structuré en 7 phases chronologiques documentées dans `features/proposition_restructuration_landing/INITIAL/`

### Phase 1 : Fondations et Architecture 🔴 CRITIQUE

**Fichier**: `INITIAL_refonte_01_fondations.md`
**Durée estimée**: 2-3 jours
**Statut**: Phase préliminaire obligatoire

**Livrables**:
- Structure de routing Next.js (`app/(marketing)/`)
- Composants réutilisables (`components/landing/`, `components/shared/`)
- Système de données centralisé (`lib/data/`)
- Types TypeScript (`lib/types/landing.ts`)
- Configuration Tailwind étendue (couleurs, animations)

**Dépendances**: Aucune (doit être terminée EN PREMIER)

**Critères de succès**:
- ✅ Structure de dossiers créée
- ✅ Composants de base fonctionnels
- ✅ Système de données opérationnel
- ✅ Build Next.js sans erreur
- ✅ Types TypeScript complets

---

### Phase 2 : Page Home (Restructurée) 🏠

**Fichier**: `INITIAL_refonte_02_home.md`
**Durée estimée**: 3-4 jours

**Livrables**:
- Hero repensé (USP claire, CTA principal)
- Section "Les 3 Agents" avec cartes cliquables vers `/louis`, `/arthur`, `/alexandra`
- Comparatif SDR traditionnel vs VoIPIA
- Section Tarifs (aperçu global + lien vers pages agents)
- FAQ générale
- Section "Développements sur-mesure"
- CTA final

**Dépendances**: Phase 1 (Fondations)

**Critères de succès**:
- ✅ Page `/landingv2` fonctionnelle
- ✅ Navigation vers les 3 pages agents
- ✅ Responsive design parfait
- ✅ Score Lighthouse > 90

---

### Phase 3 : Landing Page Louis 🔵

**Fichier**: `INITIAL_refonte_03_louis.md`
**Source**: `proposition_restructuration_landing/LP Louis.txt`
**Durée estimée**: 3-4 jours

**Livrables**:
- Page `/louis` complète (10 sections)
- Hero spécifique Louis (Rappel automatique)
- 6 cas d'utilisation (agents immobiliers, concessionnaires, etc.)
- Tableau avant/après
- Process en 4 étapes
- Tarification 190€/mois
- FAQ spécifique (9 questions)
- Témoignage Stefano Design
- Barre d'intégrations (Make, Pipedrive, HubSpot, etc.)
- CTA final

**Dépendances**: Phase 1 (Fondations)

**Critères de succès**:
- ✅ Page `/louis` opérationnelle
- ✅ SEO optimisé (meta descriptions, structured data)
- ✅ Conversions trackées (GA4 events)

---

### Phase 4 : Landing Page Arthur 🟠

**Fichier**: `INITIAL_refonte_04_arthur.md`
**Source**: `proposition_restructuration_landing/LP Arthur.txt`
**Durée estimée**: 3-4 jours

**Livrables**:
- Page `/arthur` complète (10 sections)
- Hero spécifique Arthur (Réactivation clients)
- 6 cas d'utilisation (réactivation BtoB, relance e-commerce, etc.)
- Tableau avant/après
- Process en 4 étapes
- Tarification 490€/mois
- FAQ spécifique (9 questions)
- Témoignage Norloc
- Barre d'intégrations (Make, Pipedrive, HubSpot, n8n, etc.)
- CTA final

**Dépendances**: Phase 1 (Fondations)

**Critères de succès**:
- ✅ Page `/arthur` opérationnelle
- ✅ SEO optimisé (meta descriptions, structured data)
- ✅ Conversions trackées (GA4 events)

---

### Phase 5 : Landing Page Alexandra 🟢

**Fichier**: `INITIAL_refonte_05_alexandra.md`
**Source**: `proposition_restructuration_landing/LP Alexandra.txt`
**Durée estimée**: 3-4 jours

**Livrables**:
- Page `/alexandra` complète (10 sections)
- Hero spécifique Alexandra (Réception 24/7)
- 6 cas d'utilisation (service client, SAV, prise de RDV, etc.)
- Tableau avant/après
- Process en 4 étapes
- Tarification 290€/mois
- FAQ spécifique (9 questions)
- Témoignage Stefano Design
- Barre d'intégrations (Make, Pipedrive, HubSpot, Calendly, etc.)
- CTA final

**Dépendances**: Phase 1 (Fondations)

**Critères de succès**:
- ✅ Page `/alexandra` opérationnelle
- ✅ SEO optimisé (meta descriptions, structured data)
- ✅ Conversions trackées (GA4 events)

---

### Phase 6 : Navigation et Cross-Selling 🔗

**Fichier**: `INITIAL_refonte_06_navigation.md`
**Durée estimée**: 2-3 jours

**Livrables**:
- Header avec dropdown "Solutions" (liens vers `/louis`, `/arthur`, `/alexandra`)
- Quiz de qualification sur Home (recommande l'agent adapté)
- Section "Découvrez nos autres agents" sur chaque LP (cross-selling)
- Bundles tarifaires (Pack Complet : 3 agents à prix réduit)
- Liens croisés intelligents entre les pages
- Breadcrumbs et fil d'Ariane

**Dépendances**: Phases 2, 3, 4, 5 (nécessite que les pages soient créées)

**Critères de succès**:
- ✅ Navigation fluide entre toutes les pages
- ✅ Cross-selling augmente les conversions multi-agents
- ✅ Quiz de qualification fonctionne correctement

---

### Phase 7 : SEO, Analytics et Optimisations 📈

**Fichier**: `INITIAL_refonte_07_seo_analytics.md`
**Durée estimée**: 2 jours

**Livrables**:
- Meta descriptions uniques par page (optimisées pour SEO)
- Structured data (JSON-LD) pour chaque agent (Product, FAQPage, BreadcrumbList)
- Sitemap.xml mis à jour avec toutes les pages
- Robots.txt optimisé
- Google Analytics 4 tracking (events personnalisés par agent)
- Balises Open Graph et Twitter Cards
- Performance optimizations (images WebP/AVIF, lazy loading, code splitting)
- Score Lighthouse > 90 (Performance, SEO, Accessibility, Best Practices)

**Dépendances**: Toutes les phases précédentes

**Critères de succès**:
- ✅ Score Lighthouse > 90 sur toutes les pages
- ✅ Time to Interactive < 2s
- ✅ 0 erreur console
- ✅ Tracking GA4 fonctionnel

---

## Dépendances Entre Phases

```
Phase 1 (Fondations) ← DOIT ÊTRE TERMINÉE EN PREMIER
    ↓
Phase 2 (Home) + Phase 3 (Louis) + Phase 4 (Arthur) + Phase 5 (Alexandra)
    ↓ (peuvent être faites en parallèle)
Phase 6 (Navigation) ← Nécessite que les pages soient créées
    ↓
Phase 7 (SEO/Analytics) ← Finalisation
```

**Note**: Les phases 2, 3, 4, 5 peuvent être développées en parallèle car elles sont indépendantes (après la phase 1).

---

## Protocole d'Exécution

Pour chaque phase :

1. **Lire le fichier INITIAL** : `features/proposition_restructuration_landing/INITIAL/INITIAL_refonte_XX.md`
2. **Générer le PRP** : `/generate-prp "Phase X : [titre de la phase]"`
3. **Review du PRP** : Valider la structure et le contenu
4. **Exécuter le PRP** : `/execute-prp features/proposition_restructuration_landing/PRPs/refonte-phase-X.md`
5. **Validation** :
   - Tests de build : `npm run build`
   - Tests visuels : MCP Playwright (navigate + snapshot)
   - Tests fonctionnels : CTAs, navigation, responsive
6. **Commit** : Git commit avec message descriptif
7. **Mettre à jour PROGRESS_REFONTE.md** : Documenter l'avancement

---

## Composants Clés à Créer

### Composants Partagés (`components/shared/`)

- **`Header.tsx`** - Header avec dropdown "Solutions" (Louis, Arthur, Alexandra)
- **`Footer.tsx`** - Footer commun à toutes les pages
- **`Button.tsx`** - Bouton réutilisable avec variants (primary, secondary, ghost)
- **`Card.tsx`** - Card glassmorphism avec hover effects
- **`AudioPlayer.tsx`** - Player audio pour démos d'appels

### Composants Landing (`components/landing/`)

**Hero Sections**:
- `HeroLouis.tsx` - Hero spécifique Louis (rappel automatique)
- `HeroArthur.tsx` - Hero spécifique Arthur (réactivation)
- `HeroAlexandra.tsx` - Hero spécifique Alexandra (réception 24/7)

**Features**:
- `IntegrationBar.tsx` - Barre logos tech/intégrations
- `HowItWorksLouis.tsx` - Process en 4 étapes (Louis)
- `HowItWorksArthur.tsx` - Process en 4 étapes (Arthur)
- `HowItWorksAlexandra.tsx` - Process en 4 étapes (Alexandra)
- `UseCasesLouis.tsx` - 6 cas d'utilisation (Louis)
- `UseCasesArthur.tsx` - 6 cas d'utilisation (Arthur)
- `UseCasesAlexandra.tsx` - 6 cas d'utilisation (Alexandra)

**Social Proof**:
- `BenefitsTable.tsx` - Tableau de statistiques (avant/après)
- `ComparisonTable.tsx` - Comparatif SDR vs VoIPIA
- `TestimonialLouis.tsx` - Témoignage Stefano Design (Louis)
- `TestimonialArthur.tsx` - Témoignage Norloc (Arthur)
- `TestimonialAlexandra.tsx` - Témoignage Stefano Design (Alexandra)

**Pricing & CTA**:
- `PricingLouis.tsx` - Tarification 190€/mois (Louis)
- `PricingArthur.tsx` - Tarification 490€/mois (Arthur)
- `PricingAlexandra.tsx` - Tarification 290€/mois (Alexandra)
- `FAQAccordion.tsx` - FAQ accordion (9 questions par agent)
- `CTAFinalLouis.tsx` - CTA final (Louis)
- `CTAFinalArthur.tsx` - CTA final (Arthur)
- `CTAFinalAlexandra.tsx` - CTA final (Alexandra)

**Home Components**:
- `QualificationQuiz.tsx` - Quiz Home (recommande l'agent adapté)
- `AgentCards.tsx` - Les 3 agents avec cartes cliquables
- `OtherAgents.tsx` - Cross-selling autres agents (sur chaque LP)
- `BundlePricing.tsx` - Pack 3 agents à prix réduit

### Système de Données (`lib/data/`)

- **`agents.ts`** - Données des 3 agents (nom, couleur, description, USP, etc.)
- **`pricing.ts`** - Tarifs et formules (mensuel, annuel, pack)
- **`testimonials.ts`** - Témoignages clients (Stefano Design, Norloc, etc.)
- **`integrations.ts`** - Logos intégrations (Make, Pipedrive, HubSpot, n8n, etc.)
- **`faqs.ts`** - FAQs par agent (9 questions chacun)
- **`useCases.ts`** - Cas d'utilisation par agent (6 chacun)

### Types (`lib/types/`)

- **`landing.ts`** - Types pour les LP :
  - `Agent` - Type d'agent (louis, arthur, alexandra)
  - `HeroSection` - Props du hero
  - `UseCaseCard` - Cas d'utilisation
  - `TestimonialData` - Témoignage client
  - `PricingTier` - Formule tarifaire
  - `FAQItem` - Question FAQ
  - `IntegrationLogo` - Logo intégration

---

## KPIs de Succès

### Conversions

- ✅ **+30-50% taux de conversion** vs landing actuelle
- ✅ **-20% coût d'acquisition client**
- ✅ **Taux de conversion par agent** (tracking séparé)

### SEO

- ✅ **+40% trafic organique** sur 3 mois
- ✅ **Position #1-3** sur requêtes ciblées par agent :
  - Louis : "agent vocal rappel automatique", "IA rappel client"
  - Arthur : "agent vocal réactivation", "IA réactivation BtoB"
  - Alexandra : "agent vocal réception", "IA réception 24/7"
- ✅ **Ranking sur long-tail keywords** spécifiques par industrie

### Technique

- ✅ **Score Lighthouse > 90** (Performance, SEO, Accessibility, Best Practices)
- ✅ **Time to Interactive < 2s**
- ✅ **First Contentful Paint < 1s**
- ✅ **Cumulative Layout Shift < 0.1**
- ✅ **0 erreur console** sur toutes les pages

### Business

- ✅ **Tracking précis par source/agent** (UTM parameters)
- ✅ **ROI publicitaire amélioré de 25%**
- ✅ **Taux de rebond réduit** (-15%)
- ✅ **Durée de session augmentée** (+30%)

---

## Points d'Attention Critiques

### 1. Cohérence de Marque

- Maintenir l'identité visuelle Voipia entre toutes les pages
- Couleurs par agent (Louis bleu, Arthur orange, Alexandra vert)
- Typographie cohérente (Inter variable font)
- Glassmorphism et dark theme uniformes
- Animations similaires (breathing, fade-in-up, glow)

### 2. Performance

- Optimiser images avec `next/image` (formats WebP/AVIF)
- Lazy loading pour images below-the-fold
- Code splitting par route (automatique avec App Router)
- Prefetch des pages agents (liens dans Header)
- Minimiser bundle size (tree-shaking, dynamic imports)

### 3. Mobile-First

- Responsive design parfait sur tous les breakpoints (mobile, tablet, desktop)
- Touch targets suffisants (min 44x44px)
- Navigation mobile intuitive (burger menu)
- Formulaires optimisés pour mobile (input types corrects)
- Performance mobile > 90 (Lighthouse Mobile)

### 4. SEO

- Éviter duplicate content entre les pages
- Meta descriptions uniques par page (155 caractères max)
- Balises H1 uniques et optimisées
- Structured data JSON-LD (Product, FAQPage, BreadcrumbList)
- Canonical URLs définies
- Sitemap.xml et robots.txt à jour

### 5. Maintenance

- Composants réutilisables pour faciliter les mises à jour
- Données centralisées dans `lib/data/` (éviter hardcoding)
- Types TypeScript stricts (éviter `any`)
- Documentation inline pour composants complexes
- Tests unitaires pour composants critiques (quiz, formulaires)

### 6. Accessibilité

- WCAG 2.1 AA compliance
- Contraste des couleurs suffisant (4.5:1 pour texte normal)
- Navigation au clavier fonctionnelle (focus visible)
- ARIA labels pour éléments interactifs
- Alt text descriptif pour toutes les images
- Formulaires avec labels associés

---

## Conventions de Fichiers et Suivi

### Rangement des Fichiers

**IMPORTANT** : Tous les fichiers de cette refonte sont centralisés dans :
```
features/proposition_restructuration_landing/
```

**Structure actuelle** :
```
features/proposition_restructuration_landing/
├── INITIAL/                  # Fichiers de planification des 7 phases
│   ├── INITIAL_refonte_01_fondations.md
│   ├── INITIAL_refonte_02_home.md
│   ├── INITIAL_refonte_03_louis.md
│   ├── INITIAL_refonte_04_arthur.md
│   ├── INITIAL_refonte_05_alexandra.md
│   ├── INITIAL_refonte_06_navigation.md
│   ├── INITIAL_refonte_07_seo_analytics.md
│   └── INITIAL_refonte_OVERVIEW.md
├── PRPs/                     # PRPs générés pour chaque phase
│   ├── refonte-phase-1-fondations.md
│   ├── refonte-phase-2-home.md
│   ├── refonte-phase-3-louis.md
│   ├── refonte-phase-4-arthur.md
│   ├── refonte-phase-5-alexandra.md
│   ├── refonte-phase-6-navigation.md
│   └── refonte-phase-7-seo-analytics.md
├── PROGRESS_REFONTE.md      # Fichier de suivi (MAJ automatique)
├── REFONTE_OVERVIEW.md      # Ce fichier (vue d'ensemble complète)
├── assets/                   # Screenshots, designs, mockups
│   ├── home-mockup.png
│   ├── louis-mockup.png
│   ├── arthur-mockup.png
│   └── alexandra-mockup.png
└── notes/                    # Notes diverses
```

### Fichier de Suivi des Évolutions

Un fichier **`PROGRESS_REFONTE.md`** doit être **mis à jour automatiquement à la fin de chaque PRP exécuté**.

Ce fichier contient :
- Date de complétion de chaque phase
- Composants créés
- Tests effectués (build, visuels, fonctionnels)
- Problèmes rencontrés et solutions
- Liens vers les commits Git
- Captures d'écran de validation

**À la fin de chaque PRP** :
1. Mettre à jour la section de la phase concernée dans `PROGRESS_REFONTE.md`
2. Renseigner : dates, livrables, tests, commit, screenshots, notes
3. Mettre à jour la progression globale (% de phases complétées)

---

## État d'Avancement

**Statut actuel** : 📋 Planification complète
**Prochaine étape** : Phase 1 - Fondations et Architecture
**Suivi** : Consulter `features/proposition_restructuration_landing/PROGRESS_REFONTE.md`

### Pour Démarrer la Refonte

```bash
# 1. Lire le plan de la phase 1
Read features/proposition_restructuration_landing/INITIAL/INITIAL_refonte_01_fondations.md

# 2. Générer le PRP de la phase 1
/generate-prp "Phase 1 : Fondations et Architecture - Structure routing Next.js avec /landingv2, composants réutilisables, système de données"

# 3. Exécuter le PRP
/execute-prp features/proposition_restructuration_landing/PRPs/refonte-phase-1-fondations.md

# 4. Mettre à jour le suivi
# Éditer features/proposition_restructuration_landing/PROGRESS_REFONTE.md avec les résultats
```

---

## Ressources et Références

### Documentation Source

- **LP Louis.txt** : `features/proposition_restructuration_landing/LP Louis.txt`
- **LP Arthur.txt** : `features/proposition_restructuration_landing/LP Arthur.txt`
- **LP Alexandra.txt** : `features/proposition_restructuration_landing/LP Alexandra.txt`
- **Home.txt** : `features/proposition_restructuration_landing/Home.txt`

### Inspirations Design

- **Vercel** : https://vercel.com (dark theme, glassmorphism)
- **Linear** : https://linear.app (animations fluides)
- **Framer** : https://www.framer.com (hero sections)
- **Stripe** : https://stripe.com (pricing tables)

### Outils de Validation

- **Lighthouse** : Chrome DevTools (Performance, SEO, Accessibility)
- **GTmetrix** : https://gtmetrix.com (Performance analysis)
- **Google Search Console** : Indexation et requêtes SEO
- **Google Analytics 4** : Tracking conversions et comportement
- **MCP Playwright** : Tests visuels automatisés

---

## Questions Fréquentes

### Q: Pourquoi développer sur /landingv2 au lieu de remplacer / directement ?

**R**: Pour éviter de casser la landing actuelle pendant le développement. La home actuelle continue de recevoir du trafic et génère des conversions. Une fois la refonte validée (A/B testing, feedback utilisateurs), on migrera `/landingv2` vers `/`.

### Q: Peut-on faire les phases 2, 3, 4, 5 en parallèle ?

**R**: Oui ! Une fois la phase 1 (Fondations) terminée, les phases 2 (Home), 3 (Louis), 4 (Arthur), 5 (Alexandra) sont indépendantes et peuvent être développées en parallèle.

### Q: Que se passe-t-il avec l'ancienne landing après migration ?

**R**: Après validation complète de la refonte :
1. `/landingv2` est migré vers `/` (remplace la home actuelle)
2. La route `/landingv2` est supprimée
3. Redirection 301 si nécessaire (pour liens externes vers ancienne home)
4. Anciens composants archivés dans `backup-landing-old/` (déjà fait)

### Q: Comment gérer les formulaires CTA ?

**R**: Les formulaires CTA (Tester nos agents, Demander une démo) restent centralisés. Chaque page agent a son propre formulaire avec un champ caché `agent_type` pour l'attribution. Les données sont envoyées au même endpoint `/api/contact`.

### Q: Faut-il dupliquer les composants pour chaque agent ou les rendre génériques ?

**R**: **Mixte** :
- **Composants génériques** : `Button`, `Card`, `FAQAccordion`, `IntegrationBar`
- **Composants spécifiques** : `HeroLouis`, `HeroArthur`, `HeroAlexandra` (contenu différent)
- **Raison** : Balance entre réutilisabilité et personnalisation par agent

---

## Contact et Support

Pour toute question sur la refonte :
- **Documentation complète** : `features/proposition_restructuration_landing/`
- **Suivi de progression** : `PROGRESS_REFONTE.md`
- **Architecture générale** : `CLAUDE.md`
