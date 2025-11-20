# 🚀 Guide de Migration - Enrichissement agent_calls

## 📋 Pré-requis

### ✅ Checklist avant migration

- [ ] Backup de la base de données effectué
- [ ] Aucun workflow n8n critique en cours d'exécution
- [ ] Accès au SQL Editor de Supabase
- [ ] Ce guide et les scripts à portée de main

### 💾 Créer un backup

```bash
# Option 1 : Via Supabase Dashboard
Settings → Database → Backups → Create Backup

# Option 2 : Via pg_dump (si accès direct)
pg_dump -h db.xxx.supabase.co -U postgres -d postgres > backup_avant_migration_$(date +%Y%m%d_%H%M%S).sql
```

---

## 🎯 Étapes de Migration

### ÉTAPE 1 : Vérifications pré-migration

Exécute ces requêtes dans le SQL Editor de Supabase :

```sql
-- 1.1 Vérifier le nombre d'appels actuels
SELECT COUNT(*) as total_calls FROM agent_calls;
-- Résultat attendu : ~675

-- 1.2 Vérifier que la colonne 'cost' existe
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'agent_calls' AND column_name = 'cost';
-- Résultat attendu : 1 ligne avec cost | numeric

-- 1.3 Vérifier les vues dépendantes
SELECT viewname 
FROM pg_views 
WHERE schemaname = 'public' 
  AND definition ILIKE '%agent_calls%'
ORDER BY viewname;
-- Résultat attendu : 10 vues listées

-- 1.4 Vérifier qu'aucun workflow n'est en train d'écrire
SELECT COUNT(*) as calls_last_5_min
FROM agent_calls 
WHERE created_at > NOW() - INTERVAL '5 minutes';
-- Résultat attendu : 0 (ou pause tes workflows)
```

**✅ Si tous les résultats sont bons, continue.**

---

### ÉTAPE 2 : Pause des workflows n8n

🛑 **IMPORTANT** : Met en pause tous les workflows qui écrivent dans `agent_calls` :

- Workflow "Dipler Webhook End Call"
- Workflow "Insert Call Data"
- Tout autre workflow qui fait des INSERT/UPDATE sur agent_calls

**Durée de pause estimée : 5-10 minutes**

---

### ÉTAPE 3 : Exécution de la migration

1. Ouvre le fichier `migration_agent_calls_enrichment.sql`
2. Copie TOUT le contenu
3. Va dans Supabase → SQL Editor
4. Colle le script complet
5. Clique sur **"Run"**

**⏱️ Temps d'exécution attendu : 5-15 secondes**

#### Résultats attendus :

```
✅ Success
Rows: 0 (c'est normal, c'est un script de migration)
Time: ~10-15s
```

#### En cas d'erreur :

- ❌ Le script s'arrête automatiquement (transaction rollback)
- ❌ Aucune modification n'est appliquée
- ✅ Ta base reste intacte
- 📝 Note l'erreur et contacte-moi

---

### ÉTAPE 4 : Vérifications post-migration

Exécute ces requêtes pour valider que tout fonctionne :

```sql
-- 4.1 Vérifier que la colonne a été renommée
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'agent_calls' 
  AND column_name IN ('cost', 'total_cost');
-- Résultat attendu : 1 ligne avec 'total_cost' uniquement

-- 4.2 Vérifier les nouvelles colonnes
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'agent_calls' 
  AND column_name IN (
    'conversation_id', 'call_sid', 'call_classification',
    'stt_cost', 'tts_cost', 'llm_cost', 'llm_model'
  )
ORDER BY column_name;
-- Résultat attendu : 7 lignes (toutes les nouvelles colonnes)

-- 4.3 Vérifier que les vues fonctionnent
SELECT * FROM v_global_kpis;
-- Résultat attendu : 1 ligne avec current_period et previous_period (JSONB)

SELECT * FROM v_agent_calls_enriched LIMIT 5;
-- Résultat attendu : 5 lignes avec les nouvelles colonnes (NULL pour l'instant)

-- 4.4 Vérifier le nombre d'appels (doit être identique)
SELECT COUNT(*) as total_calls FROM agent_calls;
-- Résultat attendu : ~675 (même nombre qu'avant)

-- 4.5 Vérifier que les coûts sont préservés
SELECT 
  COUNT(*) as total_calls,
  COUNT(total_cost) as calls_with_cost,
  ROUND(SUM(total_cost), 2) as total_cost_sum
FROM agent_calls;
-- Résultat attendu : même somme qu'avant (vérifier avec ton dashboard)
```

**✅ Si toutes les vérifications passent, la migration est réussie !**

---

### ÉTAPE 5 : Réactiver les workflows n8n

1. Va dans n8n
2. Ouvre chaque workflow mis en pause
3. **AVANT de réactiver**, modifie les nodes qui utilisent `cost` :
   - Recherche : `cost`
   - Remplace par : `total_cost`
   - Zones concernées : nodes Supabase (INSERT, UPDATE, SELECT)
4. Teste en exécution manuelle
5. Réactive les workflows

---

## 🔄 Prochaines étapes

### Workflow n8n à créer/modifier

**Workflow "Dipler End Call Parser"** (à créer ou modifier) :

```
Webhook Dipler
  ↓
Set (parse payload)
  ├─ conversation_id: {{$json.body.conversation.id}}
  ├─ call_sid: {{$json.body.conversation.callInfos.callSid}}
  ├─ total_cost: {{$json.body.conversation.stats.sessionTotalPriceIncludingTwilioNotBilledByDipler}}
  ├─ stt_cost: {{$json.body.conversation.stats.sttStats.price}}
  ├─ tts_cost: {{$json.body.conversation.stats.ttsStats.totalPrice}}
  ├─ llm_cost: {{$json.body.conversation.stats.llmStats.totalPrice}}
  ├─ telecom_cost: {{$json.body.conversation.callInfos.callCost}}
  ├─ dipler_commission: {{$json.body.conversation.stats.diplerCommission}}
  ├─ cost_per_minute: {{$json.body.conversation.stats.averagePricePerMinute}}
  ├─ call_classification: {{$json.body.conversation.postConversationAnalysis.callClassification}}
  ├─ call_quality_score: {{$json.body.conversation.postConversationAnalysis.callQualityScore}}
  ├─ sentiment_analysis: {{$json.body.conversation.postConversationAnalysis.sentimentAnalysis}}
  ├─ llm_model: {{$json.body.conversation.stack.llm}}
  ├─ tts_provider: {{$json.body.conversation.stack.tts.ttsProvider}}
  ├─ tts_voice_id: {{$json.body.conversation.stack.tts.voiceId}}
  ├─ stt_provider: {{$json.body.conversation.stack.stt}}
  ├─ direction: {{$json.body.conversation.callInfos.direction}}
  ├─ call_status: {{$json.body.conversation.callInfos.callStatus}}
  └─ provider: 'twilio'
  ↓
Supabase (UPSERT agent_calls)
```

---

## 🆘 En cas de problème

### Si la migration échoue

1. **Ne panique pas** : Rien n'a été modifié grâce à la transaction
2. Note l'erreur exacte
3. Vérifie les pré-requis
4. Contacte-moi avec l'erreur

### Si la migration réussit mais tu veux rollback

1. Ouvre le fichier `rollback_migration.sql`
2. **ATTENTION** : Avant de l'exécuter, sauvegarde d'abord les définitions de tes vues originales
3. Exécute le script de rollback
4. Restaure tes vues depuis le backup

### Commande pour sauvegarder les vues AVANT migration

```sql
-- Copie le résultat dans un fichier texte
SELECT 
  'CREATE VIEW ' || viewname || ' AS ' || definition || ';' as create_statement
FROM pg_views 
WHERE schemaname = 'public' 
  AND definition ILIKE '%agent_calls%'
ORDER BY viewname;
```

---

## 📊 Tests après migration complète

Une fois les workflows réactivés et quelques appels effectués :

```sql
-- Vérifier qu'un nouvel appel a bien les données enrichies
SELECT 
  id,
  conversation_id,
  call_classification,
  total_cost,
  stt_cost,
  tts_cost,
  llm_cost,
  llm_model
FROM agent_calls 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;
-- Résultat attendu : Les nouvelles colonnes sont remplies
```

---

## ✅ Checklist finale

- [ ] Migration exécutée sans erreur
- [ ] Vérifications post-migration OK
- [ ] Workflows n8n mis à jour
- [ ] Workflows réactivés et testés
- [ ] Premier appel avec données enrichies validé
- [ ] Backup conservé pendant 7 jours minimum

---

## 📞 Support

Questions ? Problèmes ?
- Copie-colle l'erreur SQL exacte
- Indique l'étape où ça bloque
- Je t'aide à débugger !

**Temps total estimé : 30-45 minutes**
