# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Development Commands

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint for code quality

---

## 📁 Project Organization & Feature Development

**IMPORTANT**: All new features, updates, and related documentation MUST be organized in the `features/` directory.

### Feature Development Convention

When working on any new feature or significant update:

1. **Create a dedicated folder** in `features/` with a descriptive name
2. **Centralize all related files**: PRPs, documentation, assets, SQL, analysis, notes
3. **Keep source code in proper locations**: `app/`, `components/`, `lib/`
4. **Move final migrations** to `supabase/migrations/`

**Recommended structure**:
```
features/[feature-name]/
├── README.md          # Feature overview
├── PRPs/              # Product Requirements Proposals
├── documentation/     # Technical specs
├── assets/           # Screenshots, mockups
├── sql/              # SQL queries (before migration)
└── notes/            # Development notes
```

**Benefits**: Focused development, historical record, clean root, separation of concerns.

---

## ⚠️ CRITICAL - Process Management for npm run dev

**IMPORTANT**: Before starting the development server, you MUST follow this process management protocol:

### Pre-Dev Server Checklist

1. **ALWAYS kill existing process on port 3000** before running `npm run dev`:
   ```bash
   # Windows
   netstat -ano | findstr :3000
   taskkill /PID <PID> /F

   # Then start dev server
   npm run dev
   ```

2. **DO NOT touch processes on other ports**:
   - ❌ NEVER kill processes on ports other than 3000
   - ❌ NEVER use `pkill` or `taskkill` without verifying the exact PID
   - ❌ NEVER kill all Node processes (`pkill node` / `taskkill /IM node.exe`)
   - ⚠️ **Risk**: You may kill your own Claude Code process, blocking all further operations

3. **Safe Process Management**:
   - ✅ ONLY target port 3000 specifically
   - ✅ Verify the PID before killing
   - ✅ Use targeted kill commands with explicit PID
   - ✅ Check that port 3000 is free before running `npm run dev`

**Remember**: One precise kill is better than a hundred broad kills that might take you down.

---

## UI Verification Workflow

**IMPORTANT**: After making any UI modifications, you MUST:
1. Use the MCP Playwright server to navigate to the site (locally on `http://localhost:3000` or production URL)
2. Take a browser snapshot to verify the visual changes
3. Check that the updates correspond to the expected behavior
4. Test responsive design by resizing the browser window
5. Verify animations and interactions are working correctly

**⚠️ CRITICAL - Screenshot Policy**:
- ❌ **NEVER take full-page screenshots** - They often exceed maximum size limits and block all context
- ✅ **ALWAYS take specific/targeted screenshots** - Screenshot only the specific element or section being modified
- ✅ **Use browser_snapshot instead** - Prefer accessibility snapshots over screenshots when possible
- When using `browser_take_screenshot`, ALWAYS specify `element` and `ref` parameters to target a specific component

This visual verification ensures that all changes are properly rendered and functioning as intended before committing.

---

## Project Architecture

This is a Voipia landing page built with **Next.js 15 App Router**, showcasing three AI voice agents (Louis, Arthur, Alexandra). The application uses a component-based architecture with clear separation of concerns.

### Core Structure

- **`app/`** - Next.js App Router (layout, pages, routes)
- **`components/sections/`** - Main page sections (Hero, AgentsGrid, HowItWorks, etc.)
- **`components/ui/`** - Reusable UI components
- **`components/animations/`** - Framer Motion animation wrappers
- **`lib/`** - Utilities, constants, types, queries

### Technology Stack

- **Next.js 15** with App Router and TypeScript
- **Tailwind CSS** with custom animations
- **Framer Motion** for advanced animations
- **Lucide React** for iconography
- **Supabase** for backend and database
- **React Query** for data fetching

### Design System

- **Dark theme** with purple/violet primary colors
- **Glassmorphism** cards and effects
- **Mobile-first** responsive design
- **Agent-specific colors**: Louis (blue), Arthur (orange), Alexandra (green)
- Custom animations: breathing, wave, fade-in-up, glow

### Data Management

- Agent data centralized in `lib/constants.ts`
- Dashboard queries in `lib/queries/`
- TypeScript types in `lib/types/`

---

## 🚀 Landing Page Refonte (Home + 3 Dedicated LPs)

The site is undergoing a **major refactoring** to transition from a single page to **Home + 3 dedicated landing pages** (one per agent).

**Architecture Target**:
```
/landingv2    → New Home (in development, will replace / after validation)
/louis        → Louis Landing Page (Automatic Callback)
/arthur       → Arthur Landing Page (Reactivation)
/alexandra    → Alexandra Landing Page (24/7 Reception)
/dashboard    → Global Dashboard (existing)
/             → Current Home (do not touch during refactoring)
```

**Plan**: 7 phases documented in `features/proposition_restructuration_landing/INITIAL/`

**Quick Start**:
1. Read phase files: `features/proposition_restructuration_landing/INITIAL/INITIAL_refonte_XX.md`
2. Generate PRP: `/generate-prp "Phase X: [title]"`
3. Execute: `/execute-prp PRPs/refonte-phase-X.md`

**Key Goals**: Improve conversions, SEO optimization, targeted advertising, better tracking.

**Full Documentation**: See `features/proposition_restructuration_landing/REFONTE_OVERVIEW.md`

---

## PRP (Product Requirements Proposal) System

This project uses a PRP system for planning and implementing features with comprehensive context and validation loops.

### Quick Commands

- **`/generate-prp "feature description"`** - Generate a comprehensive PRP for a new feature
- **`/execute-prp PRPs/feature-name.md`** - Execute an existing PRP with full validation

### PRP Workflow

1. **Planning**: Use `/generate-prp` or manually use template at `PRPs/templates/prp_base.md`
2. **Implementation**: Follow PRP's task breakdown and pseudocode
3. **Validation**: Run all commands in validation loops section
4. **Iteration**: Fix issues based on validation results

### PRP Best Practices

- Include ALL necessary context upfront
- Define clear success criteria with measurable outcomes
- Provide executable validation commands
- Reference existing code patterns and components
- Always verify UI changes with browser snapshots
- Run lint and build checks as part of validation

---

## Backend & Database Architecture

### Database Environments: Production vs Staging

**IMPORTANT**: The project uses **two separate Supabase databases** for safe development and testing.

#### Environment Overview

**Production Database** (`mcp__supabase-voipia__*`)
- **Purpose**: Live production data
- **Access**: Read-only for Claude
- **Safety**: Protected from accidental modifications

**Staging Database** (`mcp__supabase-staging__*`)
- **Purpose**: Testing and development
- **Access**: Full read/write for Claude
- **Safety**: Safe playground for testing changes

#### Development Workflow

1. **Develop & Test in Staging**: Create tables, insert test data, validate logic
2. **Generate Migration**: Create SQL migration file for production
3. **User Executes**: User manually runs migration in production

**Example**: Testing new KPI
```bash
# Step 1: Develop in staging
mcp__supabase-staging__execute_sql
- Create/modify views, functions
- Insert test data
- Validate calculations

# Step 2: Generate production migration
mcp__supabase-voipia__apply_migration
- Create migration file (YYYYMMDD_description.sql)

# Step 3: User applies to production
- User reviews and executes in Supabase dashboard
```

### Core Database Tables

**Key Tables**:
- `agent_calls` - All call data (outcome, duration, cost, emotion, etc.)
- `agent_deployments` - Agent instances deployed for clients
- `agent_types` - Types of AI agents (louis, arthur, alexandra)
- `clients` - Customer companies
- `user_client_permissions` - RLS permissions mapping

**Key Views**:
- `v_agent_calls_enriched` - Main view with calculated fields (answered, appointment_scheduled)
- `v_user_accessible_clients` - Clients accessible by authenticated user (RLS)
- `v_user_accessible_agents` - Agent deployments accessible by authenticated user (RLS)

**RPC Functions**:
- `get_kpi_metrics(...)` - Returns KPI metrics with current vs previous period
- `get_chart_data(...)` - Returns chart data (call volume, outcomes, emotions, etc.)
- `get_agent_type_cards_data(...)` - Aggregates metrics by agent TYPE
- `get_client_cards_data(...)` - Aggregates metrics by CLIENT

**Full Database Reference**: See `docs/DATABASE_REFERENCE.md` for complete schema, fields, and relationships.

### Critical KPI Formulas

```
Total Calls = COUNT(*)
Answered Calls = COUNT(*) WHERE answered = true
RDV Pris = COUNT(*) WHERE appointment_scheduled = true

Answer Rate = (answered_calls / total_calls) × 100
Conversion Rate = (appointments / ANSWERED_calls) × 100  ← NOT total_calls!
Average Duration = AVG(duration_seconds) WHERE duration_seconds > 0
Cost per Appointment = total_cost / appointments
```

**Common Pitfalls to Avoid**:
- ❌ Using `metadata ? 'key'` to check values (checks existence, not value)
- ❌ Dividing appointments by total_calls for conversion rate (gives >100%)
- ❌ Forgetting to filter by agent_type_name (mixes Louis + Arthur data)
- ❌ Treating voicemail as "answered" (outcome must NOT be in not-answered list)

---

## Dashboard Architecture

### Dashboard Types

**Global Dashboard** (`/dashboard`)
- Overview of ALL accessible agents and clients
- Two-column layout: Agent Type Cards + Client Cards

**Louis Dashboard** (`/dashboard/louis`)
- Shows ONLY Louis agent data
- KPIs: Total Calls, Taux de Décroché, Durée Moyenne, RDV Pris, Taux de Conversion
- Charts: Call Volume, Emotion Distribution, Outcome Breakdown, Voicemail by Agent

**Arthur Dashboard** (`/dashboard/arthur`)
- Shows ONLY Arthur agent data (prospecting/reactivation)
- Arthur-specific KPIs and charts

### Dashboard Filters

All dashboards support:
- **Date Range**: Start date to end date
- **Client**: Filter by specific company (optional)
- **Agent**: Filter by specific deployment (optional)

### Dashboard Data Flow

```
User → Dashboard Component
    ↓ useDashboardFilters() (URL-based filters)
    ↓ useLouisKPIs(filters) / useLouisChartData(filters)
    ↓ fetchLouisKPIMetrics(filters)
    ↓ supabase.rpc('get_kpi_metrics', {...filters, p_agent_type_name: 'louis'})
    ↓ Supabase RPC Function (with RLS)
    ↓ v_agent_calls_enriched view
    ↓ agent_calls table
```

**Full Dashboard Documentation**: See `features/Dashboard/ARCHITECTURE.md` for complete details.

---

## Migration Management

### Creating Migrations

**CRITICAL RULES**:
1. ✅ **Always create migration files** - Never ask user to run SQL directly
2. ✅ **Use descriptive filenames** - Format: `YYYYMMDD_description.sql`
3. ✅ **Include DROP IF EXISTS** - Prevent "function is not unique" errors
4. ✅ **Add comments** - Explain what changed and why
5. ✅ **Test queries** - Include verification queries at the bottom

**Migration Template**:
```sql
-- Migration: [Description]
-- Date: YYYY-MM-DD
-- Author: Claude
--
-- Changes:
-- 1. What was changed
-- 2. Why it was changed
-- 3. Expected impact

-- Drop existing functions/views if they exist
DROP FUNCTION IF EXISTS function_name(arg_types);
DROP VIEW IF EXISTS view_name;

-- Create/replace objects
CREATE OR REPLACE VIEW view_name AS ...
CREATE FUNCTION function_name(...) ...

-- Grant permissions
GRANT SELECT ON view_name TO authenticated;
GRANT EXECUTE ON FUNCTION function_name(...) TO authenticated;

-- Verification queries (commented out)
-- SELECT * FROM view_name LIMIT 10;
```

### Migration Best Practices

**Order of Execution**:
1. Views first (they don't affect data)
2. Functions second (they use views)
3. Test with verification queries

**Safety Rules**:
- ⚠️ **NEVER assume staging and production schemas are identical** - Always verify schema before migrations
- ⚠️ **ALWAYS test in staging first** - Even for "simple" changes
- ⚠️ **ALWAYS include verification queries** in migration files
- ⚠️ **ALWAYS use transactions** for multi-step changes

---

## Workflows & Automation

### n8n Workflows

**IMPORTANT**: The AI agents (Louis, Arthur, Alexandra) are orchestrated via **n8n workflows**.

- n8n handles the execution logic for agent calls
- Workflows trigger agent deployments based on schedules or events
- Call results are written to `agent_calls` table
- You have access to n8n via MCP server: `mcp__n8n-voipia__*`

### Agent Deployment Architecture

```
Client → agent_deployments → agent_types → n8n workflows → agent_calls
```

---

## Development Workflow

### Making Dashboard Changes

1. **Understand current data** - Query database via MCP Supabase
2. **Identify requirements** - What KPIs/charts are needed?
3. **Design SQL logic** - Create views/functions if needed
4. **Create migration** - Write SQL migration file
5. **Update frontend** - Modify React components
6. **Verify with browser** - Use MCP Playwright to test
7. **User executes migration** - User runs SQL in Supabase

### Testing Dashboard Changes

```bash
# 1. Run dev server
npm run dev

# 2. Navigate to dashboard
Use MCP Playwright: mcp__playwright__browser_navigate
URL: http://localhost:3000/dashboard/louis

# 3. Take snapshot
Use: mcp__playwright__browser_snapshot

# 4. Verify data
Check KPIs match expected values from database queries

# 5. Test filters
Change date range, client, agent - verify data updates
```

---

## Quick Reference

### Essential File Locations

**Dashboard Code**:
- `app/dashboard/page.tsx` - Global Dashboard
- `app/dashboard/[agentType]/page.tsx` - Dynamic route (louis, arthur)
- `app/dashboard/[agentType]/LouisDashboardClient.tsx` - Louis dashboard
- `app/dashboard/[agentType]/ArthurDashboardClient.tsx` - Arthur dashboard

**Data Queries**:
- `lib/queries/louis.ts` - Louis-specific queries
- `lib/queries/arthur.ts` - Arthur-specific queries
- `lib/queries/global.ts` - Global dashboard queries

**Types**:
- `lib/types/dashboard.ts` - Dashboard TypeScript types

**Components**:
- `components/dashboard/` - Dashboard-specific components
- `components/sections/` - Landing page sections
- `components/ui/` - Reusable UI components

**Migrations**:
- `supabase/migrations/*.sql` - Database migration files

### Key Constants

**Agent Types**: `'louis'`, `'arthur'`, `'alexandra'`

**Outcomes** (lowercase): `'appointment_scheduled'`, `'appointment_refused'`, `'voicemail'`, `'not_interested'`, `'callback_requested'`, `'too_short'`, `'call_failed'`

**Deployment Status**: `'active'`, `'paused'`, `'archived'`

**Permission Levels**: `'read'`, `'write'`, `'admin'`

---

## Additional Documentation

For more detailed information, refer to:

- **Database Reference**: `docs/DATABASE_REFERENCE.md` - Complete schema, tables, views, functions
- **Dashboard Architecture**: `features/Dashboard/ARCHITECTURE.md` - Detailed dashboard structure and data flow
- **Landing Refonte**: `features/proposition_restructuration_landing/REFONTE_OVERVIEW.md` - Complete refactoring plan
- **Known Issues**: `docs/KNOWN_ISSUES.md` - Bug history and solutions

This system ensures consistent, high-quality implementations with proper context and validation at every step.
