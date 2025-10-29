# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint for code quality

## ⚠️ CRITICAL - Process Management for npm run dev

**IMPORTANT**: Before starting the development server, you MUST follow this process management protocol:

### Pre-Dev Server Checklist

1. **ALWAYS kill existing process on port 3000** before running `npm run dev`:
   ```bash
   # Windows
   netstat -ano | findstr :3000
   taskkill /PID <PID> /F

   # Then start dev server
   npm run dev
   ```

2. **DO NOT touch processes on other ports**:
   - ❌ NEVER kill processes on ports other than 3000
   - ❌ NEVER use `pkill` or `taskkill` without verifying the exact PID
   - ❌ NEVER kill all Node processes (`pkill node` / `taskkill /IM node.exe`)
   - ⚠️ **Risk**: You may kill your own Claude Code process, blocking all further operations

3. **Safe Process Management**:
   - ✅ ONLY target port 3000 specifically
   - ✅ Verify the PID before killing
   - ✅ Use targeted kill commands with explicit PID
   - ✅ Check that port 3000 is free before running `npm run dev`

### Why This Matters

**Problem**: Claude Code may inadvertently kill its own process when trying to free ports, causing a complete system freeze.

**Solution**: Always use precise, port-specific process management and never use broad kill commands.

### Example Workflow

```bash
# 1. Check what's running on port 3000
netstat -ano | findstr :3000

# 2. If a process exists, kill it by PID
taskkill /PID 12345 /F

# 3. Verify port is free
netstat -ano | findstr :3000

# 4. Start dev server
npm run dev
```

**Remember**: One precise kill is better than a hundred broad kills that might take you down.

## UI Verification Workflow

**IMPORTANT**: After making any UI modifications, you MUST:
1. Use the MCP Playwright server to navigate to the site (locally on `http://localhost:3000` or production URL)
2. Take a browser snapshot to verify the visual changes
3. Check that the updates correspond to the expected behavior
4. Test responsive design by resizing the browser window
5. Verify animations and interactions are working correctly

**⚠️ CRITICAL - Screenshot Policy**:
- ❌ **NEVER take full-page screenshots** - They often exceed maximum size limits and block all context
- ✅ **ALWAYS take specific/targeted screenshots** - Screenshot only the specific element or section being modified
- ✅ **Use browser_snapshot instead** - Prefer accessibility snapshots over screenshots when possible
- When using `browser_take_screenshot`, ALWAYS specify `element` and `ref` parameters to target a specific component

This visual verification ensures that all changes are properly rendered and functioning as intended before committing.

## Project Architecture

This is a Voipia landing page built with Next.js 15 App Router, showcasing three AI voice agents (Louis, Arthur, Alexandra). The application uses a component-based architecture with clear separation of concerns.

### Core Structure

- **`app/`** - Next.js App Router structure with layout and main page
- **`components/sections/`** - Main page sections (Hero, AgentsGrid, HowItWorks, etc.)
- **`components/ui/`** - Reusable UI components
- **`components/animations/`** - Framer Motion animation wrappers
- **`lib/`** - Utilities and constants

### Key Components Flow

The main page (`app/page.tsx`) renders sections in order:
1. Navigation - Fixed header with smooth scrolling
2. Hero - Main value proposition with CTA
3. AgentsGrid - Three AI agents with individual capabilities
4. HowItWorks - 3-step process timeline
5. Metrics - Performance statistics with animations
6. DemoSection - Interactive conversation simulation
7. Footer - Contact information and final CTA

### Data Management

Agent data, metrics, and workflow steps are centralized in `lib/constants.ts`. Each agent has:
- Unique color scheme (louis: blue, arthur: orange, alexandra: green)
- Specific capabilities and use cases
- Associated audio demo paths
- Performance statistics

### Design System

**Colors**: Custom color palette with agent-specific colors defined in Tailwind config
**Typography**: Inter variable font with comprehensive size scale
**Animations**: Framer Motion for smooth transitions and micro-interactions

Custom animations include:
- `breathing` - Subtle avatar animation
- `wave` - Audio visualization
- `fade-in-up` - Section entrance animations
- `glow` - Button hover effects

### Technology Stack

- **Next.js 15** with App Router and TypeScript
- **Tailwind CSS** for styling with custom animations
- **Framer Motion** for advanced animations
- **Lucide React** for consistent iconography
- **clsx + tailwind-merge** for conditional styling via `cn()` utility

### Performance Optimizations

- Next.js Image optimization with WebP/AVIF formats
- Inter font loaded with `display: swap`
- Component-based architecture for code splitting
- Comprehensive SEO metadata in layout.tsx

### Styling Conventions

- Uses `cn()` utility for conditional classes
- Follows mobile-first responsive design
- Dark theme as default with purple/violet primary colors
- Gradient backgrounds extensively used for visual appeal
- Consistent spacing using Tailwind's scale

---

## 🚀 REFONTE LANDING PAGE - ARCHITECTURE HOME + 3 LP DÉDIÉES

### Vue d'ensemble

Le site Voipia fait actuellement l'objet d'une **refonte majeure** pour passer d'une page unique à une architecture **Home + 3 Landing Pages dédiées** (une pour chaque agent).

**Objectifs** :
- Améliorer le ciblage et les conversions par agent
- Optimiser le SEO avec des URLs dédiées (`/louis`, `/arthur`, `/alexandra`)
- Faciliter les campagnes publicitaires ciblées
- Améliorer l'attribution et le tracking

**Documentation complète** : `proposition_restructuration_landing/INITIAL/`

---

### Architecture Cible

**⚠️ STRATÉGIE DE DÉVELOPPEMENT** : Pour ne pas impacter la home actuelle, la nouvelle Home sera développée sur `/landingv2` jusqu'à validation complète.

```
/landingv2           → Nouvelle Home (en développement, remplacera / après validation)
/louis               → Landing Page Louis (Rappel automatique)
/arthur              → Landing Page Arthur (Réactivation)
/alexandra           → Landing Page Alexandra (Réception 24/7)
/dashboard           → Dashboard global (existant)
/                    → Home actuelle (ne pas toucher pendant la refonte)
```

**Plan de migration** :
1. Phases 1-7 : Développer sur `/landingv2` + pages agents
2. Validation complète de la refonte
3. Migration : `/landingv2` → `/` (remplace la home actuelle)
4. Nettoyage : Suppression de `/landingv2`

---

### Plan de Refonte en 7 Phases

Le projet est structuré en 7 phases chronologiques documentées dans `proposition_restructuration_landing/INITIAL/` :

#### **Phase 1 : Fondations et Architecture** 🔴 CRITIQUE
- **Fichier** : `INITIAL_refonte_01_fondations.md`
- **Durée** : 2-3 jours
- **Livrables** :
  - Structure de routing Next.js (`app/(marketing)/`)
  - Composants réutilisables (`components/landing/`, `components/shared/`)
  - Système de données centralisé (`lib/data/`)
  - Types TypeScript (`lib/types/landing.ts`)

#### **Phase 2 : Page Home (Restructurée)** 🏠
- **Fichier** : `INITIAL_refonte_02_home.md`
- **Durée** : 3-4 jours
- **Livrables** :
  - Hero repensé
  - Section "Les 3 Agents" avec cartes cliquables
  - Comparatif SDR vs VoIPIA
  - Tarifs, FAQ, développements sur-mesure

#### **Phase 3 : Landing Page Louis** 🔵
- **Fichier** : `INITIAL_refonte_03_louis.md`
- **Durée** : 3-4 jours
- **Source** : `proposition_restructuration_landing/LP Louis.txt`
- **Livrables** :
  - Page `/louis` complète (10 sections)
  - FAQ spécifique (9 questions)
  - Témoignage Stefano Design
  - Tarification 190€/mois

#### **Phase 4 : Landing Page Arthur** 🟠
- **Fichier** : `INITIAL_refonte_04_arthur.md`
- **Durée** : 3-4 jours
- **Source** : `proposition_restructuration_landing/LP Arthur.txt`
- **Livrables** :
  - Page `/arthur` complète (10 sections)
  - FAQ spécifique (9 questions)
  - Témoignage Norloc
  - Tarification 490€/mois

#### **Phase 5 : Landing Page Alexandra** 🟢
- **Fichier** : `INITIAL_refonte_05_alexandra.md`
- **Durée** : 3-4 jours
- **Source** : `proposition_restructuration_landing/LP Alexandra.txt`
- **Livrables** :
  - Page `/alexandra` complète (10 sections)
  - FAQ spécifique (9 questions)
  - Témoignage Stefano Design
  - Tarification 290€/mois

#### **Phase 6 : Navigation et Cross-Selling** 🔗
- **Fichier** : `INITIAL_refonte_06_navigation.md`
- **Durée** : 2-3 jours
- **Livrables** :
  - Header avec dropdown "Solutions"
  - Quiz de qualification sur Home
  - Section "Découvrez nos autres agents" sur chaque LP
  - Bundles tarifaires (Pack Complet)
  - Liens croisés intelligents

#### **Phase 7 : SEO, Analytics et Optimisations** 📈
- **Fichier** : `INITIAL_refonte_07_seo_analytics.md`
- **Durée** : 2 jours
- **Livrables** :
  - Meta descriptions uniques par page
  - Structured data (JSON-LD)
  - Sitemap.xml et robots.txt
  - Google Analytics 4 tracking
  - Performance optimizations (Lighthouse > 90)

---

### Dépendances Entre Phases

```
Phase 1 (Fondations) ← DOIT ÊTRE TERMINÉE EN PREMIER
    ↓
Phase 2 (Home) + Phase 3 (Louis) + Phase 4 (Arthur) + Phase 5 (Alexandra)
    ↓ (peuvent être faites en parallèle)
Phase 6 (Navigation) ← Nécessite que les pages soient créées
    ↓
Phase 7 (SEO/Analytics) ← Finalisation
```

---

### Protocole d'Exécution

Pour chaque phase :

1. **Lire le fichier INITIAL** : `proposition_restructuration_landing/INITIAL/INITIAL_refonte_XX.md`
2. **Générer le PRP** : `/generate-prp "Phase X : [titre de la phase]"`
3. **Review du PRP** : Valider la structure et le contenu
4. **Exécuter le PRP** : `/execute-prp PRPs/refonte-phase-X.md`
5. **Validation** :
   - Tests de build : `npm run build`
   - Tests visuels : MCP Playwright (navigate + snapshot)
   - Tests fonctionnels : CTAs, navigation, responsive
6. **Commit** : Git commit avec message descriptif

---

### Composants Clés à Créer

**Composants Partagés** (`components/shared/`) :
- `Header.tsx` - Header avec dropdown Solutions
- `Footer.tsx` - Footer commun
- `Button.tsx` - Bouton réutilisable avec variants
- `Card.tsx` - Card glassmorphism avec hover effects
- `AudioPlayer.tsx` - Player audio pour démos

**Composants Landing** (`components/landing/`) :
- `Hero[Agent].tsx` - Hero spécifique par agent
- `IntegrationBar.tsx` - Barre logos tech/intégrations
- `HowItWorks[Agent].tsx` - Process en 4 étapes
- `UseCases[Agent].tsx` - 6 cas d'utilisation
- `BenefitsTable.tsx` - Tableau de statistiques
- `ComparisonTable.tsx` - Avant/Après
- `Testimonial[Agent].tsx` - Témoignage client
- `Pricing[Agent].tsx` - Tarification
- `FAQAccordion.tsx` - FAQ accordion
- `CTAFinal[Agent].tsx` - CTA final
- `QualificationQuiz.tsx` - Quiz Home
- `OtherAgents.tsx` - Cross-selling autres agents
- `BundlePricing.tsx` - Pack 3 agents

**Système de Données** (`lib/data/`) :
- `agents.ts` - Données des 3 agents
- `pricing.ts` - Tarifs et formules
- `testimonials.ts` - Témoignages clients
- `integrations.ts` - Logos intégrations
- `faqs.ts` - FAQs par agent

**Types** (`lib/types/`) :
- `landing.ts` - Types pour les LP (Agent, HeroSection, UseCaseCard, etc.)

---

### KPIs de Succès

**Conversions** :
- ✅ +30-50% taux de conversion vs landing actuelle
- ✅ -20% coût d'acquisition client

**SEO** :
- ✅ +40% trafic organique sur 3 mois
- ✅ Position #1-3 sur requêtes ciblées par agent

**Technique** :
- ✅ Score Lighthouse > 90 (Performance, SEO, Accessibility)
- ✅ Time to Interactive < 2s
- ✅ 0 erreur console

**Business** :
- ✅ Tracking précis par source/agent
- ✅ ROI publicitaire amélioré de 25%

---

### Points d'Attention Critiques

1. **Cohérence de marque** : Maintenir l'identité visuelle Voipia entre toutes les pages
2. **Performance** : Optimiser images (next/image), lazy loading, code splitting
3. **Mobile-first** : Responsive design parfait sur tous les breakpoints
4. **SEO** : Éviter duplicate content, meta descriptions uniques
5. **Maintenance** : Composants réutilisables pour faciliter les mises à jour
6. **Accessibilité** : WCAG 2.1 AA compliance

---

### Conventions de Fichiers et Suivi

#### Rangement des Fichiers

**IMPORTANT** : Tous les nouveaux fichiers créés pendant la refonte (PRPs, documentation, notes) doivent être rangés dans :
```
C:\Users\pc\Documents\Projets\voipia-landing\proposition_restructuration_landing\
```

**Structure recommandée** :
```
proposition_restructuration_landing/
├── INITIAL/                  # Fichiers de planification
├── PRPs/                     # PRPs générés pour chaque phase
├── PROGRESS_REFONTE.md      # Fichier de suivi (MAJ automatique)
├── assets/                   # Screenshots, designs, mockups
└── notes/                    # Notes diverses
```

#### Fichier de Suivi des Évolutions

Un fichier **`PROGRESS_REFONTE.md`** doit être **mis à jour automatiquement à la fin de chaque PRP exécuté**.

Ce fichier contient :
- Date de complétion de chaque phase
- Composants créés
- Tests effectués
- Problèmes rencontrés et solutions
- Liens vers les commits Git
- Captures d'écran de validation

**À la fin de chaque PRP** :
1. Mettre à jour la section de la phase concernée dans `PROGRESS_REFONTE.md`
2. Renseigner : dates, livrables, tests, commit, screenshots, notes
3. Mettre à jour la progression globale (% de phases complétées)

---

### État d'Avancement

**Statut actuel** : 📋 Planification complète
**Prochaine étape** : Phase 1 - Fondations
**Suivi** : Consulter `proposition_restructuration_landing/PROGRESS_REFONTE.md`

Pour démarrer la refonte :
```bash
# 1. Lire le plan de la phase 1
cat proposition_restructuration_landing/INITIAL/INITIAL_refonte_01_fondations.md

# 2. Générer le PRP de la phase 1
/generate-prp "Phase 1 : Fondations et Architecture - Structure routing Next.js avec /landingv2, composants réutilisables, système de données"

# 3. Exécuter le PRP
/execute-prp proposition_restructuration_landing/PRPs/refonte-phase-1-fondations.md

# 4. Mettre à jour le suivi
# Éditer proposition_restructuration_landing/PROGRESS_REFONTE.md avec les résultats
```

---

## PRP (Product Requirements Proposal) System

This project uses a PRP system for planning and implementing features with comprehensive context and validation loops.

### Quick Commands

- **`/generate-prp "feature description"`** - Generate a comprehensive PRP for a new feature
- **`/execute-prp PRPs/feature-name.md`** - Execute an existing PRP with full validation

### PRP Workflow

#### 1. Creating a PRP
When planning a new feature:
1. Use `/generate-prp "your feature description"` OR
2. Manually use the base template at `PRPs/templates/prp_base.md`
3. Fill in all sections with specific details about the feature
4. Include all necessary context, references, and validation steps
5. Save the PRP in the `PRPs/` directory with a descriptive name

#### 2. PRP Structure
- **Goal**: Clear definition of what needs to be built
- **Context**: All documentation, files, and references needed
- **Implementation Blueprint**: Step-by-step plan with pseudocode
- **Validation Loops**: Commands to verify the implementation
- **Anti-patterns**: Common mistakes to avoid

#### 3. Using PRPs

**Method 1: Automated Commands**
1. Generate: `/generate-prp "Add testimonials section with carousel"`
2. Execute: `/execute-prp PRPs/testimonials-section.md`

**Method 2: Manual Process**
1. **Planning Phase**: Create a PRP document for complex features
2. **Implementation**: Follow the PRP's task breakdown and pseudocode
3. **Validation**: Run all commands in the validation loops section
4. **Iteration**: Fix issues based on validation results

#### 4. Example PRPs
- See `PRPs/EXAMPLE_testimonials_section.md` for a complete feature PRP
- Reference `INITIAL.md` for overall project context and requirements

### PRP Best Practices
- Include ALL necessary context upfront
- Define clear success criteria with measurable outcomes
- Provide executable validation commands
- Reference existing code patterns and components
- Always verify UI changes with browser snapshots
- Run lint and build checks as part of validation

### Directory Structure
```
PRPs/
├── templates/
│   └── prp_base.md         # Base template for new PRPs
├── ai_docs/                # Additional documentation for AI context
└── [feature-name].md       # Individual feature PRPs

.claude/
└── commands/
    ├── generate-prp.md     # Command to generate new PRPs
    └── execute-prp.md      # Command to execute PRPs
```

### Command Examples

```bash
# Generate a new PRP for a pricing section
/generate-prp "Add a pricing section with three tiers for each agent"

# Execute an existing PRP
/execute-prp PRPs/pricing-section.md

# Generate and execute in sequence
/generate-prp "Add FAQ section with collapsible questions"
/execute-prp PRPs/faq-section.md
```

This system ensures consistent, high-quality implementations with proper context and validation at every step.

---

## Backend & Database Architecture

### Supabase Database

**IMPORTANT**: The project uses **Supabase** as the primary database and backend.

#### Database Access & Permissions

- ✅ **READ ACCESS**: You have full read access via MCP Supabase server
- ❌ **WRITE ACCESS**: You do NOT have write permissions to modify the database directly
- 🔧 **Migrations**: All schema changes must be done via SQL migration files that the user executes manually

**Available MCP Servers**:
- `mcp__supabase-voipia__*` - Full suite of Supabase tools (queries, docs, migrations, etc.)
- Use these servers to inspect database structure, query data, and generate migrations

#### Core Database Tables

**`agent_calls`** - Main table storing all call data
- `id` (UUID) - Primary key
- `deployment_id` (UUID) - Links to agent_deployments
- `started_at` (timestamp) - Call start time
- `outcome` (text) - Call result (lowercase: 'appointment_scheduled', 'voicemail', 'appointment_refused', etc.)
- `duration_seconds` (numeric) - Call duration
- `cost` (numeric) - Call cost in EUR
- `metadata` (jsonb) - Additional call metadata
- `first_name`, `last_name`, `phone_number`, `email` - Contact info
- `emotion` (text) - Detected emotion ('positive', 'neutral', 'negative', 'unknown')

**`agent_deployments`** - Agent instances deployed for clients
- `id` (UUID) - Primary key
- `name` (text) - Deployment name
- `slug` (text) - URL-friendly identifier
- `client_id` (UUID) - Links to clients table
- `agent_type_id` (UUID) - Links to agent_types table
- `status` (text) - 'active', 'paused', or 'archived'

**`agent_types`** - Types of AI agents
- `id` (UUID) - Primary key
- `name` (text) - 'louis', 'arthur', 'alexandra'
- `display_name` (text) - 'Louis', 'Arthur', 'Alexandra'
- `status` (text) - 'active' or 'inactive'

**`clients`** - Customer companies
- `id` (UUID) - Primary key
- `name` (text) - Company name
- `industry` (text) - Industry sector

**`user_client_permissions`** - RLS permissions mapping
- Links users to clients they can access
- `permission_level` - 'read', 'write', or 'admin'

#### Enriched Views

**`v_agent_calls_enriched`** - Main view with calculated fields
```sql
-- Calculated columns:
- answered (boolean) - Call was answered (NOT voicemail/error)
- appointment_scheduled (boolean) - RDV was scheduled

-- Logic:
answered = outcome NOT IN ('voicemail', 'call_failed', 'no_answer', 'busy', ...) AND outcome IS NOT NULL
appointment_scheduled = outcome = 'appointment_scheduled'  -- ONLY based on outcome!
```

**CRITICAL**: Do NOT use `metadata ? 'appointment_scheduled_at'` - this checks if the KEY exists, not if it has a value! This caused the bug where 118 voicemail calls were counted as RDV instead of the real 13.

**`v_user_accessible_clients`** - Clients accessible by authenticated user (RLS)
**`v_user_accessible_agents`** - Agent deployments accessible by authenticated user (RLS)

#### RPC Functions

**`get_kpi_metrics(p_start_date, p_end_date, p_client_id, p_deployment_id, p_agent_type_name)`**
- Returns KPI metrics with current vs previous period comparison
- **MUST include p_agent_type_name** ('louis' or 'arthur') to filter by agent type
- Returns: total_calls, answered_calls, appointments_scheduled, answer_rate, conversion_rate, etc.

**`get_chart_data(p_start_date, p_end_date, p_client_id, p_deployment_id, p_agent_type_name)`**
- Returns chart data (call_volume_by_day, outcome_distribution, emotion_distribution, voicemail_by_agent)
- **MUST include p_agent_type_name** to avoid mixing Louis and Arthur data

**`get_agent_type_cards_data(p_start_date, p_end_date, p_client_ids)`**
- Aggregates metrics by agent TYPE (one card for all Louis, one for all Arthur)
- Used in Global Dashboard

**`get_client_cards_data(p_start_date, p_end_date)`**
- Aggregates metrics by CLIENT (one card per company)
- Used in Global Dashboard

#### KPI Calculations (CORRECTED)

**Critical Formulas**:
```
Total Calls = COUNT(*)
Answered Calls = COUNT(*) WHERE answered = true
RDV Pris = COUNT(*) WHERE appointment_scheduled = true

Answer Rate = (answered_calls / total_calls) × 100
Conversion Rate = (appointments / ANSWERED_calls) × 100  ← NOT total_calls!
Acceptance Rate = appointments / (appointments + refused) × 100
Average Duration = AVG(duration_seconds) WHERE duration_seconds > 0
Cost per Appointment = total_cost / appointments
```

**Common Pitfalls to Avoid**:
- ❌ Using `metadata ? 'key'` to check values (checks existence, not value)
- ❌ Dividing appointments by total_calls for conversion rate (gives >100%)
- ❌ Forgetting to filter by agent_type_name (mixes Louis + Arthur data)
- ❌ Treating voicemail as "answered" (outcome must NOT be in not-answered list)

---

## Dashboard Architecture

### Dashboard Types

**Global Dashboard** (`/dashboard`)
- Shows overview of ALL accessible agents and clients
- Two-column layout: Agent Type Cards (left) + Client Cards (right)
- Agent Type Cards aggregate ALL deployments of same type (e.g., all Louis together)
- Clickable cards navigate to specific dashboards

**Louis Dashboard** (`/dashboard/louis`)
- Shows ONLY Louis agent data
- KPIs: Total Calls, Taux de Décroché, Durée Moyenne, RDV Pris, Taux de Conversion
- Charts: Call Volume by Day, Emotion Distribution, Outcome Breakdown, Voicemail by Agent
- Must pass `p_agent_type_name: 'louis'` to all RPC calls

**Arthur Dashboard** (`/dashboard/arthur`)
- Shows ONLY Arthur agent data (prospecting/reactivation)
- Uses separate functions: `get_arthur_kpi_metrics`, `get_arthur_chart_data`
- Arthur-specific KPIs: Appointments Scheduled, Reactivation Rate, Cost per Conversion, etc.

### Dashboard Filters

All dashboards support:
- **Date Range**: Start date to end date
- **Client**: Filter by specific company (optional)
- **Agent**: Filter by specific deployment (optional)

**Agent Filter Behavior**:
- Shows ALL agents of the dashboard's type that the user has access to
- Format: "Deployment Name - Client Name"
- Properly deduplicated to avoid React duplicate key errors

### Dashboard Data Flow

```
User → Dashboard Component
    ↓
useDashboardFilters() - URL-based filters
    ↓
useLouisKPIs(filters) / useLouisChartData(filters)
    ↓
fetchLouisKPIMetrics(filters) / fetchLouisChartData(filters)
    ↓
supabase.rpc('get_kpi_metrics', {
  ...filters,
  p_agent_type_name: 'louis'  ← CRITICAL: Filters by agent type
})
    ↓
Supabase RPC Function (with RLS)
    ↓
v_agent_calls_enriched view
    ↓
agent_calls table (filtered by deployment_id → agent_type)
```

### Dashboard Expectations

**User Expectations**:
1. **Accurate KPIs**: Numbers must match real data in agent_calls table
2. **Agent Separation**: Louis dashboard shows ONLY Louis, never Arthur
3. **Real-time Filters**: Changing date/client/agent filters updates all data
4. **No Mixed Data**: Each dashboard is isolated by agent type
5. **Logical Values**: Conversion rate ≤ 100%, RDV ≤ Answered Calls, etc.

**Design Expectations**:
- Dark theme with glassmorphism cards
- Responsive layout (mobile-first)
- Smooth transitions and loading states
- Charts fill container height properly
- No scroll on desktop (2x2 grid for charts)

---

## Workflows & Automation

### n8n Workflows

**IMPORTANT**: The AI agents (Louis, Arthur, Alexandra) are orchestrated via **n8n workflows**.

- n8n handles the execution logic for agent calls
- Workflows trigger agent deployments based on schedules or events
- Call results are written to `agent_calls` table
- You have access to n8n via MCP server: `mcp__n8n-voipia__*`

**Available n8n MCP Tools**:
- List workflows
- Get workflow details
- View execution history
- Run webhooks
- Cannot directly modify workflows (read-only for safety)

### Agent Deployment Architecture

```
Client (Voipia, Norloc, etc.)
    ↓
agent_deployments (multiple instances per client)
    ↓
agent_types (louis, arthur, alexandra)
    ↓
n8n workflows (orchestration)
    ↓
agent_calls (results stored in Supabase)
```

---

## Migration Management

### Creating Migrations

**CRITICAL RULES**:
1. ✅ **Always create migration files** - Never ask user to run SQL directly
2. ✅ **Use descriptive filenames** - Format: `YYYYMMDD_description.sql`
3. ✅ **Include DROP IF EXISTS** - Prevent "function is not unique" errors
4. ✅ **Add comments** - Explain what changed and why
5. ✅ **Test queries** - Include verification queries at the bottom

**Migration Template**:
```sql
-- Migration: [Description]
-- Date: YYYY-MM-DD
-- Author: Claude
--
-- Changes:
-- 1. What was changed
-- 2. Why it was changed
-- 3. Expected impact

-- Drop existing functions/views if they exist
DROP FUNCTION IF EXISTS function_name(arg_types);
DROP VIEW IF EXISTS view_name;

-- Create/replace objects
CREATE OR REPLACE VIEW view_name AS ...
CREATE FUNCTION function_name(...) ...

-- Grant permissions
GRANT SELECT ON view_name TO authenticated;
GRANT EXECUTE ON FUNCTION function_name(...) TO authenticated;

-- Verification queries (commented out)
-- SELECT * FROM view_name LIMIT 10;
```

### Migration Best Practices

**Order of Execution**:
1. Views first (they don't affect data)
2. Functions second (they use views)
3. Test with verification queries

**Before Creating Migrations**:
- Understand the current schema (use MCP Supabase tools)
- Check existing views and functions
- Identify dependencies (functions using views, etc.)
- Consider RLS policies

**Common Migration Scenarios**:
- Adding calculated columns → Create/update view
- Changing KPI logic → Update RPC function
- New dashboard → Create new RPC functions
- Performance issues → Add indexes

---

## Known Issues & Solutions

### Bug: RDV Count Incorrect (SOLVED)

**Problem**: Dashboard showed 118 RDV instead of 13
**Cause**: `metadata ? 'appointment_scheduled_at'` checks if KEY exists, not value
**Solution**: Use only `outcome = 'appointment_scheduled'`
**Reference**: See `EXPLICATION_BUG_118_RDV.md`

### Bug: Conversion Rate > 100% (SOLVED)

**Problem**: Conversion rate showing 200%+
**Cause**: Formula was `appointments / total_calls` instead of `appointments / answered_calls`
**Solution**: Always divide by answered_calls, not total_calls
**Reference**: See migrations `20250120_fix_kpi_logic_v2.sql`

### Bug: Louis Dashboard Shows Arthur Data (SOLVED)

**Problem**: Dashboard Louis displayed Arthur agent data
**Cause**: RPC functions didn't filter by agent_type_name
**Solution**: Added `p_agent_type_name` parameter to all RPC functions
**Reference**: Migration `20250120_add_agent_type_filter_to_kpi_functions.sql`

### Bug: Duplicate Keys in Filters (SOLVED)

**Problem**: React errors about duplicate keys in ClientAgentFilter
**Cause**: Database views returning duplicate rows
**Solution**: Deduplicate arrays in frontend using reduce()
**Reference**: `components/dashboard/Filters/ClientAgentFilter.tsx`

---

## Development Workflow

### Making Dashboard Changes

1. **Understand current data** - Query database via MCP Supabase
2. **Identify requirements** - What KPIs/charts are needed?
3. **Design SQL logic** - Create views/functions if needed
4. **Create migration** - Write SQL migration file
5. **Update frontend** - Modify React components
6. **Verify with browser** - Use MCP Playwright to test
7. **User executes migration** - User runs SQL in Supabase

### Testing Dashboard Changes

```bash
# 1. Run dev server
npm run dev

# 2. Navigate to dashboard
Use MCP Playwright: mcp__playwright__browser_navigate
URL: http://localhost:3000/dashboard/louis

# 3. Take snapshot
Use: mcp__playwright__browser_snapshot

# 4. Verify data
Check KPIs match expected values from database queries

# 5. Test filters
Change date range, client, agent - verify data updates
```

### Common Tasks

**Add new KPI**:
1. Update RPC function to calculate new metric
2. Update TypeScript types in `lib/types/dashboard.ts`
3. Update frontend component to display KPI
4. Create migration file for SQL changes

**Fix KPI calculation**:
1. Query database to understand current logic
2. Update view or RPC function
3. Create migration with corrected formula
4. Test with verification queries

**Add new chart**:
1. Update `get_chart_data` RPC function
2. Create chart component in `components/dashboard/Charts/`
3. Add chart to dashboard layout
4. Update ChartData type

---

## Quick Reference

### Essential File Locations

**Dashboard Code**:
- `app/dashboard/page.tsx` - Global Dashboard
- `app/dashboard/[agentType]/page.tsx` - Dynamic route (louis, arthur)
- `app/dashboard/[agentType]/LouisDashboardClient.tsx` - Louis dashboard
- `app/dashboard/[agentType]/ArthurDashboardClient.tsx` - Arthur dashboard

**Data Queries**:
- `lib/queries/louis.ts` - Louis-specific queries
- `lib/queries/arthur.ts` - Arthur-specific queries
- `lib/queries/global.ts` - Global dashboard queries
- `lib/hooks/useDashboardData.ts` - React Query hooks

**Types**:
- `lib/types/dashboard.ts` - Dashboard TypeScript types

**Components**:
- `components/dashboard/` - Dashboard-specific components
- `components/dashboard/Charts/` - Chart components
- `components/dashboard/Cards/` - Card components
- `components/dashboard/Filters/` - Filter components

**Migrations**:
- `supabase/migrations/*.sql` - Database migration files

### Key Constants

**Agent Types**: `'louis'`, `'arthur'`, `'alexandra'`

**Outcomes** (lowercase):
- `'appointment_scheduled'` - RDV pris
- `'appointment_refused'` - RDV refusé
- `'voicemail'` - Messagerie
- `'not_interested'` - Pas intéressé
- `'callback_requested'` - Rappel demandé
- `'too_short'` - Appel trop court
- `'call_failed'` - Échec d'appel

**Deployment Status**: `'active'`, `'paused'`, `'archived'`

**Permission Levels**: `'read'`, `'write'`, `'admin'`

This system ensures consistent, high-quality implementations with proper context and validation at every step.