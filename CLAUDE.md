# CLAUDE.md

## Development Commands

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run lint` - Run ESLint

---

## ⚠️ CRITICAL Rules

### File Creation Policy

**NEVER create files at project root** (except config files like `.env`, `package.json`, `tsconfig.json`, `CLAUDE.md`)

**File locations**:
- Documentation → `features/[feature-name]/` or `docs/`
- Migrations → `supabase/migrations/`
- Scripts → `scripts/`
- Source code → `app/`, `components/`, `lib/`

### Feature Development

1. Create dedicated folder in `features/[feature-name]/`
2. Structure: `README.md`, `PRPs/`, `documentation/`, `assets/`, `sql/`, `notes/`
3. Source code stays in `app/`, `components/`, `lib/`
4. Final migrations move to `supabase/migrations/`

### Process Management (npm run dev)

**Before starting dev server**:
```bash
# Kill port 3000 ONLY
netstat -ano | findstr :3000
taskkill /PID <PID> /F
npm run dev
```

**NEVER**:
- ❌ Kill processes on other ports
- ❌ Use `pkill node` or `taskkill /IM node.exe` (kills Claude Code)
- ❌ Kill without verifying exact PID

### UI Verification

After UI changes:
1. Navigate with MCP Playwright to `http://localhost:3000`
2. Use `browser_snapshot` (NOT full-page screenshots)
3. If screenshot needed, ALWAYS specify `element` and `ref` parameters

---

## Project Architecture

**Stack**: Next.js 15, TypeScript, Tailwind CSS, Framer Motion, Supabase, React Query

**Structure**:
- `app/` - Next.js App Router (pages, routes)
- `components/sections/` - Page sections (Hero, AgentsGrid, etc.)
- `components/ui/` - Reusable UI components
- `components/dashboard/` - Dashboard components
- `lib/` - Utilities, constants, types, queries

**Design**: Dark theme, glassmorphism, mobile-first, agent colors (Louis=blue, Arthur=orange, Alexandra=green)

**Routes**:
- `/` - Current Home (do not touch during refonte)
- `/landingv2` - New Home (in development)
- `/louis`, `/arthur`, `/alexandra` - Agent landing pages
- `/dashboard` - Global dashboard
- `/dashboard/louis`, `/dashboard/arthur` - Agent dashboards

**Documentation**: See `features/proposition_restructuration_landing/REFONTE_OVERVIEW.md`

---

## PRP System

**Commands**:
- `/generate-prp "description"` - Generate PRP
- `/execute-prp PRPs/feature-name.md` - Execute PRP

**Requirements**: Include context, success criteria, validation commands, code patterns, browser snapshots

---

## Database Architecture

### Environments

**Production** (`mcp__supabase-voipia__*`): Read-only, live data
**Staging** (`mcp__supabase-staging__*`): Full access, testing

**Workflow**: Develop in staging → Generate migration → User executes in production

### Core Tables

- `agent_calls` - Call data (outcome, duration, cost, emotion)
- `agent_deployments` - Agent instances per client
- `agent_types` - Agent types (louis, arthur, alexandra)
- `clients` - Customer companies
- `user_client_permissions` - RLS permissions

**Views**: `v_agent_calls_enriched`, `v_user_accessible_clients`, `v_user_accessible_agents`

**RPC Functions**: `get_kpi_metrics`, `get_chart_data`, `get_agent_type_cards_data`, `get_client_cards_data`

**Full schema**: `docs/DATABASE_REFERENCE.md`

### Critical KPI Formulas

```
Total Calls = COUNT(*)
Answered Calls = COUNT(*) WHERE answered = true
RDV Pris = COUNT(*) WHERE appointment_scheduled = true
Answer Rate = (answered_calls / total_calls) × 100
Conversion Rate = (appointments / ANSWERED_calls) × 100  ← NOT total_calls!
Average Duration = AVG(duration_seconds) WHERE duration_seconds > 0
```

**Common Pitfalls**:
- ❌ `metadata ? 'key'` checks existence, not value
- ❌ Conversion rate with total_calls instead of answered_calls
- ❌ Forgetting to filter by agent_type_name
- ❌ Treating voicemail as "answered"

---

## Migrations

**Rules**:
1. Always create migration files (format: `YYYYMMDD_description.sql`)
2. Include `DROP IF EXISTS` to prevent conflicts
3. Add descriptive comments
4. Include verification queries (commented)
5. Test in staging first

**Template**:
```sql
-- Migration: [Description]
-- Date: YYYY-MM-DD
-- Changes: [what, why, impact]

DROP FUNCTION IF EXISTS func_name(args);
CREATE OR REPLACE FUNCTION func_name(...) ...
GRANT EXECUTE ON FUNCTION func_name(...) TO authenticated;

-- Verification: SELECT * FROM ...
```

**Safety**:
- ⚠️ Never assume staging = production schemas
- ⚠️ Always test in staging first
- ⚠️ Use transactions for multi-step changes

---

## n8n Workflows

AI agents orchestrated via n8n workflows. Access via `mcp__n8n-voipia__*`

**Flow**: `Client → agent_deployments → agent_types → n8n workflows → agent_calls`

---

## Quick Reference

**Dashboard Files**:
- `app/dashboard/page.tsx` - Global dashboard
- `app/dashboard/[agentType]/page.tsx` - Dynamic route
- `app/dashboard/[agentType]/LouisDashboardClient.tsx` - Louis dashboard
- `lib/queries/louis.ts`, `lib/queries/arthur.ts` - Agent queries

**Agent Types**: `'louis'`, `'arthur'`, `'alexandra'`

**Outcomes**: `'appointment_scheduled'`, `'appointment_refused'`, `'voicemail'`, `'not_interested'`, `'callback_requested'`, `'too_short'`, `'call_failed'`

**Dashboard Filters**: Date range, Client (optional), Agent (optional)

---

## Additional Documentation

- `docs/DATABASE_REFERENCE.md` - Complete schema
- `features/Dashboard/ARCHITECTURE.md` - Dashboard details
- `features/proposition_restructuration_landing/REFONTE_OVERVIEW.md` - Refonte plan
- `docs/KNOWN_ISSUES.md` - Bug history
