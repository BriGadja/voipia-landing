import { createClient } from '@/lib/supabase/client'
import type { KPIMetrics, ChartData, Client, Agent } from '@/lib/types/database'

export async function fetchKPIMetrics(
  startDate: Date,
  endDate: Date,
  clientId?: string | null,
  agentId?: string | null
): Promise<KPIMetrics> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_kpi_metrics', {
    p_start_date: startDate.toISOString(),
    p_end_date: endDate.toISOString(),
    p_client_id: clientId || null,
    p_agent_id: agentId || null,
  })

  if (error) {
    console.error('Error fetching KPI metrics:', error)
    throw error
  }

  return data as KPIMetrics
}

export async function fetchChartData(
  startDate: Date,
  endDate: Date,
  clientId?: string | null,
  agentId?: string | null
): Promise<ChartData> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_chart_data', {
    p_start_date: startDate.toISOString(),
    p_end_date: endDate.toISOString(),
    p_client_id: clientId || null,
    p_agent_id: agentId || null,
  })

  if (error) {
    console.error('Error fetching chart data:', error)
    throw error
  }

  return data as ChartData
}

export async function fetchClients(): Promise<Client[]> {
  const supabase = createClient()

  const { data, error } = await supabase
    .from('clients')
    .select('*')
    .order('name')

  if (error) {
    console.error('Error fetching clients:', error)
    throw error
  }

  return data
}

export async function fetchAgents(clientIds?: string[]): Promise<Agent[]> {
  const supabase = createClient()

  let query = supabase
    .from('agents')
    .select('*')
    .eq('status', 'active')
    .order('name')

  if (clientIds && clientIds.length > 0) {
    query = query.in('client_id', clientIds)
  }

  const { data, error } = await query

  if (error) {
    console.error('Error fetching agents:', error)
    throw error
  }

  return data
}

export async function exportCallsToCSV(
  startDate: Date,
  endDate: Date,
  clientId?: string | null,
  agentId?: string | null
): Promise<string> {
  const supabase = createClient()

  let query = supabase
    .from('calls')
    .select(`
      *,
      clients(name),
      agents(name)
    `)
    .gte('started_at', startDate.toISOString())
    .lte('started_at', endDate.toISOString())
    .order('started_at', { ascending: false })

  if (clientId) {
    query = query.eq('client_id', clientId)
  }

  if (agentId) {
    query = query.eq('agent_id', agentId)
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
    'Agent',
    'First Name',
    'Last Name',
    'Phone',
    'Email',
    'Duration (s)',
    'Cost (€)',
    'Outcome',
    'Emotion',
    'RDV Scheduled',
  ]

  const rows = data.map((call: any) => [
    new Date(call.started_at).toLocaleString('fr-FR'),
    call.clients?.name || '',
    call.agents?.name || '',
    call.first_name || '',
    call.last_name || '',
    call.phone || '',
    call.email || '',
    call.duration_seconds || '',
    call.cost ? call.cost.toFixed(2) : '',
    call.call_outcome || '',
    call.emotion || '',
    call.appointment_scheduled_at
      ? new Date(call.appointment_scheduled_at).toLocaleString('fr-FR')
      : '',
  ])

  const csv = [
    headers.join(','),
    ...rows.map((row) => row.map((cell) => `"${cell}"`).join(',')),
  ].join('\n')

  // Add BOM for Excel compatibility
  return '\ufeff' + csv
}
