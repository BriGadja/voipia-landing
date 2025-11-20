# Prompt Dipler : Call Quality Score

## Contexte

Ce prompt sera ajouté à la configuration Dipler pour calculer automatiquement un score de qualité (0-100) pour chaque appel. Le score sera retourné dans les stats de fin d'appel et alimentera la colonne `call_quality_score` dans Supabase.

---

## Prompt à ajouter dans Dipler

### Section : Post-Conversation Analysis

```
Évalue la qualité de cet appel sur une échelle de 0 à 100 en analysant les critères suivants :

**1. Durée de l'appel (25 points)**
- Moins de 30 secondes : 0 points (trop court, pas d'engagement)
- 30 à 60 secondes : 10 points (engagement minimal)
- 60 à 180 secondes : 25 points (durée optimale)
- Plus de 180 secondes : 15 points (peut-être trop long ou répétitif)

**2. Sentiment de la conversation (30 points)**
- Positif : 30 points (client satisfait, conversation fluide)
- Neutre : 15 points (pas de friction, mais pas d'enthousiasme)
- Négatif : 0 points (frustration, incompréhension, colère)

**3. Résultat de l'appel (30 points)**
- Rendez-vous programmé : 30 points (objectif atteint)
- Demande de rappel : 20 points (intérêt manifesté)
- Refus de rendez-vous : 10 points (contact établi, mais pas intéressé)
- Messagerie vocale : 5 points (pas de contact direct)
- Pas de réponse / Occupé / Échec : 0 points (pas de conversation)

**4. Fluidité technique - Latences LLM (10 points)**
- Latence LLM moyenne < 500ms : 10 points (réactivité excellente)
- Latence LLM moyenne 500-1000ms : 7 points (réactivité correcte)
- Latence LLM moyenne 1000-1500ms : 4 points (quelques ralentissements)
- Latence LLM moyenne > 1500ms : 0 points (temps de réponse trop longs)

**5. Fluidité technique - Latences TTS (5 points)**
- Latence TTS moyenne < 300ms : 5 points (génération audio rapide)
- Latence TTS moyenne 300-500ms : 3 points (génération audio acceptable)
- Latence TTS moyenne > 500ms : 1 point (génération audio lente)

**Instructions :**
- Calcule le score total en additionnant les points de chaque critère.
- Retourne UNIQUEMENT un nombre entier entre 0 et 100.
- Ne donne aucune explication, juste le score final.
- Si certaines données manquent (ex: pas de latences), attribue 0 points à ce critère.

**Exemples :**
- Appel de 90 secondes, sentiment positif, RDV pris, latence LLM 600ms, latence TTS 250ms → Score : 25 + 30 + 30 + 7 + 5 = **97/100**
- Appel de 45 secondes, sentiment neutre, refus RDV, latence LLM 800ms, latence TTS 400ms → Score : 10 + 15 + 10 + 7 + 3 = **45/100**
- Messagerie vocale 15 secondes, sentiment neutre, latence LLM 1200ms, latence TTS 350ms → Score : 0 + 15 + 5 + 4 + 3 = **27/100**

Réponds uniquement avec le score numérique final.
```

---

## Configuration Dipler

### Où placer ce prompt

**Option 1 : Data Extraction Schema (recommandé)**

Ajoutez un nouveau champ dans `postConversationDataExtractionSchema` :

```json
{
  "name": "callQualityScore",
  "isRequired": true,
  "type": "integer",
  "choices": [],
  "extractDataPrompt": "[INSÉRER LE PROMPT CI-DESSUS]",
  "itemsType": "integer"
}
```

**Option 2 : Custom Analysis Field**

Si Dipler supporte un champ custom pour les métriques, ajoutez-le dans la section `postConversationAnalysis`.

---

## Intégration n8n

### Workflow : voipia-louis-endcall

**Mise à jour du payload :**

```javascript
// Dans le node "Prepare Supabase Insert"
{
  // ... autres champs ...
  call_quality_score: $json.body.conversation.postConversationAnalysis.extractedData.callQualityScore || null,
  // ou selon la structure Dipler
  call_quality_score: $json.body.conversation.postConversationAnalysis.callQualityScore || null,
}
```

**Vérification :**
- Le score doit être un INTEGER entre 0 et 100
- Si absent, NULL est acceptable
- Ajouter une validation : `Math.min(100, Math.max(0, score))`

---

## Exemples de scores attendus

| Type d'appel | Durée | Sentiment | Outcome | Latence LLM | Latence TTS | Score |
|--------------|-------|-----------|---------|-------------|-------------|-------|
| 🟢 Excellent | 120s | Positif | RDV | 450ms | 250ms | 97/100 |
| 🟢 Très bon | 90s | Positif | Callback | 600ms | 350ms | 85/100 |
| 🟡 Moyen | 45s | Neutre | Refus | 900ms | 400ms | 45/100 |
| 🟠 Faible | 20s | Neutre | Voicemail | 1100ms | 450ms | 27/100 |
| 🔴 Mauvais | 15s | Négatif | Échec | 1600ms | 600ms | 0/100 |

---

## Avantages de cette approche

### ✅ Flexibilité
- Prompt modifiable facilement dans Dipler
- Pas besoin de redéployer du code SQL
- Ajustements rapides selon vos besoins

### ✅ Contexte complet
- Dipler a accès à TOUTES les données de l'appel
- Peut analyser la transcription, le contexte, les nuances
- Scoring plus intelligent qu'une formule SQL rigide

### ✅ Évolutif
- Facile d'ajouter de nouveaux critères
- Possible d'utiliser le LLM pour analyser des patterns
- Peut détecter des problèmes spécifiques (interruptions, incompréhensions, etc.)

---

## Variantes du prompt (optionnelles)

### Variante 1 : Scoring plus détaillé avec explications

Si vous voulez aussi l'explication du score :

```json
{
  "name": "callQualityScore",
  "type": "integer"
},
{
  "name": "callQualityExplanation",
  "type": "string",
  "extractDataPrompt": "Explique en une phrase courte pourquoi ce score a été attribué. Ex: 'Excellent appel : RDV pris, client satisfait, réactivité parfaite' ou 'Score faible : appel trop court, messagerie vocale, latences élevées'"
}
```

### Variante 2 : Scoring par catégorie

Retourner les sous-scores pour analyse détaillée :

```json
{
  "name": "qualityScoreDuration",
  "type": "integer"
},
{
  "name": "qualityScoreSentiment",
  "type": "integer"
},
{
  "name": "qualityScoreOutcome",
  "type": "integer"
},
{
  "name": "qualityScoreLatency",
  "type": "integer"
}
```

---

## Tests recommandés

### 1. Test avec appels existants

Appliquer le prompt sur quelques appels de votre historique :
- Meilleur appel (RDV pris, client heureux)
- Appel moyen (refus poli)
- Mauvais appel (messagerie, frustration)

### 2. Ajustements

Selon les résultats :
- Ajuster les seuils de durée
- Modifier les pondérations (30 points sentiment → 25 ?)
- Ajouter des critères spécifiques à vos agents

### 3. Validation

Une fois déployé :
- Vérifier que les scores semblent cohérents
- Analyser la distribution (moyenne attendue : 50-60)
- Comparer avec votre ressenti sur certains appels

---

## Implémentation recommandée

### Étape 1 : Ajouter dans Dipler (5 min)
1. Aller dans la config de votre agent Louis
2. Section "Post-Conversation Data Extraction"
3. Ajouter le champ `callQualityScore` avec le prompt
4. Sauvegarder

### Étape 2 : Tester (10 min)
1. Faire un appel test
2. Vérifier le payload `end-of-call-report`
3. Confirmer que `callQualityScore` est présent
4. Valider que c'est un INTEGER entre 0-100

### Étape 3 : Mettre à jour n8n (5 min)
1. Workflow `voipia-louis-endcall`
2. Node "Prepare Supabase Insert"
3. Ajouter : `call_quality_score: $json.body.conversation.postConversationAnalysis.extractedData.callQualityScore`
4. Activer le workflow

### Étape 4 : Backfill (optionnel)
Si vous voulez scorer les anciens appels :
- Créer un workflow n8n qui :
  1. Lit les appels sans score
  2. Passe la transcription + metadata à un LLM
  3. Calcule le score avec le même prompt
  4. Update la table

---

## Support et ajustements

Ce prompt est un **point de départ**. N'hésitez pas à :
- Ajuster les pondérations selon vos priorités
- Ajouter des critères spécifiques (ex: "nombre de fois où le client a dit 'je ne comprends pas'")
- Créer des scores différents par type d'agent (Louis vs Arthur)
- Utiliser le score pour des alertes (score < 30 = escalade)

---

**Date de création :** 2025-01-20
**Auteur :** Claude
**Version :** 1.0
**Statut :** Prêt pour implémentation
