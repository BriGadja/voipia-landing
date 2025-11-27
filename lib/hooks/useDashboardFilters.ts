'use client'

import { useCallback, useMemo } from 'react'
import { useQueryStates } from 'nuqs'
import { subDays, format, parseISO, isAfter, isValid } from 'date-fns'
import { toast } from 'sonner'
import { dashboardParsers, type AgentTypeName } from './dashboardSearchParams'
import type { DashboardFilters } from '@/lib/types/dashboard'

/**
 * Hook to manage dashboard filters via URL query parameters using nuqs
 * Provides a clean, type-safe interface for reading and updating filters
 * All filter changes are persisted in the URL
 */
export function useDashboardFilters() {
  // Use nuqs for type-safe URL state management
  const [searchParams, setSearchParams] = useQueryStates(dashboardParsers, {
    history: 'push',
    shallow: true, // Don't trigger server-side re-render
  })

  /**
   * Parse current filters from URL query params
   * Note: The 'viewAsUser' param is handled separately via useViewAsUser hook
   */
  const filters: DashboardFilters = useMemo(() => {
    const {
      clientIds: clientIdsParam,
      deploymentId,
      agentTypeName,
      startDate,
      endDate,
    } = searchParams

    // Default date range: last 30 days
    const defaultEndDate = format(new Date(), 'yyyy-MM-dd')
    const defaultStartDate = format(subDays(new Date(), 30), 'yyyy-MM-dd')

    // Use the clientIds filter if provided
    const clientIds = clientIdsParam && clientIdsParam.length > 0 ? clientIdsParam : []

    return {
      clientIds,
      deploymentId: deploymentId || null,
      agentTypeName: agentTypeName || null,
      startDate: startDate || defaultStartDate,
      endDate: endDate || defaultEndDate,
    }
  }, [searchParams])

  /**
   * Update URL query params with new filter values
   * Includes validation for date ranges
   */
  const updateFilters = useCallback(
    (updates: Partial<DashboardFilters>) => {
      const newParams: Partial<typeof searchParams> = {}

      // Update clientIds
      if (updates.clientIds !== undefined) {
        newParams.clientIds =
          updates.clientIds.length > 0 ? updates.clientIds : null
      }

      // Update deploymentId
      if (updates.deploymentId !== undefined) {
        newParams.deploymentId = updates.deploymentId || null
      }

      // Update agentTypeName
      if (updates.agentTypeName !== undefined) {
        newParams.agentTypeName = updates.agentTypeName || null
      }

      // Handle date updates with validation
      const newStartDate = updates.startDate ?? filters.startDate
      const newEndDate = updates.endDate ?? filters.endDate

      if (updates.startDate !== undefined || updates.endDate !== undefined) {
        const parsedStart = parseISO(newStartDate)
        const parsedEnd = parseISO(newEndDate)

        if (!isValid(parsedStart) || !isValid(parsedEnd)) {
          toast.error('Format de date invalide', {
            description: 'Les dates doivent etre au format YYYY-MM-DD.',
          })
          return
        }

        if (isAfter(parsedStart, parsedEnd)) {
          toast.error('Plage de dates invalide', {
            description: 'La date de debut ne peut pas etre posterieure a la date de fin.',
          })
          return
        }

        if (updates.startDate !== undefined) {
          newParams.startDate = updates.startDate
        }
        if (updates.endDate !== undefined) {
          newParams.endDate = updates.endDate
        }
      }

      setSearchParams(newParams)
    },
    [setSearchParams, filters.startDate, filters.endDate]
  )

  /**
   * Set client IDs filter
   */
  const setClientIds = useCallback(
    (clientIds: string[]) => {
      setSearchParams({
        clientIds: clientIds.length > 0 ? clientIds : null,
      })
    },
    [setSearchParams]
  )

  /**
   * Set deployment ID filter
   */
  const setDeploymentId = useCallback(
    (deploymentId: string | null) => {
      setSearchParams({ deploymentId })
    },
    [setSearchParams]
  )

  /**
   * Set agent type name filter
   */
  const setAgentTypeName = useCallback(
    (agentTypeName: AgentTypeName | null) => {
      setSearchParams({ agentTypeName })
    },
    [setSearchParams]
  )

  /**
   * Set date range filter with validation
   * Ensures startDate is not after endDate
   */
  const setDateRange = useCallback(
    (startDate: string, endDate: string) => {
      // Validate date formats
      const parsedStart = parseISO(startDate)
      const parsedEnd = parseISO(endDate)

      if (!isValid(parsedStart) || !isValid(parsedEnd)) {
        toast.error('Format de date invalide', {
          description: 'Les dates doivent etre au format YYYY-MM-DD.',
        })
        return
      }

      // Validate date range
      if (isAfter(parsedStart, parsedEnd)) {
        toast.error('Plage de dates invalide', {
          description: 'La date de debut ne peut pas etre posterieure a la date de fin.',
        })
        return
      }

      setSearchParams({ startDate, endDate })
    },
    [setSearchParams]
  )

  /**
   * Reset all filters to default values
   * Note: viewAsUser is NOT reset here - use clearViewAsUser from useViewAsUser hook
   */
  const resetFilters = useCallback(() => {
    const defaultEndDate = format(new Date(), 'yyyy-MM-dd')
    const defaultStartDate = format(subDays(new Date(), 30), 'yyyy-MM-dd')

    setSearchParams({
      clientIds: null,
      deploymentId: null,
      agentTypeName: null,
      startDate: defaultStartDate,
      endDate: defaultEndDate,
    })
  }, [setSearchParams])

  return {
    filters,
    updateFilters,
    setClientIds,
    setDeploymentId,
    setAgentTypeName,
    setDateRange,
    resetFilters,
  }
}
