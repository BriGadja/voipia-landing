# 📞 Guide Pré-Call INSERT - agent_calls

**Objectif** : Créer une ligne dans `agent_calls` AVANT le début de l'appel pour récupérer le `call_id` et le passer à Vapi/tools.

---

## 🎯 Architecture CREATE → USE → UPDATE

```
┌─────────────────────┐
│ 1. PRÉ-CALL         │
│ n8n: Create Call    │
│ → INSERT minimal    │
│ → RETURNING id      │
└──────────┬──────────┘
           │ call_id
           ▼
┌─────────────────────┐
│ 2. PENDANT APPEL    │
│ Vapi: Use call_id   │
│ → Passer aux tools  │
│ → send_email(id)    │
│ → send_sms(id)      │
└──────────┬──────────┘
           │ end_call_webhook
           ▼
┌─────────────────────┐
│ 3. POST-CALL        │
│ n8n: Update Call    │
│ → UPDATE full data  │
│ → outcome, costs    │
└─────────────────────┘
```

---

## 📋 Champs Minimum Requis (3 champs)

### Obligatoires (NOT NULL sans default)

| Champ | Type | Source | Exemple |
|-------|------|--------|---------|
| `deployment_id` | UUID | Config n8n | `{{ $('Get Deployment').item.json.id }}` |
| `phone_number` | TEXT | Trigger data | `{{ $json.contact.phone }}` |
| `started_at` | TIMESTAMPTZ | NOW() | `{{ new Date().toISOString() }}` |

### Recommandés (pour tracking)

| Champ | Type | Source | Exemple |
|-------|------|--------|---------|
| `call_status` | TEXT | Static | `in_progress` |
| `first_name` | TEXT | Trigger data | `{{ $json.contact.firstName }}` |
| `last_name` | TEXT | Trigger data | `{{ $json.contact.lastName }}` |
| `email` | TEXT | Trigger data | `{{ $json.contact.email }}` |
| `direction` | TEXT | Static | `outbound` |

---

## 🔧 Configuration n8n

### Node 1 : Get Deployment (Supabase - Select)

**Type** : `n8n-nodes-base.supabase`
**Operation** : `Get Rows`

| Paramètre | Valeur |
|-----------|--------|
| **Table** | `agent_deployments` |
| **Filter** | `id = {{ $json.deploymentId }}` |
| **Select** | `id, name, client_id, cost_per_email` |

---

### Node 2 : Create Call (Supabase - Insert)

**Type** : `n8n-nodes-base.supabase`
**Operation** : `Insert Rows`
**Table** : `agent_calls`

#### Configuration JSON (Minimum)

```json
{
  "deployment_id": "={{ $('Get Deployment').item.json.id }}",
  "phone_number": "={{ $json.contact.phone }}",
  "started_at": "={{ new Date().toISOString() }}",
  "call_status": "in_progress"
}
```

#### Configuration JSON (Recommandée)

```json
{
  "deployment_id": "={{ $('Get Deployment').item.json.id }}",
  "phone_number": "={{ $json.contact.phone }}",
  "first_name": "={{ $json.contact.firstName || null }}",
  "last_name": "={{ $json.contact.lastName || null }}",
  "email": "={{ $json.contact.email || null }}",
  "started_at": "={{ new Date().toISOString() }}",
  "call_status": "in_progress",
  "direction": "outbound",
  "metadata": "={{ { triggerSource: $json.triggerSource, campaign: $json.campaign } }}"
}
```

**⚠️ IMPORTANT** : Activer **"Return All Fields"** pour récupérer le `id` généré !

---

### Node 3 : Trigger Vapi Call

**Type** : `n8n-nodes-base.httpRequest` ou `n8n-nodes-base.webhook`

**Passer le call_id à Vapi** :

```json
{
  "phoneNumber": "={{ $json.contact.phone }}",
  "assistantId": "{{ $json.vapiAssistantId }}",
  "variables": {
    "call_id": "={{ $('Create Call').item.json.id }}",
    "first_name": "={{ $json.contact.firstName }}",
    "deployment_id": "={{ $('Get Deployment').item.json.id }}"
  }
}
```

**Ces variables seront accessibles** dans les tools Vapi :
- `{{call_id}}` → UUID de la ligne agent_calls
- `{{deployment_id}}` → UUID du deployment
- `{{first_name}}` → Prénom du contact

---

### Node 4 : End Call Webhook (Trigger)

**Type** : `n8n-nodes-base.webhook`
**Method** : `POST`
**Path** : `/webhook/vapi/end-call`

**Données reçues de Vapi** :
```json
{
  "call_id": "abc-123-xyz",
  "conversation_id": "vapi-conv-456",
  "outcome": "appointment_scheduled",
  "duration": 120,
  "transcript": "...",
  "costs": {
    "stt": 0.10,
    "tts": 0.15,
    "llm": 0.20,
    "telecom": 0.05
  }
}
```

---

### Node 5 : Update Call (Supabase - Update)

**Type** : `n8n-nodes-base.supabase`
**Operation** : `Update Rows`
**Table** : `agent_calls`

**Filter** :
```json
{
  "id": {
    "eq": "={{ $json.call_id }}"
  }
}
```

**Fields to Update** :

```json
{
  "ended_at": "={{ new Date().toISOString() }}",
  "duration_seconds": "={{ $json.duration }}",
  "outcome": "={{ $json.outcome }}",
  "emotion": "={{ $json.emotion || null }}",
  "total_cost": "={{ $json.costs.total }}",
  "stt_cost": "={{ $json.costs.stt }}",
  "tts_cost": "={{ $json.costs.tts }}",
  "llm_cost": "={{ $json.costs.llm }}",
  "telecom_cost": "={{ $json.costs.telecom }}",
  "transcript": "={{ $json.transcript || null }}",
  "transcript_summary": "={{ $json.summary || null }}",
  "recording_url": "={{ $json.recording_url || null }}",
  "conversation_id": "={{ $json.conversation_id }}",
  "call_status": "completed"
}
```

---

## 🧪 Exemple Complet avec Données Réelles

### Input du Workflow (Trigger)

```json
{
  "deploymentId": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "vapiAssistantId": "vapi-louis-123",
  "contact": {
    "phone": "+33612345678",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com"
  },
  "campaign": "rdv_relance_q4",
  "triggerSource": "manual"
}
```

### Step 1 : Get Deployment Output

```json
{
  "id": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "name": "Louis - Voipia",
  "client_id": "abc-client-123",
  "cost_per_email": 0.01
}
```

### Step 2 : Create Call Output

```json
{
  "id": "f8e9a1b2-c3d4-5e6f-7890-123456789abc",
  "deployment_id": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "phone_number": "+33612345678",
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "started_at": "2025-11-14T10:30:00Z",
  "call_status": "in_progress",
  "created_at": "2025-11-14T10:30:00Z"
}
```

**call_id récupéré** : `f8e9a1b2-c3d4-5e6f-7890-123456789abc`

### Step 3 : Vapi Call Triggered

Variables passées à Vapi :
```json
{
  "call_id": "f8e9a1b2-c3d4-5e6f-7890-123456789abc",
  "first_name": "John",
  "deployment_id": "348cc94d-b4e8-4281-b33a-bc9378fecffc"
}
```

**Dans les tools Vapi** (send_email, send_sms) :
- `call_id` est disponible comme `{{call_id}}`
- Passer ce call_id au workflow n8n send_email/send_sms

### Step 4 : End Call Webhook Received

```json
{
  "call_id": "f8e9a1b2-c3d4-5e6f-7890-123456789abc",
  "conversation_id": "vapi-conv-789xyz",
  "outcome": "appointment_scheduled",
  "emotion": "positive",
  "duration": 145,
  "transcript": "Bonjour John, je suis Louis...",
  "summary": "Client a pris RDV pour le 20 novembre à 14h",
  "recording_url": "https://storage.vapi.ai/recordings/...",
  "costs": {
    "stt": 0.12,
    "tts": 0.18,
    "llm": 0.25,
    "telecom": 0.07,
    "total": 0.62
  }
}
```

### Step 5 : Update Call Executed

```sql
UPDATE public.agent_calls
SET
    ended_at = '2025-11-14T10:32:25Z',
    duration_seconds = 145,
    outcome = 'appointment_scheduled',
    emotion = 'positive',
    total_cost = 0.62,
    stt_cost = 0.12,
    tts_cost = 0.18,
    llm_cost = 0.25,
    telecom_cost = 0.07,
    transcript = 'Bonjour John, je suis Louis...',
    transcript_summary = 'Client a pris RDV pour le 20 novembre à 14h',
    recording_url = 'https://storage.vapi.ai/recordings/...',
    conversation_id = 'vapi-conv-789xyz',
    call_status = 'completed'
WHERE id = 'f8e9a1b2-c3d4-5e6f-7890-123456789abc';
```

**Résultat Final** : Ligne complète dans `agent_calls` avec toutes les données !

---

## 🔗 Utilisation dans les Tools send_email / send_sms

### Tool send_email (exemple)

**Input reçu par le workflow n8n** :

```json
{
  "call_id": "f8e9a1b2-c3d4-5e6f-7890-123456789abc",
  "deployment_id": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "recipient": {
    "email": "john.doe@example.com",
    "firstName": "John",
    "lastName": "Doe"
  },
  "subject": "Confirmation de votre rendez-vous",
  "body": "Bonjour John, votre RDV est confirmé pour le 20 novembre à 14h."
}
```

**Node Supabase Insert dans agent_emails** :

```json
{
  "deployment_id": "={{ $json.deployment_id }}",
  "call_id": "={{ $json.call_id }}",
  "email_address": "={{ $json.recipient.email }}",
  "first_name": "={{ $json.recipient.firstName }}",
  "last_name": "={{ $json.recipient.lastName }}",
  "email_subject": "={{ $json.subject }}",
  "email_body_text": "={{ $json.body }}",
  "email_type": "appointment_confirmation",
  "status": "sent",
  "sent_at": "={{ new Date().toISOString() }}",
  "provider_cost": 0,
  "billed_cost": "={{ $('Get Deployment').item.json.cost_per_email || 0 }}"
}
```

**Résultat** : Email tracké dans `agent_emails` avec le lien vers `agent_calls` via `call_id` !

---

## ✅ Checklist Validation

Avant de déployer :

- [ ] Node "Get Deployment" récupère `cost_per_email`
- [ ] Node "Create Call" INSERT avec 3 champs minimum
- [ ] Node "Create Call" a **"Return All Fields"** activé
- [ ] call_id est bien récupéré : `{{ $('Create Call').item.json.id }}`
- [ ] call_id est passé à Vapi dans les variables
- [ ] Vapi peut accéder à `{{call_id}}` dans les tools
- [ ] End call webhook reçoit bien `call_id` de Vapi
- [ ] Node "Update Call" filtre sur `id = call_id`
- [ ] Tous les champs de l'UPDATE sont bien mappés

---

## 🚨 Erreurs Courantes

### ❌ Erreur : "call_id undefined dans les tools"
**Cause** : call_id non passé dans les variables Vapi
**Solution** : Vérifier la payload de trigger Vapi inclut `variables: { call_id: ... }`

### ❌ Erreur : "Cannot read property 'id' of undefined"
**Cause** : Node "Create Call" ne retourne pas l'ID
**Solution** : Activer **"Return All Fields"** dans la config Supabase

### ❌ Erreur : "UPDATE matched 0 rows"
**Cause** : call_id du webhook ne correspond à aucune ligne
**Solution** : Vérifier que Vapi renvoie bien le même call_id dans le webhook end_call

### ❌ Erreur : "deployment_id cannot be null"
**Cause** : Get Deployment échouée ou pas exécutée avant Create Call
**Solution** : Vérifier l'ordre des nodes et le mapping

---

## 📚 Ressources Connexes

- **Email Tracking** : `features/email-tracking/n8n_param/WORKFLOW_GUIDE.md`
- **SMS Tracking** : `features/sms-tracking/n8n_param/SUPABASE_INSERT_SMS_CONFIG.json`
- **Schema agent_calls** : Base Supabase → Table `agent_calls`

---

**Version** : 1.0
**Date** : 2025-11-14
**Auteur** : Claude
**Compatibilité** : n8n 1.0+, Supabase PostgreSQL 15+, Vapi
