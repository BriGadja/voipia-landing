'use client'

import { useEffect } from 'react'
import { DashboardErrorFallback } from '@/components/dashboard/DashboardErrorFallback'

/**
 * Dashboard Error Boundary
 * Automatically catches errors in the dashboard route segment
 * See: https://nextjs.org/docs/app/building-your-application/routing/error-handling
 */
export default function DashboardError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // Log the error to an error reporting service
    console.error('Dashboard error:', error)
  }, [error])

  return <DashboardErrorFallback error={error} resetErrorBoundary={reset} />
}
