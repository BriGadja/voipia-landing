# 📧 Guide Workflow n8n - Email Tracking

**Date** : 2025-11-14
**Feature** : Email Tracking avec Pricing Dynamique
**Version** : 1.0

---

## 🎯 Vue d'ensemble

Ce guide explique comment configurer un workflow n8n pour :
1. **Envoyer un email via Gmail**
2. **Récupérer le pricing dynamique** depuis `agent_deployments.cost_per_email`
3. **Tracker l'email** dans la table `agent_emails` avec les colonnes financières

---

## 📊 Architecture du Workflow

```
┌─────────────────┐
│ 1. Trigger      │ (Manual, Webhook, Schedule, etc.)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. Get          │ SELECT * FROM agent_deployments WHERE id = ?
│ Deployment      │ → Récupère cost_per_email
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. Send Email   │ Gmail Node: Envoie l'email
│ (Gmail)         │ → Retourne message_id, thread_id
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. Insert       │ Supabase Node: INSERT INTO agent_emails
│ Supabase        │ → billed_cost = deployment.cost_per_email
└─────────────────┘  → margin calculée automatiquement
```

---

## 🔧 Node 1 : Get Deployment (Supabase - Select)

**Objectif** : Récupérer `cost_per_email` pour calculer le pricing dynamique

### Configuration

**Type** : `n8n-nodes-base.supabase`
**Operation** : `Get Rows`
**Table** : `agent_deployments`

### Filters

```json
{
  "id": {
    "eq": "{{ $('Previous Node').item.json.deploymentId }}"
  }
}
```

### Fields to Select

```
id, name, client_id, agent_type_id, cost_per_email
```

**⚠️ IMPORTANT** : `cost_per_email` est **obligatoire** pour le pricing dynamique !

### Output Example

```json
{
  "id": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "name": "Louis - Voipia",
  "client_id": "abc-123",
  "agent_type_id": "xyz-456",
  "cost_per_email": 0.01
}
```

---

## 📧 Node 2 : Send Email (Gmail)

**Objectif** : Envoyer l'email via Gmail API

### Configuration

**Type** : `n8n-nodes-base.gmail`
**Operation** : `Send Email`

### Required Fields

| Champ n8n | Description | Exemple |
|-----------|-------------|---------|
| `to` | Email destinataire | `{{ $json.recipient_email }}` |
| `subject` | Objet de l'email | `Confirmation de votre rendez-vous` |
| `message` | Corps texte brut | `Bonjour {{ $json.first_name }}, ...` |
| `html_message` | Corps HTML (optionnel) | `<html>...</html>` |

### Optional Fields

| Champ | Description | Exemple |
|-------|-------------|---------|
| `cc` | Copie carbone | `cc@example.com` |
| `bcc` | Copie cachée | `bcc@example.com` |
| `attachments` | Pièces jointes | `Binary data` |
| `from_name` | Nom expéditeur | `Louis - Agent Voipia` |

### Output Example

```json
{
  "id": "18f2a3b4c5d6e7f8",
  "threadId": "18f2a3b4c5d6e7f8",
  "labelIds": ["SENT"],
  "snippet": "Bonjour John, voici la confirmation...",
  "payload": {
    "mimeType": "text/html",
    "headers": [...]
  }
}
```

**⚠️ Important** :
- `id` → À mapper vers `workflow_message_id`
- `threadId` → À mapper vers `gmail_thread_id`

---

## 💾 Node 3 : Insert Email (Supabase - Insert)

**Objectif** : Tracker l'email dans la table `agent_emails` avec pricing dynamique

### Configuration

**Type** : `n8n-nodes-base.supabase`
**Operation** : `Insert Rows`
**Table** : `agent_emails`

### Fields Mapping (33 champs)

#### 🔑 Champs Obligatoires

| Field ID | Source | Expression n8n |
|----------|--------|----------------|
| `deployment_id` | Deployment | `{{ $('Get Deployment').item.json.id }}` |
| `email_address` | Gmail input | `{{ $('Send Email').params.to }}` |
| `email_subject` | Gmail input | `{{ $('Send Email').params.subject }}` |
| `email_body_text` | Gmail input | `{{ $('Send Email').params.message }}` |
| `email_body_html` | Gmail input | `{{ $('Send Email').params.html_message \|\| null }}` |
| `email_type` | Static | `follow_up` ou `cold_email` ou `appointment_confirmation` |
| `status` | Static | `sent` |
| `sent_at` | Now | `{{ new Date().toISOString() }}` |

#### 👤 Champs Contact (Optionnels)

| Field ID | Source | Expression n8n |
|----------|--------|----------------|
| `first_name` | Previous node | `{{ $json.first_name \|\| null }}` |
| `last_name` | Previous node | `{{ $json.last_name \|\| null }}` |

#### 🔗 Champs Relations (Optionnels)

| Field ID | Source | Expression n8n |
|----------|--------|----------------|
| `call_id` | Previous call | `{{ $('Previous Call').item.json.id \|\| null }}` |
| `prospect_id` | Arthur prospect | `{{ $('Get Prospect').item.json.id \|\| null }}` |
| `sequence_id` | Arthur sequence | `{{ $('Get Sequence').item.json.id \|\| null }}` |

#### 📎 Champs Attachments (Optionnels)

| Field ID | Source | Expression n8n |
|----------|--------|----------------|
| `has_attachments` | Gmail input | `{{ $('Send Email').params.attachments ? true : false }}` |
| `attachment_names` | Gmail input | `{{ $('Send Email').params.attachments?.map(a => a.name) \|\| null }}` |

#### 🏢 Champs Provider (Gmail)

| Field ID | Source | Expression n8n |
|----------|--------|----------------|
| `provider` | Static | `gmail` |
| `workflow_message_id` | Gmail output | `{{ $('Send Email').item.json.id }}` |
| `gmail_thread_id` | Gmail output | `{{ $('Send Email').item.json.threadId }}` |

#### 💰 Champs Financiers (Pricing Dynamique) - CRITIQUES

| Field ID | Source | Expression n8n |
|----------|--------|----------------|
| `provider_cost` | Static | `0` (Gmail gratuit) |
| `billed_cost` | **Deployment** | `{{ $('Get Deployment').item.json.cost_per_email \|\| 0 }}` |
| `currency` | Static | `EUR` |

**⚠️ IMPORTANT** :
- `margin` est **GENERATED ALWAYS** → Ne PAS l'insérer manuellement
- `billed_cost` DOIT récupérer `cost_per_email` depuis le deployment
- Si pas de Get Deployment, `billed_cost = 0` (gratuit par défaut)

#### 🔄 Champs Workflow (Tracking n8n)

| Field ID | Source | Expression n8n |
|----------|--------|----------------|
| `workflow_id` | n8n context | `{{ $workflow.id }}` |
| `workflow_execution_id` | n8n context | `{{ $execution.id }}` |

#### 📦 Metadata (JSONB - Optionnel)

| Field ID | Source | Expression n8n |
|----------|--------|----------------|
| `metadata` | Custom | `{{ { workspaceId: $json.workspaceId, agentId: $json.agentId } }}` |

---

## 🧪 Exemples de Workflows Complets

### Exemple 1 : Follow-up après appel (Louis)

```
Trigger: Webhook (après appel terminé)
  ↓
Get Deployment (récupère cost_per_email)
  ↓
Send Email Gmail (confirmation RDV)
  ↓
Insert Supabase (track email)
```

**Données d'entrée** :
```json
{
  "deploymentId": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "callId": "abc-123-call",
  "recipient": {
    "email": "client@example.com",
    "firstName": "John",
    "lastName": "Doe"
  },
  "appointmentDate": "2025-11-15T10:00:00Z"
}
```

**Email envoyé** :
- **Subject** : `Confirmation de votre rendez-vous le 15 novembre`
- **Body** : `Bonjour John, voici la confirmation de votre rendez-vous...`

**Tracking** :
- `email_type` : `appointment_confirmation`
- `call_id` : `abc-123-call`
- `billed_cost` : `0.01€` (si cost_per_email = 0.01)
- `margin` : `0.01€` (auto-calculée)

---

### Exemple 2 : Cold email (Arthur)

```
Trigger: Schedule (tous les matins 9h)
  ↓
Get Prospects (non contactés)
  ↓
For Each Prospect:
  ↓
  Get Deployment (récupère cost_per_email)
  ↓
  Send Email Gmail (prospection)
  ↓
  Insert Supabase (track email)
```

**Données d'entrée** :
```json
{
  "deploymentId": "d44a37ed-eed8-45c4-8886-c2b326551ec6",
  "prospectId": "xyz-prospect-123",
  "sequenceId": "seq-456",
  "recipient": {
    "email": "prospect@company.com",
    "firstName": "Jane",
    "lastName": "Smith"
  }
}
```

**Email envoyé** :
- **Subject** : `Réactivez vos leads perdus avec Arthur`
- **Body** : `Bonjour Jane, je suis Arthur, votre assistant IA...`

**Tracking** :
- `email_type` : `cold_email`
- `prospect_id` : `xyz-prospect-123`
- `sequence_id` : `seq-456`
- `billed_cost` : `0.05€` (si cost_per_email = 0.05)
- `margin` : `0.05€` (auto-calculée)

---

### Exemple 3 : Email gratuit (test/internal)

```
Trigger: Manual
  ↓
Get Deployment (cost_per_email = 0)
  ↓
Send Email Gmail
  ↓
Insert Supabase
```

**Tracking** :
- `billed_cost` : `0€` (gratuit)
- `margin` : `0€`
- `provider_cost` : `0€`

---

## ✅ Checklist de Validation

Avant de déployer un workflow email, vérifier :

### Configuration Deployment
- [ ] Le deployment existe dans `agent_deployments`
- [ ] `cost_per_email` est configuré (0€ par défaut, modifiable si facturation)

### Node Gmail
- [ ] Credentials Gmail configurées
- [ ] Champs `to`, `subject`, `message` renseignés
- [ ] HTML message optionnel mais recommandé
- [ ] Test d'envoi réussi

### Node Supabase
- [ ] Credentials Supabase configurées
- [ ] **Get Deployment exécuté AVANT** (pour récupérer cost_per_email)
- [ ] Tous les champs obligatoires mappés
- [ ] `billed_cost` = `{{ $('Get Deployment').item.json.cost_per_email }}`
- [ ] `provider_cost` = `0` (Gmail gratuit)
- [ ] Ne PAS insérer `margin` (auto-calculée)
- [ ] `workflow_id` et `workflow_execution_id` mappés

### Tests
- [ ] Envoi d'email de test réussi
- [ ] Email inséré dans `agent_emails`
- [ ] Colonne `margin` correctement calculée
- [ ] View `v_agent_emails_enriched` affiche l'email
- [ ] Fonction `get_email_metrics()` retourne les métriques

---

## 🚨 Pièges Courants

### ❌ Erreur : margin NULL ou incorrecte
**Cause** : Tentative d'insérer `margin` manuellement
**Solution** : Ne JAMAIS insérer `margin`, elle est GENERATED ALWAYS

### ❌ Erreur : billed_cost toujours 0
**Cause** : Node "Get Deployment" manquante ou cost_per_email non récupéré
**Solution** : Ajouter node "Get Deployment" AVANT "Insert Supabase"

### ❌ Erreur : workflow_message_id NULL
**Cause** : Mauvais mapping depuis Gmail output
**Solution** : Utiliser `{{ $('Send Email').item.json.id }}`

### ❌ Erreur : email_type invalide
**Cause** : Valeur non supportée (CHECK constraint)
**Solution** : Utiliser uniquement : `follow_up`, `cold_email`, `appointment_confirmation`, `sequence_step`, `transactional`, `notification`

---

## 📚 Ressources

- **Documentation complète** : `features/email-tracking/documentation/N8N_INTEGRATION.md`
- **Schéma table** : `features/email-tracking/documentation/SCHEMA.md`
- **Modèle pricing** : `features/email-tracking/documentation/PRICING_MODEL.md`
- **Config Supabase** : `features/email-tracking/n8n_param/SUPABASE_INSERT_EMAIL_CONFIG.json`
- **Tests staging** : `features/email-tracking/MIGRATION_TESTED.md`

---

## 🎯 Résumé - Les 3 Étapes Essentielles

1. **Get Deployment** → Récupère `cost_per_email`
2. **Send Email** → Envoie via Gmail, retourne `message_id` et `thread_id`
3. **Insert Supabase** → Track avec `billed_cost = cost_per_email`, `margin` auto-calculée

**Pricing Dynamique** : Chaque déploiement peut avoir un prix différent !
