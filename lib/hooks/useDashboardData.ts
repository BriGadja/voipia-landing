import { useQuery, UseQueryResult } from '@tanstack/react-query'
import type {
  DashboardFilters,
  KPIMetrics,
  ChartData,
  AccessibleClient,
  AccessibleAgent,
  AgentTypePerformance,
  TopClientData,
  AgentPerformanceData,
} from '@/lib/types/dashboard'
import {
  fetchAccessibleClients,
  fetchAccessibleAgents,
  fetchGlobalKPIs,
  fetchGlobalChartData,
  fetchTopClients,
  fetchAgentTypePerformance,
} from '@/lib/queries/global'
import {
  fetchLouisKPIMetrics,
  fetchLouisChartData,
  fetchLouisAgentPerformance,
} from '@/lib/queries/louis'

// Query configuration constants
const STALE_TIME = 3600000 // 1 hour
const REFETCH_INTERVAL = 3600000 // 1 hour

/**
 * Hook to fetch all clients accessible by the authenticated user
 * Uses v_user_accessible_clients view with RLS
 */
export function useAccessibleClients(): UseQueryResult<AccessibleClient[]> {
  return useQuery({
    queryKey: ['accessible-clients'],
    queryFn: fetchAccessibleClients,
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}

/**
 * Hook to fetch all agent deployments accessible by the authenticated user
 * Uses v_user_accessible_agents view with RLS
 * @param clientIds - Optional filter by client IDs
 * @param agentTypeName - Optional filter by agent type
 */
export function useAccessibleAgents(
  clientIds?: string[],
  agentTypeName?: 'louis' | 'arthur' | 'alexandra' | null
): UseQueryResult<AccessibleAgent[]> {
  return useQuery({
    queryKey: ['accessible-agents', clientIds, agentTypeName],
    queryFn: () => fetchAccessibleAgents(clientIds, agentTypeName),
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}

/**
 * Hook to fetch Global KPI metrics
 * @param filters - Dashboard filters
 */
export function useGlobalKPIs(
  filters: DashboardFilters
): UseQueryResult<KPIMetrics> {
  return useQuery({
    queryKey: ['global-kpis', filters],
    queryFn: () => fetchGlobalKPIs(filters),
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}

/**
 * Hook to fetch Global chart data
 * @param filters - Dashboard filters
 */
export function useGlobalChartData(
  filters: DashboardFilters
): UseQueryResult<ChartData> {
  return useQuery({
    queryKey: ['global-chart-data', filters],
    queryFn: () => fetchGlobalChartData(filters),
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}

/**
 * Hook to fetch top clients by performance
 * @param filters - Dashboard filters
 * @param limit - Maximum number of clients to return
 */
export function useTopClients(
  filters: DashboardFilters,
  limit: number = 10
): UseQueryResult<TopClientData[]> {
  return useQuery({
    queryKey: ['top-clients', filters, limit],
    queryFn: () => fetchTopClients(filters, limit),
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}

/**
 * Hook to fetch agent type performance comparison
 * @param filters - Dashboard filters
 */
export function useAgentTypePerformance(
  filters: DashboardFilters
): UseQueryResult<AgentTypePerformance[]> {
  return useQuery({
    queryKey: ['agent-type-performance', filters],
    queryFn: () => fetchAgentTypePerformance(filters),
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}

/**
 * Hook to fetch Louis KPI metrics
 * @param filters - Dashboard filters
 */
export function useLouisKPIs(
  filters: DashboardFilters
): UseQueryResult<KPIMetrics> {
  return useQuery({
    queryKey: ['louis-kpis', filters],
    queryFn: () => fetchLouisKPIMetrics(filters),
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}

/**
 * Hook to fetch Louis chart data
 * @param filters - Dashboard filters
 */
export function useLouisChartData(
  filters: DashboardFilters
): UseQueryResult<ChartData> {
  return useQuery({
    queryKey: ['louis-chart-data', filters],
    queryFn: () => fetchLouisChartData(filters),
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}

/**
 * Hook to fetch Louis agent performance
 * @param filters - Dashboard filters
 */
export function useLouisAgentPerformance(
  filters: DashboardFilters
): UseQueryResult<AgentPerformanceData[]> {
  return useQuery({
    queryKey: ['louis-agent-performance', filters],
    queryFn: () => fetchLouisAgentPerformance(filters),
    staleTime: STALE_TIME,
    refetchInterval: REFETCH_INTERVAL,
  })
}
