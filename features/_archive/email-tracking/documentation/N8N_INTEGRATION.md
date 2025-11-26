# 🔗 Guide d'Intégration n8n - Email Tracking

## Vue d'ensemble

Ce guide explique comment intégrer le tracking des emails dans vos workflows n8n existants en ajoutant une node Supabase après l'envoi d'emails via Gmail.

**Date** : 2025-11-14
**Version** : 1.0

---

## 🎯 Objectif

Après chaque email envoyé par un workflow n8n, enregistrer automatiquement les métadonnées dans la table `agent_emails` pour :
- ✅ Tracker tous les emails envoyés par agent/deployment
- ✅ Associer les emails aux appels, prospects, séquences
- ✅ Générer des métriques analytics (volume, delivery rate, etc.)
- ✅ Debugger les problèmes d'envoi (logs, statuts)

---

## 📋 Prérequis

### 1. Supabase Connection

Vérifier que votre workspace n8n a accès au projet Supabase :
- **Credentials** : `Supabase Voipia` ou `Supabase Staging`
- **URL** : https://[project-ref].supabase.co
- **Service Role Key** : Clé avec permissions INSERT/UPDATE sur `agent_emails`

### 2. Migration Appliquée

Assurez-vous que la table `agent_emails` existe en production/staging :
```bash
# Vérifier dans Supabase SQL Editor
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'agent_emails';
```

---

## 🏗️ Architecture d'un Workflow

```
┌─────────────────┐
│  Trigger        │
│  (Schedule,     │
│   Webhook, etc.)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Get Deployment │ ← Récupérer deployment_id, cost_per_email, client_id, agent_type
│  (Supabase GET) │   🆕 Inclure cost_per_email pour pricing dynamique
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Get Recipient  │ ← Récupérer email_address, first_name, last_name
│  (Call, Prospect│   (depuis agent_calls, agent_arthur_prospects, etc.)
│   ou autre)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Prepare Email  │ ← Construire subject, body_html, body_text
│  Content        │   (Template engine, variables, etc.)
│  (Code/Template)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Send Email     │ ← Node Gmail : Envoyer l'email
│  (Gmail Node)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Log to         │ ← 🆕 Node Supabase : INSERT dans agent_emails
│  agent_emails   │
│  (Supabase)     │
└─────────────────┘
```

---

## 🔧 Configuration de la Node Supabase

### Node Type : **Supabase - Insert**

**Credentials** : `Supabase Voipia` (ou `Supabase Staging` pour tests)

**Table** : `agent_emails`

**Insert Mode** : `Insert`

### Mapping des Champs

#### ✅ Champs Obligatoires

| Champ n8n | Expression | Type | Description |
|-----------|------------|------|-------------|
| `deployment_id` | `{{ $('Get Deployment').item.json.id }}` | UUID | ID de l'agent deployment |
| `email_address` | `{{ $('Get Recipient').item.json.email }}` | TEXT | Email du destinataire |
| `email_subject` | `{{ $('Prepare Email').item.json.subject }}` | TEXT | Sujet de l'email |
| `status` | `'sent'` | TEXT | Statut initial (fixe à 'sent' si envoi réussi) |
| `sent_at` | `{{ $now }}` | TIMESTAMPTZ | Date/heure d'envoi |
| `provider_cost` | `0` | NUMERIC | Coût provider (Gmail = 0€, SendGrid = 0.0012€) |
| `billed_cost` | `{{ $('Get Deployment').item.json.cost_per_email }}` | NUMERIC | 🆕 Prix facturé client (récupéré depuis cost_per_email) |

#### 📝 Champs Recommandés

| Champ n8n | Expression | Type | Description |
|-----------|------------|------|-------------|
| `call_id` | `{{ $('Get Call').item.json.id }}` | UUID | Appel associé (si follow-up) |
| `prospect_id` | `{{ $('Get Prospect').item.json.id }}` | UUID | Prospect Arthur associé |
| `sequence_id` | `{{ $('Get Sequence').item.json.id }}` | UUID | Séquence multi-touch associée |
| `first_name` | `{{ $('Get Recipient').item.json.first_name }}` | TEXT | Prénom du destinataire |
| `last_name` | `{{ $('Get Recipient').item.json.last_name }}` | TEXT | Nom du destinataire |
| `email_body_html` | `{{ $('Prepare Email').item.json.body_html }}` | TEXT | Corps HTML de l'email |
| `email_body_text` | `{{ $('Prepare Email').item.json.body_text }}` | TEXT | Corps texte brut (fallback) |
| `email_type` | `'follow_up'` | TEXT | Type : follow_up, cold_email, appointment_confirmation, sequence_step |
| `workflow_id` | `{{ $workflow.id }}` | TEXT | ID du workflow n8n |
| `workflow_execution_id` | `{{ $execution.id }}` | TEXT | ID de l'exécution n8n |

#### 🔮 Champs Optionnels

| Champ n8n | Expression | Type | Description |
|-----------|------------|------|-------------|
| `workflow_message_id` | `{{ $('Send Email').item.json.id }}` | TEXT | ID du message Gmail (si disponible) |
| `gmail_thread_id` | `{{ $('Send Email').item.json.threadId }}` | TEXT | ID du thread Gmail |
| `has_attachments` | `{{ $('Send Email').item.json.attachments.length > 0 }}` | BOOLEAN | Présence de pièces jointes |
| `attachment_names` | `{{ $('Send Email').item.json.attachments.map(a => a.name) }}` | TEXT[] | Noms des fichiers joints |
| `metadata` | `{{ { template: 'follow_up_v2', campaign: 'Q4_2024' } }}` | JSONB | Métadonnées flexibles (JSON) |

---

## 📦 Exemple Complet : Follow-Up Email après Appel

### Workflow "Louis - Send Follow-Up Email"

#### Node 1 : Trigger (Schedule)
```
Type: Schedule Trigger
Cron: 0 9 * * * (chaque jour à 9h)
```

#### Node 2 : Get Calls Requiring Follow-Up
```
Type: Supabase - Select
Table: agent_calls
Filter: outcome = 'appointment_scheduled' AND follow_up_email_sent = FALSE
Limit: 50
```

#### Node 3 : Get Deployment Info (🆕 avec cost_per_email)
```
Type: Supabase - Select
Table: agent_deployments
Filter: id = {{ $('Get Calls').item.json.deployment_id }}
Select Fields: id, name, client_id, agent_type_id, cost_per_email  ← 🆕 Inclure pricing
```

**Sortie attendue** :
```json
{
  "id": "uuid-dep-001",
  "name": "Louis - ACME Corp",
  "client_id": "uuid-client-001",
  "agent_type_id": "uuid-agent-louis",
  "cost_per_email": 0.0000  ← Pricing dynamique (0€ par défaut)
}
```

#### Node 4 : Prepare Email Content
```
Type: Code Node (JavaScript)

// Input: $('Get Calls').item.json (call data)
const call = $input.item.json;

return {
  subject: `Confirmation de votre rendez-vous avec ${call.first_name}`,
  body_html: `
    <html>
      <body>
        <h2>Bonjour ${call.first_name},</h2>
        <p>Suite à notre échange téléphonique de ${call.duration_seconds}s,
           je vous confirme votre rendez-vous.</p>
        <p><strong>Date :</strong> ${call.metadata.appointment_date}</p>
        <p><strong>Heure :</strong> ${call.metadata.appointment_time}</p>
        <p>Cordialement,<br>Louis - Assistant Voipia</p>
      </body>
    </html>
  `,
  body_text: `
    Bonjour ${call.first_name},
    Suite à notre échange téléphonique, je vous confirme votre rendez-vous.
    Date : ${call.metadata.appointment_date}
    Heure : ${call.metadata.appointment_time}
    Cordialement, Louis
  `
};
```

#### Node 5 : Send Email (Gmail)
```
Type: Gmail - Send Email
To: {{ $('Get Calls').item.json.email }}
Subject: {{ $('Prepare Email').item.json.subject }}
Body (HTML): {{ $('Prepare Email').item.json.body_html }}
```

#### Node 6 : 🆕 Log to agent_emails (Supabase)
```
Type: Supabase - Insert
Table: agent_emails

Fields:
  deployment_id: {{ $('Get Deployment').item.json.id }}
  call_id: {{ $('Get Calls').item.json.id }}
  email_address: {{ $('Get Calls').item.json.email }}
  first_name: {{ $('Get Calls').item.json.first_name }}
  last_name: {{ $('Get Calls').item.json.last_name }}
  email_subject: {{ $('Prepare Email').item.json.subject }}
  email_body_html: {{ $('Prepare Email').item.json.body_html }}
  email_body_text: {{ $('Prepare Email').item.json.body_text }}
  email_type: 'appointment_confirmation'
  status: 'sent'
  sent_at: {{ $now }}
  provider_cost: 0  ← 🆕 Gmail = 0€ (SendGrid = 0.0012€)
  billed_cost: {{ $('Get Deployment').item.json.cost_per_email }}  ← 🆕 Pricing dynamique
  workflow_id: {{ $workflow.id }}
  workflow_execution_id: {{ $execution.id }}
  workflow_message_id: {{ $('Send Email').item.json.id }}
  gmail_thread_id: {{ $('Send Email').item.json.threadId }}
  has_attachments: false
  metadata: { "call_outcome": "{{ $('Get Calls').item.json.outcome }}" }
```

**Note Importante** : La colonne `margin` est calculée automatiquement par PostgreSQL :
```sql
margin = billed_cost - provider_cost
       = {{ $('Get Deployment').item.json.cost_per_email }} - 0
       = {{ $('Get Deployment').item.json.cost_per_email }}  (marge = prix client si Gmail gratuit)
```

#### Node 7 : Mark Call as Follow-Up Sent
```
Type: Supabase - Update
Table: agent_calls
Filter: id = {{ $('Get Calls').item.json.id }}
Fields:
  follow_up_email_sent: true
  follow_up_email_sent_at: {{ $now }}
```

---

## 🛡️ Gestion des Erreurs

### Cas 1 : Échec d'Envoi Gmail

Si la node Gmail échoue, ne pas insérer dans `agent_emails` :

**Solution** : Ajouter une node **Error Trigger** qui log l'échec

```
Type: Supabase - Insert
Table: agent_emails

Fields:
  deployment_id: {{ ... }}
  email_address: {{ ... }}
  email_subject: {{ ... }}
  email_type: {{ ... }}
  status: 'failed' ← Statut échec
  failed_at: {{ $now }}
  failure_reason: {{ $('Send Email').error.message }}
  workflow_id: {{ $workflow.id }}
  workflow_execution_id: {{ $execution.id }}
```

### Cas 2 : Email Manquant

Si l'email du destinataire est NULL :

**Solution** : Ajouter une node **IF** avant l'envoi

```
Type: IF Node
Condition: {{ $('Get Recipient').item.json.email != null && $('Get Recipient').item.json.email != '' }}

Branch TRUE : Envoyer email + Log
Branch FALSE : Skip (ou log comme 'failed' avec failure_reason: 'missing_email')
```

### Cas 3 : Quota Gmail Dépassé

Si Gmail retourne une erreur de quota :

**Solution** : Node Error Trigger + Log échec

```
failure_reason: 'Gmail quota exceeded - {{ $('Send Email').error.message }}'
status: 'failed'
failed_at: {{ $now }}
```

---

## 📊 Validation & Monitoring

### Vérifier que les Emails sont Loggés

Après avoir exécuté un workflow :

```sql
-- Emails des dernières 24h
SELECT
    email_subject,
    email_address,
    email_type,
    status,
    sent_at,
    workflow_id,
    workflow_execution_id
FROM agent_emails
WHERE sent_at >= NOW() - INTERVAL '24 hours'
ORDER BY sent_at DESC
LIMIT 20;
```

### KPIs à Surveiller

```sql
-- Total emails par statut (7 derniers jours)
SELECT
    status,
    COUNT(*) AS count,
    ROUND((COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER ()) * 100, 2) AS percentage
FROM agent_emails
WHERE sent_at >= NOW() - INTERVAL '7 days'
GROUP BY status;

-- Emails par workflow (top 10)
SELECT
    workflow_id,
    COUNT(*) AS total_emails,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed_emails,
    ROUND((COUNT(*) FILTER (WHERE status = 'sent')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2) AS success_rate
FROM agent_emails
WHERE sent_at >= NOW() - INTERVAL '30 days'
GROUP BY workflow_id
ORDER BY total_emails DESC
LIMIT 10;
```

---

## 🔍 Debugging

### Problème : Emails ne s'insèrent pas dans agent_emails

**Checklist** :
1. ✅ Vérifier que le Service Role Key est correct
2. ✅ Vérifier que la table `agent_emails` existe
3. ✅ Vérifier que les RLS policies sont configurées (`service_insert_emails`)
4. ✅ Vérifier les logs n8n (erreurs d'insertion Supabase)
5. ✅ Vérifier que `deployment_id` est un UUID valide (NOT NULL)

**Solution** : Activer le debugging dans n8n

```
Node Supabase : Options → Continue On Fail → TRUE
Ajouter une node IF après pour logger les erreurs
```

### Problème : Certains champs sont NULL

**Checklist** :
1. ✅ Vérifier les expressions n8n (double accolades `{{ }}`)
2. ✅ Vérifier que les nodes précédentes retournent les bonnes données
3. ✅ Tester les expressions dans l'éditeur n8n (bouton "Test Expression")
4. ✅ Ajouter des valeurs par défaut (`{{ $('Node').item.json.field || 'default' }}`)

---

## 🚀 Workflows Prioritaires à Intégrer

### 1. Follow-Up après Appel (Louis)
- **Trigger** : Schedule (chaque matin 9h)
- **Cas d'usage** : Envoi de résumés, documents, confirmations RDV
- **email_type** : `'follow_up'` ou `'appointment_confirmation'`

### 2. Cold Email Prospection (Arthur)
- **Trigger** : Webhook ou Schedule
- **Cas d'usage** : Premier contact email avant/après appel téléphonique
- **email_type** : `'cold_email'`

### 3. Séquences Multi-Touch (Arthur)
- **Trigger** : Delay après action précédente
- **Cas d'usage** : Email jour 1, jour 3, jour 7 (nurturing)
- **email_type** : `'sequence_step'`
- **sequence_id** : ID de la séquence

### 4. Rappels RDV (Tous agents)
- **Trigger** : Schedule (24h avant RDV)
- **Cas d'usage** : Rappel de rendez-vous avec détails
- **email_type** : `'appointment_confirmation'`

---

## 📚 Ressources

- **Table Schema** : `features/email-tracking/documentation/SCHEMA.md`
- **Supabase Docs** : https://supabase.com/docs/guides/api
- **n8n Supabase Node** : https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.supabase/
- **Gmail Node** : https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.gmail/

---

## ✅ Checklist d'Intégration

Pour chaque workflow d'envoi d'email :

- [ ] Ajouter une node Supabase INSERT après la node Gmail
- [ ] Mapper tous les champs obligatoires (deployment_id, email_address, email_subject, status, sent_at)
- [ ] Mapper les champs recommandés (call_id, prospect_id, first_name, last_name, body_html, body_text, email_type)
- [ ] Ajouter les IDs n8n (workflow_id, workflow_execution_id)
- [ ] Gérer les erreurs (Error Trigger → Log failed_at + failure_reason)
- [ ] Tester en staging avant production
- [ ] Vérifier que les emails apparaissent dans la table `agent_emails`
- [ ] Monitorer les KPIs (success_rate, volume par workflow)

---

## 📞 Support

En cas de problème d'intégration :
1. Consulter les logs n8n (Node Supabase → Output)
2. Vérifier les RLS policies dans Supabase
3. Tester l'insertion manuellement via SQL Editor
4. Consulter `features/email-tracking/notes/development_notes.md`
