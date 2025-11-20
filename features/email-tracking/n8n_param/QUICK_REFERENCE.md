# ⚡ Quick Reference - Email Tracking n8n

**Guide rapide** : Configuration express pour workflows email

---

## 🚀 Les 3 Nodes Essentielles

```
1. Get Deployment (Supabase)
   ↓
2. Send Email (Gmail)
   ↓
3. Insert Email (Supabase)
```

---

## 📋 Tableau de Mapping - Copier/Coller

### Node 1 : Get Deployment

| Paramètre | Valeur |
|-----------|--------|
| **Operation** | Get Rows |
| **Table** | `agent_deployments` |
| **Filter** | `id = {{ $json.deploymentId }}` |
| **Select** | `id, name, cost_per_email` |

---

### Node 2 : Send Email (Gmail)

| Champ | Expression n8n | Exemple |
|-------|----------------|---------|
| **to** | `{{ $json.recipient.email }}` | `client@example.com` |
| **subject** | `{{ $json.emailSubject }}` | `Confirmation de votre RDV` |
| **message** | `{{ $json.emailBody }}` | `Bonjour, votre RDV...` |
| **html_message** | `{{ $json.emailHtml }}` | `<html>...</html>` |

---

### Node 3 : Insert Supabase (agent_emails)

#### ✅ Champs Obligatoires (TOP 10)

| Field ID | Expression n8n | Description |
|----------|----------------|-------------|
| `deployment_id` | `{{ $('Get Deployment').item.json.id }}` | ID du deployment |
| `email_address` | `{{ $('Send Email').params.to }}` | Destinataire |
| `email_subject` | `{{ $('Send Email').params.subject }}` | Objet email |
| `email_body_text` | `{{ $('Send Email').params.message }}` | Corps texte |
| `email_type` | `follow_up` | Type d'email (voir liste) |
| `status` | `sent` | Statut fixe |
| `sent_at` | `{{ new Date().toISOString() }}` | Timestamp envoi |
| `provider_cost` | `0` | Gmail = 0€ |
| `billed_cost` | `{{ $('Get Deployment').item.json.cost_per_email \|\| 0 }}` | **⚠️ CRITIQUE** |
| `workflow_id` | `{{ $workflow.id }}` | ID workflow n8n |

#### 📎 Champs Optionnels (Recommandés)

| Field ID | Expression n8n |
|----------|----------------|
| `first_name` | `{{ $json.first_name \|\| null }}` |
| `last_name` | `{{ $json.last_name \|\| null }}` |
| `email_body_html` | `{{ $('Send Email').params.html_message \|\| null }}` |
| `call_id` | `{{ $json.callId \|\| null }}` |
| `prospect_id` | `{{ $json.prospectId \|\| null }}` |
| `sequence_id` | `{{ $json.sequenceId \|\| null }}` |
| `workflow_message_id` | `{{ $('Send Email').item.json.id }}` |
| `gmail_thread_id` | `{{ $('Send Email').item.json.threadId }}` |
| `workflow_execution_id` | `{{ $execution.id }}` |
| `metadata` | `{{ { custom: 'data' } }}` |

#### ❌ Champs AUTO-CALCULÉS (NE PAS MAPPER)

| Field ID | Raison |
|----------|--------|
| `margin` | ❌ GENERATED ALWAYS (auto-calculée) |
| `word_count` | ❌ GENERATED ALWAYS (auto-calculée) |
| `html_size_bytes` | ❌ GENERATED ALWAYS (auto-calculée) |
| `id` | ❌ UUID auto-généré |
| `created_at` | ❌ Default NOW() |
| `updated_at` | ❌ Default NOW() |

---

## 📝 Liste des email_type (CHECK Constraint)

Valeurs autorisées uniquement :

| Valeur | Usage | Agent |
|--------|-------|-------|
| `follow_up` | Suivi après appel | Louis |
| `cold_email` | Prospection initiale | Arthur |
| `appointment_confirmation` | Confirmation RDV | Louis |
| `sequence_step` | Étape séquence | Arthur |
| `transactional` | Email système | Tous |
| `notification` | Notification | Tous |

---

## 💰 Formules Pricing Dynamique

### Récupération depuis Deployment

```javascript
{{ $('Get Deployment').item.json.cost_per_email || 0 }}
```

### Calculs Automatiques

| Colonne | Formule | Calcul par |
|---------|---------|------------|
| `provider_cost` | `0` (fixe) | Vous |
| `billed_cost` | `deployment.cost_per_email` | Vous |
| `margin` | `billed_cost - provider_cost` | **PostgreSQL** |

### Scénarios de Pricing

| Scénario | cost_per_email | billed_cost | margin |
|----------|----------------|-------------|--------|
| **Gratuit** | 0€ | 0€ | 0€ |
| **Symbolique** | 0.01€ | 0.01€ | 0.01€ |
| **Standard** | 0.02€ | 0.02€ | 0.02€ |
| **Premium** | 0.05€ | 0.05€ | 0.05€ |

---

## 🔗 Workflow Complet (Template)

### Structure Recommandée

```
[Trigger]
  ↓
[Prepare Data] (optionnel)
  ↓
[Get Deployment] ← Récupère cost_per_email
  ↓
[Send Email Gmail] ← Envoie email
  ↓
[Insert Supabase] ← Track avec billed_cost
  ↓
[Update Prospect/Call] (optionnel)
```

### Temps d'Exécution Typiques

| Node | Temps moyen |
|------|-------------|
| Get Deployment | ~200ms |
| Send Email | ~500ms |
| Insert Supabase | ~150ms |
| **Total** | **~850ms** |

---

## 🚨 Erreurs Courantes et Solutions

### ❌ Erreur : "margin cannot be null"
**Cause** : Tentative d'insérer `margin` manuellement
**Solution** : Ne JAMAIS mapper `margin`, elle est auto-calculée

### ❌ Erreur : "email_type violates check constraint"
**Cause** : Valeur non autorisée (ex: `follow-up` au lieu de `follow_up`)
**Solution** : Utiliser UNIQUEMENT les valeurs de la liste ci-dessus

### ❌ Erreur : "deployment_id cannot be null"
**Cause** : Node "Get Deployment" manquante ou échouée
**Solution** : Ajouter node "Get Deployment" AVANT "Insert Supabase"

### ❌ Erreur : "email_address cannot be null"
**Cause** : Mapping incorrect depuis Gmail node
**Solution** : Utiliser `{{ $('Send Email').params.to }}`

### ⚠️ Warning : billed_cost = 0 alors que pricing configuré
**Cause** : Get Deployment n'a pas retourné `cost_per_email`
**Solution** : Vérifier SELECT fields: `id, name, cost_per_email`

---

## 🎯 Checklist Rapide

Avant de sauvegarder le workflow :

```
☐ Node "Get Deployment" ajoutée en PREMIÈRE
☐ cost_per_email récupéré (vérifier SELECT)
☐ Gmail credentials configurées
☐ Destinataire (to) mappé
☐ Subject et body mappés
☐ deployment_id → $('Get Deployment').item.json.id
☐ billed_cost → $('Get Deployment').item.json.cost_per_email
☐ provider_cost = 0 (fixe)
☐ email_type = valeur valide (voir liste)
☐ status = 'sent'
☐ sent_at = new Date().toISOString()
☐ workflow_id = $workflow.id
☐ NE PAS mapper margin, word_count, html_size_bytes
```

---

## 📞 Besoin d'Aide ?

### Documentation Complète

- **Guide workflow** : `WORKFLOW_GUIDE.md`
- **Exemples détaillés** : `MAPPING_EXAMPLES.md`
- **Config JSON** : `SUPABASE_INSERT_EMAIL_CONFIG.json`
- **Schéma table** : `../documentation/SCHEMA.md`
- **Intégration n8n** : `../documentation/N8N_INTEGRATION.md`

### Support

- **Tests staging** : `../MIGRATION_TESTED.md`
- **Pricing model** : `../documentation/PRICING_MODEL.md`

---

## 🎉 Template Copier/Coller

### Configuration Supabase Minimale (21 champs obligatoires)

```json
{
  "deployment_id": "={{ $('Get Deployment').item.json.id }}",
  "email_address": "={{ $('Send Email').params.to }}",
  "first_name": "={{ $json.first_name || null }}",
  "last_name": "={{ $json.last_name || null }}",
  "email_subject": "={{ $('Send Email').params.subject }}",
  "email_body_html": "={{ $('Send Email').params.html_message || null }}",
  "email_body_text": "={{ $('Send Email').params.message }}",
  "email_type": "follow_up",
  "provider": "gmail",
  "workflow_message_id": "={{ $('Send Email').item.json.id }}",
  "gmail_thread_id": "={{ $('Send Email').item.json.threadId }}",
  "status": "sent",
  "sent_at": "={{ new Date().toISOString() }}",
  "provider_cost": 0,
  "billed_cost": "={{ $('Get Deployment').item.json.cost_per_email || 0 }}",
  "currency": "EUR",
  "workflow_id": "={{ $workflow.id }}",
  "workflow_execution_id": "={{ $execution.id }}",
  "call_id": "={{ $json.callId || null }}",
  "prospect_id": "={{ $json.prospectId || null }}",
  "metadata": "={{ { customData: $json.customData } }}"
}
```

**Copier ce template dans votre node Supabase** → Adapter les sources de données → Tester !

---

**Version** : 1.0
**Dernière mise à jour** : 2025-11-14
**Compatibilité** : n8n 1.0+, Supabase PostgreSQL 15+
