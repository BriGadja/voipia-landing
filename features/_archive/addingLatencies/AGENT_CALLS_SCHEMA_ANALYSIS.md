# Agent Calls Table Schema Analysis

**Date**: 2025-11-20  
**Author**: Claude  
**Purpose**: Comprehensive analysis of `agent_calls` table structure, usage, and cleanup recommendations

---

## Executive Summary

The `agent_calls` table contains **37 columns** with **803 total rows** as of 2025-11-20. Analysis reveals:

- ✅ **Well-populated core columns**: All essential call data (deployment, phone, timestamps, costs, outcomes, emotions)
- ⚠️ **Naming inconsistencies**: Dual columns for same data (`emotion` vs `sentiment_analysis`, `outcome` vs `call_status`)
- ❌ **Unused columns**: `call_quality_score`, `tts_provider`, `tts_voice_id` (0-12% fill rate)
- 📊 **Metadata usage**: 221 calls (27.5%) use JSONB metadata for extra data (latencies, recordings, etc.)
- 🔄 **Partial usage**: Arthur-specific columns (`prospect_id`, `sequence_id`) only used by 36% of calls

---

## 1. Complete Table Structure

### 1.1 Schema Overview

| # | Column Name | Type | Nullable | Default | Usage |
|---|-------------|------|----------|---------|-------|
| 1 | `id` | uuid | NO | `gen_random_uuid()` | ✅ Primary key |
| 2 | `deployment_id` | uuid | NO | - | ✅ FK to agent_deployments (100%) |
| 3 | `first_name` | text | YES | - | ✅ Contact info (100%) |
| 4 | `last_name` | text | YES | - | ✅ Contact info (97%) |
| 5 | `email` | text | YES | - | ✅ Contact info (79%) |
| 6 | `phone_number` | text | NO | - | ✅ Required field (100%) |
| 7 | `started_at` | timestamptz | NO | - | ✅ Call start (100%) |
| 8 | `ended_at` | timestamptz | YES | - | ✅ Call end (100%) |
| 9 | `duration_seconds` | integer | YES | - | ✅ Call duration (100%) |
| 10 | `outcome` | text | YES | - | ✅ Call result (100%) |
| 11 | `emotion` | text | YES | - | ✅ Sentiment (94%) |
| 12 | `total_cost` | numeric | YES | - | ✅ Total cost EUR (100%) |
| 13 | `transcript` | text | YES | - | ✅ Full transcript (100%) |
| 14 | `transcript_summary` | text | YES | - | ✅ AI summary (100%) |
| 15 | `recording_url` | text | YES | - | ✅ Audio URL (100%) |
| 16 | `metadata` | jsonb | YES | `'{}'::jsonb` | ✅ Extra data (27.5%) |
| 17 | `created_at` | timestamptz | YES | `now()` | ✅ Record creation (100%) |
| 18 | `prospect_id` | uuid | YES | - | ⚠️ Arthur only (36%) |
| 19 | `sequence_id` | uuid | YES | - | ⚠️ Arthur only (36%) |
| 20 | `conversation_id` | text | YES | - | ✅ Dipler ID (100%) |
| 21 | `call_sid` | text | YES | - | ✅ Twilio SID (100%) |
| 22 | `stt_cost` | numeric | YES | - | ✅ Speech-to-text cost (100%) |
| 23 | `tts_cost` | numeric | YES | - | ✅ Text-to-speech cost (100%) |
| 24 | `llm_cost` | numeric | YES | - | ✅ LLM cost (100%) |
| 25 | `telecom_cost` | numeric | YES | - | ✅ Twilio cost (100%) |
| 26 | `dipler_commission` | numeric | YES | - | ✅ Platform fee (100%) |
| 27 | `cost_per_minute` | numeric | YES | - | ✅ CPM (100%) |
| 28 | `call_classification` | text | YES | - | ⚠️ Empty string (100%) |
| 29 | `call_quality_score` | integer | YES | - | ❌ Never used (0%) |
| 30 | `sentiment_analysis` | text | YES | - | ⚠️ Duplicate of `emotion` (<1%) |
| 31 | `llm_model` | text | YES | - | ✅ Model name (100%) |
| 32 | `tts_provider` | text | YES | - | ❌ Mostly null (12%) |
| 33 | `tts_voice_id` | text | YES | - | ❌ Mostly null (12%) |
| 34 | `stt_provider` | text | YES | - | ✅ STT provider (100%) |
| 35 | `direction` | text | YES | - | ✅ inbound/outbound (100%) |
| 36 | `call_status` | text | YES | - | ⚠️ Duplicate of `outcome` (100%) |
| 37 | `provider` | text | YES | `'twilio'::text` | ✅ Always 'twilio' (100%) |

---

## 2. Column Usage Analysis

### 2.1 Fully Populated Columns (100% fill rate)

**Core Identifiers:**
- `id`, `deployment_id`, `phone_number`, `created_at`

**Timestamps:**
- `started_at`, `ended_at`, `duration_seconds`

**Call Results:**
- `outcome`, `emotion`, `direction`, `call_status`

**Costs (all in EUR/USD):**
- `total_cost`, `stt_cost`, `tts_cost`, `llm_cost`, `telecom_cost`, `dipler_commission`, `cost_per_minute`

**Data & Identifiers:**
- `transcript`, `transcript_summary`, `recording_url`, `conversation_id`, `call_sid`

**Technical Stack:**
- `llm_model`, `stt_provider`, `provider`

**Contact Info:**
- `first_name` (100%), `last_name` (97%), `email` (79%)

### 2.2 Partially Populated Columns

| Column | Fill Rate | Use Case |
|--------|-----------|----------|
| `prospect_id` | 36% (291/803) | Arthur-specific (reactivation campaigns) |
| `sequence_id` | 36% (291/803) | Arthur-specific (call sequences) |
| `email` | 79% (631/803) | Not always available from forms |
| `last_name` | 97% (776/803) | Usually available |
| `tts_provider` | 12% (95/803) | Recently added, backfill incomplete |
| `tts_voice_id` | 12% (95/803) | Recently added, backfill incomplete |
| `emotion` | 94% (752/803) | Some old calls missing |

### 2.3 Unused/Empty Columns

| Column | Status | Notes |
|--------|--------|-------|
| `call_quality_score` | 0% (0/803) | ❌ Never populated by n8n |
| `call_classification` | 0% (empty strings) | ⚠️ Always `""`, not used in dashboard |
| `sentiment_analysis` | <1% (2/803) | ⚠️ Duplicate of `emotion` (old column) |

---

## 3. Naming Inconsistencies

### 3.1 Duplicate Columns (Same Data, Different Names)

#### Problem 1: `emotion` vs `sentiment_analysis`

**Current State:**
- `emotion`: 752 rows (94%) - **Source of truth**
- `sentiment_analysis`: 2 rows (<1%) - **Obsolete**

**Values:**
- `emotion`: `'positive'`, `'neutral'`, `'negative'`
- `sentiment_analysis`: Same values (when populated)

**Migration Applied:** `20251113_fix_outcome_emotion_columns.sql`
- ✅ Trigger `trg_sync_outcome_emotion` copies `sentiment_analysis` → `emotion` on INSERT/UPDATE
- ✅ Dashboards use `emotion` column
- ⚠️ `sentiment_analysis` should be **deprecated** but is kept for backward compatibility

**Recommendation:** 
- Keep `emotion` as source of truth
- Consider dropping `sentiment_analysis` after verifying n8n workflows no longer use it

---

#### Problem 2: `outcome` vs `call_status`

**Current State:**
- `outcome`: 803 rows (100%) - **Source of truth**
- `call_status`: 803 rows (100%) - **Duplicate**

**Values (both columns contain same data):**
- `'voicemail'`, `'appointment_scheduled'`, `'appointment_refused'`, `'not_interested'`, `'callback_requested'`, etc.

**Migration Applied:** `20251113_fix_outcome_emotion_columns.sql`
- ✅ Trigger `trg_sync_outcome_emotion` copies `call_status` → `outcome` on INSERT/UPDATE
- ✅ Dashboards use `outcome` column

**Recommendation:**
- Keep `outcome` as source of truth
- Consider dropping `call_status` after verifying n8n workflows updated

---

### 3.2 Empty/Unused Columns

#### `call_classification`

**Current State:**
- Always contains empty string `""`
- 103 calls have it set to `""`

**Expected Usage:**
- Should classify calls as `'appointment_scheduled'`, `'callback_requested'`, `'voicemail'`, etc.
- **BUT** this data is already in `outcome` column

**Recommendation:**
- ❌ **Drop this column** - it duplicates `outcome` and is never populated

---

#### `call_quality_score`

**Current State:**
- Always `NULL` (0 rows populated)

**Expected Usage:**
- Integer score (1-10) rating call quality

**Recommendation:**
- ❌ **Drop this column** - n8n workflows never populate it
- OR implement quality scoring in future n8n updates

---

## 4. Metadata (JSONB) Structure

### 4.1 Metadata Keys Found

**221 calls (27.5%)** have non-empty metadata. Common keys:

| Key | Count | Purpose |
|-----|-------|---------|
| `migrated_from` | 118 | Data migration tracking |
| `migration_date` | 118 | Migration timestamp |
| `original_call_id` | 118 | Pre-migration ID |
| `appointment_scheduled_at` | 118 | RDV datetime |
| `messageCount` | 103 | Number of conversation turns |
| `latencies` | 103 | LLM/TTS latency stats (NEW!) |
| `workspaceId` | 103 | Dipler workspace |
| `agentId` | 103 | Dipler agent ID |
| `agentName` | 103 | Agent display name |
| `isTestEnvironment` | 103 | Test vs production |
| `callPriceUnit` | 103 | USD or EUR |
| `vadAudioRecordingUrl` | 103 | VAD recording URL |
| `userMicRecordingUrl` | 103 | User mic recording URL |

### 4.2 Latency Data (NEW in endCallStats.txt)

**Structure from webhook payload:**

```json
{
  "metadata": {
    "latencies": {
      "llmLatencies": {
        "min": 555,
        "max": 1110,
        "average": 725,
        "count": 4
      },
      "ttsLatencies": {
        "min": 207,
        "max": 207,
        "average": 207,
        "count": 1
      },
      "totalLatencies": {
        "min": 555,
        "max": 1110,
        "average": 777,
        "count": 4
      }
    }
  }
}
```

**Impact:**
- ✅ Latency data is already being stored in `metadata` JSONB
- ✅ No new columns needed for latency tracking
- ⚠️ Only 103 recent calls have this data (older calls don't)

---

## 5. n8n Workflow Integration

### 5.1 Webhook Endpoint

**URL:** `https://n8n.voipia.fr/webhook/voipia-louis-endcall`

**Payload Structure:** (from `features/addingLatencies/endCallStats.txt`)

```json
{
  "type": "end-of-call-report",
  "level": "agent",
  "conversation": {
    "id": "01KAG47V8ZRZDGA2S59QJQM4R3",
    "stats": {
      "callDurationSeconds": 26,
      "sessionCost": 0.04605,
      "sessionTotalPrice": 0.06338,
      "latencies": { /* NEW FIELD */ },
      "sttStats": { "price": 0.00083 },
      "llmStats": { "totalPrice": 0.02033 },
      "ttsStats": { "totalPrice": 0.0245 },
      "diplerCommission": 0.01733
    },
    "postConversationAnalysis": {
      "sentiment": "neutral",  /* → emotion */
      "extractedData": {
        "callClassification": "voicemail"  /* → outcome */
      }
    },
    "callInfos": {
      "callSid": "CA3062b32d...",
      "callStatus": "voicemail",  /* → call_status */
      "direction": "outbound",
      "provider": "twilio"
    }
  }
}
```

### 5.2 Column Mapping (n8n → Database)

| n8n Field | Database Column | Notes |
|-----------|----------------|-------|
| `conversation.id` | `conversation_id` | ✅ Dipler conversation ID |
| `callInfos.callSid` | `call_sid` | ✅ Twilio SID |
| `callInfos.callStatus` | `call_status` | ⚠️ Synced to `outcome` by trigger |
| `postConversationAnalysis.sentiment` | `emotion` | ⚠️ Synced from `sentiment_analysis` by trigger |
| `postConversationAnalysis.extractedData.callClassification` | `call_classification` | ❌ Stored but never used (always "") |
| `stats.sessionTotalPrice` | `total_cost` | ✅ Total EUR cost |
| `stats.sttStats.price` | `stt_cost` | ✅ Speech-to-text |
| `stats.llmStats.totalPrice` | `llm_cost` | ✅ LLM cost |
| `stats.ttsStats.totalPrice` | `tts_cost` | ✅ Text-to-speech |
| `callInfos.callCost` | `telecom_cost` | ✅ Twilio cost |
| `stats.diplerCommission` | `dipler_commission` | ✅ Platform fee |
| `stats.latencies` | `metadata->'latencies'` | ✅ NEW! Stored in JSONB |

---

## 6. View: v_agent_calls_enriched

### 6.1 Purpose

Adds calculated boolean columns **without modifying base table:**
- `answered`: Was the call picked up? (vs voicemail/no answer)
- `appointment_scheduled`: Was an appointment booked?

### 6.2 Current Definition

```sql
CREATE OR REPLACE VIEW v_agent_calls_enriched AS
SELECT
  ac.*,
  
  -- Calculate if call was answered
  CASE
    WHEN outcome = ANY (ARRAY[
      'voicemail', 'call_failed', 'no_answer', 'busy', 
      'invalid_number', 'error', 'canceled', 'rejected'
    ]) THEN false
    WHEN outcome IS NULL THEN false
    ELSE true
  END AS answered,
  
  -- Calculate if appointment was scheduled
  CASE
    WHEN outcome = 'appointment_scheduled' THEN true
    ELSE false
  END AS appointment_scheduled

FROM agent_calls ac;
```

### 6.3 Usage in Dashboards

**All dashboard RPC functions use `v_agent_calls_enriched`:**
- `get_kpi_metrics()` → Filters on `answered = true` for answer rate
- `get_chart_data()` → Uses `answered` for call volume breakdowns
- `get_agent_type_cards_data()` → Aggregates by `appointment_scheduled`
- `get_client_cards_data()` → Conversion rate = appointments / answered_calls

---

## 7. TypeScript Types

### 7.1 Current Types (lib/types/database.ts)

```typescript
export type CallOutcome =
  | 'appointment_scheduled'
  | 'appointment_refused'
  | 'not_interested'
  | 'callback_requested'
  | 'voicemail'
  | 'too_short'
  | 'no_answer'
  | 'busy'
  | 'invalid_number'
  | 'call_failed'
  | 'do_not_call'

export type Emotion = 'positive' | 'neutral' | 'negative'

export interface Call {
  id: string
  client_id: string
  agent_id: string | null
  first_name: string | null
  last_name: string | null
  email: string | null
  phone: string | null
  started_at: string
  duration_seconds: number | null
  cost: number | null
  emotion: Emotion | null
  appointment_scheduled_at: string | null
  transcript: string | null
  transcript_summary: string | null
  call_outcome: CallOutcome | null
  metadata: Record<string, any> | null
  created_at: string
  updated_at: string
}
```

### 7.2 Mismatches with Database

| TypeScript | Database | Notes |
|------------|----------|-------|
| `call_outcome` | `outcome` | ⚠️ Different names! |
| `phone` | `phone_number` | ⚠️ Different names! |
| `cost` | `total_cost` | ⚠️ Different names! |
| `appointment_scheduled_at` | In `metadata` | ⚠️ Not a direct column! |
| Missing: `call_sid` | `call_sid` | ⚠️ Not in TS type |
| Missing: `conversation_id` | `conversation_id` | ⚠️ Not in TS type |
| Missing: `deployment_id` | `deployment_id` | ⚠️ Not in TS type |

**Recommendation:**
- Create new TypeScript type matching actual database schema
- Keep backward compatibility for frontend

---

## 8. Recommendations for Database Cleanup

### 8.1 Priority 1: Remove Unused Columns

```sql
-- Drop completely unused columns
ALTER TABLE agent_calls 
  DROP COLUMN IF EXISTS call_quality_score,
  DROP COLUMN IF EXISTS call_classification;
```

**Impact:** None - these are never used

---

### 8.2 Priority 2: Deprecate Duplicate Columns

**After verifying n8n workflows updated:**

```sql
-- Option A: Drop duplicates immediately
ALTER TABLE agent_calls
  DROP COLUMN IF EXISTS sentiment_analysis,
  DROP COLUMN IF EXISTS call_status;

-- Option B: Keep for 30 days, then drop
-- (Monitor n8n logs to ensure no errors)
```

**Impact:** 
- ⚠️ Must update n8n workflows first
- ⚠️ Verify trigger `trg_sync_outcome_emotion` handles all cases

---

### 8.3 Priority 3: Add Missing Columns

**TTS Provider Data (currently 88% NULL):**

```sql
-- Backfill tts_provider and tts_voice_id from metadata
UPDATE agent_calls
SET 
  tts_provider = metadata->'stack'->'tts'->0->>'ttsProvider',
  tts_voice_id = metadata->'stack'->'tts'->0->>'voiceId'
WHERE tts_provider IS NULL 
  AND metadata->'stack'->'tts' IS NOT NULL;
```

**Impact:** Improves data completeness for cost analysis

---

### 8.4 Priority 4: Add Indexes for Latency Queries

```sql
-- Index for querying latency data in metadata
CREATE INDEX IF NOT EXISTS idx_agent_calls_metadata_latencies
  ON agent_calls USING GIN ((metadata->'latencies'));

-- Index for filtering by LLM model (for latency comparisons)
CREATE INDEX IF NOT EXISTS idx_agent_calls_llm_model
  ON agent_calls(llm_model);
```

**Impact:** Faster queries for latency analysis dashboard

---

## 9. Latency Data Integration

### 9.1 Current State

✅ **Latency data is already being stored** in `metadata.latencies` (103 recent calls)

**No new columns needed!** All latency metrics are in JSONB:

```json
{
  "llmLatencies": {"min": 555, "max": 1110, "average": 725, "count": 4},
  "ttsLatencies": {"min": 207, "max": 207, "average": 207, "count": 1},
  "totalLatencies": {"min": 555, "max": 1110, "average": 777, "count": 4}
}
```

### 9.2 Querying Latencies

```sql
-- Get average LLM latency for recent calls
SELECT 
  deployment_id,
  AVG((metadata->'latencies'->'llmLatencies'->>'average')::numeric) as avg_llm_latency_ms,
  AVG((metadata->'latencies'->'ttsLatencies'->>'average')::numeric) as avg_tts_latency_ms
FROM agent_calls
WHERE metadata ? 'latencies'
  AND started_at >= NOW() - INTERVAL '30 days'
GROUP BY deployment_id;
```

### 9.3 Dashboard Integration

**Create new chart: Latency Trends**

```sql
-- Sample query for latency chart
SELECT 
  DATE(started_at) as date,
  llm_model,
  AVG((metadata->'latencies'->'llmLatencies'->>'average')::numeric) as avg_llm_ms,
  AVG((metadata->'latencies'->'ttsLatencies'->>'average')::numeric) as avg_tts_ms,
  AVG((metadata->'latencies'->'totalLatencies'->>'average')::numeric) as avg_total_ms
FROM agent_calls
WHERE metadata ? 'latencies'
  AND started_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(started_at), llm_model
ORDER BY date DESC;
```

---

## 10. Summary & Next Steps

### 10.1 Key Findings

| Category | Status | Details |
|----------|--------|---------|
| **Core Data** | ✅ Excellent | All essential fields 100% populated |
| **Naming** | ⚠️ Issues | Duplicate columns (`outcome`/`call_status`, `emotion`/`sentiment_analysis`) |
| **Unused Columns** | ❌ Cleanup Needed | `call_quality_score`, `call_classification` never used |
| **Latency Data** | ✅ Already Stored | In `metadata.latencies` JSONB (no new columns needed) |
| **TypeScript Types** | ⚠️ Mismatches | Type definitions don't match actual schema |

### 10.2 Recommended Actions

**Immediate (This Week):**
1. ✅ Document latency data structure (this file)
2. 🔧 Add GIN index on `metadata->'latencies'` for performance
3. 🔧 Backfill `tts_provider` and `tts_voice_id` from metadata

**Short Term (Next 2 Weeks):**
4. 🔍 Verify n8n workflows use `outcome` (not `call_status`)
5. 🔍 Verify n8n workflows use `emotion` (not `sentiment_analysis`)
6. ❌ Drop unused columns: `call_quality_score`, `call_classification`
7. 📊 Create latency dashboard component

**Long Term (Next Month):**
8. ❌ Drop duplicate columns: `call_status`, `sentiment_analysis` (after n8n verification)
9. 📝 Update TypeScript types to match database schema
10. 📚 Document final schema in `docs/DATABASE_REFERENCE.md`

---

## 11. Files to Update

### 11.1 Documentation
- ✅ `features/addingLatencies/AGENT_CALLS_SCHEMA_ANALYSIS.md` (this file)
- ⏳ `docs/DATABASE_REFERENCE.md` - Update with cleanup changes
- ⏳ `CLAUDE.md` - Update with new latency data info

### 11.2 Migrations
- ⏳ `supabase/migrations/20251120_add_latency_indexes.sql` - Add GIN indexes
- ⏳ `supabase/migrations/20251120_backfill_tts_data.sql` - Backfill TTS columns
- ⏳ `supabase/migrations/20251201_cleanup_unused_columns.sql` - Drop unused columns

### 11.3 Types
- ⏳ `lib/types/database.ts` - Add proper `AgentCall` interface
- ⏳ `lib/types/dashboard.ts` - Add latency chart types

### 11.4 Queries
- ⏳ `lib/queries/latency.ts` - Create latency data queries

### 11.5 Components
- ⏳ `components/dashboard/charts/LatencyChart.tsx` - New latency visualization

---

## Appendix: Sample Queries

### A.1 Check Column Fill Rates

```sql
SELECT 
    column_name,
    COUNT(*) as total_rows,
    COUNT(column_name) as non_null_count,
    COUNT(*) - COUNT(column_name) as null_count,
    ROUND(100.0 * COUNT(column_name) / COUNT(*), 2) as fill_percentage
FROM agent_calls
CROSS JOIN (
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'agent_calls' 
    AND table_schema = 'public'
    AND column_name NOT IN ('id', 'created_at', 'updated_at')
) cols
GROUP BY column_name
ORDER BY fill_percentage DESC;
```

### A.2 Check Metadata Keys

```sql
SELECT 
    jsonb_object_keys(metadata) as metadata_keys,
    COUNT(*) as count
FROM agent_calls
WHERE metadata IS NOT NULL AND metadata != '{}'
GROUP BY metadata_keys
ORDER BY count DESC;
```

### A.3 Check Latency Data Availability

```sql
SELECT 
    COUNT(*) FILTER (WHERE metadata ? 'latencies') as with_latencies,
    COUNT(*) FILTER (WHERE metadata IS NULL OR NOT (metadata ? 'latencies')) as without_latencies,
    COUNT(*) as total,
    ROUND(100.0 * COUNT(*) FILTER (WHERE metadata ? 'latencies') / COUNT(*), 2) as percentage_with_latencies
FROM agent_calls;
```

---

**End of Analysis**
