# 📋 Exemples de Mapping - Email Tracking

**Date** : 2025-11-14
**Feature** : Email Tracking - Mapping détaillé pour différents cas d'usage

---

## 🎯 Vue d'ensemble

Ce document fournit des exemples **concrets et complets** de mapping pour différents types d'emails Voipia.

---

## 📧 Exemple 1 : Follow-up après appel (Louis)

### Contexte
- **Agent** : Louis (rappel automatique)
- **Trigger** : Après un appel où un RDV a été pris
- **Objectif** : Envoyer email de confirmation avec détails du RDV

### Données d'entrée (Previous Node)

```json
{
  "deploymentId": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "callId": "abc-123-call-456",
  "contact": {
    "firstName": "Jean",
    "lastName": "Dupont",
    "email": "jean.dupont@example.com",
    "phone": "+33612345678"
  },
  "appointment": {
    "date": "2025-11-20T14:00:00Z",
    "location": "45 Rue de la Paix, 75002 Paris"
  }
}
```

### Node 1 : Get Deployment

**Supabase - Get Rows**
```json
{
  "table": "agent_deployments",
  "filters": {
    "id": {
      "eq": "={{ $json.deploymentId }}"
    }
  },
  "select": "id, name, cost_per_email"
}
```

**Output** :
```json
{
  "id": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "name": "Louis - Voipia",
  "cost_per_email": 0.01
}
```

### Node 2 : Send Email (Gmail)

**Configuration** :
```json
{
  "to": "={{ $json.contact.email }}",
  "subject": "Confirmation de votre rendez-vous le {{ new Date($json.appointment.date).toLocaleDateString('fr-FR') }}",
  "message": "Bonjour {{ $json.contact.firstName }},\n\nVotre rendez-vous est confirmé pour le {{ new Date($json.appointment.date).toLocaleDateString('fr-FR') }} à {{ new Date($json.appointment.date).toLocaleTimeString('fr-FR') }}.\n\nLieu : {{ $json.appointment.location }}\n\nÀ bientôt !\n\nLouis\nAgent Voipia",
  "html_message": "<html><body><p>Bonjour {{ $json.contact.firstName }},</p><p>Votre rendez-vous est confirmé pour le <strong>{{ new Date($json.appointment.date).toLocaleDateString('fr-FR') }}</strong> à <strong>{{ new Date($json.appointment.date).toLocaleTimeString('fr-FR') }}</strong>.</p><p>Lieu : {{ $json.appointment.location }}</p><p>À bientôt !<br>Louis<br>Agent Voipia</p></body></html>"
}
```

**Output** :
```json
{
  "id": "18f2a3b4c5d6e7f8",
  "threadId": "18f2a3b4c5d6e7f8",
  "labelIds": ["SENT"]
}
```

### Node 3 : Insert Supabase

**Configuration complète** :
```json
{
  "table": "agent_emails",
  "fields": {
    "deployment_id": "={{ $('Get Deployment').item.json.id }}",
    "call_id": "={{ $json.callId }}",
    "email_address": "={{ $json.contact.email }}",
    "first_name": "={{ $json.contact.firstName }}",
    "last_name": "={{ $json.contact.lastName }}",
    "email_subject": "Confirmation de votre rendez-vous le 20 novembre 2025",
    "email_body_text": "Bonjour Jean,\n\nVotre rendez-vous est confirmé...",
    "email_body_html": "<html><body>...",
    "email_type": "appointment_confirmation",
    "provider": "gmail",
    "workflow_message_id": "={{ $('Send Email').item.json.id }}",
    "gmail_thread_id": "={{ $('Send Email').item.json.threadId }}",
    "status": "sent",
    "sent_at": "={{ new Date().toISOString() }}",
    "provider_cost": 0,
    "billed_cost": "={{ $('Get Deployment').item.json.cost_per_email }}",
    "currency": "EUR",
    "workflow_id": "={{ $workflow.id }}",
    "workflow_execution_id": "={{ $execution.id }}",
    "metadata": {
      "appointmentDate": "={{ $json.appointment.date }}",
      "appointmentLocation": "={{ $json.appointment.location }}",
      "callId": "={{ $json.callId }}"
    }
  }
}
```

**Résultat dans la base** :
```json
{
  "id": "uuid-generated",
  "deployment_id": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "call_id": "abc-123-call-456",
  "email_address": "jean.dupont@example.com",
  "first_name": "Jean",
  "last_name": "Dupont",
  "email_subject": "Confirmation de votre rendez-vous le 20 novembre 2025",
  "email_type": "appointment_confirmation",
  "status": "sent",
  "sent_at": "2025-11-14T12:00:00Z",
  "provider_cost": 0.0000,
  "billed_cost": 0.0100,
  "margin": 0.0100,  // ✅ Auto-calculée
  "word_count": 45,  // ✅ Auto-calculée
  "html_size_bytes": 250  // ✅ Auto-calculée
}
```

---

## 📧 Exemple 2 : Cold Email (Arthur)

### Contexte
- **Agent** : Arthur (réactivation)
- **Trigger** : Schedule quotidien (9h)
- **Objectif** : Contacter prospects non répondus

### Données d'entrée (Previous Node)

```json
{
  "deploymentId": "d44a37ed-eed8-45c4-8886-c2b326551ec6",
  "prospectId": "prospect-xyz-789",
  "sequenceId": "seq-123-abc",
  "prospect": {
    "firstName": "Marie",
    "lastName": "Martin",
    "email": "marie.martin@company.fr",
    "companyName": "Tech Solutions SAS"
  },
  "sequenceStep": 1
}
```

### Node 1 : Get Deployment

**Output** :
```json
{
  "id": "d44a37ed-eed8-45c4-8886-c2b326551ec6",
  "name": "Arthur - Norloc",
  "cost_per_email": 0.05
}
```

### Node 2 : Send Email (Gmail)

**Configuration** :
```json
{
  "to": "={{ $json.prospect.email }}",
  "subject": "Réactivez vos leads perdus avec Arthur",
  "message": "Bonjour {{ $json.prospect.firstName }},\n\nJe suis Arthur, assistant IA de Voipia. J'ai remarqué que vous aviez des leads non contactés chez {{ $json.prospect.companyName }}.\n\nPuis-je vous aider à les réactiver automatiquement ?\n\nCordialement,\nArthur",
  "html_message": "<html>..."
}
```

### Node 3 : Insert Supabase

**Configuration complète** :
```json
{
  "table": "agent_emails",
  "fields": {
    "deployment_id": "={{ $('Get Deployment').item.json.id }}",
    "prospect_id": "={{ $json.prospectId }}",
    "sequence_id": "={{ $json.sequenceId }}",
    "email_address": "={{ $json.prospect.email }}",
    "first_name": "={{ $json.prospect.firstName }}",
    "last_name": "={{ $json.prospect.lastName }}",
    "email_subject": "Réactivez vos leads perdus avec Arthur",
    "email_body_text": "Bonjour Marie, je suis Arthur...",
    "email_body_html": "<html>...",
    "email_type": "cold_email",
    "provider": "gmail",
    "workflow_message_id": "={{ $('Send Email').item.json.id }}",
    "gmail_thread_id": "={{ $('Send Email').item.json.threadId }}",
    "status": "sent",
    "sent_at": "={{ new Date().toISOString() }}",
    "provider_cost": 0,
    "billed_cost": "={{ $('Get Deployment').item.json.cost_per_email }}",
    "currency": "EUR",
    "workflow_id": "={{ $workflow.id }}",
    "workflow_execution_id": "={{ $execution.id }}",
    "metadata": {
      "prospectId": "={{ $json.prospectId }}",
      "sequenceId": "={{ $json.sequenceId }}",
      "sequenceStep": "={{ $json.sequenceStep }}",
      "companyName": "={{ $json.prospect.companyName }}"
    }
  }
}
```

**Résultat dans la base** :
```json
{
  "id": "uuid-generated",
  "deployment_id": "d44a37ed-eed8-45c4-8886-c2b326551ec6",
  "prospect_id": "prospect-xyz-789",
  "sequence_id": "seq-123-abc",
  "email_address": "marie.martin@company.fr",
  "first_name": "Marie",
  "last_name": "Martin",
  "email_subject": "Réactivez vos leads perdus avec Arthur",
  "email_type": "cold_email",
  "status": "sent",
  "sent_at": "2025-11-14T09:00:00Z",
  "provider_cost": 0.0000,
  "billed_cost": 0.0500,
  "margin": 0.0500,  // ✅ Auto-calculée (5 centimes de marge)
  "word_count": 62,
  "html_size_bytes": 180
}
```

---

## 📧 Exemple 3 : Sequence Step (Arthur)

### Contexte
- **Agent** : Arthur
- **Trigger** : Séquence multi-touch (Day 3 follow-up)
- **Objectif** : 2ème email de relance dans séquence

### Données d'entrée

```json
{
  "deploymentId": "d44a37ed-eed8-45c4-8886-c2b326551ec6",
  "prospectId": "prospect-abc-123",
  "sequenceId": "seq-multi-456",
  "prospect": {
    "firstName": "Thomas",
    "lastName": "Bernard",
    "email": "thomas.bernard@startup.io"
  },
  "sequenceStep": 2,
  "previousEmailId": "email-123-first-touch"
}
```

### Node 3 : Insert Supabase

**Configuration** :
```json
{
  "table": "agent_emails",
  "fields": {
    "deployment_id": "={{ $('Get Deployment').item.json.id }}",
    "prospect_id": "={{ $json.prospectId }}",
    "sequence_id": "={{ $json.sequenceId }}",
    "email_address": "={{ $json.prospect.email }}",
    "first_name": "={{ $json.prospect.firstName }}",
    "last_name": "={{ $json.prospect.lastName }}",
    "email_subject": "Re: Réactivez vos leads perdus avec Arthur",
    "email_body_text": "Bonjour Thomas,\n\nJe reviens vers vous...",
    "email_body_html": "<html>...",
    "email_type": "sequence_step",
    "provider": "gmail",
    "workflow_message_id": "={{ $('Send Email').item.json.id }}",
    "gmail_thread_id": "={{ $('Send Email').item.json.threadId }}",
    "status": "sent",
    "sent_at": "={{ new Date().toISOString() }}",
    "provider_cost": 0,
    "billed_cost": "={{ $('Get Deployment').item.json.cost_per_email }}",
    "currency": "EUR",
    "workflow_id": "={{ $workflow.id }}",
    "workflow_execution_id": "={{ $execution.id }}",
    "metadata": {
      "prospectId": "={{ $json.prospectId }}",
      "sequenceId": "={{ $json.sequenceId }}",
      "sequenceStep": 2,
      "previousEmailId": "={{ $json.previousEmailId }}"
    }
  }
}
```

**Résultat** :
- `email_type` = `sequence_step`
- `sequence_id` = lien vers `agent_arthur_prospect_sequences`
- `metadata.sequenceStep` = 2 (pour tracking)

---

## 📧 Exemple 4 : Email Gratuit (Test/Internal)

### Contexte
- **Agent** : Louis - Voipia (test)
- **Pricing** : `cost_per_email = 0€` (gratuit)
- **Objectif** : Email interne/test sans facturation

### Node 1 : Get Deployment

**Output** :
```json
{
  "id": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
  "name": "Louis - Voipia",
  "cost_per_email": 0
}
```

### Node 3 : Insert Supabase

**Configuration** :
```json
{
  "fields": {
    "deployment_id": "348cc94d-b4e8-4281-b33a-bc9378fecffc",
    "email_address": "test@voipia.com",
    "email_subject": "Test email - Internal",
    "email_body_text": "This is a test email",
    "email_type": "transactional",
    "provider": "gmail",
    "status": "sent",
    "sent_at": "2025-11-14T12:00:00Z",
    "provider_cost": 0,
    "billed_cost": 0,  // ✅ Gratuit car cost_per_email = 0
    "currency": "EUR",
    "workflow_id": "test-workflow",
    "workflow_execution_id": "test-exec-123"
  }
}
```

**Résultat** :
```json
{
  "provider_cost": 0.0000,
  "billed_cost": 0.0000,  // ✅ Gratuit
  "margin": 0.0000        // ✅ Pas de marge (gratuit)
}
```

---

## 📧 Exemple 5 : Email avec Pièce Jointe

### Contexte
- **Agent** : Louis
- **Objectif** : Envoyer document PDF après appel

### Node 2 : Send Email (Gmail)

**Configuration** :
```json
{
  "to": "client@example.com",
  "subject": "Document demandé lors de notre appel",
  "message": "Bonjour, veuillez trouver en pièce jointe...",
  "html_message": "<html>...",
  "attachments": [
    {
      "name": "Document_Contrat.pdf",
      "data": "{{ $binary.data }}",
      "type": "application/pdf"
    }
  ]
}
```

### Node 3 : Insert Supabase

**Configuration** :
```json
{
  "fields": {
    "deployment_id": "...",
    "email_address": "client@example.com",
    "email_subject": "Document demandé lors de notre appel",
    "email_body_text": "Bonjour, veuillez trouver en pièce jointe...",
    "email_type": "follow_up",
    "has_attachments": true,  // ✅ TRUE car attachments présents
    "attachment_names": ["Document_Contrat.pdf"],  // ✅ Array de noms
    "provider": "gmail",
    "status": "sent",
    "sent_at": "={{ new Date().toISOString() }}",
    "provider_cost": 0,
    "billed_cost": "={{ $('Get Deployment').item.json.cost_per_email }}",
    "currency": "EUR"
  }
}
```

**Résultat** :
```json
{
  "has_attachments": true,
  "attachment_names": ["Document_Contrat.pdf"]
}
```

---

## 🔍 Validation des Données

### Champs Obligatoires (NOT NULL)

**✅ Toujours requis** :
- `deployment_id` → UUID du deployment
- `email_address` → Email destinataire
- `email_subject` → Objet de l'email
- `status` → `sent`, `failed`, ou `queued`
- `sent_at` → Timestamp d'envoi

**✅ Avec default mais recommandé** :
- `email_type` → Default `transactional`, mais spécifier pour analytics
- `provider` → Default `gmail`
- `currency` → Default `EUR`

### Champs Optionnels (NULL autorisé)

**Contacts** :
- `first_name`, `last_name`

**Relations** :
- `call_id`, `prospect_id`, `sequence_id`

**Contenu** :
- `email_body_html` (optionnel si text only)
- `email_body_text` (optionnel si HTML only, mais recommandé)

**Attachments** :
- `has_attachments` → Default `FALSE`
- `attachment_names` → NULL si pas d'attachments

**Tracking future (v2.0)** :
- `opened_at`, `first_clicked_at`, `bounce_type`, `spam_reported_at` → NULL pour l'instant

---

## ✅ Checklist de Validation

Avant de déployer un workflow email :

### Avant l'envoi
- [ ] Node "Get Deployment" ajoutée AVANT "Send Email"
- [ ] `cost_per_email` récupéré depuis deployment
- [ ] Email Gmail credentials configurées
- [ ] Destinataire (`to`) valide
- [ ] Subject et body renseignés

### Configuration Supabase
- [ ] `deployment_id` mappé depuis Get Deployment
- [ ] `email_address` mappé depuis Gmail input
- [ ] `email_subject`, `email_body_text` mappés
- [ ] `email_type` spécifié (pas default)
- [ ] `status` = `sent`
- [ ] `sent_at` = `{{ new Date().toISOString() }}`
- [ ] `provider_cost` = `0` (Gmail gratuit)
- [ ] `billed_cost` = `{{ $('Get Deployment').item.json.cost_per_email }}`
- [ ] `workflow_id` et `workflow_execution_id` mappés
- [ ] **Ne PAS mapper `margin`** (auto-calculée)
- [ ] **Ne PAS mapper `word_count`** (auto-calculée)
- [ ] **Ne PAS mapper `html_size_bytes`** (auto-calculée)

### Après l'exécution
- [ ] Email visible dans `agent_emails`
- [ ] `margin` correctement calculée
- [ ] View `v_agent_emails_enriched` retourne l'email
- [ ] Fonction `get_email_metrics()` inclut l'email dans les stats

---

## 📚 Ressources Complémentaires

- **Guide complet** : `features/email-tracking/n8n_param/WORKFLOW_GUIDE.md`
- **Config JSON** : `features/email-tracking/n8n_param/SUPABASE_INSERT_EMAIL_CONFIG.json`
- **Documentation N8N** : `features/email-tracking/documentation/N8N_INTEGRATION.md`
- **Schéma table** : `features/email-tracking/documentation/SCHEMA.md`

---

**Dernière mise à jour** : 2025-11-14
