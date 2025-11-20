# SMS Tracking Database Schema

## Overview

This document provides a detailed reference of the database schema for SMS tracking in Supabase.

---

## Table: agent_sms

**Purpose**: Store all SMS messages sent by Voipia AI agents via n8n workflows

**Volume**: 1000-10000 SMS/month, 2-3 year retention (~360K rows)

### Columns

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | UUID | NOT NULL | `gen_random_uuid()` | Primary key |
| `deployment_id` | UUID | NOT NULL | - | FK to agent_deployments (which agent sent this) |
| `call_id` | UUID | NULL | - | FK to agent_calls (optional link if follow-up SMS) |
| `prospect_id` | UUID | NULL | - | FK to agent_arthur_prospects (for Arthur sequences) |
| `sequence_id` | UUID | NULL | - | FK to agent_arthur_prospect_sequences |
| `phone_number` | TEXT | NOT NULL | - | Recipient phone (E.164 format: +33612345678) |
| `first_name` | TEXT | NULL | - | Recipient first name |
| `last_name` | TEXT | NULL | - | Recipient last name |
| `message_content` | TEXT | NOT NULL | - | Full SMS text content |
| `message_type` | TEXT | NULL | `'transactional'` | Type: transactional, marketing, notification, appointment_reminder |
| `character_count` | INTEGER | GENERATED | `LENGTH(message_content)` | Auto-calculated message length |
| `provider` | TEXT | NULL | `'twilio'` | SMS provider (default: twilio) |
| `provider_message_sid` | TEXT | UNIQUE | - | Twilio Message SID (unique identifier: SMxxx) |
| `provider_status` | TEXT | NULL | - | Detailed Twilio status (queued, sending, sent, delivered, undelivered, failed, unknown) |
| `status` | TEXT | NULL | `'sent'` | Simplified status for KPIs (sent, delivered, failed) |
| `sent_at` | TIMESTAMPTZ | NOT NULL | - | When SMS was sent by provider |
| `delivered_at` | TIMESTAMPTZ | NULL | - | When SMS was delivered (updated by webhook) |
| `failed_at` | TIMESTAMPTZ | NULL | - | When SMS delivery failed (updated by webhook) |
| `failure_reason` | TEXT | NULL | - | Error message if delivery failed |
| `provider_cost` | NUMERIC(10,4) | NULL | - | Real cost from provider (EUR) |
| `voipia_margin` | NUMERIC(10,4) | NULL | `0` | Voipia margin added (EUR) |
| `billed_cost` | NUMERIC(10,4) | GENERATED | `provider_cost + voipia_margin` | Total billed to client (auto-calculated) |
| `currency` | TEXT | NULL | `'EUR'` | Currency for costs |
| `workflow_id` | TEXT | NULL | - | n8n workflow ID that sent this SMS |
| `workflow_execution_id` | TEXT | NULL | - | n8n execution ID (for debugging) |
| `metadata` | JSONB | NULL | `'{}'` | Flexible additional data |
| `created_at` | TIMESTAMPTZ | NULL | `NOW()` | Record creation timestamp |
| `updated_at` | TIMESTAMPTZ | NULL | `NOW()` | Last update timestamp (auto-updated by trigger) |

### Constraints

- **Primary Key**: `id`
- **Foreign Keys**:
  - `deployment_id` → `agent_deployments(id)` ON DELETE CASCADE
  - `call_id` → `agent_calls(id)` ON DELETE SET NULL
  - `prospect_id` → `agent_arthur_prospects(id)` ON DELETE SET NULL
  - `sequence_id` → `agent_arthur_prospect_sequences(id)` ON DELETE SET NULL
- **Unique**: `provider_message_sid` (Twilio Message SID must be unique)
- **Check Constraints**:
  - `message_type IN ('transactional', 'marketing', 'notification', 'appointment_reminder')`
  - `provider_status IN ('queued', 'sending', 'sent', 'delivered', 'undelivered', 'failed', 'unknown')`
  - `status IN ('sent', 'delivered', 'failed')`
  - `provider_cost >= 0`
  - `voipia_margin >= 0`

### Indexes

| Index Name | Columns | Type | Purpose |
|------------|---------|------|---------|
| `idx_agent_sms_deployment_sent_at` | `(deployment_id, sent_at DESC)` | B-tree | Time-series queries (recent SMS by deployment) |
| `idx_agent_sms_status` | `(status)` WHERE status IN ('delivered', 'failed') | Partial | KPI calculations (delivery rate, failed count) |
| `idx_agent_sms_call_id` | `(call_id)` WHERE call_id IS NOT NULL | Partial | Call-to-SMS linkage queries |
| `idx_agent_sms_provider_sid` | `(provider_message_sid)` WHERE provider_message_sid IS NOT NULL | Partial | Fast webhook updates from Twilio |
| `idx_agent_sms_deployment_cost` | `(deployment_id, billed_cost DESC)` | B-tree | Cost aggregation queries |
| `idx_agent_sms_prospect` | `(prospect_id)` WHERE prospect_id IS NOT NULL | Partial | Prospect SMS history (Arthur) |
| `idx_agent_sms_sequence` | `(sequence_id)` WHERE sequence_id IS NOT NULL | Partial | Sequence SMS tracking (Arthur) |

### Triggers

- **agent_sms_updated_at**: Auto-updates `updated_at` timestamp on UPDATE

---

## View: v_agent_sms_enriched

**Purpose**: Enrich SMS data with client, agent, and deployment context

**Base Table**: `agent_sms` (with JOINs)

### Additional Columns

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `deployment_name` | TEXT | agent_deployments.name | Deployment name |
| `deployment_slug` | TEXT | agent_deployments.slug | Deployment slug |
| `client_id` | UUID | agent_deployments.client_id | Client ID |
| `client_name` | TEXT | clients.name | Client company name |
| `agent_type_id` | UUID | agent_deployments.agent_type_id | Agent type ID |
| `agent_type_name` | TEXT | agent_types.name | Agent type (louis, arthur, alexandra) |
| `agent_display_name` | TEXT | agent_types.display_name | Agent display name (Louis, Arthur, Alexandra) |
| `is_delivered` | BOOLEAN | CALCULATED | `status = 'delivered'` |
| `is_failed` | BOOLEAN | CALCULATED | `status = 'failed'` |
| `delivery_time_seconds` | NUMERIC | CALCULATED | Time between sent_at and delivered_at |

### Usage

```sql
-- Get recent SMS for a deployment with context
SELECT
    deployment_name,
    client_name,
    agent_display_name,
    phone_number,
    message_content,
    status,
    billed_cost
FROM v_agent_sms_enriched
WHERE deployment_id = 'xxx'
  AND sent_at >= NOW() - INTERVAL '30 days'
ORDER BY sent_at DESC;
```

---

## View: v_agent_communications

**Purpose**: Unified view of all agent touchpoints (calls + SMS)

**Structure**: UNION of agent_calls and agent_sms

### Columns

| Column | Type | Description |
|--------|------|-------------|
| `communication_type` | TEXT | 'call' or 'sms' |
| `id` | UUID | Record ID (from agent_calls or agent_sms) |
| `deployment_id` | UUID | Deployment that sent the communication |
| `phone_number` | TEXT | Contact phone number |
| `first_name` | TEXT | Contact first name |
| `last_name` | TEXT | Contact last name |
| `timestamp` | TIMESTAMPTZ | When communication happened (started_at for calls, sent_at for SMS) |
| `result` | TEXT | Outcome (call outcome or SMS status) |
| `cost` | NUMERIC | Total cost (total_cost for calls, billed_cost for SMS) |
| `duration_seconds` | INTEGER | Call duration (NULL for SMS) |
| `message_content` | TEXT | SMS content (NULL for calls) |
| `message_type` | TEXT | SMS type (NULL for calls) |
| `provider_message_sid` | TEXT | Twilio Message SID (NULL for calls) |
| `metadata` | JSONB | Additional metadata |

### Usage

```sql
-- Get all touchpoints for a contact (timeline view)
SELECT
    communication_type,
    timestamp,
    result,
    COALESCE(duration_seconds::TEXT, message_content) AS details
FROM v_agent_communications
WHERE phone_number = '+33612345678'
ORDER BY timestamp DESC;
```

---

## RPC Function: get_sms_metrics

**Purpose**: Calculate comprehensive SMS KPI metrics with period comparison

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_start_date` | TIMESTAMPTZ | YES | Start of current period |
| `p_end_date` | TIMESTAMPTZ | YES | End of current period |
| `p_client_id` | UUID | NO | Filter by specific client |
| `p_deployment_id` | UUID | NO | Filter by specific deployment |
| `p_agent_type_name` | TEXT | NO | Filter by agent type (louis, arthur, alexandra) |

### Returns

JSONB with structure:

```json
{
  "current_period": {
    // Volume metrics
    "total_sms": 1523,
    "delivered_sms": 1489,
    "failed_sms": 23,
    "sent_sms": 11,

    // Rate metrics
    "delivery_rate": 97.77,
    "failure_rate": 1.51,

    // Cost metrics
    "total_cost": 106.61,
    "total_provider_cost": 76.15,
    "total_margin": 30.46,
    "margin_percentage": 28.57,
    "avg_cost_per_sms": 0.07,

    // Message metrics
    "avg_characters": 142,
    "min_characters": 45,
    "max_characters": 160,

    // Engagement metrics
    "unique_recipients": 987,
    "active_deployments": 3,
    "active_workflows": 2,
    "sms_linked_to_calls": 456,
    "call_linkage_rate": 29.94,

    // Timing metrics
    "avg_delivery_time_seconds": 3.42,

    // Breakdown by type
    "by_message_type": [
      {
        "message_type": "appointment_reminder",
        "count": 789,
        "delivered": 772,
        "delivery_rate": 97.85,
        "cost": 55.23
      },
      {
        "message_type": "notification",
        "count": 734,
        "delivered": 717,
        "delivery_rate": 97.68,
        "cost": 51.38
      }
    ]
  },
  "previous_period": {
    "total_sms": 1402,
    "delivered_sms": 1368,
    "failed_sms": 19,
    "delivery_rate": 97.57,
    "failure_rate": 1.35,
    "total_cost": 98.14,
    "total_margin": 28.04,
    "avg_cost_per_sms": 0.07,
    "avg_characters": 138,
    "unique_recipients": 912
  },
  "comparison": {
    "total_sms_change": 121,
    "total_sms_change_pct": 8.63,
    "delivered_sms_change": 121,
    "cost_change": 8.47,
    "cost_change_pct": 8.63
  }
}
```

### Usage

```sql
-- Get SMS metrics for Louis agent, last 30 days
SELECT get_sms_metrics(
    (NOW() - INTERVAL '30 days')::TIMESTAMPTZ,
    NOW()::TIMESTAMPTZ,
    NULL, -- all clients
    NULL, -- all deployments
    'louis' -- only Louis agent
);
```

---

## Row-Level Security (RLS)

### Policies

| Policy Name | Type | Role | Description |
|-------------|------|------|-------------|
| `users_view_accessible_sms` | SELECT | authenticated | Users can view SMS from deployments linked to their accessible clients |
| `admins_manage_sms` | ALL | authenticated | Admin users can manage (INSERT/UPDATE/DELETE) SMS for their clients |
| `service_insert_sms` | INSERT | service_role | n8n can insert new SMS records |
| `service_update_sms` | UPDATE | service_role | n8n webhooks can update SMS status |

### How RLS Works

1. **Authenticated Users**:
   - Can SELECT SMS where `deployment_id` is in their accessible deployments
   - Admins can also INSERT/UPDATE/DELETE for their clients

2. **Service Role (n8n)**:
   - Can INSERT new SMS (after sending via Twilio)
   - Can UPDATE SMS status (when receiving webhooks)
   - Bypasses RLS (full access)

3. **Security Chain**:
   ```
   User → user_client_permissions → clients ← agent_deployments ← agent_sms
   ```

   User can only access SMS if:
   - SMS belongs to a deployment (`deployment_id`)
   - Deployment belongs to a client (`client_id`)
   - User has permission to that client (`user_client_permissions`)

---

## Metadata JSONB Examples

### Appointment Reminder SMS

```json
{
  "campaign_id": "appointment_reminders_2025",
  "template_id": "appointment_confirmation_v2",
  "appointment_id": "550e8400-e29b-41d4-a716-446655440000",
  "custom_variables": {
    "slot": "14h00",
    "date": "2025-11-15",
    "location": "Siège social Paris"
  }
}
```

### Marketing Campaign SMS

```json
{
  "campaign_id": "summer_promo_2025",
  "template_id": "promo_50_discount",
  "link_url": "https://voipia.com/promo/summer2025",
  "link_clicked": true,
  "click_timestamp": "2025-11-14T10:23:45Z",
  "user_replied": true,
  "reply_content": "OUI",
  "opted_out": false
}
```

### Arthur Sequence SMS

```json
{
  "sequence_name": "cold_outreach_v3",
  "sequence_step": 2,
  "previous_outcome": "voicemail",
  "next_action": "follow_up_call_in_3_days",
  "personalization": {
    "company_name": "Acme Corp",
    "industry": "SaaS",
    "pain_point": "high_acquisition_cost"
  }
}
```

---

## Performance Considerations

### Query Optimization

- ✅ Use `v_agent_sms_enriched` for analytics (pre-joined context)
- ✅ Filter by `deployment_id` first (indexed for time-series)
- ✅ Use `sent_at` range filters (indexed)
- ✅ Query `get_sms_metrics()` instead of manual aggregations

### Example: Optimized Query

```sql
-- GOOD: Uses indexes, filters efficiently
SELECT *
FROM v_agent_sms_enriched
WHERE deployment_id = 'xxx'
  AND sent_at >= NOW() - INTERVAL '30 days'
ORDER BY sent_at DESC
LIMIT 100;

-- BAD: Full table scan, slow
SELECT *
FROM agent_sms
WHERE message_content LIKE '%keyword%'; -- No index on message_content
```

### Index Usage

- **Time-series**: `idx_agent_sms_deployment_sent_at` (most common)
- **Webhooks**: `idx_agent_sms_provider_sid` (fast updates)
- **Cost analytics**: `idx_agent_sms_deployment_cost` (aggregations)

---

## Migration Files

| File | Purpose | Dependencies |
|------|---------|--------------|
| `20251113_create_agent_sms_table.sql` | Create table, indexes, triggers | None |
| `20251113_sms_rls_policies.sql` | RLS policies and permissions | Table must exist |
| `20251113_sms_analytics.sql` | Views and RPC functions | Table + RLS must exist |

**Execution Order**: 1 → 2 → 3 (must be sequential)

---

## Related Tables

### agent_deployments

- Linked via `agent_sms.deployment_id`
- Provides: deployment name, client_id, agent_type_id

### agent_calls

- Optionally linked via `agent_sms.call_id`
- Enables: Call-to-SMS follow-up tracking

### agent_arthur_prospects

- Linked via `agent_sms.prospect_id` (Arthur only)
- Enables: Prospect SMS history

### agent_arthur_prospect_sequences

- Linked via `agent_sms.sequence_id` (Arthur only)
- Enables: Multi-touch campaign tracking

---

## Common Queries

### 1. Total SMS cost by client (last 30 days)

```sql
SELECT
    client_name,
    COUNT(*) AS total_sms,
    SUM(billed_cost) AS total_billed,
    SUM(provider_cost) AS total_provider_cost,
    SUM(voipia_margin) AS total_margin
FROM v_agent_sms_enriched
WHERE sent_at >= NOW() - INTERVAL '30 days'
GROUP BY client_name
ORDER BY total_billed DESC;
```

### 2. Delivery rate by agent type

```sql
SELECT
    agent_display_name,
    COUNT(*) AS total_sms,
    COUNT(*) FILTER (WHERE status = 'delivered') AS delivered,
    ROUND((COUNT(*) FILTER (WHERE status = 'delivered')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2) AS delivery_rate
FROM v_agent_sms_enriched
WHERE sent_at >= NOW() - INTERVAL '30 days'
GROUP BY agent_display_name;
```

### 3. Failed SMS for debugging

```sql
SELECT
    deployment_name,
    phone_number,
    message_content,
    failure_reason,
    sent_at
FROM v_agent_sms_enriched
WHERE status = 'failed'
  AND sent_at >= NOW() - INTERVAL '7 days'
ORDER BY sent_at DESC;
```

### 4. SMS-to-call conversion tracking

```sql
SELECT
    ac.outcome AS call_outcome,
    sms.message_type AS sms_type,
    COUNT(*) AS count
FROM agent_calls ac
JOIN agent_sms sms ON sms.call_id = ac.id
WHERE ac.started_at >= NOW() - INTERVAL '30 days'
GROUP BY ac.outcome, sms.message_type
ORDER BY count DESC;
```

---

## Data Retention

**Current Policy**: 2-3 years

**Future Considerations**:
- Archive old SMS to cold storage (> 1 year)
- Partitioning by month if volume exceeds 1M rows
- GDPR compliance: Right to erasure (delete SMS on request)

---

## Support & References

- **Supabase Docs**: https://supabase.com/docs
- **Twilio SMS API**: https://www.twilio.com/docs/sms
- **n8n Docs**: https://docs.n8n.io
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
