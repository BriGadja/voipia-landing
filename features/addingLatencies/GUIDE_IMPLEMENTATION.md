# Guide d'implémentation : Enrichissement agent_calls

**Date** : 2025-01-20
**Projet** : Ajout latences + quality score + nettoyage colonnes
**Durée estimée** : 2h30

---

## Vue d'ensemble

Ce guide vous accompagne étape par étape pour implémenter les améliorations sur la table `agent_calls`.

### Phases

1. **Phase 1 (Manuel)** : Configuration Dipler pour quality score - **20 min**
2. **Phases 2-5 (Automatique)** : Migrations SQL - **35 min**
3. **Phases 6-8 (Automatique)** : Frontend dashboard latences - **1h**
4. **Phase 9 (Automatique)** : Documentation - **30 min**

---

## Phase 1 : Quality Score avec Dipler (MANUEL)

### ⚠️ Cette phase nécessite votre intervention manuelle

Claude a créé le prompt pour vous, mais vous devez l'ajouter dans Dipler.

### Étape 1.1 : Ouvrir la configuration Dipler

1. Allez sur https://dipler.ai (ou votre instance)
2. Connectez-vous
3. Sélectionnez l'agent **Louis** (ou l'agent concerné)
4. Allez dans **Settings** > **Post-Conversation Analysis**

### Étape 1.2 : Ajouter le champ callQualityScore

Ajoutez un nouveau champ dans `postConversationDataExtractionSchema` :

```json
{
  "name": "callQualityScore",
  "isRequired": true,
  "type": "integer",
  "choices": [],
  "extractDataPrompt": "Évalue la qualité de cet appel sur une échelle de 0 à 100 en analysant les critères suivants :\n\n**1. Durée de l'appel (25 points)**\n- Moins de 30 secondes : 0 points (trop court, pas d'engagement)\n- 30 à 60 secondes : 10 points (engagement minimal)\n- 60 à 180 secondes : 25 points (durée optimale)\n- Plus de 180 secondes : 15 points (peut-être trop long ou répétitif)\n\n**2. Sentiment de la conversation (30 points)**\n- Positif : 30 points (client satisfait, conversation fluide)\n- Neutre : 15 points (pas de friction, mais pas d'enthousiasme)\n- Négatif : 0 points (frustration, incompréhension, colère)\n\n**3. Résultat de l'appel (30 points)**\n- Rendez-vous programmé : 30 points (objectif atteint)\n- Demande de rappel : 20 points (intérêt manifesté)\n- Refus de rendez-vous : 10 points (contact établi, mais pas intéressé)\n- Messagerie vocale : 5 points (pas de contact direct)\n- Pas de réponse / Occupé / Échec : 0 points (pas de conversation)\n\n**4. Fluidité technique - Latences LLM (10 points)**\n- Latence LLM moyenne < 500ms : 10 points (réactivité excellente)\n- Latence LLM moyenne 500-1000ms : 7 points (réactivité correcte)\n- Latence LLM moyenne 1000-1500ms : 4 points (quelques ralentissements)\n- Latence LLM moyenne > 1500ms : 0 points (temps de réponse trop longs)\n\n**5. Fluidité technique - Latences TTS (5 points)**\n- Latence TTS moyenne < 300ms : 5 points (génération audio rapide)\n- Latence TTS moyenne 300-500ms : 3 points (génération audio acceptable)\n- Latence TTS moyenne > 500ms : 1 point (génération audio lente)\n\n**Instructions :**\n- Calcule le score total en additionnant les points de chaque critère.\n- Retourne UNIQUEMENT un nombre entier entre 0 et 100.\n- Ne donne aucune explication, juste le score final.\n- Si certaines données manquent (ex: pas de latences), attribue 0 points à ce critère.\n\nRéponds uniquement avec le score numérique final.",
  "itemsType": "integer"
}
```

**Référence complète** : Voir `DIPLER_QUALITY_SCORE_PROMPT.md` pour plus de détails

### Étape 1.3 : Sauvegarder et tester

1. **Sauvegarder** la configuration Dipler
2. **Faire un appel test** avec l'agent Louis
3. **Vérifier** dans les logs que le payload contient :
   ```json
   {
     "conversation": {
       "postConversationAnalysis": {
         "extractedData": {
           "callQualityScore": 85  // ← Doit être présent
         }
       }
     }
   }
   ```

### Étape 1.4 : Mettre à jour n8n

1. Aller sur https://n8n.voipia.fr
2. Ouvrir le workflow **voipia-louis-endcall**
3. Trouver le node **"Prepare Supabase Insert"**
4. Ajouter le champ :
   ```javascript
   call_quality_score: $json.body.conversation.postConversationAnalysis.extractedData.callQualityScore || null,
   ```
5. **Sauvegarder** et **activer** le workflow

### Étape 1.5 : Vérifier l'insertion

1. Faire un nouvel appel test
2. Vérifier dans Supabase que `call_quality_score` est rempli :
   ```sql
   SELECT id, started_at, outcome, call_quality_score
   FROM agent_calls
   ORDER BY started_at DESC
   LIMIT 5;
   ```

### ✅ Phase 1 terminée quand :
- [ ] Prompt ajouté dans Dipler
- [ ] Appel test réussi avec score présent
- [ ] n8n mis à jour
- [ ] Score visible dans Supabase

---

## Phases 2-5 : Migrations SQL (AUTOMATIQUE)

### ⚠️ Ces migrations seront exécutées automatiquement par Claude

Claude va créer et appliquer ces migrations dans l'ordre :

1. **20251120_cleanup_call_classification.sql** - Supprimer call_classification
2. **20251120_backfill_tts_data.sql** - Remplir tts_provider/tts_voice_id
3. **20251120_add_latency_indexes.sql** - Ajouter indices GIN/B-tree sur metadata
4. **20251120_add_latency_columns.sql** - ⭐ **Ajouter 9 colonnes dédiées + backfill + RPC function**

**Note** : La migration `20251120_create_latency_rpc.sql` est obsolète et remplacée par `add_latency_columns.sql` qui fait tout en une fois (colonnes + indices + fonction RPC optimisée).

### Votre rôle

**Rien à faire** - Claude s'en occupe automatiquement.

Vous recevrez une confirmation quand les migrations sont appliquées.

### En cas d'erreur

Si une migration échoue :
1. Claude vous alertera
2. Les migrations sont dans `supabase/migrations/`
3. Vous pouvez les appliquer manuellement si besoin

---

## Phases 6-8 : Frontend Dashboard Latences (AUTOMATIQUE)

### ⚠️ Ces composants seront créés automatiquement par Claude

Claude va créer :

1. **Hook React** : `lib/hooks/useLatencyData.ts`
2. **Types** : `lib/types/latency.ts`
3. **Composant Chart** : `components/dashboard/charts/LatencyChart.tsx`
4. **Intégrations** : Dashboards Louis/Arthur/Global

### Votre rôle

**Rien à faire** - Claude s'en occupe automatiquement.

### Vérification finale

Une fois terminé :
1. Démarrer le dev server : `npm run dev`
2. Ouvrir http://localhost:3000/dashboard/louis
3. Vérifier la nouvelle section "Performance & Latences"
4. Tester les filtres de date/client/agent

---

## Phase 9 : Documentation (AUTOMATIQUE)

### ⚠️ La documentation sera mise à jour automatiquement

Claude va mettre à jour :
- `docs/DATABASE_REFERENCE.md`
- `CLAUDE.md`
- `features/addingLatencies/README.md`

---

## Checklist finale

### Après toutes les phases automatiques

- [ ] Dev server démarre sans erreur (`npm run dev`)
- [ ] Dashboard Louis affiche section latences
- [ ] Filtres de date fonctionnent
- [ ] Données latences s'affichent correctement
- [ ] Quality scores visibles dans la table
- [ ] Aucune erreur console

### Tests en production

Avant de déployer :
- [ ] Tester en staging d'abord
- [ ] Faire plusieurs appels tests
- [ ] Vérifier que n8n insère toujours les données
- [ ] Monitorer logs Supabase pour erreurs
- [ ] Valider dashboards fonctionnent

---

## Support

Si vous rencontrez un problème à n'importe quelle étape :

1. **Vérifier les logs** :
   - Logs Dipler (pour quality score)
   - Logs n8n (pour insertion)
   - Logs Supabase (pour migrations)
   - Console navigateur (pour frontend)

2. **Fichiers de référence** :
   - `IMPACT_ANALYSIS.md` - Analyse des dépendances
   - `AGENT_CALLS_SCHEMA_ANALYSIS.md` - Schema complet
   - `DIPLER_QUALITY_SCORE_PROMPT.md` - Détails quality score
   - `ANALYSE_PAYLOAD.md` - Analyse du payload

3. **Demander à Claude** :
   - Claude peut debugger et corriger les problèmes
   - Fournir les messages d'erreur exacts

---

## Prochaines étapes (optionnelles)

Une fois tout fonctionnel, vous pourriez :

1. **Créer des alertes** :
   - Alert si quality_score < 30
   - Alert si latence_moyenne > 2000ms

2. **Backfill quality scores** :
   - Scorer les anciens appels avec un workflow n8n
   - Utiliser le même prompt Dipler

3. **Optimiser le prompt** :
   - Ajuster les pondérations selon vos priorités
   - Ajouter des critères spécifiques

4. **A/B Testing** :
   - Comparer différents modèles LLM
   - Comparer différents providers TTS
   - Optimiser sur base des latences

---

**Prêt à commencer ?** Claude va maintenant exécuter les phases automatiques 2-9.

Vous devrez juste faire la Phase 1 (Dipler) manuellement quand vous serez prêt.
