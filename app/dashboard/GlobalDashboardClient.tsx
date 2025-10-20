'use client'

import { useDashboardFilters } from '@/lib/hooks/useDashboardFilters'
import {
  useClientCardsData,
  useAgentTypeCardsData,
} from '@/lib/hooks/useDashboardData'
import { exportGlobalCallsToCSV } from '@/lib/queries/global'
import { DashboardHeader } from '@/components/dashboard/DashboardHeader'
import { DateRangeFilter } from '@/components/dashboard/Filters/DateRangeFilter'
import { ExportCSVButton } from '@/components/dashboard/ExportCSVButton'
import { ClientCard } from '@/components/dashboard/Cards/ClientCard'
import { AgentTypeCard } from '@/components/dashboard/Cards/AgentTypeCard'

interface GlobalDashboardClientProps {
  userEmail: string
}

/**
 * Global Dashboard Client Component
 * Displays dynamic cards based on user permissions:
 * - Admin users see: Client cards + Agent type cards
 * - Regular users see: Only the agent types they have access to
 *
 * All cards are dynamically generated from Supabase data
 */
export function GlobalDashboardClient({ userEmail }: GlobalDashboardClientProps) {
  // URL-based filters
  const { filters, setDateRange } = useDashboardFilters()

  // Fetch dynamic cards data
  const { data: clientCards, isLoading: isLoadingClients } = useClientCardsData(filters)
  const { data: agentTypeCards, isLoading: isLoadingAgentTypes } = useAgentTypeCardsData(filters)

  // Handle filter changes
  const handleDateChange = (start: Date, end: Date) => {
    setDateRange(start.toISOString().split('T')[0], end.toISOString().split('T')[0])
  }

  const hasClientCards = clientCards && clientCards.length > 0
  const hasAgentTypeCards = agentTypeCards && agentTypeCards.length > 0
  const isLoading = isLoadingClients || isLoadingAgentTypes

  return (
    <>
      {/* Header */}
      <DashboardHeader userEmail={userEmail} title="Dashboard Global" />

      {/* Main Content */}
      <div className="container mx-auto px-4 py-8 space-y-8">
        {/* Filters Row */}
        <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
          <DateRangeFilter
            startDate={new Date(filters.startDate)}
            endDate={new Date(filters.endDate)}
            onChange={handleDateChange}
          />

          <ExportCSVButton
            filters={filters}
            exportFn={exportGlobalCallsToCSV}
            filename="global-dashboard-export.csv"
          />
        </div>

        {/* Two Column Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Left Column: Agent Type Cards */}
          {(hasAgentTypeCards || isLoadingAgentTypes) && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-2xl font-bold text-white">
                  Agents déployés
                </h2>
                {hasAgentTypeCards && (
                  <span className="text-sm text-white/60">
                    {agentTypeCards.length} type{agentTypeCards.length > 1 ? 's' : ''} d'agent
                  </span>
                )}
              </div>

              {isLoadingAgentTypes ? (
                <div className="space-y-6">
                  {[...Array(2)].map((_, i) => (
                    <div
                      key={i}
                      className="h-64 bg-black/20 border border-white/20 rounded-xl animate-pulse"
                    />
                  ))}
                </div>
              ) : (
                <div className="space-y-6">
                  {agentTypeCards?.map((agentType) => (
                    <AgentTypeCard key={agentType.agent_type_name} agentType={agentType} />
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Right Column: Client Cards */}
          {(hasClientCards || isLoadingClients) && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-2xl font-bold text-white">
                  Entreprises
                </h2>
                {hasClientCards && (
                  <span className="text-sm text-white/60">
                    {clientCards.length} {clientCards.length > 1 ? 'clients' : 'client'}
                  </span>
                )}
              </div>

              {isLoadingClients ? (
                <div className="space-y-6">
                  {[...Array(3)].map((_, i) => (
                    <div
                      key={i}
                      className="h-64 bg-black/20 border border-white/20 rounded-xl animate-pulse"
                    />
                  ))}
                </div>
              ) : (
                <div className="space-y-6">
                  {clientCards?.map((client) => (
                    <ClientCard key={client.client_id} client={client} />
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Empty State - Only show when not loading and no data */}
        {!isLoading && !hasClientCards && !hasAgentTypeCards && (
          <div className="flex flex-col items-center justify-center py-16 space-y-4">
            <div className="p-4 rounded-full bg-white/5">
              <svg
                className="w-12 h-12 text-white/20"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
                />
              </svg>
            </div>
            <div className="text-center space-y-2">
              <p className="text-lg font-semibold text-white">
                Aucune donnée disponible
              </p>
              <p className="text-sm text-white/60">
                Aucun agent ou entreprise trouvé pour cette période
              </p>
            </div>
          </div>
        )}
      </div>
    </>
  )
}
