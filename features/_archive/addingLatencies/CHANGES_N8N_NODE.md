# Modifications de la node Supabase n8n

**Date** : 2025-01-20
**Workflow** : voipia-louis-endcall
**Node** : "Update a row" (Supabase)

---

## 📋 Résumé des changements

### ✅ 1 champ corrigé
- `call_quality_score` - Chemin corrigé vers `extractedData`

### ⭐ 10 nouveaux champs ajoutés
- `call_quality_analysis` - Analyse textuelle de la qualité
- `avg_llm_latency_ms` - Latence LLM moyenne
- `min_llm_latency_ms` - Latence LLM minimale
- `max_llm_latency_ms` - Latence LLM maximale
- `avg_tts_latency_ms` - Latence TTS moyenne
- `min_tts_latency_ms` - Latence TTS minimale
- `max_tts_latency_ms` - Latence TTS maximale
- `avg_total_latency_ms` - Latence totale moyenne
- `min_total_latency_ms` - Latence totale minimale
- `max_total_latency_ms` - Latence totale maximale

---

## 🔧 Changements détaillés

### CORRECTION : call_quality_score (ligne 123-125)

**❌ ANCIEN (incorrect)** :
```json
{
  "fieldId": "call_quality_score",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.postConversationAnalysis?.callQualityScore || null }}"
}
```

**✅ NOUVEAU (correct)** :
```json
{
  "fieldId": "call_quality_score",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.postConversationAnalysis?.extractedData?.callQualityScore || null }}"
}
```

**Raison** : `callQualityScore` est dans `extractedData`, pas directement dans `postConversationAnalysis`.

---

### AJOUT : call_quality_analysis (après call_quality_score)

**⭐ NOUVEAU champ à ajouter** :
```json
{
  "fieldId": "call_quality_analysis",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.postConversationAnalysis?.extractedData?.callQualityAnalysis || null }}"
}
```

**Source dans le payload** :
```
conversation.postConversationAnalysis.extractedData.callQualityAnalysis
```

**Exemple de valeur** :
```
"DÉTAIL DES POINTS :
- Durée : 240 secondes → 15/25 points
- Sentiment : positif → 30/30 points
..."
```

---

### AJOUT : 9 colonnes de latences (après outcome, avant metadata)

**⭐ Latences LLM** :
```json
{
  "fieldId": "avg_llm_latency_ms",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.stats.latencies?.llmLatencies?.average || null }}"
},
{
  "fieldId": "min_llm_latency_ms",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.stats.latencies?.llmLatencies?.min || null }}"
},
{
  "fieldId": "max_llm_latency_ms",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.stats.latencies?.llmLatencies?.max || null }}"
}
```

**⭐ Latences TTS** :
```json
{
  "fieldId": "avg_tts_latency_ms",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.stats.latencies?.ttsLatencies?.average || null }}"
},
{
  "fieldId": "min_tts_latency_ms",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.stats.latencies?.ttsLatencies?.min || null }}"
},
{
  "fieldId": "max_tts_latency_ms",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.stats.latencies?.ttsLatencies?.max || null }}"
}
```

**⭐ Latences Total** :
```json
{
  "fieldId": "avg_total_latency_ms",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.stats.latencies?.totalLatencies?.average || null }}"
},
{
  "fieldId": "min_total_latency_ms",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.stats.latencies?.totalLatencies?.min || null }}"
},
{
  "fieldId": "max_total_latency_ms",
  "fieldValue": "={{ $('webhookCallEvent').item.json.body.conversation.stats.latencies?.totalLatencies?.max || null }}"
}
```

**Source dans le payload** :
```javascript
conversation.stats.latencies = {
  "llmLatencies": {
    "min": 567,
    "max": 1721,
    "average": 876,
    "count": 25
  },
  "ttsLatencies": {
    "min": 224,
    "max": 488,
    "average": 278,
    "count": 17
  },
  "totalLatencies": {
    "min": 567,
    "max": 1953,
    "average": 965,
    "count": 25
  }
}
```

---

## 📊 Ordre des champs dans la node (recommandé)

```
1-22. [Champs existants] (conversation_id, call_sid, first_name, etc.)
23.   call_quality_score         ✅ CORRIGÉ
24.   call_quality_analysis       ⭐ NOUVEAU
25.   emotion
26.   outcome
27.   avg_llm_latency_ms          ⭐ NOUVEAU
28.   min_llm_latency_ms          ⭐ NOUVEAU
29.   max_llm_latency_ms          ⭐ NOUVEAU
30.   avg_tts_latency_ms          ⭐ NOUVEAU
31.   min_tts_latency_ms          ⭐ NOUVEAU
32.   max_tts_latency_ms          ⭐ NOUVEAU
33.   avg_total_latency_ms        ⭐ NOUVEAU
34.   min_total_latency_ms        ⭐ NOUVEAU
35.   max_total_latency_ms        ⭐ NOUVEAU
36.   metadata                    (conservé tel quel)
```

---

## 🎯 Fichier complet mis à jour

Le fichier `updateRowSupabase_UPDATED.json` contient la configuration complète mise à jour.

**Pour l'importer dans n8n** :
1. Ouvrir le workflow `voipia-louis-endcall`
2. Sélectionner la node "Update a row" (Supabase)
3. Copier le contenu de `parameters.fieldsUi.fieldValues` depuis `updateRowSupabase_UPDATED.json`
4. Remplacer le contenu actuel
5. Sauvegarder le workflow

**Ou manuellement** :
1. Ouvrir la node "Update a row"
2. Corriger le champ `call_quality_score` (ligne 123-125)
3. Ajouter les 10 nouveaux champs après `call_quality_score`
4. Sauvegarder

---

## ⚠️ Points d'attention

### 1. Null safety
Tous les nouveaux champs utilisent l'opérateur `?.` et `|| null` :
```javascript
$('webhookCallEvent').item.json.body.conversation.stats.latencies?.llmLatencies?.average || null
```

**Raison** :
- Les latences ne sont pas disponibles sur tous les appels (seulement récents)
- Si une donnée manque, on insère `null` plutôt que de faire crasher l'insertion

### 2. Types de données

| Champ | Type SQL | Type n8n |
|-------|----------|----------|
| `call_quality_score` | INTEGER | number (0-100) |
| `call_quality_analysis` | TEXT | string |
| `avg_llm_latency_ms` | NUMERIC(10,2) | number (float) |
| `min_llm_latency_ms` | INTEGER | number (int) |
| `max_llm_latency_ms` | INTEGER | number (int) |
| `avg_tts_latency_ms` | NUMERIC(10,2) | number (float) |
| ... | ... | ... |

### 3. Valeurs attendues

**Exemple d'appel complet** (basé sur endCallStatsv2.txt) :
```javascript
{
  "call_quality_score": 92,
  "call_quality_analysis": "DÉTAIL DES POINTS : - Durée : 240s → 15/25 | Sentiment : positif → 30/30 | ...",
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

## 🧪 Test post-modification

Après avoir mis à jour la node :

### 1. Test en staging (recommandé)

1. Modifier la node pour pointer vers Supabase **staging**
2. Faire un appel test
3. Vérifier que toutes les colonnes sont bien remplies :

```sql
SELECT
  id,
  started_at,
  call_quality_score,
  LEFT(call_quality_analysis, 50) as analysis_preview,
  avg_llm_latency_ms,
  avg_tts_latency_ms
FROM agent_calls
ORDER BY started_at DESC
LIMIT 1;
```

### 2. Test en production

1. Remettre la node sur Supabase **production**
2. Faire un appel test
3. Vérifier dans Supabase Dashboard que toutes les colonnes sont remplies

### 3. Vérifier les erreurs n8n

Si une erreur survient, vérifier les logs n8n :
- Erreur "column does not exist" → Migration SQL pas encore appliquée
- Erreur "null value" → Normal si latences absentes, vérifier `|| null`
- Erreur "invalid input syntax" → Vérifier le type de données

---

## 📚 Références

- Payload complet : `endCallStatsv2.txt`
- Migration SQL production : `supabase/migrations/20251120_add_latency_and_quality_columns_PRODUCTION.sql`
- Instructions complètes : `INSTRUCTIONS_N8N_PRODUCTION.md`
- Configuration Dipler : `DIPLER_QUALITY_ANALYSIS_PROMPT.md`

---

**Questions ?** Consultez `README.md` ou les fichiers de documentation dans `features/addingLatencies/`.
