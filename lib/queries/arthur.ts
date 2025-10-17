import { createClient } from '@/lib/supabase/client'
import type {
  ArthurKPIMetrics,
  ArthurChartData,
  ArthurCallEnriched,
} from '@/lib/types/arthur'

/**
 * Fetch Arthur KPI metrics with current and previous period comparison
 *
 * @param startDate - Start of current period
 * @param endDate - End of current period
 * @param clientId - Optional client filter (UUID)
 * @param agentTypeId - Optional agent_type filter (UUID) ⚠️ NOT agentId
 * @returns Promise<ArthurKPIMetrics>
 */
export async function fetchArthurKPIMetrics(
  startDate: Date,
  endDate: Date,
  clientId?: string | null,
  agentTypeId?: string | null
): Promise<ArthurKPIMetrics> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_arthur_kpi_metrics', {
    p_start_date: startDate.toISOString(),
    p_end_date: endDate.toISOString(),
    p_client_id: clientId || null,
    p_agent_type_id: agentTypeId || null, // ⚠️ CRITICAL: p_agent_type_id, NOT p_agent_id
  })

  if (error) {
    console.error('Error fetching Arthur KPI metrics:', error)
    throw error
  }

  return data as ArthurKPIMetrics
}

/**
 * Fetch Arthur chart data (4 datasets)
 *
 * @param startDate - Start date
 * @param endDate - End date
 * @param clientId - Optional client filter (UUID)
 * @param agentTypeId - Optional agent_type filter (UUID) ⚠️ NOT agentId
 * @returns Promise<ArthurChartData>
 */
export async function fetchArthurChartData(
  startDate: Date,
  endDate: Date,
  clientId?: string | null,
  agentTypeId?: string | null
): Promise<ArthurChartData> {
  const supabase = createClient()

  const { data, error } = await supabase.rpc('get_arthur_chart_data', {
    p_start_date: startDate.toISOString(),
    p_end_date: endDate.toISOString(),
    p_client_id: clientId || null,
    p_agent_type_id: agentTypeId || null, // ⚠️ CRITICAL: p_agent_type_id, NOT p_agent_id
  })

  if (error) {
    console.error('Error fetching Arthur chart data:', error)
    throw error
  }

  return data as ArthurChartData
}

/**
 * Export Arthur calls to CSV with BOM for Excel compatibility
 *
 * @param startDate - Start date
 * @param endDate - End date
 * @param clientId - Optional client filter
 * @param agentTypeId - Optional agent_type filter
 * @returns Promise<string> CSV content with BOM
 */
export async function exportArthurCallsToCSV(
  startDate: Date,
  endDate: Date,
  clientId?: string | null,
  agentTypeId?: string | null
): Promise<string> {
  const supabase = createClient()

  let query = supabase
    .from('v_arthur_calls_enriched')
    .select('*')
    .gte('started_at', startDate.toISOString())
    .lte('started_at', endDate.toISOString())
    .order('started_at', { ascending: false })

  if (clientId) {
    query = query.eq('client_id', clientId)
  }

  if (agentTypeId) {
    query = query.eq('agent_type_id', agentTypeId)
  }

  const { data, error } = await query

  if (error) {
    console.error('Error fetching Arthur calls for export:', error)
    throw error
  }

  // Convert to CSV
  const headers = [
    'Date',
    'Client',
    'Prospect',
    'Entreprise',
    'Téléphone',
    'Email',
    'Tentative',
    'Durée (s)',
    'Coût (€)',
    'Outcome',
    'Statut Séquence',
    'RDV Planifié',
    'Segment IA',
  ]

  const rows = (data as ArthurCallEnriched[]).map((call) => [
    new Date(call.started_at).toLocaleString('fr-FR'),
    call.client_name || '',
    `${call.first_name} ${call.last_name}`,
    call.company || '',
    call.phone || '',
    call.email || '',
    call.attempt_label || '',
    call.duration_seconds || '',
    call.cost ? call.cost.toFixed(2) : '',
    call.call_outcome || '',
    call.sequence_status || '',
    call.appointment_scheduled_at
      ? new Date(call.appointment_scheduled_at).toLocaleString('fr-FR')
      : '',
    call.ai_segment || 'Non segmenté',
  ])

  const csv = [
    headers.join(','),
    ...rows.map((row) => row.map((cell) => `"${cell}"`).join(',')),
  ].join('\n')

  // Add BOM for Excel compatibility
  return '\ufeff' + csv
}
