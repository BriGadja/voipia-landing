# Analyse du Payload end-of-call-report

## Vue d'ensemble

Ce payload contient une mine de données pour analyser les performances et la qualité des appels de vos agents IA. Voici une analyse détaillée des données disponibles et leurs utilisations potentielles.

---

## 1. 📊 Données de Latence (Déjà identifiées)

### A. Latences agrégées (`stats.latencies`)

**Actuellement disponibles** :
```json
"latencies": {
  "llmLatencies": { "min": 555, "max": 1110, "average": 725, "count": 4 },
  "ttsLatencies": { "min": 207, "max": 207, "average": 207, "count": 1 },
  "totalLatencies": { "min": 555, "max": 1110, "average": 777, "count": 4 }
}
```

**Utilisation** :
- Suivre la performance moyenne/min/max des LLM et TTS
- Identifier les pics de latence
- Optimiser les temps de réponse

### B. Latences détaillées par message

**Dans chaque message de `conversation.messages`** :
```json
"llmStats": {
  "firstReadableChunkLatency": 488,  // Temps avant le 1er chunk lisible
  "latency": 607                      // Latence totale LLM
},
"ttsStats": {
  "completeLatency": 2092,            // Latence totale TTS
  "firstChunkLatency": 377            // Temps avant le 1er chunk audio
},
"latencyBetweenLlmAndStartSpeaking": 207  // Délai LLM → début TTS
```

**Utilisation potentielle** :
- Analyser les latences tour par tour (quel turn a le plus de latence ?)
- Détecter les variations de performance durant l'appel
- Identifier si certaines phases de la conversation sont plus lentes

---

## 2. 🎯 Données d'Analyse de Conversation (Très utiles !)

### `postConversationAnalysis` (lignes 202-212)

```json
{
  "sentiment": "neutral",                    // positive, negative, neutral
  "sentimentExplanation": "...",            // Explication du sentiment
  "summary": "...",                         // Résumé de la conversation
  "tags": ["noProfilChangeAsked"],          // Tags automatiques
  "isVoiceMail": true,                      // Détection messagerie
  "extractedData": {
    "callClassification": "voicemail"       // Classification de l'appel
  }
}
```

**✅ TRÈS UTILE pour :**
- **Analyse qualitative** : Comprendre le sentiment global des appels
- **Segmentation** : Filtrer les appels par sentiment (positif/négatif/neutre)
- **Détection de problèmes** : Identifier rapidement les appels problématiques
- **Amélioration continue** : Comprendre ce qui génère de la frustration
- **KPI qualité** : Taux de satisfaction estimé

**Pourrait enrichir votre table `agent_calls`** :
- Ajouter colonne `sentiment` (ENUM: 'positive', 'negative', 'neutral')
- Ajouter colonne `sentiment_explanation` (TEXT)
- Ajouter colonne `conversation_summary` (TEXT)

---

## 3. 📞 LogHistory - Timeline complète de l'appel

### `conversation.logHistory` (lignes 218-312)

Timeline précise de tous les événements :
```json
[
  {"type": "sessionStarted", "timestamp": 1763625406686},
  {"type": "userSpeechStart", "timestamp": 1763625407512},
  {"type": "userSpeechEnd", "timestamp": 1763625408231},
  {"type": "sttTranscription", "timestamp": 1763625408727},
  {"type": "llmComplete", "timestamp": 1763625409335, "turnIndex": 4},
  {"type": "ttsComplete", "timestamp": 1763625411438, "turnIndex": 4},
  {"type": "modelSpeechStart", "timestamp": 1763625419769},
  {"type": "modelSpeechEnd", "timestamp": 1763625430477},
  {"type": "hungUp", "timestamp": 1763625430478}
]
```

**✅ TRÈS UTILE pour :**
- **Calcul de métriques avancées** :
  - Temps entre userSpeechEnd et llmComplete (latence de traitement)
  - Temps entre llmComplete et ttsComplete (génération audio)
  - Temps entre ttsComplete et modelSpeechStart (buffering)
  - Durée totale de parole de l'agent vs utilisateur
- **Détection de silences** : Combien de temps entre userSpeechEnd et modelSpeechStart ?
- **Analyse d'interruptions** : userSpeechStart pendant modelSpeech = interruption
- **Fluidité de la conversation** : Temps de réponse moyen

**Possibilités d'analyse** :
- Moyenne du temps de réponse (userSpeechEnd → llmComplete)
- Distribution des pauses/silences
- Taux d'interruption (utilisateur coupe l'agent)
- Identification des "dead air" (silences trop longs)

---

## 4. 💰 Statistiques de Coûts détaillées

### Actuellement vous utilisez :
- Prix STT/TTS/LLM par appel
- Coût total de session

### Données supplémentaires disponibles :

**A. Détails par composant** :
```json
"sttStats": {
  "durationSeconds": 24.86,
  "price": 0.00083
},
"llmStats": {
  "textInputTokens": 65870,
  "textOutputTokens": 227,
  "textInputPrice": 0.01975,
  "textOutputPrice": 0.00058,
  "totalPrice": 0.02033,
  "generationsCount": 5           // ← Nombre d'appels LLM
},
"ttsStats": {
  "totalGenerationTime": 5138,    // ← Temps total de génération TTS (ms)
  "totalPrice": 0.0245,
  "instances": [{
    "generatedSeconds": 17.18,    // ← Durée audio générée
    "generatedChars": 377          // ← Nb caractères générés
  }]
}
```

**B. Coûts téléphonie** :
```json
"callInfos": {
  "callCost": 0.0404,             // Coût Twilio
  "callPriceUnit": "USD"
}
"diplerCommission": 0.01733,      // Commission Dipler
"sessionTotalPriceIncludingTwilioNotBilledByDipler": 0.10378
```

**✅ UTILE pour :**
- **Analyse de rentabilité fine** : Coût par composant
- **Optimisation des coûts** : Identifier quel composant coûte le plus
- **Prédiction de coûts** : Estimer le coût d'un appel en fonction des tokens
- **Dashboard financier avancé** : Breakdown par techno (STT vs TTS vs LLM vs Telecom)

---

## 5. 🎙️ Qualité Audio & Performance TTS

### Données TTS par message :
```json
"ttsStats": {
  "price": 0.01033,
  "nbChars": 159,                 // Nombre de caractères
  "durationSeconds": 6.502,       // Durée audio générée
  "voiceKey": "cartesiaTts:..."   // Voix utilisée
}
```

**✅ UTILE pour :**
- **Vitesse de parole** : nbChars / durationSeconds = chars/seconde
- **Comparaison de voix** : Quelle voix génère le plus rapidement ?
- **Optimisation de verbosité** : Détecter les messages trop longs
- **Cohérence** : Durée moyenne d'un message par agent

**Calcul possible** :
- Vitesse de parole moyenne : ~24 chars/seconde (159 chars / 6.5s)
- Messages trop longs : > 30 secondes
- Messages trop courts : < 2 secondes

---

## 6. 📝 Tokens & Contexte LLM

### Statistiques LLM détaillées :
```json
"systemPromptStats": {
  "charCount": 21999,
  "tokenCount": 5711              // ← Taille du system prompt
},
"llmStats": {
  "textInputTokens": 65870,       // Total tokens input (toute la conversation)
  "textOutputTokens": 227,        // Total tokens output
  "generationsCount": 5           // Nombre d'appels LLM
}
```

**Par message** :
```json
"llmStats": {
  "textInputTokens": 13114,       // Tokens input pour CE message
  "textOutputTokens": 48,         // Tokens output pour CE message
  "model": "gemini-2.5-flash"
}
```

**✅ TRÈS UTILE pour :**
- **Optimisation du prompt** : System prompt trop long ? (5711 tokens = coûteux)
- **Croissance du contexte** : Tracking de l'augmentation des tokens au fil de la conversation
- **Détection de prompts inefficaces** : textInputTokens élevés avec peu d'output
- **Coût par génération** : Prix moyen d'un appel LLM
- **Efficacité du modèle** : Output tokens / Input tokens ratio

**Analyse possible** :
- Graphique : Evolution des tokens input au fil des turns
- KPI : Token efficiency = Output / Input
- Alerte : Conversations qui dépassent le context window

---

## 7. 🗣️ Analyse conversationnelle avancée

### A. Messages et Turns
```json
"messageCount": 8,                // Nombre de messages échangés
"conversation.messages": [...]    // Tous les messages avec timestamps
```

**✅ UTILE pour :**
- **Longueur de conversation** : Nombre moyen de tours de parole
- **Distribution** : Combien de conversations ont X tours ?
- **Détection d'abandons** : Conversations trop courtes (< 3 messages)
- **Engagement** : Plus de tours = meilleur engagement ?

### B. Transcript complet
```json
"transcript": "User : ... Model : ... User : ..."
```

**✅ UTILE pour :**
- **Analyse sémantique** : Extraction de mots-clés, entités
- **Détection de problèmes récurrents** : Quelles questions reviennent ?
- **Formation du modèle** : Dataset pour fine-tuning
- **Analyse de compliance** : Vérifier que l'agent suit le script

### C. Tool Calls
```json
"functionCall": {
  "name": "hangUp",
  "args": {"isVoiceMail": true}
}
```

**✅ UTILE pour :**
- **Usage des fonctions** : Quels tools sont les plus appelés ?
- **Taux de succès** : sendConfirmation appelé = RDV pris ?
- **Analyse de flow** : Combien d'appels avant hangUp ?
- **Détection d'erreurs** : Tool calls échoués ?

---

## 8. 📡 Configuration & Stack technique

### Stack utilisé :
```json
"stack": {
  "stt": "sstt",
  "llm": "gemini-2.5-flash",
  "tts": [{
    "ttsProvider": "cartesiaTts",
    "voiceId": "39881201-9d47-45f6-b8e1-f7a1ea55da1f",
    "languageRule": "default"
  }]
}
```

**✅ UTILE pour :**
- **A/B Testing** : Comparer gemini-2.5-flash vs autres modèles
- **Performance par provider** : SStt vs Azure vs Google STT
- **Optimisation voix** : Quelle voix performe le mieux ?
- **Traçabilité** : Savoir exactement quelle config a été utilisée

---

## 9. 🎤 Enregistrements Audio

### URLs signées disponibles :
```json
"recordingSignedUrl": "...",           // Enregistrement complet
"userMicRecordingSignedUrl": "...",    // Audio utilisateur seul
"vadAudioRecordingSignedUrl": "..."    // Audio VAD
```

**✅ UTILE pour :**
- **Contrôle qualité** : Écouter les appels problématiques
- **Formation équipe** : Partager exemples de bons/mauvais appels
- **Analyse audio avancée** : Détection d'émotions par analyse vocale
- **Compliance** : Archivage légal des enregistrements

---

## 10. 📋 Variables de session & Contexte CRM

### Variables injectées :
```json
"sessionVariables": {
  "voipiaCallId": "...",
  "personCRMId": "228",
  "mail": "brice@voipia.fr",
  "dealId": "279",
  "deploymentId": "...",
  "telephone": "+33648057431",
  "prenom": "Brice",
  "nom": "Testgacha",
  "direction": "outbound"
}
```

**✅ UTILE pour :**
- **Enrichissement CRM** : Lier appel à Pipedrive/HubSpot
- **Segmentation** : Analyser par deal, par personne
- **Attribution** : Quel deployment a généré l'appel ?
- **Direction** : Comparer inbound vs outbound

---

## 📊 Recommandations pour enrichir agent_calls

### Colonnes à ajouter (par priorité) :

#### 🔴 Haute priorité

1. **Sentiment & Qualité** :
   - `sentiment` (ENUM: 'positive', 'negative', 'neutral')
   - `sentiment_explanation` (TEXT)
   - `conversation_summary` (TEXT)

2. **Latences détaillées** :
   - `llm_latency_avg` (FLOAT) - ms
   - `llm_latency_min` (FLOAT) - ms
   - `llm_latency_max` (FLOAT) - ms
   - `tts_latency_avg` (FLOAT) - ms
   - `first_response_latency` (FLOAT) - Temps avant 1ère réponse

3. **Tokens & Contexte** :
   - `llm_input_tokens` (INTEGER)
   - `llm_output_tokens` (INTEGER)
   - `llm_generations_count` (INTEGER) - Nb d'appels LLM
   - `system_prompt_tokens` (INTEGER)

#### 🟡 Priorité moyenne

4. **Performance conversationnelle** :
   - `message_count` (INTEGER) - Nombre de tours de parole
   - `user_speech_duration` (FLOAT) - Durée totale de parole utilisateur
   - `agent_speech_duration` (FLOAT) - Durée totale de parole agent
   - `silence_duration` (FLOAT) - Durée totale de silences

5. **TTS/STT détails** :
   - `tts_chars_generated` (INTEGER)
   - `tts_audio_duration` (FLOAT) - secondes
   - `stt_duration` (FLOAT) - secondes d'audio transcrit
   - `speech_rate` (FLOAT) - chars/seconde (vitesse de parole)

#### 🟢 Priorité basse (nice to have)

6. **Coûts détaillés** :
   - `dipler_commission` (DECIMAL)
   - `twilio_cost` (DECIMAL)
   - `total_cost_with_telco` (DECIMAL)

7. **Technique** :
   - `llm_model` (VARCHAR) - ex: "gemini-2.5-flash"
   - `tts_provider` (VARCHAR) - ex: "cartesiaTts"
   - `stt_provider` (VARCHAR) - ex: "sstt"
   - `voice_id` (VARCHAR)

8. **Audio & Enregistrements** :
   - `recording_url` (TEXT) - URL S3 de l'enregistrement
   - `has_recording` (BOOLEAN)

---

## 🎯 Cas d'usage avancés

### 1. Dashboard Qualité
- **Taux de satisfaction** : % sentiment positive
- **Appels problématiques** : Liste des sentiment negative avec explanations
- **Top 5 problèmes récurrents** : Analyse des sentiment_explanation

### 2. Dashboard Performance
- **Latence moyenne par agent** : Comparer Louis vs Arthur vs Alexandra
- **Évolution de la latence** : Graphique temporel
- **Peak hours** : Quelles heures ont les pires latences ?

### 3. Dashboard Efficacité conversationnelle
- **Durée moyenne par outcome** : appointment_scheduled vs voicemail vs not_interested
- **Nombre de tours optimal** : Corrélation message_count vs taux de conversion
- **Taux d'interruption** : Combien de fois l'utilisateur coupe l'agent ?

### 4. Dashboard Coûts avancé
- **Coût par composant** : STT vs TTS vs LLM vs Telecom (pie chart)
- **Coût par minute de conversation** : averagePricePerMinute tracking
- **ROI par appel** : (Revenu - Coût) / Coût
- **Efficacité token** : Coût LLM / Nombre de RDV pris

### 5. Analyse prédictive
- **Prédire le sentiment** : ML model avec latences + message_count + duration
- **Prédire le coût** : Estimer coût avant l'appel (basé sur historique)
- **Détection précoce d'échec** : Si latence > X à turn 2, probabilité voicemail élevée

---

## 🚀 Actions recommandées

### Phase 1 : Latences (en cours)
✅ Ajouter `llm_latency_avg`, `llm_latency_max`, `tts_latency_avg`, `first_response_latency`

### Phase 2 : Sentiment & Qualité
- Ajouter `sentiment`, `sentiment_explanation`, `conversation_summary`
- Créer dashboard "Appels problématiques"
- Alertes automatiques sur sentiment = 'negative'

### Phase 3 : Tokens & Contexte
- Ajouter `llm_input_tokens`, `llm_output_tokens`, `llm_generations_count`
- Analyse de l'efficacité du prompt
- Optimisation du system prompt (réduire tokenCount)

### Phase 4 : Performance conversationnelle
- Ajouter `message_count`, `user_speech_duration`, `agent_speech_duration`
- Analyse de la fluidité (silences, interruptions)
- KPI : Durée idéale de conversation par outcome

### Phase 5 : Coûts avancés
- Ajouter breakdown par composant
- Dashboard "Coût par technologie"
- Optimisation basée sur coût/performance ratio

---

## 💡 Conclusion

Vous avez accès à **beaucoup plus de données que vous n'utilisez actuellement** !

**Top 3 des données les plus impactantes à ajouter** :
1. **Sentiment Analysis** → Comprendre la satisfaction client
2. **Message Count & Speech Durations** → Analyser l'engagement conversationnel
3. **LLM Tokens détaillés** → Optimiser les coûts et le prompt

Ces données vous permettront de passer d'un dashboard "opérationnel" (combien d'appels ?) à un dashboard "stratégique" (quelle qualité d'appels ? comment optimiser ?).

Souhaitez-vous que je vous aide à implémenter l'une de ces phases ?
