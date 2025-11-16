// Financial Dashboard React Hooks
// Generated: 2025-01-16

import { useQuery, UseQueryResult } from "@tanstack/react-query";
import type {
  FinancialKPIResponse,
  FinancialFilters,
  DrilldownLevel,
  ClientFinancialData,
  AgentTypeFinancialData,
  DeploymentFinancialData,
  ChannelDrilldownResponse,
} from "@/lib/types/financial";
import {
  fetchFinancialKPIMetrics,
  fetchClientBreakdown,
  fetchAgentTypeBreakdown,
  fetchDeploymentBreakdown,
  fetchChannelBreakdown,
} from "@/lib/queries/financial";

// ============================================================================
// Query Keys
// ============================================================================

const FINANCIAL_QUERY_KEYS = {
  kpis: (filters: FinancialFilters) => ["financial", "kpis", filters] as const,
  clientBreakdown: (filters: FinancialFilters) =>
    ["financial", "client-breakdown", filters] as const,
  agentTypeBreakdown: (filters: FinancialFilters) =>
    ["financial", "agent-type-breakdown", filters] as const,
  deploymentBreakdown: (filters: FinancialFilters) =>
    ["financial", "deployment-breakdown", filters] as const,
  channelBreakdown: (filters: FinancialFilters) =>
    ["financial", "channel-breakdown", filters] as const,
} as const;

// ============================================================================
// KPI Hooks
// ============================================================================

/**
 * Fetch financial KPI metrics with period comparison
 */
export function useFinancialKPIs(
  filters: FinancialFilters
): UseQueryResult<FinancialKPIResponse, Error> {
  return useQuery({
    queryKey: FINANCIAL_QUERY_KEYS.kpis(filters),
    queryFn: () => fetchFinancialKPIMetrics(filters),
    staleTime: 1000 * 60 * 5, // 5 minutes
    refetchOnWindowFocus: false,
  });
}

// ============================================================================
// Drilldown Hooks
// ============================================================================

/**
 * Fetch client-level financial breakdown
 */
export function useClientBreakdown(
  filters: FinancialFilters
): UseQueryResult<ClientFinancialData[], Error> {
  return useQuery({
    queryKey: FINANCIAL_QUERY_KEYS.clientBreakdown(filters),
    queryFn: () => fetchClientBreakdown(filters),
    staleTime: 1000 * 60 * 5, // 5 minutes
    refetchOnWindowFocus: false,
  });
}

/**
 * Fetch agent type-level financial breakdown
 */
export function useAgentTypeBreakdown(
  filters: FinancialFilters
): UseQueryResult<AgentTypeFinancialData[], Error> {
  return useQuery({
    queryKey: FINANCIAL_QUERY_KEYS.agentTypeBreakdown(filters),
    queryFn: () => fetchAgentTypeBreakdown(filters),
    staleTime: 1000 * 60 * 5, // 5 minutes
    refetchOnWindowFocus: false,
  });
}

/**
 * Fetch deployment-level financial breakdown
 */
export function useDeploymentBreakdown(
  filters: FinancialFilters
): UseQueryResult<DeploymentFinancialData[], Error> {
  return useQuery({
    queryKey: FINANCIAL_QUERY_KEYS.deploymentBreakdown(filters),
    queryFn: () => fetchDeploymentBreakdown(filters),
    staleTime: 1000 * 60 * 5, // 5 minutes
    refetchOnWindowFocus: false,
  });
}

/**
 * Fetch channel-level financial breakdown
 */
export function useChannelBreakdown(
  filters: FinancialFilters
): UseQueryResult<ChannelDrilldownResponse, Error> {
  return useQuery({
    queryKey: FINANCIAL_QUERY_KEYS.channelBreakdown(filters),
    queryFn: () => fetchChannelBreakdown(filters),
    staleTime: 1000 * 60 * 5, // 5 minutes
    refetchOnWindowFocus: false,
  });
}

// ============================================================================
// Combined Hook for All Financial Data
// ============================================================================

/**
 * Fetch all financial data at once
 * Useful for dashboard pages that need multiple data sources
 */
export function useFinancialDashboard(filters: FinancialFilters) {
  const kpis = useFinancialKPIs(filters);
  const clientBreakdown = useClientBreakdown(filters);
  const agentTypeBreakdown = useAgentTypeBreakdown(filters);
  const deploymentBreakdown = useDeploymentBreakdown(filters);
  const channelBreakdown = useChannelBreakdown(filters);

  return {
    kpis,
    clientBreakdown,
    agentTypeBreakdown,
    deploymentBreakdown,
    channelBreakdown,
    isLoading:
      kpis.isLoading ||
      clientBreakdown.isLoading ||
      agentTypeBreakdown.isLoading ||
      deploymentBreakdown.isLoading ||
      channelBreakdown.isLoading,
    isError:
      kpis.isError ||
      clientBreakdown.isError ||
      agentTypeBreakdown.isError ||
      deploymentBreakdown.isError ||
      channelBreakdown.isError,
    error:
      kpis.error ||
      clientBreakdown.error ||
      agentTypeBreakdown.error ||
      deploymentBreakdown.error ||
      channelBreakdown.error,
  };
}
