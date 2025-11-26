# SMS Tracking Feature

## Overview

This feature implements a comprehensive SMS tracking system for Voipia's AI agents (Louis, Arthur, Alexandra). SMS messages are sent via n8n workflows using Twilio, and all data is stored in Supabase for analytics, billing, and customer insights.

## Status

**Current Phase**: Implementation
**Start Date**: 2025-11-13
**Target Completion**: 2025-11-15

## Architecture

### Database Schema

**Main Table**: `agent_sms`
- Stores all SMS messages sent by agents
- Links to: agent_deployments, agent_calls (optional), prospects, sequences
- Tracks: content, delivery status, costs (real + margin), provider details
- Volume: 1000-10000 SMS/month, 2-3 year retention (~360K rows)

**Key Features**:
- ✅ Optional call linking (supports follow-up SMS and standalone campaigns)
- ✅ Detailed cost breakdown (provider_cost + voipia_margin = billed_cost)
- ✅ Dual status system (simple for KPIs, detailed for debugging)
- ✅ RLS security (inherits client permissions)
- ✅ Optimized indexes for time-series queries

### Analytics

**Views**:
- `v_agent_sms_enriched` - SMS with client/agent context
- `v_agent_communications` - Unified view of calls + SMS

**RPC Functions**:
- `get_sms_metrics()` - KPI metrics with period comparison

## Implementation Checklist

- [x] Feature directory created
- [x] README documentation
- [x] Migration 1: Create agent_sms table
- [x] Migration 2: RLS policies
- [x] Migration 3: Analytics views/functions
- [x] Migration 4: Fix pricing model (revenue/cost/margin)
- [x] n8n integration documentation
- [x] Staging tests (100% passed)
- [ ] Production deployment

## Files

### Migrations
- `supabase/migrations/20251113_create_agent_sms_table.sql`
- `supabase/migrations/20251113_sms_rls_policies.sql`
- `supabase/migrations/20251113_sms_analytics.sql`
- `supabase/migrations/20251113_fix_sms_pricing_model_v2.sql` ⚠️ **IMPORTANT**

### Documentation
- `features/sms-tracking/PRICING_MODEL.md` **← LIRE EN PREMIER** 💰
- `features/sms-tracking/IMPLEMENTATION_SUMMARY.md`
- `features/sms-tracking/documentation/N8N_INTEGRATION.md`
- `features/sms-tracking/documentation/SCHEMA.md`

## Usage

### Query SMS for a deployment
```sql
SELECT * FROM v_agent_sms_enriched
WHERE deployment_id = 'xxx'
  AND sent_at >= NOW() - INTERVAL '30 days'
ORDER BY sent_at DESC;
```

### Get SMS KPI metrics
```sql
SELECT get_sms_metrics(
  '2025-11-01'::timestamptz,
  '2025-11-30'::timestamptz,
  NULL, -- client_id (optional)
  'xxx', -- deployment_id (optional)
  'louis' -- agent_type_name (optional)
);
```

### Find failed SMS
```sql
SELECT
  phone_number,
  message_content,
  failure_reason,
  sent_at
FROM v_agent_sms_enriched
WHERE status = 'failed'
  AND sent_at >= NOW() - INTERVAL '7 days';
```

## Integration Points

### n8n Workflows
- **Insert**: After Twilio sends SMS, insert record to agent_sms
- **Update**: Webhook receives Twilio status callbacks, updates delivery status
- **Service Role**: n8n uses service_role key for INSERT/UPDATE permissions

### Frontend (Future)
- SMS KPI dashboard cards
- SMS history timeline
- Cost analytics (real vs billed)
- Delivery rate charts

## Performance Expectations

- **Dashboard KPIs**: <100ms (even with 360K rows)
- **Recent SMS lookup**: <10ms (indexed on deployment+sent_at)
- **Webhook updates**: <5ms (unique index on provider_message_sid)
- **Cost aggregations**: <50ms (index-only scans)

## Next Steps (Post-Implementation)

1. Update n8n workflows to log SMS
2. Create React components for SMS dashboard
3. Add SMS metrics to Global Dashboard
4. Set up alerts for high failure rates
5. Monitor query performance and optimize indexes if needed

## References

- [Agent Planning Document](./documentation/SMS_TRACKING_PLAN.md)
- [n8n Integration Guide](./documentation/N8N_INTEGRATION.md)
- [Database Schema Details](./documentation/SCHEMA.md)
