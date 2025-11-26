# 📊 Schema Documentation - Table `agent_emails`

## Vue d'ensemble

Ce document décrit en détail le schéma de la table `agent_emails` qui track tous les emails envoyés par les agents Voipia.

**Table** : `public.agent_emails`
**Date de création** : 2025-11-14
**Version** : 1.0

---

## 🗂️ CREATE TABLE Statement

```sql
CREATE TABLE IF NOT EXISTS public.agent_emails (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    deployment_id UUID NOT NULL REFERENCES public.agent_deployments(id) ON DELETE CASCADE,
    call_id UUID REFERENCES public.agent_calls(id) ON DELETE SET NULL,
    prospect_id UUID REFERENCES public.agent_arthur_prospects(id) ON DELETE SET NULL,
    sequence_id UUID REFERENCES public.agent_arthur_prospect_sequences(id) ON DELETE SET NULL,

    -- Recipient information
    email_address TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,

    -- Email content
    email_subject TEXT NOT NULL,
    email_body_html TEXT,
    email_body_text TEXT,
    word_count INTEGER GENERATED ALWAYS AS (
        LENGTH(REGEXP_REPLACE(COALESCE(email_body_text, ''), '\s+', ' ', 'g'))
    ) STORED,
    html_size_bytes INTEGER GENERATED ALWAYS AS (
        LENGTH(COALESCE(email_body_html, ''))
    ) STORED,
    has_attachments BOOLEAN DEFAULT FALSE,
    attachment_names TEXT[],

    -- Email type
    email_type TEXT DEFAULT 'transactional' CHECK (email_type IN (
        'follow_up',
        'cold_email',
        'appointment_confirmation',
        'sequence_step',
        'transactional',
        'notification'
    )),

    -- Provider details (Gmail via n8n)
    provider TEXT DEFAULT 'gmail',
    workflow_message_id TEXT,
    gmail_thread_id TEXT,

    -- Status tracking
    status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'failed', 'queued')),
    sent_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    failure_reason TEXT,

    -- Tracking metrics (FUTURES - NULL pour l'instant)
    opened_at TIMESTAMP WITH TIME ZONE,
    first_clicked_at TIMESTAMP WITH TIME ZONE,
    bounce_type TEXT CHECK (bounce_type IN ('hard', 'soft', 'none', NULL)),
    spam_reported_at TIMESTAMP WITH TIME ZONE,

    -- Cost tracking (dynamic pricing model - same as SMS)
    provider_cost NUMERIC(10, 4) CHECK (provider_cost >= 0),
    billed_cost NUMERIC(10, 4) CHECK (billed_cost >= 0),
    margin NUMERIC(10, 4) GENERATED ALWAYS AS (COALESCE(billed_cost, 0) - COALESCE(provider_cost, 0)) STORED,
    currency TEXT DEFAULT 'EUR',

    -- n8n workflow tracking
    workflow_id TEXT,
    workflow_execution_id TEXT,

    -- Metadata (flexible JSONB)
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 📋 Description des Colonnes

### Identification

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `id` | UUID | NOT NULL | Identifiant unique de l'email (PRIMARY KEY, auto-généré) |

### Foreign Keys

| Colonne | Type | Nullable | Référence | DELETE Behavior | Description |
|---------|------|----------|-----------|-----------------|-------------|
| `deployment_id` | UUID | NOT NULL | `agent_deployments(id)` | CASCADE | Agent ayant envoyé l'email |
| `call_id` | UUID | NULL | `agent_calls(id)` | SET NULL | Appel associé (si email de follow-up) |
| `prospect_id` | UUID | NULL | `agent_arthur_prospects(id)` | SET NULL | Prospect Arthur associé |
| `sequence_id` | UUID | NULL | `agent_arthur_prospect_sequences(id)` | SET NULL | Séquence multi-touch associée |

**Comportements ON DELETE** :
- `CASCADE` pour `deployment_id` : Si l'agent est supprimé, tous ses emails sont supprimés
- `SET NULL` pour les autres FK : Si l'entité liée est supprimée, l'email reste mais la référence est NULL

### Destinataire

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `email_address` | TEXT | NOT NULL | Adresse email du destinataire |
| `first_name` | TEXT | NULL | Prénom du destinataire |
| `last_name` | TEXT | NULL | Nom du destinataire |

### Contenu de l'Email

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `email_subject` | TEXT | NOT NULL | Sujet de l'email |
| `email_body_html` | TEXT | NULL | Corps de l'email en HTML |
| `email_body_text` | TEXT | NULL | Corps de l'email en texte brut (fallback) |
| `word_count` | INTEGER | NOT NULL | **GÉNÉRÉ** - Nombre de mots dans `email_body_text` |
| `html_size_bytes` | INTEGER | NOT NULL | **GÉNÉRÉ** - Taille du HTML en bytes |
| `has_attachments` | BOOLEAN | NOT NULL | Présence de pièces jointes (défaut: FALSE) |
| `attachment_names` | TEXT[] | NULL | Noms des fichiers joints (array) |

**Colonnes GENERATED** :
- `word_count` : Calculé automatiquement en comptant les mots dans `email_body_text`
- `html_size_bytes` : Calculé automatiquement en mesurant la longueur de `email_body_html`

**Pourquoi 3 colonnes pour le contenu ?** :
- `email_subject` : Séparé pour analytics (analyse des sujets)
- `email_body_html` : Version HTML riche (mise en forme, images, liens)
- `email_body_text` : Version texte brut (fallback pour clients email sans HTML)

### Type d'Email

| Colonne | Type | Nullable | Default | Valeurs Possibles | Description |
|---------|------|----------|---------|-------------------|-------------|
| `email_type` | TEXT | NOT NULL | `'transactional'` | `'follow_up'`, `'cold_email'`, `'appointment_confirmation'`, `'sequence_step'`, `'transactional'`, `'notification'` | Type d'email selon le cas d'usage |

**Détail des types** :
- `follow_up` : Email envoyé après un appel (résumé, documents, informations complémentaires)
- `cold_email` : Email de prospection (Arthur) avant ou après appel téléphonique
- `appointment_confirmation` : Email de confirmation ou rappel de rendez-vous
- `sequence_step` : Étape dans une séquence automatisée (jour 1, jour 3, jour 7, etc.)
- `transactional` : Email transactionnel générique (ex: confirmation d'action)
- `notification` : Notification système (ex: alerte, mise à jour)

### Provider (Gmail via n8n)

| Colonne | Type | Nullable | Default | Description |
|---------|------|----------|---------|-------------|
| `provider` | TEXT | NOT NULL | `'gmail'` | Provider d'envoi (fixé à 'gmail') |
| `workflow_message_id` | TEXT | NULL | - | ID du message Gmail (optionnel) |
| `gmail_thread_id` | TEXT | NULL | - | ID du thread Gmail (conversations) |

**Note** : Contrairement aux SMS (Twilio), Gmail via n8n ne fournit pas de `message_sid` externe. Ces colonnes permettent un tracking manuel si le workflow n8n capture les IDs retournés par Gmail.

### Status d'Envoi

| Colonne | Type | Nullable | Default | Valeurs Possibles | Description |
|---------|------|----------|---------|-------------------|-------------|
| `status` | TEXT | NOT NULL | `'sent'` | `'sent'`, `'failed'`, `'queued'` | Statut d'envoi simplifié |
| `sent_at` | TIMESTAMPTZ | NULL | - | Datetime d'envoi effectif |
| `failed_at` | TIMESTAMPTZ | NULL | - | Datetime d'échec d'envoi |
| `failure_reason` | TEXT | NULL | - | Raison de l'échec (erreur Gmail, quota dépassé, etc.) |

**Workflow des statuts** :
```
queued → sent → (success)
   ↓
queued → failed → (error avec failure_reason)
```

**Simplifié par rapport aux SMS** :
- SMS : Dual system (`status` + `provider_status`) avec webhooks Twilio
- Emails : Simple system (`status` uniquement) sans webhooks Gmail

### Tracking Avancé (FUTUR)

| Colonne | Type | Nullable | Default | Description | État |
|---------|------|----------|---------|-------------|------|
| `opened_at` | TIMESTAMPTZ | NULL | - | Date de première ouverture | 🔜 Future (pixel tracking) |
| `first_clicked_at` | TIMESTAMPTZ | NULL | - | Date de premier clic sur un lien | 🔜 Future (link tracking) |
| `bounce_type` | TEXT | NULL | - | Type de bounce (hard, soft, none) | 🔜 Future (webhooks Gmail API) |
| `spam_reported_at` | TIMESTAMPTZ | NULL | - | Date de report spam | 🔜 Future (webhooks Gmail API) |

**Ces colonnes sont préparées pour le tracking avancé mais restent NULL en v1.0**

Voir `TRACKING_FUTURE.md` pour le plan d'implémentation.

### Coûts

| Colonne | Type | Nullable | Default | Description |
|---------|------|----------|---------|-------------|
| `provider_cost` | NUMERIC(10,4) | NULL | - | Coût payé au provider (Gmail = 0€, SendGrid = ~0.0012€) |
| `billed_cost` | NUMERIC(10,4) | NULL | - | Prix facturé au client (récupéré depuis `agent_deployments.cost_per_email`) |
| `margin` | NUMERIC(10,4) | NOT NULL | **GÉNÉRÉ** | Marge auto-calculée : `billed_cost - provider_cost` |
| `currency` | TEXT | NOT NULL | `'EUR'` | Devise (EUR par défaut) |

**Modèle de pricing : Dynamique Pay-Per-Use**
- Identique au modèle SMS : 3 colonnes financières (`provider_cost`, `billed_cost`, `margin`)
- `cost_per_email` défini dans `agent_deployments` (défaut 0€, peut être modifié par déploiement)
- `billed_cost` = récupéré dynamiquement depuis `agent_deployments.cost_per_email` lors de l'insertion n8n
- `provider_cost` = 0€ par défaut (Gmail inclus), mais préparé pour migration SendGrid
- `margin` = calculé automatiquement (GENERATED COLUMN)

**Colonne GENERATED** :
- `margin` : Auto-calculée lors de chaque INSERT/UPDATE
- Formule : `COALESCE(billed_cost, 0) - COALESCE(provider_cost, 0)`
- Ne peut pas être modifiée manuellement (protection PostgreSQL)

**Pricing par défaut** :
- Nouveau déploiement : `cost_per_email = 0€` → emails gratuits inclus
- Peut être modifié par client : `UPDATE agent_deployments SET cost_per_email = 0.01` (1 centime/email)
- Workflow n8n récupère dynamiquement `cost_per_email` et l'insère dans `billed_cost`

Voir `PRICING_MODEL.md` pour les détails et exemples de facturation.

### Tracking n8n Workflow

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `workflow_id` | TEXT | NULL | ID du workflow n8n ayant envoyé l'email |
| `workflow_execution_id` | TEXT | NULL | ID de l'exécution n8n spécifique |

**Utilité** :
- Tracer quel workflow a envoyé l'email
- Debugger les problèmes d'envoi (consulter logs n8n)
- Analytics : performances par workflow

### Metadata Flexible

| Colonne | Type | Nullable | Default | Description |
|---------|------|----------|---------|-------------|
| `metadata` | JSONB | NOT NULL | `'{}'` | Données additionnelles flexibles (JSON) |

**Exemples d'usage** :
```json
{
  "template_name": "follow_up_call_summary",
  "variables": {
    "agent_name": "Louis",
    "call_duration": "5:32",
    "next_steps": ["Envoyer devis", "Rappeler lundi"]
  },
  "campaign_id": "campaign_2024_q4",
  "utm_parameters": {
    "utm_source": "voipia_agent",
    "utm_medium": "email",
    "utm_campaign": "follow_up"
  }
}
```

### Timestamps

| Colonne | Type | Nullable | Default | Description |
|---------|------|----------|---------|-------------|
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | Date de création de l'enregistrement |
| `updated_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | Date de dernière mise à jour (auto-update via trigger) |

**Trigger auto-update** : `update_agent_emails_updated_at` met à jour automatiquement `updated_at` à chaque UPDATE.

---

## 🔍 Indexes

### 7 Indexes Optimisés

```sql
-- 1. Time-series queries (deployment + time)
CREATE INDEX idx_agent_emails_deployment_sent_at
ON public.agent_emails (deployment_id, sent_at DESC);

-- 2. Status filtering
CREATE INDEX idx_agent_emails_status
ON public.agent_emails (status)
WHERE status IN ('sent', 'failed');

-- 3. Call relationship lookup
CREATE INDEX idx_agent_emails_call_id
ON public.agent_emails (call_id)
WHERE call_id IS NOT NULL;

-- 4. Email address lookup (pour dédoublonnage, fréquence d'envoi)
CREATE INDEX idx_agent_emails_email_address
ON public.agent_emails (email_address);

-- 5. Email type analytics
CREATE INDEX idx_agent_emails_type
ON public.agent_emails (email_type, sent_at DESC);

-- 6. Prospect history (Arthur)
CREATE INDEX idx_agent_emails_prospect
ON public.agent_emails (prospect_id)
WHERE prospect_id IS NOT NULL;

-- 7. Sequence tracking
CREATE INDEX idx_agent_emails_sequence
ON public.agent_emails (sequence_id)
WHERE sequence_id IS NOT NULL;
```

**Performance** :
- Optimisé pour 5000-20000 emails/mois
- Rétention : 2-3 ans
- Partial indexes pour réduire la taille (WHERE clauses)

---

## 🔒 Row-Level Security (RLS)

### Policies

**1. `users_view_accessible_emails`** (SELECT)
```sql
CREATE POLICY users_view_accessible_emails ON public.agent_emails
FOR SELECT TO authenticated
USING (
    deployment_id IN (
        SELECT ad.id
        FROM public.agent_deployments ad
        JOIN public.user_client_permissions ucp ON ucp.client_id = ad.client_id
        WHERE ucp.user_id = auth.uid()
    )
);
```

**2. `admins_manage_emails`** (ALL)
```sql
CREATE POLICY admins_manage_emails ON public.agent_emails
FOR ALL TO authenticated
USING (
    deployment_id IN (
        SELECT ad.id
        FROM public.agent_deployments ad
        JOIN public.user_client_permissions ucp ON ucp.client_id = ad.client_id
        WHERE ucp.user_id = auth.uid() AND ucp.permission_level = 'admin'
    )
)
WITH CHECK (same condition);
```

**3. `service_insert_emails`** (INSERT - n8n)
```sql
CREATE POLICY service_insert_emails ON public.agent_emails
FOR INSERT TO service_role
WITH CHECK (true);
```

**4. `service_update_emails`** (UPDATE - webhooks futurs)
```sql
CREATE POLICY service_update_emails ON public.agent_emails
FOR UPDATE TO service_role
USING (true) WITH CHECK (true);
```

### Grants

```sql
GRANT SELECT ON public.agent_emails TO authenticated;
GRANT INSERT, UPDATE ON public.agent_emails TO service_role;
```

**Sécurité héritée** :
```
User → user_client_permissions → clients ← agent_deployments ← agent_emails
```

---

## 🔧 Triggers

### Auto-Update `updated_at`

```sql
CREATE OR REPLACE FUNCTION update_agent_emails_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER agent_emails_updated_at
BEFORE UPDATE ON public.agent_emails
FOR EACH ROW
EXECUTE FUNCTION update_agent_emails_updated_at();
```

**Utilité** : `updated_at` est automatiquement mis à jour à chaque modification de la ligne.

---

## 📊 Views Dépendantes

### `v_agent_emails_enriched`

View qui enrichit `agent_emails` avec le contexte client/agent/deployment.

**Colonnes additionnelles** :
- `deployment_name`, `deployment_slug`
- `client_id`, `client_name`
- `agent_type_id`, `agent_type_name`, `agent_display_name`
- `is_sent`, `is_failed` (booleans calculés)

### `v_agent_communications_unified`

View unifiée combinant **calls + sms + emails** pour une vision globale des communications.

**Colonnes communes** :
- `communication_type` ('call', 'sms', 'email')
- `id`, `deployment_id`, `contact_info` (phone ou email)
- `timestamp`, `result`, `cost`, `duration` (si applicable)
- `content` (message_content ou email_subject)

---

## 🎯 Requêtes Courantes

### Total emails envoyés par agent type (30 derniers jours)
```sql
SELECT
    agent_display_name,
    COUNT(*) AS total_emails,
    COUNT(*) FILTER (WHERE status = 'sent') AS sent,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed,
    ROUND((COUNT(*) FILTER (WHERE status = 'sent')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2) AS delivery_rate
FROM v_agent_emails_enriched
WHERE sent_at >= NOW() - INTERVAL '30 days'
GROUP BY agent_display_name
ORDER BY total_emails DESC;
```

### Répartition par type d'email
```sql
SELECT
    email_type,
    COUNT(*) AS count,
    ROUND(AVG(word_count), 2) AS avg_word_count,
    ROUND(AVG(html_size_bytes / 1024.0), 2) AS avg_html_size_kb,
    COUNT(*) FILTER (WHERE has_attachments = TRUE) AS with_attachments,
    ROUND((COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER ()) * 100, 2) AS percentage
FROM agent_emails
WHERE sent_at >= NOW() - INTERVAL '30 days'
GROUP BY email_type
ORDER BY count DESC;
```

### Emails liés à des appels (follow-up)
```sql
SELECT
    ae.email_subject,
    ae.sent_at,
    ac.started_at AS call_started_at,
    EXTRACT(EPOCH FROM (ae.sent_at - ac.started_at)) / 60 AS minutes_after_call,
    ae.email_type,
    ae.status
FROM agent_emails ae
JOIN agent_calls ac ON ae.call_id = ac.id
WHERE ae.sent_at >= NOW() - INTERVAL '7 days'
ORDER BY ae.sent_at DESC
LIMIT 20;
```

### Top 10 destinataires par volume d'emails
```sql
SELECT
    email_address,
    COUNT(*) AS total_emails,
    COUNT(DISTINCT deployment_id) AS agents_count,
    ARRAY_AGG(DISTINCT email_type) AS email_types,
    MIN(sent_at) AS first_email,
    MAX(sent_at) AS last_email
FROM agent_emails
WHERE sent_at >= NOW() - INTERVAL '90 days'
GROUP BY email_address
ORDER BY total_emails DESC
LIMIT 10;
```

---

## 🔄 Migrations

**Ordre d'exécution** :
1. `20251114_create_agent_emails_table.sql` - Table + indexes + triggers
2. `20251114_email_rls_policies.sql` - RLS policies + grants
3. `20251114_email_analytics.sql` - Views + RPC functions

**Rollback** :
```sql
-- Ordre inverse
DROP VIEW IF EXISTS v_agent_communications_unified;
DROP VIEW IF EXISTS v_agent_emails_enriched;
DROP FUNCTION IF EXISTS get_email_metrics(...);
DROP POLICY users_view_accessible_emails ON agent_emails;
DROP POLICY admins_manage_emails ON agent_emails;
DROP POLICY service_insert_emails ON agent_emails;
DROP POLICY service_update_emails ON agent_emails;
DROP TRIGGER IF EXISTS agent_emails_updated_at ON agent_emails;
DROP FUNCTION IF EXISTS update_agent_emails_updated_at();
DROP TABLE IF EXISTS agent_emails CASCADE;
```

---

## 📚 Références

- **Table SMS** : `public.agent_sms` (structure similaire)
- **Supabase RLS** : https://supabase.com/docs/guides/auth/row-level-security
- **PostgreSQL Indexes** : https://www.postgresql.org/docs/current/indexes.html
- **JSONB Type** : https://www.postgresql.org/docs/current/datatype-json.html
