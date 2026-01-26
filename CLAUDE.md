# CLAUDE.md - Sablia Vox

**Voice AI Agent Platform** - B2B sales automation via AI voice agents. Domain: **vox.sablia.io**

---

## What is Sablia Vox?

Sablia Vox is Brice's SaaS platform that deploys AI voice agents for B2B clients. The main product is **Louis** - an AI agent that:
- Instantly calls back new leads (<60 seconds)
- Qualifies prospects via conversation
- Books appointments directly in client calendars
- Sends confirmation SMS

**Business Model**: Monthly subscription + consumption-based billing (per minute/SMS)

**Target Market**: French B2B companies needing automated lead follow-up without hiring SDRs.

---

## Development Commands

```bash
npm run dev      # Start dev server (port 3000)
npm run build    # Build for production
npm run lint     # Run ESLint
```

---

## CRITICAL Rules

### Process Management (Windows)

**Before starting dev server**:
```bash
netstat -ano | findstr :3000
taskkill /PID <PID> /F
npm run dev
```

**NEVER**:
- Kill processes on other ports
- Use `pkill node` or `taskkill /IM node.exe` (kills Claude Code)
- Kill without verifying exact PID

### File Creation Policy

**NEVER create files at project root** (except config files)

**Locations**:
- Documentation → `features/[feature-name]/` or `docs/`
- Migrations → `supabase/migrations/`
- Source code → `app/`, `components/`, `lib/`

---

## Site Architecture

### Public Pages

| Route | Purpose |
|-------|---------|
| `/` | Landing page - Value proposition, how it works, FAQ |
| `/tester-nos-agents` | Demo request form |
| `/login` | Authentication |

### Dashboard (Authenticated)

| Route | Purpose |
|-------|---------|
| `/dashboard` | Main dashboard overview |
| `/dashboard/agents` | Agent deployments list |
| `/dashboard/agents/[agentId]` | Agent detail + calls |
| `/dashboard/clients` | Client companies list |
| `/dashboard/clients/[clientId]` | Client detail |
| `/dashboard/financial` | Financial analytics (admin) |
| `/dashboard/consumption` | User consumption tracking |
| `/dashboard/admin/calls` | Admin calls explorer |
| `/dashboard/performance` | Performance analytics |

### Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS + Framer Motion
- **Database**: Supabase (PostgreSQL)
- **State**: React Query
- **Auth**: Supabase Auth
- **Voice AI**: Dipler + n8n workflows

---

## Database Architecture

### Environments

| Environment | MCP Tools | Access |
|-------------|-----------|--------|
| **Production** | `mcp__supabase-vox__*` | Read-only |
| **Staging** | `mcp__supabase-staging__*` | Full access |

**Workflow**: Develop in staging → Generate migration → Brice executes in production

### Core Tables

```
clients                    → Customer companies
  └── agent_deployments    → Agent instances per client
        └── agent_calls    → Individual call records

agent_types                → louis, arthur, alexandra (types)
user_client_permissions    → RLS: who can see what
```

### Key Views

- `v_agent_calls_enriched` - Calls with calculated `answered` and `appointment_scheduled` booleans
- `v_user_accessible_clients` - RLS-filtered clients
- `v_user_accessible_agents` - RLS-filtered deployments

### RPC Functions

- `get_kpi_metrics(start, end, client?, deployment?, agent_type?)` - Dashboard KPIs
- `get_chart_data(...)` - Chart data (volume, outcomes, emotions)
- `get_agent_type_cards_data(...)` - Aggregated metrics by agent type
- `get_client_cards_data(...)` - Aggregated metrics by client

### Critical KPI Formulas

```sql
Answer Rate      = answered_calls / total_calls × 100
Conversion Rate  = appointments / ANSWERED_calls × 100  -- NOT total_calls!
Cost per RDV     = total_cost / appointments
```

**Common Pitfalls**:
- `metadata ? 'key'` checks key existence, not value (use `appointment_scheduled = true`)
- Conversion rate denominator is answered_calls, not total_calls
- Voicemail is NOT answered (outcome='voicemail' → answered=false)

**Full schema**: `docs/DATABASE_REFERENCE.md`

---

## Component Structure

```
components/
├── landing/           # Landing page sections (home only)
│   ├── HeroHomeV2.tsx
│   ├── HowItWorksV2.tsx
│   ├── DashboardShowcase.tsx
│   ├── IntegrationsTriple.tsx
│   ├── SDRComparison.tsx
│   ├── CustomDevelopment.tsx
│   ├── FAQAccordion.tsx
│   └── FloatingCTA.tsx
├── dashboard/         # Dashboard components
│   ├── Charts/        # Recharts visualizations
│   ├── Cards/         # KPI and info cards
│   ├── Filters/       # Date, client, agent filters
│   ├── Financial/     # Financial dashboard
│   └── Sidebar/       # Navigation
├── shared/            # Shared (HeaderV2, Button, Card)
├── ui/                # shadcn/ui + custom UI
└── chatbot/           # Chatbot widget
```

---

## Data Files

```
lib/data/
├── faqs.ts           # FAQ content for home page
└── integrations.ts   # Integration logos/data
```

---

## Migrations

**Format**: `YYYYMMDD_description.sql`

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
- Test in staging first
- Include DROP IF EXISTS
- Use transactions for multi-step changes

---

## PRP System

Project Request Proposals for feature development.

**Commands**:
- `/generate-prp "description"` - Generate PRP
- `/execute-prp PRPs/feature-name.md` - Execute PRP

---

## UI Verification

After UI changes:
1. Navigate with MCP Playwright to `http://localhost:3000`
2. Use `browser_snapshot` (NOT full-page screenshots)
3. If screenshot needed, specify `element` and `ref` parameters

---

## Quick Reference

### Outcomes (lowercase)
`appointment_scheduled`, `appointment_refused`, `voicemail`, `not_interested`, `callback_requested`, `too_short`, `call_failed`, `no_answer`, `busy`, `error`

### Emotions
`positive`, `neutral`, `negative`, `unknown`

### Design Tokens
- **Background**: Dark gradient (black → purple-950/20 → black)
- **Cards**: Glassmorphism (bg-white/5, border-white/10)
- **Accent**: Violet/Purple (#8B5CF6)

---

## Documentation

- `docs/DATABASE_REFERENCE.md` - Complete database schema
- `docs/KNOWN_ISSUES.md` - Bug history and solutions
- `docs/MIGRATION_BEST_PRACTICES.md` - Migration guidelines
- `features/_archive/` - Archived feature documentation
