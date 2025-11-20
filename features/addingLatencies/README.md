# Ajout des Latences et Quality Score

**Date de création** : 2025-01-20
**Statut** : Implémenté
**Auteur** : Claude

---

## Vue d'ensemble

Ce projet ajoute deux fonctionnalités majeures au dashboard Voipia :

1. **Visualisation des latences** (LLM, TTS, Total) dans les dashboards
2. **Quality Score** calculé automatiquement par Dipler pour chaque appel

---

## Fonctionnalités implémentées

### 1. Dashboard Latences

**Objectif** : Monitorer les performances des agents en temps réel

**Composants** :
- KPI Cards : Latences moyennes LLM/TTS/Total + min/max
- Time Series Chart : Évolution des latences dans le temps
- Deployment Comparison : Comparaison des latences par agent

**Données sources** :
- **Colonnes dédiées** : `avg_llm_latency_ms`, `min_llm_latency_ms`, `max_llm_latency_ms`, etc. (9 colonnes)
- **Metadata JSONB** (historique) : `metadata.latencies`
- Format metadata :
  ```json
  {
    "llmLatencies": {"min": 555, "max": 1110, "average": 725, "count": 4},
    "ttsLatencies": {"min": 207, "max": 207, "average": 207, "count": 1},
    "totalLatencies": {"min": 555, "max": 1110, "average": 777, "count": 4}
  }
  ```
- **Avantage colonnes** : Requêtes plus rapides, requêtes SQL simplifiées, meilleure indexation

**Localisation** :
- Dashboard Louis : Section "Performance & Latences"
- Accessible via `/dashboard/louis` après login

### 2. Quality Score

**Objectif** : Scorer automatiquement la qualité de chaque appel (0-100) + justification

**Implémentation** : Via prompt Dipler (pas SQL)

**Critères de scoring** :
- **Durée** (25 points) : Optimal 60-180s
- **Sentiment** (30 points) : Positif = 30, Neutre = 15, Négatif = 0
- **Outcome** (30 points) : RDV = 30, Callback = 20, Refus = 10
- **Latence LLM** (10 points) : <500ms = 10, 500-1000ms = 7
- **Latence TTS** (5 points) : <300ms = 5

**Stockage** :
- Colonne `call_quality_score` (INTEGER) - Score numérique 0-100
- Colonne `call_quality_analysis` (TEXT) - Justification détaillée du score
- Alimentées automatiquement via n8n workflow

**Deux prompts Dipler** :
1. **callQualityScore** → Retourne juste le nombre (ex: 85)
2. **callQualityAnalysis** → Retourne l'explication structurée (DÉTAIL / POINTS FORTS / AXES D'AMÉLIORATION)

---

## Architecture technique

### Backend (Supabase)

#### Nouvelles migrations

1. **`20251120_cleanup_call_classification.sql`**
   - Supprime colonne inutilisée `call_classification`
   - Met à jour 3 vues dépendantes
   - Risque : LOW

2. **`20251120_backfill_tts_data.sql`**
   - Extrait `tts_provider` et `tts_voice_id` depuis metadata
   - Passe de 12% → 30%+ de remplissage
   - Risque : LOW

3. **`20251120_add_latency_indexes.sql`**
   - Ajoute 4 indices GIN/B-tree pour performance
   - Optimise requêtes sur `metadata->'latencies'`
   - Risque : LOW

4. **`20251120_add_latency_columns.sql`** ⭐ **NOUVELLE**
   - Ajoute 9 colonnes dédiées pour latences (LLM/TTS/Total: avg/min/max)
   - Backfill automatique depuis `metadata.latencies`
   - Ajoute 3 indices pour performance
   - Met à jour `get_latency_metrics()` pour utiliser colonnes (plus rapide)
   - Garde `metadata.latencies` pour historique
   - Risque : LOW

5. **`20251120_add_quality_justification_column.sql`** ⭐ **NOUVELLE**
   - Ajoute colonne `call_quality_analysis` (TEXT)
   - Complète `call_quality_score` avec explication détaillée
   - Ajoute index full-text search (recherche française)
   - Permet d'afficher justification dans dashboard/exports
   - Risque : LOW

6. **`20251120_create_latency_rpc.sql`** (obsolète - remplacée par migration 4)
   - Crée fonction `get_latency_metrics()`
   - ⚠️ Remplacée par la version dans `add_latency_columns.sql`
   - Risque : LOW

#### Colonnes conservées

⚠️ **IMPORTANT** : Les colonnes suivantes n'ont **PAS** été supprimées (contrairement au plan initial) :

- `sentiment_analysis` - Encore référencée, trigger actif
- `call_status` - n8n écrit activement dedans
- Raison : Analyse d'impact a révélé qu'elles sont critiques pour l'ingestion n8n

### Frontend (React/Next.js)

#### Nouveaux fichiers

1. **Types** : `lib/types/latency.ts`
   - `LatencyMetric`, `LatencyFilters`, `LatencyKPIs`

2. **Hook** : `lib/hooks/useLatencyData.ts`
   - `useLatencyMetrics()` - Fetch via RPC
   - `calculateLatencyKPIs()` - Calcul agrégé
   - `groupMetricsByDate()` - Préparation time series
   - `groupMetricsByDeployment()` - Préparation bar chart

3. **Composant** : `components/dashboard/charts/LatencyChart.tsx`
   - KPI Cards
   - Area Chart (Recharts)
   - Bar Chart (Recharts)
   - States : loading, empty, data

4. **Intégration** : `app/dashboard/[agentType]/LouisDashboardClient.tsx`
   - Section "Performance & Latences"
   - Filtres synchronisés avec dashboard

---

## Données disponibles

### Colonnes dédiées dans `agent_calls` ⭐ **RECOMMANDÉ**

**LLM Latencies** :
- `avg_llm_latency_ms` (NUMERIC) - Latence LLM moyenne en millisecondes
- `min_llm_latency_ms` (INTEGER) - Latence LLM minimale en millisecondes
- `max_llm_latency_ms` (INTEGER) - Latence LLM maximale en millisecondes

**TTS Latencies** :
- `avg_tts_latency_ms` (NUMERIC) - Latence TTS moyenne en millisecondes
- `min_tts_latency_ms` (INTEGER) - Latence TTS minimale en millisecondes
- `max_tts_latency_ms` (INTEGER) - Latence TTS maximale en millisecondes

**Total Latencies** :
- `avg_total_latency_ms` (NUMERIC) - Latence totale moyenne en millisecondes
- `min_total_latency_ms` (INTEGER) - Latence totale minimale en millisecondes
- `max_total_latency_ms` (INTEGER) - Latence totale maximale en millisecondes

**Avantages** : Requêtes plus rapides, SQL simplifié, meilleure indexation

### Champs metadata.latencies (historique JSONB)

```typescript
{
  llmLatencies: {
    min: number      // Latence LLM minimale (ms)
    max: number      // Latence LLM maximale (ms)
    average: number  // Latence LLM moyenne (ms)
    count: number    // Nombre d'appels LLM
  },
  ttsLatencies: {
    min: number      // Latence TTS minimale (ms)
    max: number      // Latence TTS maximale (ms)
    average: number  // Latence TTS moyenne (ms)
    count: number    // Nombre de générations TTS
  },
  totalLatencies: {
    min: number      // Latence totale minimale (ms)
    max: number      // Latence totale maximale (ms)
    average: number  // Latence totale moyenne (ms)
    count: number    // Nombre de tours de parole
  }
}
```

**Note** : Les colonnes dédiées sont automatiquement synchronisées avec `metadata.latencies` lors du backfill. Utilisez les colonnes pour les requêtes, metadata pour l'historique et la flexibilité.

---

## Utilisation

### Requêtes SQL

#### Récupérer latences via RPC

```sql
SELECT *
FROM get_latency_metrics(
  '2025-01-01'::DATE,  -- start_date
  '2025-01-31'::DATE,  -- end_date
  NULL,                 -- deployment_id (optional)
  NULL,                 -- client_id (optional)
  'louis'              -- agent_type_name (optional)
);
```

#### Requête directe sur colonnes dédiées ⭐ **RECOMMANDÉ**

```sql
-- Requête simple et performante avec colonnes dédiées
SELECT
  deployment_id,
  ROUND(AVG(avg_llm_latency_ms), 2) as avg_llm_ms,
  ROUND(AVG(avg_tts_latency_ms), 2) as avg_tts_ms,
  ROUND(AVG(avg_total_latency_ms), 2) as avg_total_ms,
  COUNT(*) as call_count
FROM agent_calls
WHERE avg_llm_latency_ms IS NOT NULL
  AND started_at >= '2025-01-01'
GROUP BY deployment_id;
```

#### Requête sur metadata (alternative legacy)

```sql
-- Ancienne méthode avec extraction JSONB (plus lente)
SELECT
  deployment_id,
  AVG((metadata->'latencies'->'llmLatencies'->>'average')::numeric) as avg_llm_ms,
  AVG((metadata->'latencies'->'ttsLatencies'->>'average')::numeric) as avg_tts_ms
FROM agent_calls
WHERE metadata ? 'latencies'
  AND started_at >= '2025-01-01'
GROUP BY deployment_id;
```

### Frontend (React)

```typescript
import { useLatencyMetrics } from '@/lib/hooks/useLatencyData'
import { LatencyChart } from '@/components/dashboard/charts/LatencyChart'

function MyDashboard() {
  const { data, isLoading } = useLatencyMetrics({
    startDate: '2025-01-01',
    endDate: '2025-01-31',
    agentTypeName: 'louis',
  })

  return <LatencyChart data={data || []} isLoading={isLoading} />
}
```

---

## Configuration Dipler (Manuel)

### Ajout du Quality Score

1. Aller dans Dipler > Agent Louis > Settings
2. Section "Post-Conversation Data Extraction"
3. Ajouter champ :

```json
{
  "name": "callQualityScore",
  "isRequired": true,
  "type": "integer",
  "extractDataPrompt": "Évalue la qualité de cet appel sur une échelle de 0 à 100..."
}
```

4. Mettre à jour n8n workflow `voipia-louis-endcall` :

```javascript
{
  call_quality_score: $json.body.conversation.postConversationAnalysis.extractedData.callQualityScore || null,
}
```

**Voir** : `DIPLER_QUALITY_SCORE_PROMPT.md` pour le prompt complet

---

## Tests

### Test RPC function

```sql
-- Test 1: Latences pour tous les agents Louis (30 derniers jours)
SELECT *
FROM get_latency_metrics(
  CURRENT_DATE - 30,
  CURRENT_DATE,
  NULL, NULL, 'louis'
)
LIMIT 10;

-- Test 2: Vérifier RLS (doit retourner seulement clients accessibles)
SELECT DISTINCT client_name
FROM get_latency_metrics(CURRENT_DATE - 30, CURRENT_DATE, NULL, NULL, NULL);
```

### Test Frontend

1. Démarrer dev server : `npm run dev`
2. Naviguer vers `http://localhost:3000/dashboard/louis`
3. Scroller vers "Performance & Latences"
4. Vérifier :
   - KPI Cards affichent latences
   - Time Series Chart montre évolution
   - Deployment Comparison fonctionne
   - Filtres de date/client mettent à jour les données

---

## Troubleshooting

### Problème : Aucune donnée de latence

**Cause** : Les latences ne sont disponibles que pour les appels récents (depuis nov 2025)

**Solution** :
- Filtrer sur les 30 derniers jours
- Vérifier que des appels ont été passés récemment

### Problème : Quality score NULL

**Cause** : Prompt Dipler pas encore configuré

**Solution** :
1. Suivre `GUIDE_IMPLEMENTATION.md` Phase 1
2. Tester un appel après config
3. Vérifier payload endCall contient `callQualityScore`

### Problème : Erreur RPC get_latency_metrics

**Cause** : Migration pas encore appliquée

**Solution** :
```sql
-- Vérifier fonction existe
SELECT proname FROM pg_proc WHERE proname = 'get_latency_metrics';

-- Si vide, appliquer migration
-- supabase/migrations/20251120_create_latency_rpc.sql
```

---

## Fichiers du projet

### Documentation

- `ANALYSE_PAYLOAD.md` - Analyse complète du payload endCall
- `AGENT_CALLS_SCHEMA_ANALYSIS.md` - Analyse détaillée de la table
- `IMPACT_ANALYSIS.md` - Analyse des dépendances avant suppression
- `DIPLER_QUALITY_SCORE_PROMPT.md` - Prompt score numérique (0-100)
- `DIPLER_QUALITY_ANALYSIS_PROMPT.md` - ⭐ **Prompt justification détaillée**
- `GUIDE_IMPLEMENTATION.md` - Guide étape par étape
- `README.md` - Ce fichier

### Migrations SQL

- `supabase/migrations/20251120_cleanup_call_classification.sql` - Supprime `call_classification`
- `supabase/migrations/20251120_backfill_tts_data.sql` - Enrichit données TTS
- `supabase/migrations/20251120_add_latency_indexes.sql` - Indices GIN/B-tree
- `supabase/migrations/20251120_add_latency_columns.sql` - ⭐ **Ajoute colonnes latences + backfill**
- `supabase/migrations/20251120_add_quality_justification_column.sql` - ⭐ **Ajoute justification qualité**
- `supabase/migrations/20251120_create_latency_rpc.sql` - ⚠️ Obsolète (remplacée par add_latency_columns)

### Frontend

- `lib/types/latency.ts` - Types TypeScript
- `lib/hooks/useLatencyData.ts` - Hook React
- `components/dashboard/charts/LatencyChart.tsx` - Composant visualisation
- `app/dashboard/[agentType]/LouisDashboardClient.tsx` - Intégration dashboard

---

## Prochaines étapes (optionnelles)

### Court terme

1. **Ajouter latences dans dashboard Arthur**
   - Copier l'intégration de Louis
   - Filtrer `agent_type_name = 'arthur'`

2. **Ajouter latences dans dashboard Global**
   - Vue agrégée tous agents
   - Comparaison Louis vs Arthur vs Alexandra

### Moyen terme

3. **Alertes sur latences élevées**
   - Notification si `avg_llm_latency > 2000ms`
   - Email automatique aux admins

4. **Optimisation basée sur latences**
   - A/B testing : Gemini 2.5 Flash vs autres modèles
   - Comparaison providers TTS
   - ROI performance vs coût

### Long terme

5. **Backfill quality scores**
   - Workflow n8n pour scorer anciens appels
   - Utiliser même prompt Dipler

6. **Machine Learning**
   - Prédire latences avant l'appel
   - Détection anomalies en temps réel
   - Recommandations d'optimisation

---

## Statistiques

- **Migrations SQL** : 6 fichiers (5 actives + 1 obsolète)
- **Documentation** : 7 fichiers markdown
- **Nouveaux fichiers frontend** : 4 fichiers
- **Colonnes supprimées** : 1 (`call_classification`)
- **Colonnes ajoutées** : 10 (9 latences + 1 justification) ⭐
- **Colonnes enrichies** : 3 (`call_quality_score`, `tts_provider`, `tts_voice_id`)
- **Nouvelles RPC functions** : 1 (`get_latency_metrics`)
- **Indices ajoutés** : 9 (4 GIN JSONB + 3 B-tree latences + 2 full-text search)
- **Lignes de code ajoutées** : ~1300 lignes

---

## Contributeurs

- **Conception** : Claude (IA)
- **Implémentation** : Claude (IA)
- **Validation** : Utilisateur (Brice)
- **Date** : 2025-01-20

---

**Questions ou problèmes ?** Référez-vous aux fichiers de documentation ci-dessus ou demandez à Claude.
