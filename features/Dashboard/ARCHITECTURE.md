# Dashboard Architecture

This document provides a comprehensive overview of the Voipia dashboard architecture, data flow, and implementation details.

---

## Overview

The Voipia dashboard provides analytics and insights for AI voice agents (Louis, Arthur, Alexandra). It uses a multi-dashboard architecture with role-based access control (RLS) and real-time data filtering.

---

## Dashboard Types

### Global Dashboard (`/dashboard`)

**Purpose**: Provides an overview of ALL accessible agents and clients for the authenticated user.

**Layout**:
- Two-column layout
- **Left column**: Agent Type Cards (aggregate data by agent type)
- **Right column**: Client Cards (aggregate data by client)

**Features**:
- Clickable cards navigate to specific dashboards
- Aggregates metrics across multiple deployments
- Respects RLS permissions (only shows accessible data)

**Key Metrics**:
- Total Calls
- Answered Calls
- Appointments Scheduled
- Answer Rate
- Conversion Rate

**Data Source**:
- `get_agent_type_cards_data()` - Aggregates by agent TYPE
- `get_client_cards_data()` - Aggregates by CLIENT

---

### Louis Dashboard (`/dashboard/louis`)

**Purpose**: Shows detailed analytics for ONLY Louis agent data (automatic callback/reminders).

**Layout**:
- Header with filters (Date Range, Client, Agent)
- KPI Cards (5 metrics in a row)
- Charts Grid (2x2 layout on desktop)

**KPIs**:
1. **Total Calls** - Count of all calls
2. **Taux de Décroché** - Answer rate (answered / total × 100)
3. **Durée Moyenne** - Average call duration
4. **RDV Pris** - Appointments scheduled
5. **Taux de Conversion** - Conversion rate (appointments / answered × 100)

**Charts**:
1. **Call Volume by Day** - Line/area chart showing calls over time
2. **Emotion Distribution** - Donut chart (positive, neutral, negative, unknown)
3. **Outcome Breakdown** - Bar chart showing call outcomes
4. **Voicemail by Agent** - Horizontal bar chart showing voicemail rate per deployment

**Data Source**:
- `get_kpi_metrics(..., p_agent_type_name: 'louis')`
- `get_chart_data(..., p_agent_type_name: 'louis')`

**Critical**: MUST pass `p_agent_type_name: 'louis'` to all RPC calls to ensure only Louis data is returned.

---

### Arthur Dashboard (`/dashboard/arthur`)

**Purpose**: Shows detailed analytics for ONLY Arthur agent data (prospecting/reactivation).

**Layout**: Similar to Louis Dashboard

**KPIs** (Arthur-specific):
1. **Total Calls**
2. **Appointments Scheduled**
3. **Reactivation Rate**
4. **Cost per Conversion**
5. **Success Rate**

**Charts**: Similar to Louis, but with Arthur-specific data

**Data Source**:
- `get_arthur_kpi_metrics(...)`
- `get_arthur_chart_data(...)`

**Note**: Arthur has separate RPC functions due to different business logic.

---

## Dashboard Filters

All dashboards support the following filters:

### Date Range Filter

- **Start Date**: Beginning of date range
- **End Date**: End of date range
- **Quick Selectors**: Today, Last 7 Days, Last 30 Days, This Month, Last Month, This Year

**URL Parameters**: `?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD`

**Default**: Last 30 days

### Client Filter

- **Type**: Dropdown select
- **Options**: All clients accessible to the user (via RLS)
- **Format**: "Client Name"
- **Optional**: Can be left empty to show all clients

**URL Parameter**: `?clientId=UUID`

### Agent Filter

- **Type**: Dropdown select
- **Options**: All agent deployments of the dashboard's type accessible to the user
- **Format**: "Deployment Name - Client Name"
- **Optional**: Can be left empty to show all agents
- **Deduplication**: Uses `reduce()` to ensure unique keys (avoids React duplicate key errors)

**URL Parameter**: `?deploymentId=UUID`

**Example**:
```typescript
// Deduplication logic in ClientAgentFilter.tsx
const uniqueAgents = agents.reduce((acc, agent) => {
  if (!acc.find(a => a.id === agent.id)) {
    acc.push(agent);
  }
  return acc;
}, []);
```

---

## Data Flow Architecture

### High-Level Flow

```
User Interaction
    ↓
Dashboard Component (React)
    ↓
useDashboardFilters() Hook (URL-based state management)
    ↓
useLouisKPIs() / useLouisChartData() Hooks (React Query)
    ↓
fetchLouisKPIMetrics() / fetchLouisChartData() Functions
    ↓
Supabase Client (supabase.rpc())
    ↓
PostgreSQL RPC Functions (get_kpi_metrics, get_chart_data)
    ↓
v_agent_calls_enriched View
    ↓
agent_calls Table (with JOINs to deployments, types, clients)
    ↓
Row Level Security (RLS) Filters
    ↓
Data Returned to Client
```

### Detailed Component Flow

```typescript
// 1. Dashboard Component
<LouisDashboardClient />

// 2. Filter Hook (URL-based state)
const filters = useDashboardFilters();
// Returns: { startDate, endDate, clientId, deploymentId }

// 3. Data Fetching Hooks (React Query)
const { data: kpis } = useLouisKPIs(filters);
const { data: charts } = useLouisChartData(filters);

// 4. Fetch Functions
async function fetchLouisKPIMetrics(filters) {
  const { data } = await supabase.rpc('get_kpi_metrics', {
    p_start_date: filters.startDate,
    p_end_date: filters.endDate,
    p_client_id: filters.clientId || null,
    p_deployment_id: filters.deploymentId || null,
    p_agent_type_name: 'louis', // ← CRITICAL: Filters by agent type
  });
  return data;
}

// 5. Supabase RPC Function (PostgreSQL)
CREATE FUNCTION get_kpi_metrics(...)
RETURNS json AS $$
  SELECT json_build_object(
    'total_calls', COUNT(*),
    'answered_calls', COUNT(*) FILTER (WHERE answered = true),
    'appointments', COUNT(*) FILTER (WHERE appointment_scheduled = true),
    -- ... more metrics
  )
  FROM v_agent_calls_enriched vac
  JOIN agent_deployments ad ON vac.deployment_id = ad.id
  JOIN agent_types at ON ad.agent_type_id = at.id
  WHERE at.name = p_agent_type_name
    AND vac.started_at BETWEEN p_start_date AND p_end_date
    AND (p_client_id IS NULL OR ad.client_id = p_client_id)
    AND (p_deployment_id IS NULL OR vac.deployment_id = p_deployment_id)
$$ LANGUAGE sql;

// 6. View (v_agent_calls_enriched)
CREATE VIEW v_agent_calls_enriched AS
SELECT
  ac.*,
  -- Calculated fields
  (outcome NOT IN ('voicemail', 'call_failed', 'no_answer', ...)
   AND outcome IS NOT NULL) AS answered,
  (outcome = 'appointment_scheduled') AS appointment_scheduled
FROM agent_calls ac;

// 7. RLS Policies (automatically applied)
-- Only returns calls from deployments the user has access to
```

---

## Dashboard Components Structure

### File Organization

```
app/dashboard/
├── page.tsx                        # Global Dashboard (server component)
├── [agentType]/
│   ├── page.tsx                    # Dynamic route (louis, arthur)
│   ├── LouisDashboardClient.tsx    # Louis dashboard (client component)
│   └── ArthurDashboardClient.tsx   # Arthur dashboard (client component)

components/dashboard/
├── Cards/
│   ├── KPICard.tsx                 # Individual KPI metric card
│   ├── AgentTypeCard.tsx           # Agent type aggregate card (Global)
│   └── ClientCard.tsx              # Client aggregate card (Global)
├── Charts/
│   ├── CallVolumeChart.tsx         # Line/area chart for call volume
│   ├── EmotionChart.tsx            # Donut chart for emotions
│   ├── OutcomeChart.tsx            # Bar chart for outcomes
│   └── VoicemailByAgentChart.tsx   # Horizontal bar chart
└── Filters/
    ├── DateRangeFilter.tsx         # Date range picker with quick selectors
    ├── ClientAgentFilter.tsx       # Client + Agent dropdowns
    └── useDashboardFilters.ts      # URL-based filter hook

lib/queries/
├── louis.ts                        # Louis-specific queries
├── arthur.ts                       # Arthur-specific queries
└── global.ts                       # Global dashboard queries

lib/hooks/
└── useDashboardData.ts             # React Query hooks for data fetching

lib/types/
└── dashboard.ts                    # TypeScript types for dashboard data
```

### Component Responsibilities

**`LouisDashboardClient.tsx`**:
- Client-side component (uses hooks)
- Manages filter state via URL
- Fetches KPI and chart data
- Renders KPI cards and charts
- Handles loading/error states

**`KPICard.tsx`**:
- Displays single KPI metric
- Shows current value and comparison (vs previous period)
- Animated number transitions
- Glassmorphism design

**`CallVolumeChart.tsx`**:
- Renders Recharts LineChart/AreaChart
- Shows call volume over time (daily)
- Multiple series: Total Calls, Answered Calls, Appointments
- Responsive height and width

**`DateRangeFilter.tsx`**:
- Date range picker (start + end date)
- Quick selector buttons (Today, Last 7 Days, etc.)
- Updates URL parameters on change
- Validates date ranges

**`ClientAgentFilter.tsx`**:
- Client dropdown (fetches accessible clients via RLS)
- Agent dropdown (filtered by agent type)
- Deduplicates options to avoid React duplicate key errors
- Updates URL parameters on change

**`useDashboardFilters.ts`**:
- Custom hook for URL-based filter state
- Syncs filters with URL search params
- Provides `setFilters()` function
- Default values (last 30 days)

---

## KPI Calculations

### Critical Formulas (CORRECTED)

```sql
-- Total Calls
total_calls = COUNT(*)

-- Answered Calls (call was picked up, NOT voicemail/error)
answered_calls = COUNT(*) WHERE answered = true

-- RDV Pris (appointments scheduled)
appointments = COUNT(*) WHERE appointment_scheduled = true

-- Answer Rate (percentage of calls answered)
answer_rate = (answered_calls / total_calls) × 100

-- Conversion Rate (percentage of ANSWERED calls that became appointments)
conversion_rate = (appointments / ANSWERED_calls) × 100  ← NOT total_calls!

-- Acceptance Rate (of those who got the offer, how many accepted?)
acceptance_rate = appointments / (appointments + refused) × 100

-- Average Duration (only non-zero durations)
avg_duration = AVG(duration_seconds) WHERE duration_seconds > 0

-- Cost per Appointment
cost_per_appointment = SUM(cost) / appointments
```

### Calculated Fields (v_agent_calls_enriched)

**`answered` (boolean)**:
```sql
answered = outcome NOT IN (
  'voicemail',
  'call_failed',
  'no_answer',
  'busy',
  'not_available',
  'error'
) AND outcome IS NOT NULL
```

**`appointment_scheduled` (boolean)**:
```sql
appointment_scheduled = (outcome = 'appointment_scheduled')
```

**CRITICAL**: Do NOT use `metadata ? 'appointment_scheduled_at'` to check for appointments!
- This checks if the **KEY exists**, not if it has a **value**
- This caused the bug where 118 voicemail calls were counted as RDV instead of the real 13

---

## Common Pitfalls & Solutions

### Pitfall #1: Conversion Rate > 100%

**Problem**: Dashboard shows conversion rate of 200%+

**Cause**: Formula was `appointments / total_calls` instead of `appointments / answered_calls`

**Solution**: Always divide by `answered_calls`, not `total_calls`

**Correct Formula**:
```sql
CASE
  WHEN answered_calls > 0
  THEN (appointments::float / answered_calls * 100)::numeric(10,2)
  ELSE 0
END AS conversion_rate
```

---

### Pitfall #2: Louis Dashboard Shows Arthur Data

**Problem**: Dashboard Louis displays Arthur agent data

**Cause**: RPC functions didn't filter by `agent_type_name`

**Solution**: Added `p_agent_type_name` parameter to all RPC functions

**Correct Implementation**:
```sql
-- RPC Function
CREATE FUNCTION get_kpi_metrics(
  p_start_date date,
  p_end_date date,
  p_client_id uuid DEFAULT NULL,
  p_deployment_id uuid DEFAULT NULL,
  p_agent_type_name text DEFAULT NULL  ← CRITICAL parameter
)
...
WHERE at.name = p_agent_type_name  ← Filter by agent type

-- Frontend Call
supabase.rpc('get_kpi_metrics', {
  ...filters,
  p_agent_type_name: 'louis'  ← MUST pass this!
})
```

---

### Pitfall #3: Duplicate Keys in Filters

**Problem**: React errors about duplicate keys in ClientAgentFilter

**Cause**: Database views returning duplicate rows

**Solution**: Deduplicate arrays in frontend using `reduce()`

**Correct Implementation**:
```typescript
const uniqueAgents = agents.reduce((acc, agent) => {
  if (!acc.find(a => a.id === agent.id)) {
    acc.push(agent);
  }
  return acc;
}, [] as Agent[]);
```

---

### Pitfall #4: Metadata Key Check

**Problem**: Using `metadata ? 'appointment_scheduled_at'` to check for appointments

**Cause**: `?` operator checks if KEY exists, not if it has a value

**Solution**: Use ONLY `outcome = 'appointment_scheduled'`

**Wrong**:
```sql
appointment_scheduled = (metadata ? 'appointment_scheduled_at')  ❌
-- This returns TRUE even if the key exists with NULL value!
```

**Correct**:
```sql
appointment_scheduled = (outcome = 'appointment_scheduled')  ✅
```

---

## Dashboard Expectations

### User Expectations

1. **Accurate KPIs**: Numbers must match real data in `agent_calls` table
2. **Agent Separation**: Louis dashboard shows ONLY Louis data, never Arthur
3. **Real-time Filters**: Changing date/client/agent filters updates all data
4. **No Mixed Data**: Each dashboard is isolated by agent type
5. **Logical Values**:
   - Conversion rate ≤ 100%
   - RDV ≤ Answered Calls
   - Answered Calls ≤ Total Calls

### Design Expectations

- **Dark theme** with glassmorphism cards
- **Responsive layout** (mobile-first)
- **Smooth transitions** and loading states
- **Charts fill container** height properly
- **No scroll on desktop** (2x2 grid for charts)
- **Accessible colors** and contrast
- **Consistent spacing** (Tailwind scale)

---

## Testing Dashboard Changes

### Manual Testing Checklist

1. **Run dev server**: `npm run dev`
2. **Navigate to dashboard**: Use MCP Playwright `browser_navigate` to `http://localhost:3000/dashboard/louis`
3. **Take snapshot**: Use `browser_snapshot` to verify UI
4. **Verify KPIs**: Check numbers match database queries
5. **Test filters**:
   - Change date range → verify data updates
   - Change client → verify filtering works
   - Change agent → verify single deployment data
6. **Test responsive**: Resize browser to mobile/tablet/desktop
7. **Check console**: No errors or warnings

### Database Verification Queries

```sql
-- Verify total calls for Louis in date range
SELECT COUNT(*) AS total_calls
FROM v_agent_calls_enriched vac
JOIN agent_deployments ad ON vac.deployment_id = ad.id
JOIN agent_types at ON ad.agent_type_id = at.id
WHERE at.name = 'louis'
  AND vac.started_at BETWEEN '2024-01-01' AND '2024-01-31';

-- Verify answered calls
SELECT COUNT(*) AS answered_calls
FROM v_agent_calls_enriched vac
JOIN agent_deployments ad ON vac.deployment_id = ad.id
JOIN agent_types at ON ad.agent_type_id = at.id
WHERE at.name = 'louis'
  AND vac.started_at BETWEEN '2024-01-01' AND '2024-01-31'
  AND vac.answered = true;

-- Verify appointments
SELECT COUNT(*) AS appointments
FROM v_agent_calls_enriched vac
JOIN agent_deployments ad ON vac.deployment_id = ad.id
JOIN agent_types at ON ad.agent_type_id = at.id
WHERE at.name = 'louis'
  AND vac.started_at BETWEEN '2024-01-01' AND '2024-01-31'
  AND vac.appointment_scheduled = true;

-- Calculate conversion rate manually
SELECT
  COUNT(*) FILTER (WHERE answered = true) AS answered_calls,
  COUNT(*) FILTER (WHERE appointment_scheduled = true) AS appointments,
  ROUND(
    COUNT(*) FILTER (WHERE appointment_scheduled = true)::numeric /
    NULLIF(COUNT(*) FILTER (WHERE answered = true), 0) * 100,
    2
  ) AS conversion_rate
FROM v_agent_calls_enriched vac
JOIN agent_deployments ad ON vac.deployment_id = ad.id
JOIN agent_types at ON ad.agent_type_id = at.id
WHERE at.name = 'louis'
  AND vac.started_at BETWEEN '2024-01-01' AND '2024-01-31';
```

---

## Common Tasks

### Task: Add New KPI

1. **Update RPC function** to calculate new metric
   ```sql
   -- Add to get_kpi_metrics()
   'new_metric', COUNT(*) FILTER (WHERE condition)
   ```

2. **Update TypeScript types** in `lib/types/dashboard.ts`
   ```typescript
   export interface LouisKPIMetrics {
     // ... existing fields
     new_metric: number;
   }
   ```

3. **Update frontend component** to display KPI
   ```typescript
   <KPICard
     title="New Metric"
     value={kpis.new_metric}
     previousValue={kpis.previous_new_metric}
     format="number"
   />
   ```

4. **Create migration file** for SQL changes
   ```bash
   # Create migration
   supabase/migrations/20240115_add_new_metric.sql
   ```

---

### Task: Fix KPI Calculation

1. **Query database** to understand current logic
   ```sql
   -- Check current calculation
   SELECT * FROM get_kpi_metrics(...);
   ```

2. **Update view or RPC function** with corrected formula
   ```sql
   -- Fix formula
   CREATE OR REPLACE FUNCTION get_kpi_metrics(...)
   ```

3. **Create migration** with corrected formula
   ```sql
   -- Migration: Fix [metric] calculation
   -- Changes: Updated formula from X to Y
   ```

4. **Test with verification queries**
   ```sql
   -- Verify new calculation
   SELECT ...; -- Include in migration as comment
   ```

---

### Task: Add New Chart

1. **Update `get_chart_data` RPC function**
   ```sql
   'new_chart_data', (
     SELECT json_agg(row_to_json(t))
     FROM (
       SELECT ...
     ) t
   )
   ```

2. **Create chart component** in `components/dashboard/Charts/`
   ```typescript
   export function NewChart({ data }: { data: NewChartData[] }) {
     return (
       <ResponsiveContainer width="100%" height="100%">
         <BarChart data={data}>
           {/* ... */}
         </BarChart>
       </ResponsiveContainer>
     );
   }
   ```

3. **Add chart to dashboard layout**
   ```typescript
   <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
     {/* ... existing charts */}
     <Card>
       <NewChart data={chartData.new_chart_data} />
     </Card>
   </div>
   ```

4. **Update ChartData type**
   ```typescript
   export interface LouisChartData {
     // ... existing fields
     new_chart_data: NewChartDataPoint[];
   }
   ```

---

## Performance Considerations

### Database Indexes

Ensure indexes exist on frequently queried columns:
```sql
-- agent_calls indexes
CREATE INDEX idx_agent_calls_deployment_id ON agent_calls(deployment_id);
CREATE INDEX idx_agent_calls_started_at ON agent_calls(started_at);
CREATE INDEX idx_agent_calls_outcome ON agent_calls(outcome);

-- agent_deployments indexes
CREATE INDEX idx_agent_deployments_client_id ON agent_deployments(client_id);
CREATE INDEX idx_agent_deployments_agent_type_id ON agent_deployments(agent_type_id);
```

### React Query Caching

Use appropriate `staleTime` and `cacheTime`:
```typescript
const { data: kpis } = useQuery({
  queryKey: ['louis-kpis', filters],
  queryFn: () => fetchLouisKPIMetrics(filters),
  staleTime: 5 * 60 * 1000, // 5 minutes
  cacheTime: 10 * 60 * 1000, // 10 minutes
});
```

### Component Optimization

- Use `React.memo` for expensive chart components
- Debounce filter changes (date picker)
- Lazy load charts (code splitting)
- Use CSS transitions instead of JS animations

---

## Related Documentation

- **Database Reference**: See `docs/DATABASE_REFERENCE.md` for complete schema
- **Known Issues**: See `docs/KNOWN_ISSUES.md` for bug history and solutions
- **Migration Guide**: See `CLAUDE.md` for migration best practices
