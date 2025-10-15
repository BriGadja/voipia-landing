# INITIAL_DASHBOARD.md - Dashboard Analytics Voipia

## 🎯 Feature Overview

Je souhaite implémenter un **dashboard analytics professionnel** pour visualiser et analyser les données des appels passés par les agents vocaux IA de Voipia. Ce dashboard permettra aux clients et aux utilisateurs internes de suivre les performances de leurs agents, analyser les tendances, et prendre des décisions data-driven.

### Objectif Business
- **Transparence** : Permettre aux clients de suivre en temps réel les performances de leurs agents
- **Insights actionables** : Identifier les opportunités d'optimisation et les points de friction
- **ROI démontré** : Prouver la valeur des agents vocaux avec des métriques concrètes
- **Rétention client** : Augmenter l'engagement via un outil de suivi professionnel
- **Multi-tenant** : Support de plusieurs clients avec isolation des données

### Emplacement dans le site
Cette fonctionnalité sera accessible depuis :
1. Une **nouvelle route** `/dashboard` avec authentification requise
2. Un **lien dans la navigation** principale (pour les utilisateurs connectés)
3. Possibilité de **deep-linking** vers des vues spécifiques (client, date, agent)

---

## 📋 Functional Requirements

### 1. Architecture des Données

#### 1.1 Schema Database Existant

**Tables actuelles** :
- `clients` (4 clients) : id, name, industry, webhook_url, created_at, updated_at
- `calls` (117 appels) : id, client_id, first_name, last_name, email, phone, started_at, duration_seconds, cost, emotion, appointment_scheduled_at, transcript, transcript_summary, metadata, call_outcome

**Tables à créer** :
- `agents` : Nouvelle table pour gérer les agents individuels par client
- `tenants` : Système multi-tenant pour isolation complète (optionnel selon le modèle business)
- `user_client_permissions` : Permissions granulaires (qui peut voir quels clients)

#### 1.2 Extensions Requises

**Colonnes à ajouter sur `calls`** :
- `agent_id` : UUID référence vers la table agents
- `tenant_id` : UUID pour multi-tenant (optionnel)

**Indexes Critiques** :
- BRIN index sur `started_at` (99% plus léger que B-tree pour time-series)
- Composite index `(client_id, started_at DESC)`
- Composite index `(agent_id, started_at DESC)`
- Index sur `call_outcome`
- Index sur `tenant_id` pour RLS

**Materialized Views** :
- `daily_call_metrics` : Agrégations quotidiennes pré-calculées
- Refresh automatique toutes les 15-60 minutes

### 2. Métriques Prioritaires (KPIs)

#### 2.1 KPI Cards (Top Priority)

**1. RDV Pris** :
- Valeur : COUNT(*) WHERE appointment_scheduled_at IS NOT NULL
- Delta : Comparaison période précédente (%)
- Sparkline : Tendance sur les 7 derniers jours
- Format : Nombre entier

**2. Taux de Décroché** :
- Valeur : (COUNT(*) WHERE call_outcome = 'answered') / COUNT(*) total
- Delta : Comparaison période précédente (%)
- Format : Pourcentage (XX.X%)

**3. Durée Moyenne d'Appel** :
- Valeur : AVG(duration_seconds)
- Format : MM:SS (ex: 03:24)
- Delta : Comparaison période précédente

**4. Coût Moyen par Appel** :
- Valeur : AVG(cost)
- Format : X.XX€
- Delta : Comparaison période précédente

**5. Taux de Conversion** :
- Valeur : RDV Pris / Appels répondus
- Format : Pourcentage
- Badge : Vert si > 10%, Amber si 5-10%, Rouge si < 5%

**6. Coût par Acquisition (CPA)** :
- Valeur : SUM(cost) / COUNT(*) WHERE appointment_scheduled_at IS NOT NULL
- Format : XX.XX€
- Indicateur : Plus bas = meilleur

**7. ROI Estimé** :
- Calcul : (Valeur des conversions - Coût total) / Coût total × 100
- Nécessite : Configuration de la valeur moyenne d'une conversion par client
- Format : +XX% ou -XX%

#### 2.2 Charts Principaux

**Chart 1 - Volume d'appels par jour** :
- Type : AreaChart (Tremor)
- Axe X : Date
- Axe Y : Nombre d'appels
- Catégories : Total appels, Appels répondus, RDV pris
- Couleurs : Bleu, Vert, Violet
- Granularité : Par jour, semaine, ou mois selon la plage

**Chart 2 - Distribution des émotions** :
- Type : DonutChart (Tremor)
- Données : COUNT(*) GROUP BY emotion
- Catégories : Positive, Neutre, Négative
- Couleurs : Vert, Amber, Rouge
- Format : Pourcentages + nombres absolus

**Chart 3 - Call Outcomes (Résultats d'appels)** :
- Type : BarChart (Tremor)
- Données : COUNT(*) GROUP BY call_outcome
- Catégories : appointment_scheduled, appointment_refused, not_interested, callback_requested, voicemail, no_answer, etc.
- Tri : Par volume décroissant
- Couleurs : Palette professionnelle

**Chart 4 - Évolution temporelle par client** :
- Type : LineChart (Tremor)
- Axe X : Date
- Axe Y : Métriques au choix (appels, RDV, coût)
- Multi-séries : Une ligne par client/agent
- Légende : Interactive

**Chart 5 - Taux de messagerie par agent** :
- Type : BarChart horizontal
- Données : Pourcentage de voicemail par agent
- Tri : Du plus élevé au plus bas
- Couleur : Gradient selon le taux

**Chart 6 - Performance par période** :
- Type : Heatmap ou Calendar view (nice-to-have)
- Affichage : Jours de la semaine × Heures
- Couleur : Intensité = volume d'appels

### 3. Filtres Interactifs

#### 3.1 Filtre Temporel

**Composant** : react-datepicker avec presets
- **Date de début** : Date picker
- **Date de fin** : Date picker
- **Validation** : Date fin >= Date début

**Presets rapides** :
- Aujourd'hui
- 7 derniers jours (défaut)
- 30 derniers jours
- Ce mois
- Mois dernier
- Cette année

**Comportement** :
- Synchronisation temps réel avec tous les charts
- Stockage dans URL (query params) pour partage
- Validation : Max 1 an de données à la fois (performance)

#### 3.2 Filtre Client/Agent

**Sélection Client** :
- Dropdown multi-select (ou single selon permissions)
- Affichage : Nom du client
- Valeur par défaut : "Tous les clients" (si permission admin)
- Icône : Badge avec nombre de clients sélectionnés

**Sélection Agent** :
- Dropdown cascading (dépend du client sélectionné)
- Désactivé si aucun client sélectionné
- Reset automatique lors du changement de client
- Affichage : Nom de l'agent + client parent

**Logic** :
```typescript
// Si client change → reset agent selection
useEffect(() => {
  if (selectedClients.length > 0 && agents) {
    const validAgentIds = agents
      .filter(a => selectedClients.includes(a.client_id))
      .map(a => a.id)
    setSelectedAgents(prev => prev.filter(id => validAgentIds.includes(id)))
  }
}, [selectedClients, agents])
```

#### 3.3 Export de Données

**Format CSV** :
- Export des données filtrées actuelles
- Colonnes : Date, Client, Agent, Durée, Coût, Outcome, Émotion, RDV
- Encodage : UTF-8 avec BOM (compatibilité Excel)
- Nom de fichier : `voipia-calls-export-YYYY-MM-DD.csv`

**Format JSON** (pour intégrations) :
- Structure complète avec métadonnées
- Include filtres appliqués
- Format ISO pour les dates

### 4. Authentification et Sécurité

#### 4.1 Row Level Security (RLS)

**Isolation par Tenant** :
- Chaque query est automatiquement filtrée par `tenant_id`
- Extrait du JWT via `auth.tenant_id()`
- Policy PostgreSQL appliquée database-level

**Permissions Granulaires** :
- Admins : Voient tous les clients du tenant
- Users : Voient uniquement leurs clients assignés
- Table `user_client_permissions` pour mapping

**Exemple de Policy** :
```sql
CREATE POLICY "user_client_access"
ON calls
FOR SELECT
TO authenticated
USING (
  (SELECT auth.tenant_id()) = tenant_id
  AND (
    -- Admins voient tout
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
      AND tenant_id = (SELECT auth.tenant_id())
    )
    OR
    -- Users voient leurs clients assignés
    client_id IN (
      SELECT client_id FROM user_client_permissions
      WHERE user_id = auth.uid()
    )
  )
);
```

#### 4.2 Middleware Next.js 15

**Protection de route** :
- Middleware sur `/dashboard/*`
- Vérification avec `supabase.auth.getUser()` (pas getSession)
- Refresh automatique des tokens
- Redirection vers `/login` si non authentifié

**Pattern** :
```typescript
// middleware.ts
export async function middleware(request: NextRequest) {
  const supabase = createServerClient(...)
  const { data: { user } } = await supabase.auth.getUser()

  if (!user && !request.nextUrl.pathname.startsWith('/login')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return response
}

export const config = {
  matcher: ['/dashboard/:path*']
}
```

---

## 🎨 UI/UX Requirements

### Design System Integration

**Stack UI Recommandée** :
- **Tremor** : Composants analytics (charts, KPI cards, sparklines)
  - 35+ composants dashboard-ready
  - Intégration Tailwind native
  - TypeScript first-class
  - Bundle ~150kb
- **shadcn/ui** : Composants de base (buttons, inputs, dialogs, dropdowns)
- **TanStack Query** : Gestion de données, polling, cache
- **date-fns** : Manipulation de dates (léger, tree-shakable)
- **react-datepicker** : Sélecteur de dates avec presets

### Layout Structure

```
┌─────────────────────────────────────────────────┐
│  Navigation (avec lien Dashboard)                │
├─────────────────────────────────────────────────┤
│                                                  │
│  [Filtres: Dates | Clients | Agents] [Export]  │
│                                                  │
├─────────────────────────────────────────────────┤
│  KPI Cards (Grid 4 colonnes)                    │
│  [RDV] [Décroché] [Durée] [Coût]               │
│  [Conversion] [CPA] [ROI]                       │
├─────────────────────────────────────────────────┤
│  Charts Principaux (Grid 2 colonnes)            │
│  [Volume d'appels]    [Émotions]               │
├─────────────────────────────────────────────────┤
│  Charts Secondaires (Grid 2 colonnes)           │
│  [Call Outcomes]      [Messagerie par agent]    │
├─────────────────────────────────────────────────┤
│  Table détaillée (optionnelle)                   │
│  [Liste des appels avec pagination]             │
└─────────────────────────────────────────────────┘
```

### Palette de Couleurs

**Cohérence avec le site Voipia** :
- Primary : #3b82f6 (Bleu)
- Success : #10b981 (Vert - positif)
- Warning : #f59e0b (Ambre - attention)
- Danger : #ef4444 (Rouge - négatif)
- Info : #06b6d4 (Cyan)

**Charts** :
- chart-1 : #3b82f6 (Bleu)
- chart-2 : #10b981 (Vert)
- chart-3 : #f59e0b (Ambre)
- chart-4 : #8b5cf6 (Violet)
- chart-5 : #ec4899 (Rose)

### Animations

**Framer Motion** :
- Fade-in des KPI cards (stagger 50ms)
- Skeleton loaders pendant le chargement
- Transitions fluides lors du changement de filtres
- Animations des charts (Tremor inclut déjà)

### Responsive Design

**Breakpoints** :
- Mobile (< 768px) : 1 colonne, charts empilés, filtres en modal
- Tablet (768px - 1024px) : 2 colonnes pour KPI, charts 1-2 colonnes
- Desktop (> 1024px) : Layout complet 4 colonnes

---

## 🔧 Technical Architecture

### Stack Complète

**Frontend** :
- Next.js 15 (App Router) ✅ Déjà en place
- React 19 ✅ Déjà en place
- TypeScript ✅ Déjà en place
- Tailwind CSS ✅ Déjà en place
- Framer Motion ✅ Déjà en place

**À installer** :
```bash
npm install @tremor/react
npm install @tanstack/react-query @tanstack/react-query-devtools
npm install react-datepicker date-fns
npm install -D @types/react-datepicker

# shadcn/ui components
npx shadcn@latest init
npx shadcn@latest add card button skeleton dialog dropdown-menu select
```

**Backend/Data** :
- Supabase PostgreSQL ✅ Déjà configuré
- Supabase Auth (à configurer)
- @supabase/ssr (pour Next.js 15)

### Architecture Next.js 15

**Pattern Server/Client Components** :

**Server Component** (`app/dashboard/page.tsx`) :
- Fetch initial data côté serveur
- Optimise LCP (Largest Contentful Paint)
- SEO-friendly
- Parallel data fetching avec Promise.all

**Client Component** (`app/dashboard/DashboardClient.tsx`) :
- Gère interactivité (filtres, charts)
- TanStack Query pour polling horaire
- State management local
- Animations Framer Motion

**Exemple d'architecture** :
```typescript
// app/dashboard/page.tsx (Server Component)
export default async function DashboardPage({ searchParams }) {
  const params = await searchParams
  const supabase = await createClient()

  const [kpiData, chartData] = await Promise.all([
    supabase.rpc('get_kpi_metrics', { start_date, end_date, client_id }),
    supabase.rpc('get_chart_data', { start_date, end_date, client_id })
  ])

  return <DashboardClient kpiData={kpiData} chartData={chartData} />
}
```

### Polling & Data Refresh

**TanStack Query Configuration** :
- **Refresh horaire** : refetchInterval: 3600000 (1 heure)
- **Stale time** : 1 heure (data considérée fraîche)
- **Cache time** : 1 heure (garde en cache)
- **DevTools** : Activés en dev pour debugging

**Avantages vs Supabase Realtime** :
- Pas de WebSocket (économie batterie mobile)
- Moins coûteux en infrastructure
- Suffisant pour analytics (pas de real-time nécessaire)
- Meilleure gestion du cache et erreurs

### Performance Optimizations

**BRIN Indexes** :
- Sur `started_at` : 99% plus léger que B-tree
- 15% plus rapide pour time-series queries
- Configuration : `pages_per_range = 128`

**Materialized Views** :
- Pré-calcul des métriques quotidiennes
- Refresh toutes les 15-60 minutes
- Évite recalcul à chaque requête

**Lazy Loading** :
- Charts chargés après KPI cards
- Dynamic imports pour réduire bundle initial
- Améliore LCP de 40-60%

**Code Splitting** :
```typescript
import dynamic from 'next/dynamic'

const CallVolumeChart = dynamic(() => import('./CallVolumeChart'), {
  loading: () => <Skeleton height={400} />,
  ssr: false
})
```

---

## 📊 Database Schema Extensions

### Tables à Créer

#### 1. Table `agents`
```sql
CREATE TABLE agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT, -- 'inbound' ou 'outbound'
  status TEXT DEFAULT 'active', -- 'active', 'inactive', 'archived'
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_agents_client_id ON agents(client_id);
```

#### 2. Table `user_client_permissions` (optionnel)
```sql
CREATE TABLE user_client_permissions (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE NOT NULL,
  permission_level TEXT NOT NULL DEFAULT 'read', -- 'read', 'write', 'admin'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, client_id)
);
```

### Modifications de `calls`

```sql
-- Ajouter agent_id si pas déjà présent
ALTER TABLE calls ADD COLUMN IF NOT EXISTS agent_id UUID REFERENCES agents(id) ON DELETE SET NULL;

-- Ajouter index
CREATE INDEX IF NOT EXISTS idx_calls_agent_id ON calls(agent_id);
```

### Indexes Critiques

```sql
-- BRIN index pour started_at (optimal pour time-series)
CREATE INDEX idx_calls_started_at_brin
ON calls USING BRIN (started_at)
WITH (pages_per_range = 128);

-- Composite indexes pour filtres fréquents
CREATE INDEX idx_calls_client_started ON calls (client_id, started_at DESC);
CREATE INDEX idx_calls_agent_started ON calls (agent_id, started_at DESC);
CREATE INDEX idx_calls_client_agent_started ON calls (client_id, agent_id, started_at DESC);

-- Index pour filtrage par call_outcome
CREATE INDEX idx_calls_outcome ON calls (call_outcome) WHERE call_outcome IS NOT NULL;
```

### Materialized View

```sql
-- Vue matérialisée pour métriques quotidiennes
CREATE MATERIALIZED VIEW daily_call_metrics AS
SELECT
  client_id,
  agent_id,
  DATE(started_at) as metric_date,

  -- Métriques prioritaires
  COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL) as appointments_scheduled,
  COUNT(*) FILTER (WHERE call_outcome = 'voicemail') as voicemail_count,
  COUNT(*) FILTER (WHERE call_outcome IN ('appointment_scheduled', 'appointment_refused', 'not_interested', 'callback_requested')) as answered_count,

  -- Durée et coût
  AVG(duration_seconds) as avg_duration_seconds,
  SUM(cost) as total_cost,
  AVG(cost) as avg_cost,

  -- Distribution émotions
  COUNT(*) FILTER (WHERE emotion = 'positive') as emotion_positive,
  COUNT(*) FILTER (WHERE emotion = 'neutral') as emotion_neutral,
  COUNT(*) FILTER (WHERE emotion = 'negative') as emotion_negative,

  -- Total
  COUNT(*) as total_calls

FROM calls
WHERE started_at >= CURRENT_DATE - INTERVAL '365 days'
GROUP BY client_id, agent_id, DATE(started_at);

-- Index sur la view
CREATE INDEX idx_daily_metrics_client_date
ON daily_call_metrics (client_id, metric_date DESC);

-- Refresh (à automatiser avec pg_cron ou app-level)
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_call_metrics;
```

### Fonctions SQL pour Queries Complexes

```sql
-- Fonction pour obtenir les KPIs
CREATE OR REPLACE FUNCTION get_kpi_metrics(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_client_id UUID DEFAULT NULL,
  p_agent_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'appointments_scheduled', COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL),
    'answer_rate', ROUND((COUNT(*) FILTER (WHERE call_outcome IN ('appointment_scheduled', 'appointment_refused', 'not_interested', 'callback_requested'))::NUMERIC / NULLIF(COUNT(*), 0) * 100), 2),
    'avg_duration', ROUND(AVG(duration_seconds)),
    'avg_cost', ROUND(AVG(cost)::NUMERIC, 2),
    'conversion_rate', ROUND((COUNT(*) FILTER (WHERE appointment_scheduled_at IS NOT NULL)::NUMERIC / NULLIF(COUNT(*) FILTER (WHERE call_outcome IN ('appointment_scheduled', 'appointment_refused', 'not_interested', 'callback_requested')), 0) * 100), 2),
    'total_calls', COUNT(*)
  )
  INTO result
  FROM calls
  WHERE started_at >= p_start_date
    AND started_at <= p_end_date
    AND (p_client_id IS NULL OR client_id = p_client_id)
    AND (p_agent_id IS NULL OR agent_id = p_agent_id);

  RETURN result;
END;
$$;
```

---

## 🚀 Implementation Roadmap

### Phase 1 - Setup & Infrastructure (2-3 jours)

1. **Setup Database** :
   - [ ] Créer table `agents`
   - [ ] Créer table `user_client_permissions`
   - [ ] Ajouter `agent_id` à `calls`
   - [ ] Créer tous les indexes (BRIN + composites)
   - [ ] Configurer RLS policies
   - [ ] Créer materialized view `daily_call_metrics`
   - [ ] Créer fonctions SQL (`get_kpi_metrics`, etc.)

2. **Setup Authentication** :
   - [ ] Configurer Supabase Auth
   - [ ] Créer middleware Next.js 15
   - [ ] Créer helpers Supabase (`lib/supabase/client.ts`, `server.ts`)
   - [ ] Tester isolation RLS

3. **Install Dependencies** :
   ```bash
   npm install @tremor/react
   npm install @tanstack/react-query @tanstack/react-query-devtools
   npm install react-datepicker date-fns
   npm install -D @types/react-datepicker
   npx shadcn@latest init
   npx shadcn@latest add card button skeleton dialog dropdown-menu select
   ```

4. **Setup TanStack Query Provider** :
   - [ ] Créer `app/providers.tsx`
   - [ ] Configurer QueryClient avec defaults
   - [ ] Wrapper app dans Provider

### Phase 2 - Dashboard Core (3-4 jours)

1. **Layout & Routing** :
   - [ ] Créer `app/dashboard/page.tsx` (Server Component)
   - [ ] Créer `app/dashboard/DashboardClient.tsx` (Client Component)
   - [ ] Créer `app/dashboard/loading.tsx` (Skeleton UI)
   - [ ] Créer `app/dashboard/error.tsx` (Error boundary)

2. **Filtres** :
   - [ ] Créer `components/dashboard/Filters/DateRangeFilter.tsx`
   - [ ] Créer `components/dashboard/Filters/ClientAgentFilter.tsx`
   - [ ] Implémenter presets de dates
   - [ ] Implémenter cascading dropdowns client/agent
   - [ ] Synchroniser filtres avec URL (query params)

3. **KPI Cards** :
   - [ ] Créer `components/dashboard/KPICard.tsx`
   - [ ] Implémenter les 7 KPI cards :
     - RDV Pris
     - Taux de Décroché
     - Durée Moyenne
     - Coût Moyen
     - Taux de Conversion
     - Coût par Acquisition
     - ROI Estimé
   - [ ] Ajouter sparklines (tendance 7 jours)
   - [ ] Ajouter badges delta (comparaison période précédente)

### Phase 3 - Charts & Visualizations (3-4 jours)

1. **Charts Principaux** :
   - [ ] Volume d'appels (AreaChart)
   - [ ] Distribution émotions (DonutChart)
   - [ ] Call Outcomes (BarChart)
   - [ ] Performance par client (LineChart multi-séries)
   - [ ] Taux messagerie par agent (BarChart horizontal)

2. **Queries & Data Fetching** :
   - [ ] Créer `lib/queries/dashboard.ts`
   - [ ] Implémenter fetch KPIs avec TanStack Query
   - [ ] Implémenter fetch charts avec TanStack Query
   - [ ] Configurer polling horaire
   - [ ] Gérer les états loading/error

### Phase 4 - Features Avancées (2-3 jours)

1. **Export de Données** :
   - [ ] Fonction export CSV
   - [ ] Fonction export JSON
   - [ ] Bouton export avec indicateur de chargement
   - [ ] Validation encodage UTF-8 + BOM

2. **Responsive Design** :
   - [ ] Mobile (< 768px) : Layout 1 colonne
   - [ ] Tablet (768-1024px) : Layout 2 colonnes
   - [ ] Desktop (> 1024px) : Layout 4 colonnes
   - [ ] Test sur tous devices

3. **Animations & Polish** :
   - [ ] Framer Motion fade-in stagger
   - [ ] Skeleton loaders avec dimensions exactes
   - [ ] Transitions fluides filtres
   - [ ] Micro-interactions

### Phase 5 - Optimisation & Tests (2 jours)

1. **Performance** :
   - [ ] Lazy loading charts
   - [ ] Vérifier bundle size (< 200kb)
   - [ ] Optimiser images
   - [ ] Tester LCP < 2.5s

2. **Tests** :
   - [ ] Tests unitaires fonctions calcul
   - [ ] Tests RLS policies
   - [ ] Tests permissions
   - [ ] Tests responsive

3. **Documentation** :
   - [ ] Documenter l'API
   - [ ] Guide utilisateur
   - [ ] Guide admin

---

## ⚠️ Important Considerations

### 1. Permissions et Sécurité

**RLS obligatoire** :
- Toutes les tables doivent avoir RLS activé
- Tester les policies avec différents users
- Vérifier l'isolation tenant

**JWT App Metadata** :
- Stocker `tenant_id` dans `app_metadata` (immuable par user)
- Extraire via `auth.tenant_id()` dans les policies
- Ne jamais faire confiance aux claims `user_metadata`

### 2. Performance Queries

**Limiter les plages de dates** :
- Max 1 an de données à la fois
- Paginer les résultats si > 1000 rows
- Utiliser materialized views pour agrégations

**Éviter N+1 queries** :
- Utiliser `Promise.all` pour parallel fetching
- Pré-charger les relations (clients, agents)
- Cache agressif avec TanStack Query

### 3. UX Critical

**Loading States** :
- Skeleton UI avec dimensions exactes (éviter CLS)
- Spinners pour actions async
- Disable boutons pendant loading

**Error Handling** :
- Messages d'erreur explicites
- Fallback UI en cas d'échec
- Retry automatique avec backoff

### 4. Data Integrity

**Validation** :
- Valider dates (début < fin)
- Valider permissions client/agent
- Gérer les cas "aucune donnée"

**Timezone** :
- Toutes les dates en UTC dans la DB
- Conversion timezone côté client
- Utiliser `date-fns` avec `date-fns-tz` si nécessaire

### 5. Mobile Experience

**Touch-friendly** :
- Boutons min 44x44px
- Date pickers adaptés mobile
- Charts swipeable sur mobile
- Filtres en modal sur mobile

### 6. Scalabilité

**Anticiper la croissance** :
- Pagination des résultats
- Lazy loading des charts
- Compression des exports CSV (pour gros volumes)
- Monitoring des query performances

---

## ✅ Success Criteria

### Fonctionnalité
- [ ] Toutes les 7 KPI cards fonctionnelles avec données réelles
- [ ] 5 charts principaux affichés correctement
- [ ] Filtres (date, client, agent) synchronisés en temps réel
- [ ] Export CSV/JSON fonctionnel
- [ ] Refresh automatique horaire sans bug
- [ ] RLS et permissions respectées

### Performance
- [ ] LCP < 2.5s (Largest Contentful Paint)
- [ ] CLS < 0.1 (Cumulative Layout Shift)
- [ ] Bundle JS < 200kb (gzipped)
- [ ] Queries < 500ms (95e percentile)
- [ ] FID < 100ms (First Input Delay)

### UX/UI
- [ ] Design cohérent avec le site Voipia
- [ ] Responsive parfait (mobile → desktop)
- [ ] Animations fluides 60fps
- [ ] Accessibilité WCAG 2.1 AA
- [ ] Zero erreurs console

### Sécurité
- [ ] RLS activé et testé sur toutes les tables
- [ ] Authentification requise pour /dashboard
- [ ] Isolation complète entre tenants/clients
- [ ] Aucune fuite de données cross-client
- [ ] JWT validation côté serveur

### Business
- [ ] Tracking Analytics configuré
- [ ] Adoption user > 70% (clients qui utilisent le dashboard)
- [ ] Feedback positif clients
- [ ] Réduction demandes support data (-30%)

---

## 🎯 Next Steps

### For Developer (Claude Code)

**Phase 1** - Préparer les fichiers :
1. Créer structure de dossiers :
   ```
   app/dashboard/
   components/dashboard/
   lib/queries/
   lib/supabase/
   types/dashboard.ts
   ```

2. Installer dépendances npm

3. Configurer TanStack Query Provider

**Phase 2** - Attendre confirmation user :
1. User doit créer/modifier les tables Supabase
2. User doit configurer RLS policies
3. User doit créer les indexes
4. User doit tester l'authentification

**Phase 3** - Développer le dashboard :
1. Layout et routing
2. Filtres
3. KPI Cards
4. Charts
5. Export
6. Polish

### For User (Vous)

**Voir fichier `USER_TODO_DASHBOARD.md`** pour la liste complète des tâches à effectuer dans Supabase avant que je puisse continuer le développement.

---

## 📝 Notes Additionnelles

**Templates de référence** :
- Razikus/supabase-nextjs-template : Auth + RLS complet
- Vercel Admin Dashboard : Next.js 15 + Postgres
- TailAdmin : 500+ composants dashboards

**Documentation clés** :
- Tremor : https://tremor.so/docs
- TanStack Query : https://tanstack.com/query/latest
- Supabase RLS : https://supabase.com/docs/guides/auth/row-level-security
- Next.js 15 : https://nextjs.org/docs

**Optimisations futures** :
- Cache Redis pour queries lourdes
- CDN pour exports CSV volumineux
- WebSockets pour updates < 1 min (si besoin)
- AI Insights automatiques sur les données

---

**Version** : 1.0
**Date** : 2025-01-15
**Auteur** : Voipia Team
