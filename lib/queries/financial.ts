// Financial Dashboard Queries
// Generated: 2025-01-16

import { createClient } from "@/lib/supabase/client";
import type {
  FinancialKPIResponse,
  FinancialFilters,
  DrilldownLevel,
  DrilldownData,
  ClientFinancialData,
  AgentTypeFinancialData,
  DeploymentFinancialData,
  ChannelDrilldownResponse,
} from "@/lib/types/financial";

// ============================================================================
// Fetch Financial KPI Metrics
// ============================================================================

export async function fetchFinancialKPIMetrics(
  filters: FinancialFilters
): Promise<FinancialKPIResponse> {
  const supabase = createClient();

  const { data, error } = await supabase.rpc("get_financial_kpi_metrics", {
    p_start_date: filters.startDate,
    p_end_date: filters.endDate,
    p_client_id: filters.clientId || null,
    p_agent_type_name: filters.agentTypeName || null,
    p_deployment_id: filters.deploymentId || null,
  });

  if (error) {
    console.error("Error fetching financial KPI metrics:", error);
    throw new Error(`Failed to fetch financial KPI metrics: ${error.message}`);
  }

  return data as FinancialKPIResponse;
}

// ============================================================================
// Fetch Financial Drilldown Data
// ============================================================================

export async function fetchFinancialDrilldown(
  filters: FinancialFilters,
  level: DrilldownLevel
): Promise<DrilldownData> {
  const supabase = createClient();

  const { data, error } = await supabase.rpc("get_financial_drilldown", {
    p_start_date: filters.startDate,
    p_end_date: filters.endDate,
    p_level: level,
    p_client_id: filters.clientId || null,
    p_agent_type_name: filters.agentTypeName || null,
    p_deployment_id: filters.deploymentId || null,
  });

  if (error) {
    console.error(`Error fetching ${level} drilldown:`, error);
    throw new Error(`Failed to fetch ${level} drilldown: ${error.message}`);
  }

  // Handle channel drilldown response structure
  if (level === "channel") {
    return data as ChannelDrilldownResponse;
  }

  return (data || []) as DrilldownData;
}

// ============================================================================
// Convenience Functions for Specific Drilldown Levels
// ============================================================================

export async function fetchClientBreakdown(
  filters: FinancialFilters
): Promise<ClientFinancialData[]> {
  const data = await fetchFinancialDrilldown(filters, "client");
  return data as ClientFinancialData[];
}

export async function fetchAgentTypeBreakdown(
  filters: FinancialFilters
): Promise<AgentTypeFinancialData[]> {
  const data = await fetchFinancialDrilldown(filters, "agent_type");
  return data as AgentTypeFinancialData[];
}

export async function fetchDeploymentBreakdown(
  filters: FinancialFilters
): Promise<DeploymentFinancialData[]> {
  const data = await fetchFinancialDrilldown(filters, "deployment");
  return data as DeploymentFinancialData[];
}

export async function fetchChannelBreakdown(
  filters: FinancialFilters
): Promise<ChannelDrilldownResponse> {
  const data = await fetchFinancialDrilldown(filters, "channel");
  return data as ChannelDrilldownResponse;
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Format currency value to EUR
 */
export function formatCurrency(value: number): string {
  return new Intl.NumberFormat("fr-FR", {
    style: "currency",
    currency: "EUR",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

/**
 * Format percentage value
 */
export function formatPercentage(value: number, decimals: number = 1): string {
  return `${value.toFixed(decimals)}%`;
}

/**
 * Format number with thousands separator
 */
export function formatNumber(value: number): string {
  return new Intl.NumberFormat("fr-FR").format(value);
}

/**
 * Calculate percentage change between two values
 */
export function calculatePercentageChange(
  current: number,
  previous: number
): number {
  if (previous === 0) return 0;
  return ((current - previous) / previous) * 100;
}

/**
 * Determine if change is positive, negative, or neutral
 */
export function getChangeType(
  change: number
): "positive" | "negative" | "neutral" {
  if (change > 0) return "positive";
  if (change < 0) return "negative";
  return "neutral";
}

/**
 * Get default date range (last 30 days)
 */
export function getDefaultDateRange(): { startDate: string; endDate: string } {
  const endDate = new Date();
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - 30);

  return {
    startDate: startDate.toISOString().split("T")[0],
    endDate: endDate.toISOString().split("T")[0],
  };
}

/**
 * Export financial data to CSV
 */
export function exportToCSV(
  data: any[],
  filename: string = "financial_data.csv"
): void {
  if (!data || data.length === 0) {
    console.warn("No data to export");
    return;
  }

  // Get headers from first object
  const headers = Object.keys(data[0]);

  // Build CSV content
  const csvContent = [
    headers.join(","), // Header row
    ...data.map((row) =>
      headers
        .map((header) => {
          const value = row[header];
          // Escape values that contain commas or quotes
          if (typeof value === "string" && (value.includes(",") || value.includes('"'))) {
            return `"${value.replace(/"/g, '""')}"`;
          }
          return value;
        })
        .join(",")
    ),
  ].join("\n");

  // Create blob and download
  const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
  const link = document.createElement("a");
  const url = URL.createObjectURL(blob);

  link.setAttribute("href", url);
  link.setAttribute("download", filename);
  link.style.visibility = "hidden";
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
