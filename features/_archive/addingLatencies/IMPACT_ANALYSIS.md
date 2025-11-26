# Impact Analysis: Dropping Columns from agent_calls Table

**Date:** 2025-01-20  
**Author:** Claude  
**Purpose:** Comprehensive analysis before dropping duplicate/unused columns from production `agent_calls` table

---

## Executive Summary

### Columns Under Review

| Column | Status | Usage | Safe to Drop? |
|--------|--------|-------|---------------|
| `sentiment_analysis` | ⚠️ Duplicate of `emotion` | Used by 4 views, synced by trigger | ⚠️ **RISKY** |
| `call_status` | ⚠️ Duplicate of `outcome` | Used by 3 views, synced by trigger | ⚠️ **RISKY** |
| `call_classification` | ✅ Empty/Unused | Used by 3 views (always empty string) | ✅ **SAFE** |

### Overall Recommendation

🛑 **DO NOT DROP YET** - All three columns are referenced in production views. Dropping them will cause catastrophic failures.

**Required Steps Before Drop:**
1. Update all dependent views to remove references
2. Verify n8n workflows don't write to these columns
3. Test in staging environment
4. Create migration in correct dependency order
5. Only then drop columns

---

## Part 1: Database Objects Analysis

### 1.1 Views Using These Columns

Found **4 views** that reference the target columns:

#### View 1: `v_agent_calls_enriched` (CRITICAL)
- **Purpose:** Main view used by ALL dashboards
- **References:**
  - ✅ `call_classification` (line 21)
  - ✅ `sentiment_analysis` (line 23)
  - Uses `emotion` and `outcome` for computed columns
- **Impact:** 🔴 **CRITICAL** - Used by 100% of dashboard queries
- **Dependencies:** Referenced by ALL RPC functions

#### View 2: `v_arthur_calls_enriched` 
- **Purpose:** Arthur-specific dashboard view
- **References:**
  - ✅ `call_classification` (line 27)
  - ✅ `call_quality_score` (line 28)
  - ✅ `sentiment_analysis` (line 29)
  - ✅ `call_status` (line 35)
- **Impact:** 🔴 **CRITICAL** - Used by Arthur dashboard
- **Dependencies:** Arthur KPI/chart functions

#### View 3: `v_global_kpis`
- **Purpose:** Global dashboard KPIs
- **References:**
  - ✅ `call_classification` (line 28)
  - ✅ `call_quality_score` (line 29)
  - ✅ `sentiment_analysis` (line 30)
  - ✅ `call_status` (line 36)
- **Impact:** 🟡 **MEDIUM** - Used by global dashboard (older version)

#### View 4: `v_agent_communications`
- **Purpose:** Unified view of calls + SMS + emails
- **References:**
  - ✅ `call_status` (AS status)
- **Impact:** 🟡 **MEDIUM** - Used for multi-channel analytics

### 1.2 RPC Functions

**ALL RPC functions use `v_agent_calls_enriched`**, so they indirectly depend on these columns.

Critical functions:
- `get_kpi_metrics()` - Main KPI function (Louis/Arthur dashboards)
- `get_chart_data()` - Chart data (all dashboards)
- `get_agent_cards_data()` - Agent cards (global dashboard)
- `get_client_cards_data()` - Client cards (global dashboard)
- `get_arthur_kpi_metrics()` - Arthur-specific KPIs
- `get_arthur_chart_data()` - Arthur-specific charts

**None of these functions reference the columns directly**, but they ALL depend on views that do.

### 1.3 Triggers

Found **1 trigger** that actively uses these columns:

#### Trigger: `trg_sync_outcome_emotion`
- **Function:** `sync_outcome_emotion_columns()`
- **Purpose:** Syncs `call_status` → `outcome` and `sentiment_analysis` → `emotion`
- **Created:** 2025-11-13 (migration `20251113_fix_outcome_emotion_columns.sql`)
- **Logic:**
  ```sql
  IF (NEW.outcome IS NULL OR NEW.outcome = '') AND
     (NEW.call_status IS NOT NULL AND NEW.call_status != '') THEN
    NEW.outcome := NEW.call_status;
  END IF;

  IF (NEW.emotion IS NULL OR NEW.emotion = '') AND
     (NEW.sentiment_analysis IS NOT NULL AND NEW.sentiment_analysis != '') THEN
    NEW.emotion := NEW.sentiment_analysis;
  END IF;
  ```
- **Impact:** 🔴 **CRITICAL** - Dropping `call_status` or `sentiment_analysis` will break this trigger

### 1.4 RLS Policies

✅ **No RLS policies reference these columns**

The only RLS policy on `agent_calls` is:
- `users_view_accessible_calls` - Filters by `deployment_id` only

### 1.5 Indexes

✅ **No indexes on these columns**

---

## Part 2: Frontend Code Analysis

### 2.1 TypeScript Types

**No references found** in:
- `lib/types/` - ✅ Clean
- TypeScript type definitions do not include these columns

### 2.2 Dashboard Queries

**No direct references found** in:
- `lib/queries/louis.ts` - ✅ Clean
- `lib/queries/arthur.ts` - ✅ Clean
- `lib/queries/global.ts` - ✅ Clean

All queries use RPC functions, which use views, which reference these columns.

### 2.3 Components

**No references found** in:
- `components/dashboard/` - ✅ Clean

---

## Part 3: Migration Files Analysis

Found **1 migration** that uses these columns:

### Migration: `20251113_fix_outcome_emotion_columns.sql`

**Purpose:** Created trigger to sync duplicate columns

**What it does:**
1. Copies `call_status` → `outcome` (one-time UPDATE)
2. Copies `sentiment_analysis` → `emotion` (one-time UPDATE)
3. Creates trigger to auto-sync on INSERT/UPDATE

**Key Quote from Migration:**
> "Continue using 'outcome' and 'emotion' as the source of truth"

This confirms:
- ✅ `outcome` is the canonical column (not `call_status`)
- ✅ `emotion` is the canonical column (not `sentiment_analysis`)
- ⚠️ But the trigger STILL REFERENCES the duplicate columns

---

## Part 4: n8n Workflow Analysis

### Current Situation (from documentation)

**From `AGENT_CALLS_SCHEMA_ANALYSIS.md`:**

> "**n8n Workflow Changes** (November 2025):
> - Anciennement : écrivaient dans `outcome` et `emotion`
> - Maintenant : écrivent dans `call_status` et `sentiment_analysis`"

**Translation:** n8n workflows recently SWITCHED from writing to the canonical columns (`outcome`, `emotion`) to the duplicate columns (`call_status`, `sentiment_analysis`).

**Mapping from n8n JSON:**
```
callInfos.callStatus → call_status (then synced to outcome by trigger)
postConversationAnalysis.sentiment → emotion (with sentiment_analysis as fallback)
postConversationAnalysis.extractedData.callClassification → call_classification (always "")
```

### ⚠️ CRITICAL FINDING

**n8n workflows ARE actively writing to `call_status` and `sentiment_analysis`!**

If we drop these columns:
1. n8n inserts will FAIL (column doesn't exist)
2. Even if we fix n8n to write to `outcome`/`emotion`, we lose the safety net of the trigger

---

## Part 5: Dependencies Map

### Column: `sentiment_analysis`

**Direct Dependencies:**
1. ✅ View `v_agent_calls_enriched` (line 23) - SELECT column
2. ✅ View `v_arthur_calls_enriched` (line 29) - SELECT column
3. ✅ View `v_global_kpis` (line 30) - SELECT column
4. ✅ Trigger `trg_sync_outcome_emotion` - Reads column, writes to `emotion`

**Indirect Dependencies:**
- ALL RPC functions (via `v_agent_calls_enriched`)
- ALL dashboards (via RPC functions)

**External Dependencies:**
- ⚠️ n8n workflows may write to this column (needs verification)

### Column: `call_status`

**Direct Dependencies:**
1. ✅ View `v_arthur_calls_enriched` (line 35) - SELECT column
2. ✅ View `v_global_kpis` (line 36) - SELECT column  
3. ✅ View `v_agent_communications` (line 12) - SELECT as `status`
4. ✅ Trigger `trg_sync_outcome_emotion` - Reads column, writes to `outcome`

**Indirect Dependencies:**
- Arthur RPC functions (via `v_arthur_calls_enriched`)
- Global RPC functions (via `v_global_kpis`)
- Communication analytics (via `v_agent_communications`)

**External Dependencies:**
- ⚠️ n8n workflows ARE writing to this column (confirmed)

### Column: `call_classification`

**Direct Dependencies:**
1. ✅ View `v_agent_calls_enriched` (line 21) - SELECT column
2. ✅ View `v_arthur_calls_enriched` (line 27) - SELECT column
3. ✅ View `v_global_kpis` (line 28) - SELECT column

**Indirect Dependencies:**
- ALL RPC functions (via views)

**External Dependencies:**
- ⚠️ n8n writes empty string `""` to this column (always empty, never used)

**Data Status:**
- 100% empty strings
- Never used in any dashboard logic
- Could be safely removed from views

---

## Part 6: Migration Order

If we decide to drop these columns, here's the CORRECT order:

### Phase 1: Update Views (FIRST)

```sql
-- Step 1: Drop views that reference the columns
DROP VIEW IF EXISTS v_agent_communications;
DROP VIEW IF EXISTS v_global_kpis;
DROP VIEW IF EXISTS v_arthur_calls_enriched;
DROP VIEW IF EXISTS v_agent_calls_enriched;

-- Step 2: Recreate views WITHOUT the columns
CREATE OR REPLACE VIEW v_agent_calls_enriched AS
  SELECT 
    -- ... all columns EXCEPT:
    -- call_classification,
    -- sentiment_analysis,
    -- (keep call_status if needed for v_agent_communications)
  FROM agent_calls;

-- Recreate other views similarly
```

### Phase 2: Drop Trigger (SECOND)

```sql
-- Only if dropping sentiment_analysis AND call_status
DROP TRIGGER IF EXISTS trg_sync_outcome_emotion ON agent_calls;
DROP FUNCTION IF EXISTS sync_outcome_emotion_columns();
```

### Phase 3: Drop Columns (LAST)

```sql
-- Finally safe to drop
ALTER TABLE agent_calls
  DROP COLUMN IF EXISTS call_classification,
  DROP COLUMN IF EXISTS sentiment_analysis,  -- Only if trigger removed
  DROP COLUMN IF EXISTS call_status;         -- Only if trigger removed
```

### ⚠️ CRITICAL: n8n Must Be Updated FIRST

Before any database changes:
1. Update n8n workflows to write to `outcome` (not `call_status`)
2. Update n8n workflows to write to `emotion` (not `sentiment_analysis`)
3. Test in staging for 1 week
4. Monitor for errors
5. ONLY THEN proceed with database changes

---

## Part 7: Recommendations

### Recommendation 1: `call_classification` - Safe to Drop

**Status:** ✅ **SAFE TO DROP** (after view updates)

**Reasoning:**
- Always empty string `""`
- Never used in any dashboard logic
- Only appears in SELECT lists (never in WHERE/JOIN clauses)

**Steps:**
1. Update views to remove `call_classification` from SELECT lists
2. Test all dashboards in staging
3. Drop column from table

**Risk Level:** 🟢 **LOW**

---

### Recommendation 2: `sentiment_analysis` - DO NOT DROP YET

**Status:** 🛑 **DO NOT DROP**

**Reasoning:**
- Active trigger depends on it
- n8n may still write to it
- Serves as backup/fallback for `emotion`
- Only 2 rows out of 803 have data in this column

**Alternative:**
- Keep column as safety net
- Monitor n8n logs to confirm it's not being written to
- Re-evaluate in 3 months

**Risk Level:** 🔴 **HIGH** (if dropped now)

---

### Recommendation 3: `call_status` - DO NOT DROP YET

**Status:** 🛑 **DO NOT DROP**

**Reasoning:**
- Active trigger depends on it
- n8n IS writing to it (confirmed)
- Used in `v_agent_communications` view
- 100% populated (803/803 rows)

**Alternative:**
- Keep column indefinitely
- It's the PRIMARY column n8n writes to
- Trigger syncs to `outcome` for dashboards

**Risk Level:** 🔴 **CRITICAL** (if dropped now)

---

## Part 8: Safe Migration Path

### Immediate Actions (Week 1)

1. ✅ **Drop `call_classification` only**
   - Update 3 views
   - Test dashboards
   - Low risk

### Short Term (Month 1)

2. 🔍 **Audit n8n workflows**
   - Export all workflow JSONs
   - Search for references to `sentiment_analysis` and `call_status`
   - Document which workflows write to which columns

3. 📊 **Monitor column usage**
   - Add logging to trigger function
   - Track how often `call_status` → `outcome` sync happens
   - Track how often `sentiment_analysis` → `emotion` sync happens

### Medium Term (Month 2-3)

4. 🔧 **Update n8n workflows** (if needed)
   - Change workflows to write directly to `outcome` and `emotion`
   - Deploy to staging
   - Test for 2 weeks
   - Deploy to production
   - Monitor for 2 weeks

5. 🧪 **Test in staging**
   - Drop `call_status` and `sentiment_analysis` in staging only
   - Run all dashboards
   - Insert test data via n8n
   - Verify no errors

### Long Term (Month 4+)

6. ❌ **Drop duplicate columns** (only after 100% confidence)
   - Update all views
   - Drop trigger
   - Drop columns
   - Monitor production for issues

---

## Part 9: Sample Migration (Safe Path)

### Migration 1: Drop call_classification Only

```sql
-- Migration: Drop unused call_classification column
-- Date: 2025-01-20
-- Risk: LOW
-- Dependencies: 3 views

BEGIN;

-- Step 1: Recreate views without call_classification
DROP VIEW IF EXISTS v_global_kpis CASCADE;
DROP VIEW IF EXISTS v_arthur_calls_enriched CASCADE;
DROP VIEW IF EXISTS v_agent_calls_enriched CASCADE;

-- Recreate v_agent_calls_enriched (main view)
CREATE OR REPLACE VIEW v_agent_calls_enriched AS
SELECT 
  id,
  deployment_id,
  first_name,
  last_name,
  email,
  phone_number,
  started_at,
  ended_at,
  duration_seconds,
  outcome,
  emotion,
  total_cost,
  transcript,
  transcript_summary,
  recording_url,
  metadata,
  created_at,
  prospect_id,
  sequence_id,
  conversation_id,
  -- call_classification,  ← REMOVED
  call_quality_score,
  sentiment_analysis,
  CASE
    WHEN outcome IN ('voicemail', 'call_failed', 'no_answer', 'busy', 
                     'invalid_number', 'error', 'canceled', 'rejected')
    THEN false
    WHEN outcome IS NULL
    THEN false
    ELSE true
  END AS answered,
  CASE
    WHEN outcome = 'appointment_scheduled'
    THEN true
    ELSE false
  END AS appointment_scheduled
FROM agent_calls;

-- Recreate v_arthur_calls_enriched
CREATE OR REPLACE VIEW v_arthur_calls_enriched AS
SELECT 
  ac.*,
  -- call_classification,  ← REMOVED (add remaining columns)
  ad.name AS deployment_name,
  ad.slug AS deployment_slug,
  ad.client_id,
  c.name AS client_name,
  at.name AS agent_type_name,
  at.display_name AS agent_type_display_name
FROM agent_calls ac
JOIN agent_deployments ad ON ac.deployment_id = ad.id
JOIN agent_types at ON ad.agent_type_id = at.id
JOIN clients c ON ad.client_id = c.id
WHERE at.name = 'arthur';

-- Recreate v_global_kpis (simplified - adjust as needed)
-- [Add full view definition here]

-- Step 2: Grant permissions
GRANT SELECT ON v_agent_calls_enriched TO authenticated;
GRANT SELECT ON v_arthur_calls_enriched TO authenticated;
GRANT SELECT ON v_global_kpis TO authenticated;

-- Step 3: Drop the column
ALTER TABLE agent_calls DROP COLUMN IF EXISTS call_classification;

-- Step 4: Verify
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'agent_calls' 
      AND column_name = 'call_classification'
  ) THEN
    RAISE EXCEPTION 'Failed to drop call_classification column';
  END IF;
  
  RAISE NOTICE 'Successfully dropped call_classification column';
END $$;

COMMIT;
```

---

## Part 10: Summary & Decision Matrix

| Action | Risk | Impact | Timeline | Decision |
|--------|------|--------|----------|----------|
| Drop `call_classification` | 🟢 LOW | Minimal | Week 1 | ✅ **PROCEED** |
| Drop `sentiment_analysis` | 🔴 HIGH | Breaking | Month 4+ | 🛑 **WAIT** |
| Drop `call_status` | 🔴 CRITICAL | Breaking | Month 4+ | 🛑 **WAIT** |

### Final Recommendation

**DO NOT drop `sentiment_analysis` or `call_status` until:**

1. ✅ n8n workflows are updated to write to `outcome`/`emotion`
2. ✅ Tested in staging for 2+ weeks
3. ✅ Deployed to production and monitored for 2+ weeks
4. ✅ Zero errors/issues observed
5. ✅ Trigger is no longer needed
6. ✅ Views are updated
7. ✅ All stakeholders approve

**ONLY safe to drop `call_classification` now:**
- Used but never populated
- Low risk
- Can proceed after view updates

---

## Appendix: Testing Checklist

Before dropping ANY column in production:

- [ ] Export all n8n workflow JSONs
- [ ] Search for column references in workflows
- [ ] Test column drop in staging database
- [ ] Run ALL dashboard pages (Louis, Arthur, Global, Financial)
- [ ] Insert test call via n8n in staging
- [ ] Verify no console errors
- [ ] Verify no SQL errors in logs
- [ ] Monitor staging for 1 week
- [ ] Get approval from team
- [ ] Schedule maintenance window
- [ ] Prepare rollback script
- [ ] Execute migration during low-traffic period
- [ ] Monitor production for 24 hours
- [ ] Verify all dashboards still work

---

**Generated:** 2025-01-20  
**Status:** Ready for review  
**Next Steps:** Review with team, decide on `call_classification` drop timeline
