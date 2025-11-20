# n8n Integration Guide for SMS Tracking

## Overview

This guide explains how to integrate the `agent_sms` table with your n8n workflows to track all SMS messages sent via Twilio.

**Key Integration Points**:
1. **Insert SMS** - After sending SMS with Twilio, log to Supabase
2. **Update Status** - Receive Twilio webhooks and update delivery status
3. **Query SMS** - Read SMS data for analytics and reporting

---

## Prerequisites

- ✅ Migrations applied to Supabase (table + RLS + views)
- ✅ n8n with Supabase integration installed
- ✅ Twilio account with SMS capability
- ✅ Service role key from Supabase (for n8n authentication)

---

## 1. Workflow Pattern: Send SMS + Log to Supabase

### Workflow Overview

```
Trigger (Schedule/Webhook)
    ↓
Get Contact Data
    ↓
Get Deployment Info (agent_deployments)
    ↓
Calculate Costs (provider + margin)
    ↓
Twilio: Send SMS
    ↓
Supabase: Insert SMS Record
    ↓
Handle Errors
```

### Node 1: Get Deployment Info

**Purpose**: Fetch the deployment_id for the agent sending the SMS

**Node Type**: Supabase (Query)

```javascript
{
  "operation": "get",
  "table": "agent_deployments",
  "filters": {
    "slug": "{{ $json.agent_slug }}" // e.g., 'louis-voipia'
  }
}
```

**Output**: Deployment ID, client_id, agent_type_id

---

### Node 2: Calculate Costs

**Purpose**: Calculate provider_cost and voipia_margin

**Node Type**: Code (Function)

```javascript
// Calculate SMS costs
// Twilio France pricing: ~0.05€/SMS (may vary by country)
// Voipia margin: 0.02€ per SMS (or configurable per client)

const providerCost = 0.05; // EUR per SMS
const voipiaMargin = 0.02; // EUR margin

// Check if deployment has custom SMS pricing
const deployment = $('Get Deployment Info').first().json;
const customCost = deployment.cost_per_sms || providerCost;

return {
  provider_cost: customCost,
  voipia_margin: voipiaMargin,
  billed_cost: customCost + voipiaMargin
};
```

**Output**: `provider_cost`, `voipia_margin`, `billed_cost`

---

### Node 3: Twilio - Send SMS

**Node Type**: Twilio

**Configuration**:
```javascript
{
  "resource": "sms",
  "operation": "send",
  "from": "{{ $json.twilio_phone_number }}", // Voipia Twilio number
  "to": "{{ $json.recipient_phone }}", // E.164 format: +33612345678
  "message": "{{ $json.sms_content }}"
}
```

**Important**: Capture the response:
- `sid` (Message SID) - Unique Twilio identifier
- `status` - Initial status (queued, sending, sent)
- `date_created` - Timestamp when SMS was sent

---

### Node 4: Supabase - Insert SMS Record

**Node Type**: Supabase (Insert)

**Authentication**: Use **Service Role Key** (not anon key)

**Configuration**:
```javascript
{
  "operation": "insert",
  "table": "agent_sms",
  "data": {
    // Required fields
    "deployment_id": "{{ $('Get Deployment Info').item.json.id }}",
    "phone_number": "{{ $('Twilio').item.json.to }}",
    "message_content": "{{ $('Twilio').item.json.body }}",
    "sent_at": "{{ $('Twilio').item.json.date_created }}",

    // Optional: Link to call if SMS is follow-up
    "call_id": "{{ $('Previous Call').item.json.id || null }}",

    // Optional: Link to prospect (Arthur agent)
    "prospect_id": "{{ $('Get Prospect').item.json.id || null }}",
    "sequence_id": "{{ $('Get Sequence').item.json.id || null }}",

    // Recipient details
    "first_name": "{{ $('Contact Data').item.json.first_name }}",
    "last_name": "{{ $('Contact Data').item.json.last_name }}",

    // Message metadata
    "message_type": "appointment_reminder", // or 'transactional', 'marketing', 'notification'

    // Provider details
    "provider": "twilio",
    "provider_message_sid": "{{ $('Twilio').item.json.sid }}",
    "provider_status": "{{ $('Twilio').item.json.status }}",
    "status": "sent", // Initial simplified status

    // Costs (from Calculate Costs node)
    "provider_cost": "{{ $('Calculate Costs').item.json.provider_cost }}",
    "voipia_margin": "{{ $('Calculate Costs').item.json.voipia_margin }}",
    // billed_cost is auto-calculated by database

    // n8n tracking
    "workflow_id": "{{ $workflow.id }}",
    "workflow_execution_id": "{{ $execution.id }}",

    // Metadata (flexible JSONB)
    "metadata": {
      "campaign_id": "{{ $json.campaign_id || null }}",
      "template_id": "{{ $json.template_id || null }}",
      "appointment_id": "{{ $json.appointment_id || null }}",
      "custom_variables": {
        "slot": "{{ $json.time_slot }}",
        "date": "{{ $json.appointment_date }}"
      }
    }
  }
}
```

**Notes**:
- Use `||` for null coalescing (e.g., `{{ $json.value || null }}`)
- `character_count` and `billed_cost` are auto-calculated by database
- `sent_at` should be ISO 8601 timestamp with timezone

---

### Node 5: Error Handling

**Node Type**: IF (Conditional)

**Condition**: Check if Twilio send failed

```javascript
// If Twilio returns error
if ($('Twilio').item.json.error_code) {
  // Log error to Supabase with status = 'failed'
  return {
    ...data,
    status: 'failed',
    failed_at: new Date().toISOString(),
    failure_reason: $('Twilio').item.json.error_message
  };
}
```

---

## 2. Webhook Pattern: Twilio Status Callbacks

### Overview

Twilio can send webhooks when SMS status changes (delivered, undelivered, failed). Configure this to keep `agent_sms` up-to-date.

**Workflow**: Webhook receives status update → Update Supabase

---

### Setup: Twilio Status Callback URL

In Twilio Console:
1. Go to Messaging > Settings > Geo permissions
2. Set **Status Callback URL**: `https://your-n8n-instance.com/webhook/twilio-sms-status`
3. Enable callbacks for: `delivered`, `undelivered`, `failed`

---

### Webhook Node Configuration

**Node Type**: Webhook

**Configuration**:
```javascript
{
  "path": "twilio-sms-status",
  "httpMethod": "POST",
  "responseMode": "onReceived"
}
```

**Webhook Payload from Twilio**:
```json
{
  "MessageSid": "SMxxxxxxxxxxxx",
  "MessageStatus": "delivered", // or 'undelivered', 'failed'
  "ErrorCode": null,
  "ErrorMessage": null,
  "To": "+33612345678",
  "From": "+33XXXXXXXXX",
  "AccountSid": "ACxxxxxxxxxxxx"
}
```

---

### Map Status Node

**Node Type**: Code (Function)

**Purpose**: Map Twilio detailed status to simplified status

```javascript
// Map Twilio status to simple status for agent_sms table
const twilioStatus = $input.item.json.MessageStatus;

let simpleStatus;
let timestampField;
let timestamp = new Date().toISOString();

switch (twilioStatus) {
  case 'delivered':
    simpleStatus = 'delivered';
    timestampField = 'delivered_at';
    break;
  case 'undelivered':
  case 'failed':
    simpleStatus = 'failed';
    timestampField = 'failed_at';
    break;
  case 'sent':
  case 'queued':
  case 'sending':
  default:
    simpleStatus = 'sent';
    timestampField = null;
    break;
}

return {
  provider_message_sid: $input.item.json.MessageSid,
  provider_status: twilioStatus,
  simple_status: simpleStatus,
  timestamp_field: timestampField,
  timestamp: timestamp,
  error_code: $input.item.json.ErrorCode,
  error_message: $input.item.json.ErrorMessage
};
```

---

### Supabase Update Node

**Node Type**: Supabase (Update)

**Authentication**: Use **Service Role Key**

**Configuration**:
```javascript
{
  "operation": "update",
  "table": "agent_sms",
  "filters": {
    "provider_message_sid": "{{ $('Map Status').item.json.provider_message_sid }}"
  },
  "update_fields": {
    "provider_status": "{{ $('Map Status').item.json.provider_status }}",
    "status": "{{ $('Map Status').item.json.simple_status }}",

    // Conditionally set delivered_at or failed_at
    "delivered_at": "{{ $('Map Status').item.json.timestamp_field === 'delivered_at' ? $('Map Status').item.json.timestamp : undefined }}",
    "failed_at": "{{ $('Map Status').item.json.timestamp_field === 'failed_at' ? $('Map Status').item.json.timestamp : undefined }}",

    "failure_reason": "{{ $('Map Status').item.json.error_message || null }}"
  }
}
```

**Note**: Use `undefined` to skip fields (not update them) if condition not met

---

## 3. Query SMS Data

### Example: Get Recent SMS for Dashboard

**Node Type**: Supabase (Query)

**Configuration**:
```javascript
{
  "operation": "get",
  "table": "v_agent_sms_enriched",
  "filters": {
    "deployment_id": "{{ $json.deployment_id }}",
    "sent_at": {
      "gte": "{{ $now().subtract(30, 'days').toISOString() }}"
    }
  },
  "sort": [
    { "field": "sent_at", "direction": "desc" }
  ],
  "limit": 100
}
```

**Returns**: SMS with client name, agent type, costs, delivery status

---

### Example: Get SMS KPI Metrics

**Node Type**: Supabase (RPC Function)

**Configuration**:
```javascript
{
  "operation": "rpc",
  "function": "get_sms_metrics",
  "parameters": {
    "p_start_date": "{{ $now().subtract(30, 'days').toISOString() }}",
    "p_end_date": "{{ $now().toISOString() }}",
    "p_client_id": null, // Optional: filter by client
    "p_deployment_id": "{{ $json.deployment_id }}", // Optional: filter by deployment
    "p_agent_type_name": "louis" // Optional: filter by agent type
  }
}
```

**Returns**: JSONB with KPIs (total SMS, delivery rate, costs, period comparison)

---

## 4. Complete Workflow Templates

### Template 1: Send Appointment Reminder SMS

```
[Trigger: Schedule Daily 9:00 AM]
    ↓
[Supabase: Get Today's Appointments]
    ↓
[Filter: Appointments without SMS reminder]
    ↓
[Loop: For each appointment]
    ↓
[Get Deployment Info]
    ↓
[Calculate Costs]
    ↓
[Build SMS Content] (Code node with template)
    ↓
[Twilio: Send SMS]
    ↓
[Supabase: Insert SMS Record]
    ↓
[IF: Success] → Log success
[IF: Error] → Retry + Alert
```

---

### Template 2: Arthur Cold Outreach SMS Campaign

```
[Trigger: Webhook or Schedule]
    ↓
[Supabase: Get Prospects in Sequence]
    ↓
[Filter: Prospects at SMS step]
    ↓
[Loop: For each prospect]
    ↓
[Get Deployment Info] (Arthur agent)
    ↓
[Calculate Costs]
    ↓
[Build Personalized SMS] (merge variables)
    ↓
[Twilio: Send SMS]
    ↓
[Supabase: Insert SMS Record with prospect_id + sequence_id]
    ↓
[Supabase: Update Sequence Progress]
    ↓
[IF: Error] → Mark sequence step as failed
```

---

## 5. Best Practices

### Cost Management
- ✅ Always calculate costs before sending (check deployment-specific pricing)
- ✅ Track provider_cost separately from margin (for reconciliation with Twilio invoices)
- ✅ Monitor failed SMS to avoid wasting budget

### Data Quality
- ✅ Validate phone numbers before sending (E.164 format)
- ✅ Store original message content (for debugging and compliance)
- ✅ Use descriptive message_type values (enables analytics by type)

### Error Handling
- ✅ Log failed SMS to Supabase (with failure_reason)
- ✅ Set up alerts for high failure rates (> 5%)
- ✅ Retry logic for transient errors (but avoid infinite loops)

### Metadata Usage
- ✅ Store campaign_id, template_id in metadata for A/B testing
- ✅ Track appointment_id for appointment-related SMS
- ✅ Log link URLs and track clicks (requires webhook for link tracking)

### Performance
- ✅ Use bulk inserts for large campaigns (array of SMS records)
- ✅ Index on provider_message_sid is critical for webhook performance
- ✅ Query v_agent_sms_enriched (not raw table) for analytics

---

## 6. Troubleshooting

### Issue: SMS not logged to Supabase

**Check**:
1. Service role key is used (not anon key)
2. deployment_id is valid UUID
3. sent_at is valid ISO 8601 timestamp
4. All required fields are provided

**Debug Query**:
```sql
-- Check if SMS was inserted
SELECT * FROM agent_sms
WHERE provider_message_sid = 'SMxxxxx';
```

---

### Issue: Webhook not updating status

**Check**:
1. Twilio Status Callback URL is configured
2. Webhook is publicly accessible (not localhost)
3. provider_message_sid matches exactly

**Debug Query**:
```sql
-- Check SMS status updates
SELECT provider_message_sid, status, provider_status, delivered_at, failed_at
FROM agent_sms
WHERE sent_at >= NOW() - INTERVAL '1 hour'
ORDER BY sent_at DESC;
```

---

### Issue: RLS blocking insert/update

**Check**:
1. Using service_role key (bypasses RLS)
2. Not using anon key (would require authenticated user)

**Test Service Role**:
```sql
-- Should work with service_role key
INSERT INTO agent_sms (deployment_id, phone_number, message_content, sent_at)
VALUES ('valid-uuid', '+33612345678', 'Test', NOW());
```

---

## 7. Security Considerations

### Service Role Key
- ⚠️ **NEVER expose service_role key in frontend code**
- ✅ Store in n8n credentials (encrypted)
- ✅ Use only in server-side workflows

### Data Privacy
- ✅ SMS content may contain PII (personal identifiable information)
- ✅ Apply GDPR compliance (data retention policies)
- ✅ Log only necessary data (avoid logging sensitive info in metadata)

### Rate Limiting
- ✅ Respect Twilio rate limits (1 message/second for standard accounts)
- ✅ Implement delays in loops (avoid flooding)
- ✅ Monitor Twilio usage dashboard for anomalies

---

## 8. Next Steps

After integration:
1. ✅ Test with 1-2 test SMS in staging
2. ✅ Verify SMS appears in `v_agent_sms_enriched` view
3. ✅ Test webhook by sending SMS and checking Twilio logs
4. ✅ Create dashboard to visualize SMS KPIs
5. ✅ Set up alerts for high failure rates
6. ✅ Document custom workflows for team

---

## Support

For questions or issues:
- Check Supabase logs: Project Settings > Logs
- Check Twilio logs: Console > Monitor > Logs > Messaging
- Review n8n execution logs for errors
- Query `agent_sms` table directly for debugging

---

**Happy SMS Tracking! 🚀**
