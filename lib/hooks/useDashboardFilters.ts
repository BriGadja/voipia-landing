import { useCallback, useMemo } from 'react'
import { useRouter, useSearchParams, usePathname } from 'next/navigation'
import { subDays, format } from 'date-fns'
import type { DashboardFilters } from '@/lib/types/dashboard'

/**
 * Hook to manage dashboard filters via URL query parameters
 * Provides a clean interface for reading and updating filters
 * All filter changes are persisted in the URL
 */
export function useDashboardFilters() {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()

  /**
   * Parse current filters from URL query params
   */
  const filters: DashboardFilters = useMemo(() => {
    const clientIdsParam = searchParams.get('clientIds')
    const deploymentIdParam = searchParams.get('deploymentId')
    const agentTypeNameParam = searchParams.get('agentTypeName')
    const startDateParam = searchParams.get('startDate')
    const endDateParam = searchParams.get('endDate')

    // Default date range: last 30 days
    const defaultEndDate = format(new Date(), 'yyyy-MM-dd')
    const defaultStartDate = format(subDays(new Date(), 30), 'yyyy-MM-dd')

    return {
      clientIds: clientIdsParam ? clientIdsParam.split(',') : [],
      deploymentId: deploymentIdParam || null,
      agentTypeName: (agentTypeNameParam as 'louis' | 'arthur' | 'alexandra') || null,
      startDate: startDateParam || defaultStartDate,
      endDate: endDateParam || defaultEndDate,
    }
  }, [searchParams])

  /**
   * Update URL query params with new filter values
   */
  const updateFilters = useCallback(
    (updates: Partial<DashboardFilters>) => {
      const params = new URLSearchParams(searchParams.toString())

      // Update clientIds
      if (updates.clientIds !== undefined) {
        if (updates.clientIds.length > 0) {
          params.set('clientIds', updates.clientIds.join(','))
        } else {
          params.delete('clientIds')
        }
      }

      // Update deploymentId
      if (updates.deploymentId !== undefined) {
        if (updates.deploymentId) {
          params.set('deploymentId', updates.deploymentId)
        } else {
          params.delete('deploymentId')
        }
      }

      // Update agentTypeName
      if (updates.agentTypeName !== undefined) {
        if (updates.agentTypeName) {
          params.set('agentTypeName', updates.agentTypeName)
        } else {
          params.delete('agentTypeName')
        }
      }

      // Update startDate
      if (updates.startDate !== undefined) {
        params.set('startDate', updates.startDate)
      }

      // Update endDate
      if (updates.endDate !== undefined) {
        params.set('endDate', updates.endDate)
      }

      // Update URL without full page reload
      router.push(`${pathname}?${params.toString()}`, { scroll: false })
    },
    [router, pathname, searchParams]
  )

  /**
   * Set client IDs filter
   */
  const setClientIds = useCallback(
    (clientIds: string[]) => {
      updateFilters({ clientIds })
    },
    [updateFilters]
  )

  /**
   * Set deployment ID filter
   */
  const setDeploymentId = useCallback(
    (deploymentId: string | null) => {
      updateFilters({ deploymentId })
    },
    [updateFilters]
  )

  /**
   * Set agent type name filter
   */
  const setAgentTypeName = useCallback(
    (agentTypeName: 'louis' | 'arthur' | 'alexandra' | null) => {
      updateFilters({ agentTypeName })
    },
    [updateFilters]
  )

  /**
   * Set date range filter
   */
  const setDateRange = useCallback(
    (startDate: string, endDate: string) => {
      updateFilters({ startDate, endDate })
    },
    [updateFilters]
  )

  /**
   * Reset all filters to default values
   */
  const resetFilters = useCallback(() => {
    const defaultEndDate = format(new Date(), 'yyyy-MM-dd')
    const defaultStartDate = format(subDays(new Date(), 30), 'yyyy-MM-dd')

    const params = new URLSearchParams()
    params.set('startDate', defaultStartDate)
    params.set('endDate', defaultEndDate)

    router.push(`${pathname}?${params.toString()}`, { scroll: false })
  }, [router, pathname])

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
