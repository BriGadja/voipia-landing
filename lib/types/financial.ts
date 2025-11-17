// Financial Dashboard Types
// Generated: 2025-01-16

// ============================================================================
// KPI Metrics Types
// ============================================================================

export interface FinancialKPIMetrics {
  total_revenue: number;
  total_provider_cost: number;
  total_margin: number;
  margin_percentage: number;
  call_revenue: number;
  sms_revenue: number;
  email_revenue: number;
  leasing_revenue: number;
  call_provider_cost: number;
  sms_provider_cost: number;
  email_provider_cost: number;
  call_count: number;
  answered_calls: number;
  appointments_scheduled: number;
  sms_count: number;
  email_count: number;
  unique_clients: number;
  unique_deployments: number;
  avg_revenue_per_client: number;
  avg_margin_per_client: number;
}

export interface FinancialPeriodInfo {
  start_date: string;
  end_date: string;
  duration_days: number;
  previous_start_date: string;
  previous_end_date: string;
}

export interface FinancialComparison {
  revenue_change: number;
  revenue_change_percentage: number;
  margin_change: number;
  margin_change_percentage: number;
}

export interface FinancialKPIResponse {
  current_period: FinancialKPIMetrics;
  previous_period: Pick<
    FinancialKPIMetrics,
    'total_revenue' | 'total_provider_cost' | 'total_margin' | 'margin_percentage'
  >;
  period_info: FinancialPeriodInfo;
  comparison: FinancialComparison;
}

// ============================================================================
// Drilldown Types
// ============================================================================

export interface ClientFinancialData {
  client_id: string;
  client_name: string;
  total_revenue: number;
  total_provider_cost: number;
  total_margin: number;
  margin_percentage: number;
  call_revenue: number;
  sms_revenue: number;
  email_revenue: number;
  leasing_revenue: number;
  call_count: number;
  sms_count: number;
  email_count: number;
  answered_calls: number;
  appointments_scheduled: number;
  unique_deployments: number;
  active_days: number;
}

export interface AgentTypeFinancialData {
  agent_type_id: string;
  agent_type_name: string;
  total_revenue: number;
  total_provider_cost: number;
  total_margin: number;
  margin_percentage: number;
  call_revenue: number;
  sms_revenue: number;
  email_revenue: number;
  leasing_revenue: number;
  call_count: number;
  sms_count: number;
  email_count: number;
  answered_calls: number;
  appointments_scheduled: number;
  unique_clients: number;
  unique_deployments: number;
}

export interface DeploymentFinancialData {
  deployment_id: string;
  client_id: string;
  client_name: string;
  agent_type_id: string;
  agent_type_name: string;
  total_revenue: number;
  total_provider_cost: number;
  total_margin: number;
  margin_percentage: number;
  call_revenue: number;
  sms_revenue: number;
  email_revenue: number;
  leasing_revenue: number;
  call_count: number;
  sms_count: number;
  email_count: number;
  answered_calls: number;
  appointments_scheduled: number;
  active_days: number;
}

// Deployment breakdown for a specific client (from get_client_deployments_breakdown)
export interface ClientDeploymentData {
  deployment_id: string;
  deployment_name: string;
  agent_type_name: string;
  agent_type_label: string;
  status: string;
  created_at: string;
  total_revenue: number;
  total_provider_cost: number;
  total_margin: number;
  margin_percentage: number;
  call_count: number;
  sms_count: number;
  email_count: number;
  answered_calls: number;
  appointments_scheduled: number;
  answer_rate: number;
  conversion_rate: number;
  call_cost: number;
  sms_cost: number;
  email_cost: number;
  leasing_revenue: number;
  avg_call_duration: number;
  cost_per_call: number;
  cost_per_appointment: number;
}

export interface ChannelFinancialData {
  channel_name: 'calls' | 'sms' | 'email' | 'leasing';
  revenue: number;
  provider_cost: number;
  margin: number;
  margin_percentage: number;
  volume: number;
  answered?: number;     // For calls
  delivered?: number;    // For SMS/email
  description?: string;  // For leasing
}

export interface ChannelDrilldownResponse {
  channels: ChannelFinancialData[];
}

// Deployment channel breakdown (from get_deployment_channels_breakdown)
export interface DeploymentChannelData {
  channel_name: 'calls' | 'sms' | 'email' | 'leasing';
  channel_label: string;
  channel_icon: string;
  revenue: number;
  provider_cost: number;
  margin: number;
  margin_percentage: number;
  volume: number;
  answered_calls: number | null;
  appointments: number | null;
  avg_duration: number | null;
  answer_rate: number | null;
  cost_per_item: number;
  revenue_per_item: number;
}

export type DrilldownLevel = 'client' | 'agent_type' | 'deployment' | 'channel';

export type DrilldownData =
  | ClientFinancialData[]
  | AgentTypeFinancialData[]
  | DeploymentFinancialData[]
  | ChannelDrilldownResponse;

// ============================================================================
// Filter Types
// ============================================================================

export interface FinancialFilters {
  startDate: string;
  endDate: string;
  clientId?: string | null;
  agentTypeName?: string | null;
  deploymentId?: string | null;
}

// ============================================================================
// Chart Data Types
// ============================================================================

export interface TrendDataPoint {
  date: string;
  revenue: number;
  cost: number;
  margin: number;
  margin_percentage: number;
}

export interface RevenueByChannelData {
  channel: string;
  revenue: number;
  percentage: number;
}

export interface MarginByClientData {
  client_name: string;
  margin: number;
  margin_percentage: number;
  revenue: number;
}

// ============================================================================
// Time Series Types
// ============================================================================

export interface TimeSeriesRevenue {
  total: number;
  calls: number;
  sms: number;
  email: number;
  leasing: number;
}

export interface TimeSeriesCost {
  total: number;
  calls: number;
  sms: number;
  email: number;
}

export interface TimeSeriesMargin {
  total: number;
  percentage: number;
}

export interface TimeSeriesVolume {
  calls: number;
  answered_calls: number;
  sms: number;
  email: number;
  appointments: number;
}

export interface TimeSeriesMetrics {
  unique_clients: number;
  unique_deployments: number;
  answer_rate: number;
  conversion_rate: number;
}

export interface TimeSeriesDataPoint {
  date: string;
  revenue: TimeSeriesRevenue;
  cost: TimeSeriesCost;
  margin: TimeSeriesMargin;
  volume: TimeSeriesVolume;
  metrics: TimeSeriesMetrics;
}

export type TimeSeriesGranularity = 'day' | 'week' | 'month';

export interface TimeSeriesFilters extends FinancialFilters {
  granularity?: TimeSeriesGranularity;
}

export interface TimeSeriesResponse {
  data: TimeSeriesDataPoint[];
  granularity: TimeSeriesGranularity;
  period: {
    start: string;
    end: string;
  };
}

// ============================================================================
// Component Props Types
// ============================================================================

export interface FinancialKPICardProps {
  title: string;
  value: number | string;
  previousValue?: number;
  changePercentage?: number;
  prefix?: string;
  suffix?: string;
  format?: 'currency' | 'percentage' | 'number';
  icon?: React.ComponentType<{ className?: string }>;
  color?: string;
  isLoading?: boolean;
}

export interface FinancialChartProps {
  data: any[];
  isLoading?: boolean;
  title?: string;
  height?: number;
}

export interface DrilldownTableProps {
  level: DrilldownLevel;
  data: DrilldownData;
  isLoading?: boolean;
  onDrillDown?: (item: any) => void;
}

// ============================================================================
// Cost Breakdown Types
// ============================================================================

export interface CallCosts {
  total: number;
  stt: number;
  tts: number;
  llm: number;
  telecom: number;
  dipler_commission: number;
}

export interface SMSCosts {
  total: number;
}

export interface EmailCosts {
  total: number;
}

export interface TotalCosts {
  provider_cost: number;
  stt: number;
  tts: number;
  llm: number;
  telecom: number;
  dipler_commission: number;
  all_channels: number;
}

export interface CostVolume {
  calls: number;
  sms: number;
  emails: number;
}

export interface CostBreakdownResponse {
  call_costs: CallCosts;
  sms_costs: SMSCosts;
  email_costs: EmailCosts;
  total_costs: TotalCosts;
  volume: CostVolume;
}

export interface CostBreakdownChartDataPoint {
  name: string;
  value: number;
  percentage: number;
  color: string;
}
