# Migration Dashboard Louis vers agent_calls

## 📋 Résumé

Le dashboard Louis utilisait l'ancienne table `calls` avec des références directes à `client_id` et `agent_id`. Cette migration fait pointer le dashboard vers la nouvelle table unifiée `agent_calls` qui utilise `deployment_id` pour lier aux déploiements d'agents.

## ✅ Changements effectués dans le code

### 1. lib/queries/dashboard.ts

#### fetchKPIMetrics()
- **AVANT**: `agentId?: string | null` → `p_agent_id`
- **APRÈS**: `deploymentId?: string | null` → `p_deployment_id`

#### fetchChartData()
- **AVANT**: `agentId?: string | null` → `p_agent_id`
- **APRÈS**: `deploymentId?: string | null` → `p_deployment_id`

#### fetchAgents()
- **AVANT**: Query `agents` table avec `status = 'active'`
- **APRÈS**: Query `agent_deployments` avec JOIN `agent_types` et filtre `agent_types.name = 'louis'`
- Retourne les déploiements Louis au lieu des agents génériques

#### exportCallsToCSV()
- **AVANT**:
  - Table: `calls`
  - Joins: `clients(name), agents(name)`
  - Colonnes: `call_outcome`, `phone`, `appointment_scheduled_at`

- **APRÈS**:
  - Table: `agent_calls`
  - Joins: `agent_deployments!inner(name, client_id, clients(name), agent_types!inner(name))`
  - Colonnes: `outcome`, `phone_number`, `metadata->>'appointment_scheduled_at'`
  - Filtre: `agent_types.name = 'louis'`

### 2. app/dashboard/DashboardClient.tsx

- **AVANT**: `selectedAgentIds` state variable
- **APRÈS**: `selectedDeploymentIds` state variable
- Tous les appels de fonctions mis à jour pour passer `deploymentId` au lieu de `agentId`

## 🗄️ Migration SQL à appliquer

Le fichier de migration a été créé : `supabase/migrations/20250118_migrate_louis_dashboard_to_agent_calls.sql`

### Fonctions RPC mises à jour:

#### get_kpi_metrics()
- **Changements clés**:
  - Paramètre `p_agent_id` → `p_deployment_id`
  - Query `calls` → `agent_calls` avec JOINs
  - Filtre automatique sur `agent_types.name = 'louis'`
  - Mapping: `call_outcome IN (...)` → `outcome IN (...)`
  - Mapping: `appointment_scheduled_at` → `metadata->>'appointment_scheduled_at'`

#### get_chart_data()
- **Changements clés**:
  - Paramètre `p_agent_id` → `p_deployment_id`
  - Query `calls` → `agent_calls` avec JOINs
  - Filtre automatique sur `agent_types.name = 'louis'`
  - 4 charts mis à jour: call_volume_by_day, emotion_distribution, outcome_distribution, voicemail_by_agent
  - Chart "voicemail_by_agent" utilise `ad.name` (deployment name) au lieu de `a.name` (agent name)

## 📋 Mapping des colonnes

| calls (ancienne table) | agent_calls (nouvelle table) |
|------------------------|------------------------------|
| `client_id` | `agent_deployments.client_id` (via JOIN) |
| `agent_id` | `deployment_id` |
| `call_outcome` (ENUM) | `outcome` (TEXT) |
| `phone` | `phone_number` |
| `appointment_scheduled_at` | `metadata->>'appointment_scheduled_at'` |

## 🚀 Instructions d'application

### Étape 1: Appliquer la migration SQL

**Option A: Via Supabase CLI** (recommandé)
```bash
# Depuis la racine du projet
npx supabase db push
```

**Option B: Via Supabase Dashboard**
1. Aller sur https://supabase.com/dashboard/project/YOUR_PROJECT/sql
2. Copier le contenu de `supabase/migrations/20250118_migrate_louis_dashboard_to_agent_calls.sql`
3. Coller et exécuter

### Étape 2: Vérifier les fonctions RPC

```sql
-- Vérifier que les fonctions ont bien été mises à jour
SELECT proname, pg_get_functiondef(oid)
FROM pg_proc
WHERE proname IN ('get_kpi_metrics', 'get_chart_data')
  AND pronamespace = 'public'::regnamespace;
```

### Étape 3: Tester le dashboard

1. Démarrer le serveur dev: `npm run dev`
2. Se connecter au dashboard Louis
3. Vérifier que les KPIs s'affichent correctement
4. Vérifier que les 4 charts s'affichent correctement
5. Tester les filtres (Client et Agent Deployment)
6. Tester l'export CSV

## 🧪 Tests de validation

### Test 1: Vérifier le nombre d'appels

```sql
-- Les deux requêtes doivent retourner le même nombre
SELECT COUNT(*) FROM calls;
SELECT COUNT(*) FROM agent_calls
  JOIN agent_deployments ad ON agent_calls.deployment_id = ad.id
  JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE at.name = 'louis';
```

### Test 2: Vérifier les KPIs

```sql
-- Appeler la fonction RPC avec une plage de dates
SELECT * FROM get_kpi_metrics(
  '2025-01-01'::timestamptz,
  '2025-12-31'::timestamptz,
  NULL,
  NULL
);
```

Résultat attendu: JSON avec `current_period` et `previous_period` contenant:
- `appointments_scheduled`
- `answer_rate`
- `avg_duration`
- `avg_cost`
- `conversion_rate`
- `total_cost`
- `total_calls`
- `cpa`

### Test 3: Vérifier les charts

```sql
SELECT * FROM get_chart_data(
  '2025-01-01'::timestamptz,
  '2025-12-31'::timestamptz,
  NULL,
  NULL
);
```

Résultat attendu: JSON avec 4 arrays:
- `call_volume_by_day`
- `emotion_distribution`
- `outcome_distribution`
- `voicemail_by_agent`

## ⚠️ Points d'attention

1. **Filtre automatique sur Louis**: Les nouvelles fonctions RPC filtrent automatiquement sur `agent_types.name = 'louis'`. Si d'autres agents doivent utiliser ces fonctions, il faudra créer des versions spécifiques ou passer le type d'agent en paramètre.

2. **Nom du paramètre**: Le paramètre s'appelle toujours `selectedAgentIds` dans le composant React mais contient maintenant des deployment IDs. Ceci est intentionnel pour éviter de modifier le composant `ClientAgentFilter` qui est partagé.

3. **Export CSV**: Le header de la colonne "Agent" est devenu "Agent Deployment" pour refléter le changement.

4. **Compatibilité**: L'ancienne table `calls` contient toujours les mêmes données que `agent_calls` (118 lignes chacune). Elle peut être supprimée une fois la migration validée.

## 🔄 Rollback (si nécessaire)

Si la migration pose problème, vous pouvez revenir en arrière en:

1. Restaurer les anciennes fonctions RPC (sauvegarder le code avant migration)
2. Rétablir `lib/queries/dashboard.ts` et `app/dashboard/DashboardClient.tsx` depuis Git
3. Redémarrer le serveur dev

```bash
git checkout HEAD -- lib/queries/dashboard.ts app/dashboard/DashboardClient.tsx
npm run dev
```

## 📊 État actuel

- ✅ Code TypeScript mis à jour
- ✅ Migration SQL créée
- ⏳ Migration SQL à appliquer manuellement
- ⏳ Tests de validation à effectuer

## 📝 Notes

- La table `calls` peut être renommée en `calls_deprecated` ou supprimée après validation complète
- Les 118 lignes des deux tables correspondent aux appels Louis existants
- Le dashboard Arthur utilise déjà `agent_calls` directement avec ses propres fonctions RPC
