import { createClient } from '@/lib/supabase/client'
import type {
  DashboardFilters,
  KPIMetrics,
  ChartData,
  AccessibleClient,
  AccessibleAgent,
  AgentTypePerformance,
  TopClientData,
  ClientCardData,
  AgentCardData,
  AgentTypeCardData,
} from '@/lib/types/dashboard'

/**
 * Fetch all clients accessible by the authenticated user
 * Uses v_user_accessible_clients view with RLS
 */
export async function fetchAccessibleClients(): Promise<AccessibleClient[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .from('v_user_accessible_clients')
    .select('*')
    .order('client_name')

  if (error) {
    console.error('Error fetching accessible clients:', error)
    throw error
  }

  return data as AccessibleClient[]
}

/**
 * Fetch all agent deployments accessible by the authenticated user
 * Uses v_user_accessible_agents view with RLS
 * @param clientIds - Optional filter by client IDs
 * @param agentTypeName - Optional filter by agent type (louis, arthur, alexandra)
 */
export async function fetchAccessibleAgents(
  clientIds?: string[],
  agentTypeName?: 'louis' | 'arthur' | 'alexandra' | null
): Promise<AccessibleAgent[]> {
  const supabase = createClient()

  let query = supabase
    .from('v_user_accessible_agents')
    .select('*')
    .order('client_name')
    .order('deployment_name')

  if (clientIds && clientIds.length > 0) {
    query = query.in('client_id', clientIds)
  }

  if (agentTypeName) {
    query = query.eq('agent_type_name', agentTypeName)
  }

  const { data, error } = await query

  if (error) {
    console.error('Error fetching accessible agents:', error)
    throw error
  }

  return data as AccessibleAgent[]
}

/**
 * Fetch Global KPI metrics using RPC function
 * Returns current period and previous period comparison
 * @param filters - Dashboard filters (clientIds, deploymentId, agentTypeName, startDate, endDate)
 */
export async function fetchGlobalKPIs(
  filters: DashboardFilters
): Promise<KPIMetrics> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_global_kpis', {
    p_start_date: filters.startDate,
    p_end_date: filters.endDate,
    p_client_ids: filters.clientIds.length > 0 ? filters.clientIds : null,
    p_deployment_id: filters.deploymentId || null,
    p_agent_type_name: filters.agentTypeName || null,
  })

  if (error) {
    console.error('Error fetching global KPIs:', error)
    throw error
  }

  return data as KPIMetrics
}

/**
 * Fetch Global chart data using RPC function
 * Returns call volume by day, outcome distribution, emotion distribution, etc.
 * @param filters - Dashboard filters (clientIds, deploymentId, agentTypeName, startDate, endDate)
 */
export async function fetchGlobalChartData(
  filters: DashboardFilters
): Promise<ChartData> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_global_chart_data', {
    p_start_date: filters.startDate,
    p_end_date: filters.endDate,
    p_client_ids: filters.clientIds.length > 0 ? filters.clientIds : null,
    p_deployment_id: filters.deploymentId || null,
    p_agent_type_name: filters.agentTypeName || null,
  })

  if (error) {
    console.error('Error fetching global chart data:', error)
    throw error
  }

  return data as ChartData
}

/**
 * Fetch top clients by performance
 * Uses v_global_top_clients view
 * @param filters - Dashboard filters
 * @param limit - Maximum number of clients to return (default: 10)
 */
export async function fetchTopClients(
  filters: DashboardFilters,
  limit: number = 10
): Promise<TopClientData[]> {
  const supabase = createClient()

  let query = supabase
    .from('v_global_top_clients')
    .select('*')
    .gte('started_at', filters.startDate)
    .lte('started_at', filters.endDate)
    .order('total_calls', { ascending: false })
    .limit(limit)

  if (filters.clientIds.length > 0) {
    query = query.in('client_id', filters.clientIds)
  }

  if (filters.agentTypeName) {
    query = query.eq('agent_type_name', filters.agentTypeName)
  }

  const { data, error } = await query

  if (error) {
    console.error('Error fetching top clients:', error)
    throw error
  }

  return data as TopClientData[]
}

/**
 * Fetch agent type performance comparison
 * Uses v_global_agent_type_performance view
 * @param filters - Dashboard filters
 */
export async function fetchAgentTypePerformance(
  filters: DashboardFilters
): Promise<AgentTypePerformance[]> {
  const supabase = createClient()

  let query = supabase
    .from('v_global_agent_type_performance')
    .select('*')
    .order('total_calls', { ascending: false })

  if (filters.clientIds.length > 0) {
    query = query.in('client_id', filters.clientIds)
  }

  const { data, error } = await query

  if (error) {
    console.error('Error fetching agent type performance:', error)
    throw error
  }

  return data as AgentTypePerformance[]
}

/**
 * Fetch client card data with aggregated metrics for the dashboard
 * Uses RPC function get_client_cards_data
 * @param filters - Dashboard filters (startDate, endDate)
 */
export async function fetchClientCardsData(
  filters: DashboardFilters
): Promise<ClientCardData[]> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_client_cards_data', {
    p_start_date: filters.startDate,
    p_end_date: filters.endDate,
  })

  if (error) {
    console.error('Error fetching client cards data:', error)
    throw error
  }

  return data as ClientCardData[]
}

/**
 * Fetch agent card data with aggregated metrics for the dashboard
 * Uses RPC function get_agent_cards_data
 * @param filters - Dashboard filters (startDate, endDate, optional clientIds)
 */
export async function fetchAgentCardsData(
  filters: DashboardFilters
): Promise<AgentCardData[]> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_agent_cards_data', {
    p_start_date: filters.startDate,
    p_end_date: filters.endDate,
    p_client_ids: filters.clientIds.length > 0 ? filters.clientIds : null,
  })

  if (error) {
    console.error('Error fetching agent cards data:', error)
    throw error
  }

  return data as AgentCardData[]
}

/**
 * Fetch agent type card data with aggregated metrics for ALL deployments of each agent type
 * Uses RPC function get_agent_type_cards_data
 * Returns one card per agent type (e.g., one "Louis" card for all Louis deployments)
 * @param filters - Dashboard filters (startDate, endDate, optional clientIds)
 */
export async function fetchAgentTypeCardsData(
  filters: DashboardFilters
): Promise<AgentTypeCardData[]> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_agent_type_cards_data', {
    p_start_date: filters.startDate,
    p_end_date: filters.endDate,
    p_client_ids: filters.clientIds.length > 0 ? filters.clientIds : null,
  })

  if (error) {
    console.error('Error fetching agent type cards data:', error)
    throw error
  }

  return data as AgentTypeCardData[]
}

/**
 * Determine the default dashboard destination for a user
 * Returns null if user should see global dashboard
 * Returns agent type name if user should be redirected to specific agent dashboard
 *
 * Logic:
 * - If user has access to >= 2 clients OR >= 2 agents → Global dashboard (null)
 * - If user has access to exactly 1 agent → Redirect to that agent's dashboard
 * - Otherwise → Global dashboard (null) as fallback
 */
export async function getDashboardDestination(): Promise<{
  shouldRedirect: boolean
  agentType?: 'louis' | 'arthur' | 'alexandra'
}> {
  try {
    // Fetch accessible clients and agents
    const [clients, agents] = await Promise.all([
      fetchAccessibleClients(),
      fetchAccessibleAgents(),
    ])

    // If user has 2+ clients or 2+ agents, show global dashboard
    if (clients.length >= 2 || agents.length >= 2) {
      return { shouldRedirect: false }
    }

    // If user has exactly 1 agent, redirect to that agent's dashboard
    if (agents.length === 1) {
      const agentType = agents[0].agent_type_name
      return {
        shouldRedirect: true,
        agentType: agentType as 'louis' | 'arthur' | 'alexandra',
      }
    }

    // Fallback: show global dashboard
    return { shouldRedirect: false }
  } catch (error) {
    console.error('Error determining dashboard destination:', error)
    // On error, default to global dashboard
    return { shouldRedirect: false }
  }
}

/**
 * Export global dashboard data to CSV
 * @param filters - Dashboard filters
 */
export async function exportGlobalCallsToCSV(
  filters: DashboardFilters
): Promise<string> {
  const supabase = createClient()

  let query = supabase
    .from('agent_calls')
    .select(`
      *,
      agent_deployments!inner(
        name,
        slug,
        client_id,
        clients(name, industry),
        agent_types!inner(name, display_name)
      )
    `)
    .gte('started_at', filters.startDate)
    .lte('started_at', filters.endDate)
    .order('started_at', { ascending: false })

  if (filters.clientIds.length > 0) {
    query = query.in('agent_deployments.client_id', filters.clientIds)
  }

  if (filters.deploymentId) {
    query = query.eq('deployment_id', filters.deploymentId)
  }

  if (filters.agentTypeName) {
    query = query.eq('agent_deployments.agent_types.name', filters.agentTypeName)
  }

  const { data, error } = await query

  if (error) {
    console.error('Error fetching calls for export:', error)
    throw error
  }

  // Convert to CSV
  const headers = [
    'Date',
    'Client',
    'Industry',
    'Agent Type',
    'Agent Name',
    'First Name',
    'Last Name',
    'Phone',
    'Email',
    'Duration (s)',
    'Cost (€)',
    'Outcome',
    'Emotion',
    'Answered',
    'RDV Scheduled',
  ]

  const rows = data.map((call: any) => [
    new Date(call.started_at).toLocaleString('fr-FR'),
    call.agent_deployments?.clients?.name || '',
    call.agent_deployments?.clients?.industry || '',
    call.agent_deployments?.agent_types?.display_name || '',
    call.agent_deployments?.name || '',
    call.first_name || '',
    call.last_name || '',
    call.phone_number || '',
    call.email || '',
    call.duration_seconds || '',
    call.cost ? call.cost.toFixed(2) : '',
    call.outcome || '',
    call.emotion || '',
    call.answered ? 'Oui' : 'Non',
    call.metadata?.appointment_scheduled_at
      ? new Date(call.metadata.appointment_scheduled_at).toLocaleString('fr-FR')
      : '',
  ])

  const csv = [
    headers.join(','),
    ...rows.map((row) => row.map((cell) => `"${cell}"`).join(',')),
  ].join('\n')

  // Add BOM for Excel compatibility
  return '\ufeff' + csv
}
