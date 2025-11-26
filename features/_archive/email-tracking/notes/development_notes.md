# 📝 Development Notes - Email Tracking System

## Date: 2025-11-14

### Contexte

Suite à l'implémentation réussie de `agent_sms` (features/sms-tracking/), nous avons conçu un système similaire pour tracker les emails envoyés par les agents Voipia (Louis, Arthur, Alexandra) via Gmail et n8n.

---

## Décisions de Conception

### 1. Structure de la Table

**Décision** : Créer une table `agent_emails` similaire à `agent_sms` mais adaptée aux spécificités des emails.

**Raisons** :
- ✅ Réutiliser l'architecture éprouvée de `agent_sms` (FK, RLS, indexes)
- ✅ Adapter le contenu : 3 colonnes (subject + html + text) vs 1 pour SMS
- ✅ Simplifier le pricing : 1 colonne (`internal_cost`) vs 3 pour SMS
- ✅ Préparer le tracking avancé : colonnes NULL pour v2.0 (opens, clicks, bounces)

**Trade-offs** :
- ⚖️ Colonnes futures (opened_at, clicked_at) occupent de l'espace mais évitent une migration v2.0
- ⚖️ JSONB metadata flexible vs colonnes strictes (choix : JSONB pour flexibilité)

### 2. Modèle de Pricing

**Décision** : Pricing dynamique pay-per-use (identique au modèle SMS) avec défaut à 0€.

**Raisons** :
- ✅ **Anticipation de la facturation** - Infrastructure prête si nécessaire (migration SendGrid, premium features)
- ✅ **Flexibilité commerciale** - Possibilité d'activer la facturation par client/déploiement
- ✅ **Cohérence avec SMS** - Même structure de données (3 colonnes : provider_cost, billed_cost, margin)
- ✅ **Comptabilité précise** - Tracking des coûts réels et marges par déploiement
- ✅ **Scaling** - Si volume augmente, possibilité d'amortir les coûts infrastructure

**Implémentation** :
- Colonne `cost_per_email` dans `agent_deployments` (défaut 0€, modifiable par déploiement)
- 3 colonnes financières dans `agent_emails` : `provider_cost`, `billed_cost`, `margin` (GENERATED)
- Workflow n8n récupère dynamiquement `cost_per_email` et l'insère dans `billed_cost`
- Marge calculée automatiquement par PostgreSQL

**Pricing par défaut** : 0€ (gratuit inclus, rétrocompatibilité) - peut être modifié si nécessaire

### 3. Provider : Gmail via n8n

**Décision** : Utiliser Gmail via n8n workflows (pas de provider externe comme Twilio pour SMS).

**Raisons** :
- ✅ Déjà utilisé pour l'envoi d'emails (pas besoin de nouvelle intégration)
- ✅ Coût 0€ (inclus dans Google Workspace)
- ✅ Simplicité (pas de webhooks externes à gérer)

**Limitations** :
- ❌ Pas de tracking natif des ouvertures/clics (besoin de pixel/link tracking custom en v2.0)
- ❌ Pas de webhooks automatiques pour bounces (nécessite Gmail API Pub/Sub en v2.0)

**Alternative future** : Migration vers SendGrid/Mailgun pour tracking automatique (coût 19.95$/mois)

### 4. Tracking Avancé (v2.0)

**Décision** : Préparer les colonnes maintenant (NULL), implémenter le tracking en v2.0.

**Raisons** :
- ✅ Évite une migration de schéma en v2.0 (ADD COLUMN)
- ✅ Colonnes documentées et comprises dès v1.0
- ✅ Flexibilité : peut rester NULL si tracking non implémenté

**Colonnes futures** :
- `opened_at`, `first_clicked_at`, `bounce_type`, `spam_reported_at`
- Seront peuplées via routes API `/api/track/open` et `/api/track/click` (v2.0)

### 5. Indexes Optimisés

**Décision** : Créer 7 indexes stratégiques avec partial indexes (WHERE clauses).

**Raisons** :
- ✅ Performance sur time-series queries (deployment + sent_at)
- ✅ Partial indexes réduisent la taille (ex: WHERE status IN ('sent', 'failed'))
- ✅ Support des patterns de requêtes courants (par type, par destinataire, par prospect)

**Trade-offs** :
- ⚖️ Plus d'indexes = meilleure lecture, mais INSERT légèrement plus lent
- ⚖️ Partial indexes économisent de l'espace mais nécessitent WHERE clauses exactes

### 6. RLS Policies

**Décision** : Réutiliser la même logique RLS que `agent_sms` (sécurité héritée de `user_client_permissions`).

**Raisons** :
- ✅ Cohérence avec l'architecture existante
- ✅ Users voient uniquement les emails de leurs clients
- ✅ Service role (n8n) peut INSERT/UPDATE sans restriction

**Policies** :
1. `users_view_accessible_emails` (SELECT)
2. `admins_manage_emails` (ALL)
3. `service_insert_emails` (INSERT - n8n)
4. `service_update_emails` (UPDATE - webhooks futurs)

---

## Différences Clés avec agent_sms

| Aspect | agent_sms | agent_emails |
|--------|-----------|--------------|
| **Contenu** | 1 colonne (`message_content`) | 3 colonnes (`email_subject`, `email_body_html`, `email_body_text`) |
| **Taille** | `character_count` (GENERATED) | `word_count` + `html_size_bytes` (GENERATED) |
| **Provider** | Twilio (externe) | Gmail via n8n (interne) |
| **Provider ID** | `provider_message_sid` (unique) | `workflow_message_id` (optionnel) |
| **Status** | Dual system (`status` + `provider_status`) | Simple system (`status` uniquement) |
| **Pricing** | 3 colonnes (`provider_cost`, `billed_cost`, `margin`) | 3 colonnes (`provider_cost`, `billed_cost`, `margin`) ✅ |
| **Colonne déploiement** | `cost_per_sms` (agent_deployments) | `cost_per_email` (agent_deployments) ✅ |
| **Facturation** | 0.07€/SMS (facturé) | 0€/email par défaut (modifiable) ✅ |
| **Tracking** | Livraison uniquement | Prêt pour opens/clicks (v3.0) |
| **Pièces jointes** | ❌ | ✅ `has_attachments` + `attachment_names[]` |

---

## Requêtes SQL Courantes

### 1. Emails envoyés par client (30 derniers jours)

```sql
SELECT
    client_name,
    COUNT(*) AS total_emails,
    COUNT(*) FILTER (WHERE status = 'sent') AS sent,
    COUNT(*) FILTER (WHERE status = 'failed') AS failed,
    ROUND((COUNT(*) FILTER (WHERE status = 'sent')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2) AS delivery_rate
FROM v_agent_emails_enriched
WHERE sent_at >= NOW() - INTERVAL '30 days'
GROUP BY client_name
ORDER BY total_emails DESC;
```

### 2. Répartition par type d'email

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

### 3. Emails liés à des appels (follow-up)

```sql
SELECT
    ae.email_subject,
    ae.sent_at,
    ac.started_at AS call_started_at,
    EXTRACT(EPOCH FROM (ae.sent_at - ac.started_at)) / 60 AS minutes_after_call
FROM agent_emails ae
JOIN agent_calls ac ON ae.call_id = ac.id
WHERE ae.sent_at >= NOW() - INTERVAL '7 days'
ORDER BY ae.sent_at DESC
LIMIT 20;
```

### 4. Top destinataires par volume

```sql
SELECT
    email_address,
    COUNT(*) AS total_emails,
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

## Tests à Effectuer en Staging

### Phase 1 : Migrations SQL

```bash
# 1. Appliquer migration 1 (table)
psql -f features/email-tracking/sql/20251114_create_agent_emails_table.sql

# 2. Vérifier table créée
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'agent_emails';

# 3. Vérifier indexes
SELECT indexname FROM pg_indexes
WHERE tablename = 'agent_emails';

# 4. Appliquer migration 2 (RLS)
psql -f features/email-tracking/sql/20251114_email_rls_policies.sql

# 5. Vérifier policies
SELECT policyname FROM pg_policies
WHERE tablename = 'agent_emails';

# 6. Appliquer migration 3 (analytics)
psql -f features/email-tracking/sql/20251114_email_analytics.sql

# 7. Vérifier views
SELECT viewname FROM pg_views
WHERE schemaname = 'public' AND viewname LIKE 'v_agent_%';

# 8. Vérifier fonction RPC
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_name = 'get_email_metrics';
```

### Phase 2 : Insertion Données de Test

```sql
-- Insérer 50-100 emails de test (via n8n ou manuellement)
INSERT INTO agent_emails (
    deployment_id,
    email_address,
    first_name,
    last_name,
    email_subject,
    email_body_html,
    email_body_text,
    email_type,
    status,
    sent_at,
    workflow_id
) VALUES (
    'YOUR-DEPLOYMENT-UUID',
    'test1@example.com',
    'John',
    'Doe',
    'Test Follow-Up Email',
    '<html><body><p>This is a test email.</p></body></html>',
    'This is a test email.',
    'follow_up',
    'sent',
    NOW(),
    'test-workflow-id'
);

-- Répéter avec différents email_type, status, clients
```

### Phase 3 : Tests Analytics

```sql
-- Test view enriched
SELECT
    email_subject,
    client_name,
    agent_display_name,
    is_sent,
    sent_at
FROM v_agent_emails_enriched
ORDER BY sent_at DESC
LIMIT 10;

-- Test fonction RPC
SELECT get_email_metrics(
    NOW() - INTERVAL '30 days',
    NOW(),
    NULL,  -- All clients
    NULL,  -- All deployments
    NULL   -- All agent types
);

-- Test filtré par agent type (Louis)
SELECT get_email_metrics(
    NOW() - INTERVAL '30 days',
    NOW(),
    NULL,
    NULL,
    'louis'  -- Only Louis
);
```

### Phase 4 : Tests RLS

```sql
-- Test as authenticated user (should see filtered)
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims.sub = 'USER-UUID';
SELECT COUNT(*) FROM agent_emails;
-- Expected: Only accessible clients' emails

-- Test as service_role (should see all)
SET LOCAL ROLE service_role;
SELECT COUNT(*) FROM agent_emails;
-- Expected: All emails

-- Test INSERT as service_role (should succeed)
INSERT INTO agent_emails (deployment_id, email_address, email_subject, status)
VALUES ('UUID', 'test@example.com', 'Test', 'sent');

-- Test INSERT as authenticated (should fail)
SET LOCAL ROLE authenticated;
INSERT INTO agent_emails (deployment_id, email_address, email_subject, status)
VALUES ('UUID', 'test@example.com', 'Test', 'sent');
-- Expected: ERROR - permission denied

RESET ROLE;
```

---

## Problèmes Potentiels et Solutions

### Problème 1 : Performance avec Grand Volume

**Symptôme** : Requêtes lentes sur v_agent_emails_enriched avec 100K+ emails

**Solution** :
- Ajouter index composite sur (client_id, sent_at)
- Créer materialized view pour dashboards
- Archiver emails > 2 ans dans table `agent_emails_archive`

### Problème 2 : JSONB metadata Trop Gros

**Symptôme** : Colonne metadata > 1 MB (limite PostgreSQL 1 GB/row)

**Solution** :
- Limiter metadata à 10 KB max
- Stocker données volumineuses dans S3/R2 (référence dans metadata)
- Valider taille avant INSERT via trigger

### Problème 3 : Duplicate Keys React (Filtres)

**Symptôme** : Warnings React "duplicate keys" dans ClientAgentFilter

**Solution** :
- Dédupliquer les rows en frontend (reduce avec Map)
- Ajouter DISTINCT dans v_agent_emails_enriched si nécessaire

### Problème 4 : Migration Gmail → SendGrid

**Symptôme** : Besoin de tracking natif opens/clicks sans développement custom

**Solution** :
- Ajouter colonnes v2.0 : `provider_cost`, `billed_cost`, `margin`
- Migrer workflows n8n vers SendGrid node
- Configurer webhooks SendGrid → `/api/webhooks/sendgrid`
- Mettre à jour `get_email_metrics()` avec nouvelles métriques

---

## Performance Benchmarks (Estimés)

| Métrique | Valeur |
|----------|--------|
| **Volume attendu** | 5000-20000 emails/mois |
| **Rétention** | 2-3 ans (60K-720K rows) |
| **Taille moyenne row** | ~2 KB (avec HTML) |
| **Taille totale table** | 120 MB - 1.4 GB |
| **Temps requête SELECT** | < 50ms (avec indexes) |
| **Temps INSERT** | < 10ms |
| **Temps RPC metrics** | < 200ms (30 jours, 1 client) |

**Optimisations possibles** :
- Partitioning par mois (si > 1M rows)
- Compression TOAST pour email_body_html
- Materialized view pour métriques statiques

---

## Changelog

### v1.0 - 2025-11-14 (Implémentation initiale)

**Ajouté** :
- ✅ Table `agent_emails` avec 30+ colonnes (modèle "gratuit inclus")
- ✅ 7 indexes optimisés
- ✅ RLS policies (4 policies)
- ✅ View `v_agent_emails_enriched`
- ✅ View `v_agent_communications_unified` (mise à jour)
- ✅ Fonction RPC `get_email_metrics()`
- ✅ Trigger `update_agent_emails_updated_at`
- ✅ Documentation complète (5 fichiers)
- ✅ Migrations SQL (3 fichiers)
- ✅ Colonnes financières : `internal_cost` (1 colonne)

### v2.0 - 2025-11-14 (Pricing Dynamique) ✅ COMPLÉTÉ

**Modifié** :
- ✅ Ajout colonne `cost_per_email` dans `agent_deployments` (migration `20251114_add_cost_per_email_to_deployments.sql`)
- ✅ Remplacement `internal_cost` par 3 colonnes : `provider_cost`, `billed_cost`, `margin` (GENERATED)
- ✅ Mise à jour `20251114_create_agent_emails_table.sql` (3 colonnes financières)
- ✅ Mise à jour `20251114_email_analytics.sql` (RPC avec métriques financières)
- ✅ Mise à jour `v_agent_communications_unified` (utilise `billed_cost`)
- ✅ Mise à jour `get_email_metrics()` (total_revenue, total_margin, margin_percentage)
- ✅ Réécriture complète `PRICING_MODEL.md` (dynamic pay-per-use)
- ✅ Mise à jour `SCHEMA.md`, `N8N_INTEGRATION.md`, `README.md`, `IMPLEMENTATION_SUMMARY.md`, `development_notes.md`

**Raison du changement** :
- Suite à la demande utilisateur : "revoir tout le concept générer pour finalement mettre un cout sur les mails"
- Anticipation de la facturation future (SendGrid, premium features)
- Cohérence avec le modèle SMS (3 colonnes financières)
- Pricing configurable par déploiement (défaut 0€)

**À venir v3.0** :
- 🔜 Pixel tracking (ouvertures)
- 🔜 Link tracking (clics)
- 🔜 Bounce detection (Gmail API)
- 🔜 Routes API `/api/track/open` et `/api/track/click`
- 🔜 Mise à jour `get_email_metrics()` avec open_rate, click_rate

---

## Références Utiles

### Documentation Supabase
- [RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [Views](https://supabase.com/docs/guides/database/tables#views)
- [RPC Functions](https://supabase.com/docs/guides/database/functions)
- [JSONB](https://supabase.com/docs/guides/database/json)

### Documentation n8n
- [Supabase Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.supabase/)
- [Gmail Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.gmail/)

### Documentation Gmail API
- [Push Notifications](https://developers.google.com/gmail/api/guides/push)
- [Send Email](https://developers.google.com/gmail/api/reference/rest/v1/users.messages/send)

### Inspirations
- `features/sms-tracking/` - Architecture similaire
- `agent_sms` table - Modèle de référence
- HubSpot, SendGrid - Best practices email tracking
