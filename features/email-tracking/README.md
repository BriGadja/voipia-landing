# 📧 Email Tracking System

## Vue d'ensemble

Ce feature implémente un système complet de tracking des emails envoyés par les agents Voipia (Louis, Arthur, Alexandra), similaire au système de tracking SMS existant.

**Date de création** : 2025-11-14
**Statut** : ✅ Implémenté
**Inspiré de** : `features/sms-tracking/` (table `agent_sms`)

---

## 🎯 Objectifs

### Objectifs Principaux
- ✅ Tracker tous les emails envoyés par les agents Voipia
- ✅ Associer les emails aux appels, prospects, et séquences
- ✅ Suivre les statuts d'envoi (sent, failed, queued)
- ✅ Préparer l'infrastructure pour le tracking avancé (opens, clicks) - future roadmap
- ✅ Fournir des métriques analytics via views et RPC functions

### Cas d'Usage Supportés
1. **Follow-up après appel** - Envoi de documents, résumés, informations complémentaires
2. **Cold emails (Arthur)** - Prospection par email avant/après appel téléphonique
3. **Confirmations RDV** - Emails de confirmation et rappels de rendez-vous
4. **Séquences automatisées** - Campagnes multi-touch (jour 1, jour 3, jour 7, etc.)

---

## 🏗️ Architecture

### Table Principale : `agent_emails`

**Colonnes clés** :
- `id` (UUID) - Identifiant unique
- `deployment_id` (UUID) - Agent ayant envoyé l'email
- `call_id`, `prospect_id`, `sequence_id` (UUID) - Relations avec autres entités
- `email_address` (TEXT) - Destinataire
- `email_subject`, `email_body_html`, `email_body_text` - Contenu
- `email_type` - Type d'email (follow_up, cold_email, appointment_confirmation, sequence_step, etc.)
- `status` - Statut d'envoi (sent, failed, queued)
- `workflow_id`, `workflow_execution_id` - Tracking n8n

**Tracking futur (colonnes préparées)** :
- `opened_at` - Date de première ouverture (NULL pour l'instant)
- `first_clicked_at` - Date de premier clic (NULL pour l'instant)
- `bounce_type` - Type de bounce (hard, soft, none, NULL)
- `spam_reported_at` - Date de report spam (NULL pour l'instant)

### Relations

```
agent_emails
├── deployment_id → agent_deployments(id) ON DELETE CASCADE
├── call_id → agent_calls(id) ON DELETE SET NULL
├── prospect_id → agent_arthur_prospects(id) ON DELETE SET NULL
└── sequence_id → agent_arthur_prospect_sequences(id) ON DELETE SET NULL
```

### Sécurité RLS

Les utilisateurs peuvent voir uniquement les emails des clients auxquels ils ont accès via `user_client_permissions`.

---

## 🔧 Provider : Gmail via n8n

**Différences avec SMS (Twilio)** :
- **SMS** : Provider externe (Twilio) avec tracking natif via webhooks
- **Emails** : Gmail via n8n workflows (pas de provider externe)

**Conséquences** :
- Pas de `provider_message_sid` (Gmail n'a pas d'ID externe comme Twilio)
- Pas de webhooks automatiques pour delivery status
- Tracking manuel via colonnes `workflow_message_id` et `gmail_thread_id`

---

## 💰 Modèle de Pricing : Dynamique Pay-Per-Use

**Philosophie** : Pricing configurable par déploiement (défaut 0€, modifiable pour activer la facturation).

**Colonne dans `agent_deployments`** :
- `cost_per_email` (NUMERIC) - Prix par email (défaut 0€, modifiable par déploiement)

**Colonnes financières dans `agent_emails`** :
- `provider_cost` (NUMERIC) - Coût provider (Gmail = 0€, SendGrid = ~0.0012€)
- `billed_cost` (NUMERIC) - Prix facturé client (récupéré depuis `cost_per_email`)
- `margin` (NUMERIC GENERATED) - Marge auto-calculée (billed_cost - provider_cost)
- `currency` (TEXT) - EUR par défaut

**Identique au modèle SMS** :
- SMS : 3 colonnes (`provider_cost`, `billed_cost`, `margin`) ✅
- Emails : 3 colonnes (`provider_cost`, `billed_cost`, `margin`) ✅
- Pricing dynamique récupéré depuis `agent_deployments`

**Pricing par défaut** : cost_per_email = 0€ (gratuit inclus, peut être modifié)

Voir `documentation/PRICING_MODEL.md` pour les détails complets.

---

## 📊 Analytics

### Views

1. **`v_agent_emails_enriched`** - Emails avec contexte client/agent/deployment
2. **`v_agent_communications_unified`** - Vue unifiée des appels + SMS + Emails

### Fonction RPC

**`get_email_metrics(p_start_date, p_end_date, p_client_id, p_deployment_id, p_agent_type_name)`**

Retourne des métriques complètes :
- Total emails, sent, failed
- Delivery rate
- **Métriques financières** : total_provider_cost, total_revenue, total_margin, margin_percentage
- Coûts moyens : avg_provider_cost, avg_billed_cost, avg_margin
- Moyenne word_count, html_size
- Répartition par email_type
- Comparaison période précédente (incluant revenus et marges)

---

## 📁 Structure du Dossier

```
features/email-tracking/
├── README.md                           # Ce fichier
├── IMPLEMENTATION_SUMMARY.md           # Résumé d'implémentation
├── MIGRATION_TESTED.md                 # Résultats tests staging
├── documentation/
│   ├── SCHEMA.md                       # Schéma complet de la table
│   ├── N8N_INTEGRATION.md             # Guide intégration n8n + Gmail
│   ├── TRACKING_FUTURE.md             # Roadmap tracking opens/clicks
│   └── PRICING_MODEL.md               # Modèle de coût (gratuit inclus)
├── sql/
│   ├── 20251114_create_agent_emails_table.sql  # Table + indexes + triggers
│   ├── 20251114_email_rls_policies.sql         # RLS policies + grants
│   └── 20251114_email_analytics.sql            # Views + RPC functions
└── notes/
    └── development_notes.md
```

---

## 🚀 Intégration n8n

### Workflow Node Gmail → Node Supabase

Après chaque email envoyé par Gmail dans un workflow n8n :

1. **Node Gmail** envoie l'email
2. **Node Supabase** insère l'enregistrement dans `agent_emails`

**Exemple de données à insérer** :
```json
{
  "deployment_id": "{{ $('Get Deployment ID').item.json.id }}",
  "call_id": "{{ $('Previous Call').item.json.id }}",
  "email_address": "{{ $json.recipient }}",
  "first_name": "{{ $json.first_name }}",
  "last_name": "{{ $json.last_name }}",
  "email_subject": "{{ $json.subject }}",
  "email_body_html": "{{ $json.html_body }}",
  "email_body_text": "{{ $json.text_body }}",
  "email_type": "follow_up",
  "status": "sent",
  "sent_at": "{{ $now }}",
  "provider_cost": 0,
  "billed_cost": "{{ $('Get Deployment').item.json.cost_per_email }}",
  "workflow_id": "{{ $workflow.id }}",
  "workflow_execution_id": "{{ $execution.id }}",
  "workflow_message_id": "{{ $('Gmail').item.json.id }}",
  "gmail_thread_id": "{{ $('Gmail').item.json.threadId }}"
}
```

**Note** : `billed_cost` est récupéré dynamiquement depuis `agent_deployments.cost_per_email`, `margin` est calculée automatiquement.

Voir `documentation/N8N_INTEGRATION.md` pour le guide complet.

---

## 📈 Roadmap : Tracking Avancé

### Phase Actuelle (v1.0) ✅
- ✅ Tracking envoi (sent, failed)
- ✅ Relations avec calls/prospects/sequences
- ✅ Métriques de base (volume, delivery rate)

### Phase Future (v2.0) 🔜
- 📍 Tracking ouvertures (pixel tracking)
- 📍 Tracking clics (link tracking)
- 📍 Détection bounces (webhooks Gmail API)
- 📍 Détection spam reports

**Voir `documentation/TRACKING_FUTURE.md` pour le plan détaillé**

---

## 🔍 Requêtes Utiles

### Total emails envoyés par client (30 derniers jours)
```sql
SELECT
    client_name,
    COUNT(*) AS total_emails,
    COUNT(*) FILTER (WHERE status = 'sent') AS sent_emails,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed_emails,
    ROUND(AVG(word_count), 2) AS avg_word_count
FROM v_agent_emails_enriched
WHERE sent_at >= NOW() - INTERVAL '30 days'
GROUP BY client_name
ORDER BY total_emails DESC;
```

### Répartition par type d'email
```sql
SELECT
    email_type,
    COUNT(*) AS count,
    ROUND(AVG(word_count), 2) AS avg_word_count,
    COUNT(*) FILTER (WHERE has_attachments = TRUE) AS with_attachments
FROM agent_emails
WHERE sent_at >= NOW() - INTERVAL '30 days'
GROUP BY email_type
ORDER BY count DESC;
```

---

## ✅ Checklist d'Implémentation

- [x] Créer la structure de dossier `features/email-tracking/`
- [x] Créer la table `agent_emails` avec toutes les colonnes
- [x] Créer les 7 indexes optimisés
- [x] Créer les RLS policies (4 policies)
- [x] Créer les views `v_agent_emails_enriched` et `v_agent_communications_unified`
- [x] Créer la fonction RPC `get_email_metrics()`
- [x] Créer le trigger `update_agent_emails_updated_at`
- [x] Tester en staging avec données réelles
- [x] Documenter l'intégration n8n
- [x] Documenter la roadmap tracking avancé

---

## 📚 Références

- **Inspiré de** : `features/sms-tracking/` (table `agent_sms`)
- **Différences clés** : Provider Gmail (pas Twilio), pricing gratuit (pas facturé), tracking futur (pas implémenté)
- **Documentation Supabase** : [RLS](https://supabase.com/docs/guides/auth/row-level-security), [Views](https://supabase.com/docs/guides/database/tables#views), [RPC](https://supabase.com/docs/guides/database/functions)

---

## 📞 Support

Pour toute question sur ce feature, consulter :
1. `documentation/SCHEMA.md` - Schéma détaillé
2. `documentation/N8N_INTEGRATION.md` - Guide d'intégration
3. `documentation/TRACKING_FUTURE.md` - Roadmap tracking avancé
4. `IMPLEMENTATION_SUMMARY.md` - Résumé d'implémentation
