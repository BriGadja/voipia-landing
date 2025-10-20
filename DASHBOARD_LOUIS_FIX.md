# Fix Dashboard Louis - Filtrage par Agent Type

## Problèmes identifiés

### 1. **Dashboard Louis affichait des données Arthur**
- **Cause** : Les fonctions RPC `get_kpi_metrics` et `get_chart_data` ne filtraient PAS par agent type
- **Symptôme** : Vous voyiez des références à Arthur dans le dashboard Louis
- **Impact** : Les KPIs incluaient Louis + Arthur au lieu de seulement Louis

### 2. **118 RDV pris - valeur incohérente**
- **Cause** : Les RDV comptés incluaient TOUS les agents (Louis + Arthur)
- **Solution** : Maintenant seuls les RDV des agents Louis sont comptés

### 3. **Graphique "Total appels" manquant**
- Le graphique est bien configuré pour afficher 3 courbes :
  - Total appels (cyan)
  - Appels répondus (lime/vert)
  - RDV pris (violet)
- Les données devraient apparaître correctement après la migration

## Solution implémentée

### Migration SQL
**Fichier** : `supabase/migrations/20250120_add_agent_type_filter_to_kpi_functions.sql`

Cette migration :
1. Supprime les anciennes versions de `get_kpi_metrics` et `get_chart_data`
2. Recrée ces fonctions avec un nouveau paramètre : `p_agent_type_name`
3. Filtre les appels par agent type via la jointure :
   ```sql
   ac.deployment_id -> agent_deployments.id -> agent_types.id -> agent_types.name
   ```

### Code Frontend
**Fichier** : `lib/queries/louis.ts`

Ajout du paramètre `p_agent_type_name: 'louis'` aux appels RPC :
```typescript
const { data, error } = await supabase.rpc('get_kpi_metrics', {
  p_start_date: filters.startDate,
  p_end_date: filters.endDate,
  p_client_id: filters.clientIds.length === 1 ? filters.clientIds[0] : null,
  p_deployment_id: filters.deploymentId || null,
  p_agent_type_name: 'louis', // ← CRITIQUE : Filtre seulement Louis
})
```

## À faire maintenant

### 1. Exécuter les migrations dans Supabase

Vous devez exécuter **2 migrations** dans l'ordre suivant :

#### Migration 1 : Correction de la logique KPI
```sql
-- Fichier : supabase/migrations/20250120_fix_kpi_logic_v2.sql
```
Cette migration :
- Corrige la définition de "appel répondu" (NOT voicemail/erreurs)
- Corrige le taux de conversion (appointments / answered_calls)

#### Migration 2 : Ajout du filtrage par agent type
```sql
-- Fichier : supabase/migrations/20250120_add_agent_type_filter_to_kpi_functions.sql
```
Cette migration :
- Ajoute le paramètre `p_agent_type_name` aux fonctions
- Filtre les données par type d'agent (louis, arthur, etc.)

### 2. Vérifier les résultats

Après l'exécution des migrations, vérifiez :

✅ **Dashboard Louis** (`/dashboard/louis`) :
- Ne montre QUE des agents Louis (pas d'Arthur)
- Nombre de RDV cohérent (probablement bien moins que 118)
- Graphique "Volume d'appels" affiche les 3 courbes
- Taux de conversion entre 0% et 100%
- Taux de décroché > 50% (au lieu de 2%)

✅ **Filtre Agent** :
- Liste TOUS les agents Louis accessibles
- Pas de doublons

### 3. Requêtes de vérification

Vous pouvez exécuter ces requêtes dans Supabase pour vérifier :

```sql
-- Vérifier la répartition par agent type
SELECT
  at.name as agent_type,
  COUNT(*) as call_count,
  COUNT(*) FILTER (WHERE answered = true) as answered_count,
  COUNT(*) FILTER (WHERE appointment_scheduled = true) as rdv_count
FROM v_agent_calls_enriched ac
INNER JOIN agent_deployments ad ON ac.deployment_id = ad.id
INNER JOIN agent_types at ON ad.agent_type_id = at.id
WHERE ac.started_at >= '2025-01-01'
  AND ac.started_at <= CURRENT_DATE
GROUP BY at.name;

-- Tester les KPIs Louis seulement
SELECT get_kpi_metrics(
  '2025-01-01',
  CURRENT_DATE,
  NULL,
  NULL,
  'louis'  -- ← Filtre Louis
);

-- Tester les KPIs Arthur seulement
SELECT get_kpi_metrics(
  '2025-01-01',
  CURRENT_DATE,
  NULL,
  NULL,
  'arthur'  -- ← Filtre Arthur
);
```

## Architecture du filtrage

### Chaîne de filtrage

```
Dashboard Louis
    ↓
useLouisKPIs(filters)
    ↓
fetchLouisKPIMetrics(filters)
    ↓
supabase.rpc('get_kpi_metrics', {
  ...filters,
  p_agent_type_name: 'louis'  ← CRITIQUE
})
    ↓
get_kpi_metrics(p_agent_type_name)
    ↓
WHERE ac.deployment_id IN (
  SELECT ad.id
  FROM agent_deployments ad
  INNER JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE at.name = 'louis'  ← Filtre SQL
)
```

### Validation

Le dashboard Louis utilise **3 niveaux de filtrage** :
1. **Date** : `p_start_date` et `p_end_date`
2. **Client** : `p_client_id` (optionnel)
3. **Agent Type** : `p_agent_type_name = 'louis'` ← **NOUVEAU**
4. **Deployment** : `p_deployment_id` (optionnel, si un agent spécifique est sélectionné)

## Notes importantes

### Définition des KPIs (rappel)

- **Total appels** : COUNT(*) de tous les appels
- **Appels répondus** : Appels où outcome ≠ VOICEMAIL/NO_ANSWER/BUSY/FAILED/etc.
- **RDV pris** : Appels où outcome = 'RDV PRIS' OU metadata contient 'appointment_scheduled_at'
- **Taux de décroché** : (answered_calls / total_calls) × 100
- **Taux de conversion** : (rdv_pris / **answered_calls**) × 100 ← PAS total_calls !

### Arthur n'est PAS affecté

Arthur utilise des fonctions différentes :
- `get_arthur_kpi_metrics`
- `get_arthur_chart_data`

Ces fonctions existent déjà et ne sont pas modifiées par cette migration.

## Résultat attendu

Après les migrations :
- ✅ Dashboard Louis : UNIQUEMENT données Louis
- ✅ Dashboard Arthur : UNIQUEMENT données Arthur (si vous y accédez)
- ✅ KPIs cohérents et logiques
- ✅ Graphiques corrects avec toutes les courbes
- ✅ Taux de conversion ≤ 100%
- ✅ Pas de mélange entre agents
