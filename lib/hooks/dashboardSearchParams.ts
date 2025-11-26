/**
 * Dashboard Search Params Parsers
 * Shared parser definitions for dashboard filters using nuqs
 * Can be used in both server and client components
 */
import {
  parseAsString,
  parseAsArrayOf,
  parseAsStringLiteral,
  createLoader,
  createSerializer,
  type UrlKeys,
} from 'nuqs/server'
import { subDays, format } from 'date-fns'

// Agent type literals
const agentTypes = ['louis', 'arthur', 'alexandra'] as const
export type AgentTypeName = (typeof agentTypes)[number]

// Default date range: last 30 days
const getDefaultStartDate = () => format(subDays(new Date(), 30), 'yyyy-MM-dd')
const getDefaultEndDate = () => format(new Date(), 'yyyy-MM-dd')

/**
 * Dashboard filter parsers
 * - tenant: Client ID for admin tenant switching (takes precedence over clientIds)
 * - clientIds: Comma-separated client IDs
 * - deploymentId: Single agent deployment UUID
 * - agentTypeName: Agent type filter (louis, arthur, alexandra)
 * - startDate: Start date in YYYY-MM-DD format
 * - endDate: End date in YYYY-MM-DD format
 */
export const dashboardParsers = {
  tenant: parseAsString,
  clientIds: parseAsArrayOf(parseAsString, ','),
  deploymentId: parseAsString,
  agentTypeName: parseAsStringLiteral(agentTypes),
  startDate: parseAsString.withDefault(getDefaultStartDate()),
  endDate: parseAsString.withDefault(getDefaultEndDate()),
}

/**
 * URL key mappings (optional, for shorter URLs)
 */
export const dashboardUrlKeys: UrlKeys<typeof dashboardParsers> = {
  tenant: 'tenant',
  clientIds: 'clientIds',
  deploymentId: 'deploymentId',
  agentTypeName: 'agentTypeName',
  startDate: 'startDate',
  endDate: 'endDate',
}

/**
 * Server-side loader for parsing search params
 * Use in server components and API routes
 */
export const loadDashboardParams = createLoader(dashboardParsers, {
  urlKeys: dashboardUrlKeys,
})

/**
 * Serializer for creating URLs with dashboard params
 * Use for navigation links
 */
export const serializeDashboardParams = createSerializer(dashboardParsers, {
  urlKeys: dashboardUrlKeys,
})
