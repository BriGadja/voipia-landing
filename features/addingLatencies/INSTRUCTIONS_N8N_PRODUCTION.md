# Instructions pour configurer n8n et appliquer la migration en production

**Date** : 2025-01-20
**Statut** : Prêt pour production

---

## 📋 Checklist complète

### ✅ Étape 1 : Appliquer la migration SQL en production

1. Se connecter à **Supabase Dashboard** (production)
2. Aller dans **SQL Editor**
3. Copier le contenu du fichier : `supabase/migrations/20251120_add_latency_and_quality_columns_PRODUCTION.sql`
4. Exécuter le script
5. Vérifier les NOTICES dans les logs pour confirmer le backfill

**Résultat attendu** :
```
=== BACKFILL LATENCES ===
Total appels: [X]
Appels avec metadata.latencies: [Y]
Appels avec latences remplies: [Y]

=== MIGRATION TERMINÉE ===
Total appels: [X]
Appels avec latences: [Y] (Z%)
Appels avec quality score: 0 (0%)
Appels avec quality analysis: 0 (0%)
```

---

### ✅ Étape 2 : Configurer Dipler (si pas déjà fait)

Vérifier que les 2 champs existent dans **Dipler > Agent Louis > Settings > Post-Conversation Data Extraction** :

#### Champ 1 : `callQualityScore`
```json
{
  "name": "callQualityScore",
  "isRequired": true,
  "type": "number",
  "extractDataPrompt": "[Votre prompt actuel pour le score]"
}
```

#### Champ 2 : `callQualityAnalysis`
```json
{
  "name": "callQualityAnalysis",
  "isRequired": true,
  "type": "string",
  "extractDataPrompt": "[Voir DIPLER_QUALITY_ANALYSIS_PROMPT.md]"
}
```

**⚠️ Important** : Le nom du champ Dipler est bien `callQualityAnalysis` (correspondance exacte).

---

### ✅ Étape 3 : Mettre à jour le workflow n8n

Ouvrir le workflow **voipia-louis-endcall** dans n8n et mettre à jour le node **"Prepare Supabase Insert"** :

```javascript
{
  // ===== DONNÉES EXISTANTES (à conserver) =====
  deployment_id: $json.body.deploymentId,
  started_at: new Date($json.body.conversation.startedAt).toISOString(),
  ended_at: new Date($json.body.conversation.endedAt).toISOString(),
  duration_seconds: $json.body.metadata.callDurationSeconds,

  // Outcome et sentiment
  outcome: $json.body.conversation.postConversationAnalysis.extractedData.callClassification,
  emotion: $json.body.conversation.postConversationAnalysis.sentiment,

  // Autres champs existants
  llm_model: $json.body.metadata.stack?.llm?.[0]?.model || null,
  tts_provider: $json.body.metadata.stack?.tts?.[0]?.ttsProvider || null,
  tts_voice_id: $json.body.metadata.stack?.tts?.[0]?.voiceId || null,
  metadata: $json.body.metadata,

  // ===== ⭐ NOUVELLES COLONNES - QUALITY SCORE & ANALYSIS =====
  call_quality_score: $json.body.conversation.postConversationAnalysis.extractedData.callQualityScore || null,
  call_quality_analysis: $json.body.conversation.postConversationAnalysis.extractedData.callQualityAnalysis || null,

  // ===== ⭐ NOUVELLES COLONNES - LATENCES LLM =====
  avg_llm_latency_ms: $json.body.metadata?.latencies?.llmLatencies?.average || null,
  min_llm_latency_ms: $json.body.metadata?.latencies?.llmLatencies?.min || null,
  max_llm_latency_ms: $json.body.metadata?.latencies?.llmLatencies?.max || null,

  // ===== ⭐ NOUVELLES COLONNES - LATENCES TTS =====
  avg_tts_latency_ms: $json.body.metadata?.latencies?.ttsLatencies?.average || null,
  min_tts_latency_ms: $json.body.metadata?.latencies?.ttsLatencies?.min || null,
  max_tts_latency_ms: $json.body.metadata?.latencies?.ttsLatencies?.max || null,

  // ===== ⭐ NOUVELLES COLONNES - LATENCES TOTAL =====
  avg_total_latency_ms: $json.body.metadata?.latencies?.totalLatencies?.average || null,
  min_total_latency_ms: $json.body.metadata?.latencies?.totalLatencies?.min || null,
  max_total_latency_ms: $json.body.metadata?.latencies?.totalLatencies?.max || null,
}
```

**⚠️ Points d'attention** :
- Utiliser `callQualityAnalysis` (nom Dipler) → `call_quality_analysis` (colonne SQL)
- Les latences proviennent de `$json.body.metadata.latencies` (pas de Dipler)
- Tous les nouveaux champs acceptent `null` (pas d'erreur si données absentes)

---

### ✅ Étape 4 : Tester avec un appel réel

1. Faire un appel test avec l'agent Louis
2. Vérifier dans Supabase que les nouvelles colonnes sont bien remplies :

```sql
SELECT
  id,
  started_at,
  outcome,
  duration_seconds,
  -- Quality
  call_quality_score,
  LEFT(call_quality_analysis, 100) as analysis_preview,
  -- Latences
  avg_llm_latency_ms,
  avg_tts_latency_ms,
  avg_total_latency_ms
FROM agent_calls
ORDER BY started_at DESC
LIMIT 1;
```

**Résultat attendu** :
```
| call_quality_score | analysis_preview                              | avg_llm_latency_ms | avg_tts_latency_ms |
|--------------------|-----------------------------------------------|--------------------|--------------------|
| 92                 | DÉTAIL DES POINTS : - Durée : 240s → 15/25..| 876.00             | 278.00             |
```

---

### ✅ Étape 5 : Vérifier le dashboard Louis

1. Aller sur `https://votre-site.com/dashboard/louis`
2. Vérifier la section **"Performance & Latences"**
3. Confirmer que les KPI et graphiques s'affichent correctement

**KPIs attendus** :
- Latence LLM Moyenne : [X]ms
- Latence TTS Moyenne : [X]ms
- Latence Totale Moyenne : [X]ms
- Appels Analysés : [X]

---

## 🔍 Vérifications post-déploiement

### Vérification 1 : Toutes les colonnes existent

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'agent_calls'
  AND (column_name LIKE '%latency%' OR column_name LIKE '%quality%')
ORDER BY column_name;
```

**Résultat attendu** : 11 colonnes
- `avg_llm_latency_ms` (numeric)
- `avg_total_latency_ms` (numeric)
- `avg_tts_latency_ms` (numeric)
- `call_quality_analysis` (text)
- `call_quality_score` (integer)
- `max_llm_latency_ms` (integer)
- `max_total_latency_ms` (integer)
- `max_tts_latency_ms` (integer)
- `min_llm_latency_ms` (integer)
- `min_total_latency_ms` (integer)
- `min_tts_latency_ms` (integer)

### Vérification 2 : Indices créés

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'agent_calls'
  AND (indexname LIKE '%latency%' OR indexname LIKE '%quality%')
ORDER BY indexname;
```

**Résultat attendu** : 5 indices
- `idx_agent_calls_avg_llm_latency`
- `idx_agent_calls_avg_tts_latency`
- `idx_agent_calls_has_analysis`
- `idx_agent_calls_quality_analysis_fts`
- `idx_agent_calls_started_latency`

### Vérification 3 : Fonction RPC fonctionne

```sql
SELECT *
FROM get_latency_metrics(
  CURRENT_DATE - INTERVAL '7 days',
  CURRENT_DATE,
  NULL, NULL, 'louis'
)
LIMIT 5;
```

**Résultat attendu** : Données de latence agrégées par jour et déploiement

---

## 📊 Mapping complet des champs

| Source | Champ Dipler/Payload | Type | Colonne SQL | Type SQL |
|--------|---------------------|------|-------------|----------|
| **Dipler** | `callQualityScore` | number | `call_quality_score` | INTEGER |
| **Dipler** | `callQualityAnalysis` | string | `call_quality_analysis` | TEXT |
| **Payload** | `metadata.latencies.llmLatencies.average` | number | `avg_llm_latency_ms` | NUMERIC(10,2) |
| **Payload** | `metadata.latencies.llmLatencies.min` | number | `min_llm_latency_ms` | INTEGER |
| **Payload** | `metadata.latencies.llmLatencies.max` | number | `max_llm_latency_ms` | INTEGER |
| **Payload** | `metadata.latencies.ttsLatencies.average` | number | `avg_tts_latency_ms` | NUMERIC(10,2) |
| **Payload** | `metadata.latencies.ttsLatencies.min` | number | `min_tts_latency_ms` | INTEGER |
| **Payload** | `metadata.latencies.ttsLatencies.max` | number | `max_tts_latency_ms` | INTEGER |
| **Payload** | `metadata.latencies.totalLatencies.average` | number | `avg_total_latency_ms` | NUMERIC(10,2) |
| **Payload** | `metadata.latencies.totalLatencies.min` | number | `min_total_latency_ms` | INTEGER |
| **Payload** | `metadata.latencies.totalLatencies.max` | number | `max_total_latency_ms` | INTEGER |

---

## ⚠️ Notes importantes

### Problème connu : Latences dans l'analyse Dipler

**Symptôme** : `callQualityAnalysis` mentionne "Latence LLM : Données non disponibles"

**Cause** : Dipler génère l'analyse AVANT que les latences soient calculées et agrégées dans le payload.

**Impact** :
- Le score numérique peut être incohérent avec l'analyse textuelle
- L'analyse mentionne toujours 0 points pour les latences

**Solution temporaire** : Accepter cette limitation en attendant que Dipler donne accès aux latences pendant l'analyse.

**Solution future** (si Dipler ajoute les latences) :
- Les latences seront déjà remplies dans les colonnes SQL depuis le payload
- Seule l'analyse textuelle devra être mise à jour
- Pas de changement nécessaire côté n8n

---

## 🎯 Résultat final

Après déploiement, chaque nouvel appel aura :
```sql
{
  "id": "...",
  "started_at": "2025-01-20 15:30:00",
  "outcome": "appointment_scheduled",
  "call_quality_score": 92,
  "call_quality_analysis": "DÉTAIL DES POINTS : - Durée : 240s → 15/25 | ...",
  "avg_llm_latency_ms": 876.00,
  "min_llm_latency_ms": 567,
  "max_llm_latency_ms": 1721,
  "avg_tts_latency_ms": 278.00,
  "min_tts_latency_ms": 224,
  "max_tts_latency_ms": 488,
  "avg_total_latency_ms": 965.00,
  "min_total_latency_ms": 567,
  "max_total_latency_ms": 1953
}
```

---

## 📞 Support

En cas de problème :
1. Vérifier les logs Supabase (NOTICES de migration)
2. Vérifier les logs n8n (erreurs d'insertion)
3. Tester avec un appel manuel et vérifier le payload reçu
4. Consulter `README.md` pour troubleshooting détaillé

**Documentation complète** : `features/addingLatencies/README.md`
