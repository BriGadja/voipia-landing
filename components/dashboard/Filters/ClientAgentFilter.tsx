'use client'

import { useEffect } from 'react'
import { ChevronDown } from 'lucide-react'
import { useAccessibleClients, useAccessibleAgents } from '@/lib/hooks/useDashboardData'

interface ClientAgentFilterProps {
  selectedClientIds: string[]
  selectedAgentIds: string[]
  onChange: (clientIds: string[], agentIds: string[]) => void
  agentType?: 'louis' | 'arthur' | 'alexandra' // Optional filter by agent type
}

export function ClientAgentFilter({
  selectedClientIds,
  selectedAgentIds,
  onChange,
  agentType,
}: ClientAgentFilterProps) {
  // Fetch all accessible clients
  const { data: clientsRaw, isLoading: isLoadingClients } = useAccessibleClients()

  // Deduplicate clients by client_id (in case the view returns duplicates)
  const clients = clientsRaw?.reduce((acc, client) => {
    if (!acc.find((c) => c.client_id === client.client_id)) {
      acc.push(client)
    }
    return acc
  }, [] as typeof clientsRaw)

  // Fetch accessible agents filtered by agent type and selected clients
  const { data: allAgentsRaw, isLoading: isLoadingAgents } = useAccessibleAgents(
    selectedClientIds.length > 0 ? selectedClientIds : undefined,
    agentType // Filter by agent type
  )

  // Deduplicate agents by deployment_id (in case the view returns duplicates)
  const allAgents = allAgentsRaw?.reduce((acc, agent) => {
    if (!acc.find((a) => a.deployment_id === agent.deployment_id)) {
      acc.push(agent)
    }
    return acc
  }, [] as typeof allAgentsRaw)

  // Agents are already filtered by database query via selectedClientIds
  const agents = allAgents

  // Reset agents selection if clients change and selected agent is no longer valid
  useEffect(() => {
    if (selectedClientIds.length > 0 && agents) {
      const validAgentIds = agents.map((a) => a.deployment_id)
      const newAgentIds = selectedAgentIds.filter((id) => validAgentIds.includes(id))
      if (newAgentIds.length !== selectedAgentIds.length) {
        onChange(selectedClientIds, newAgentIds)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedClientIds, agents])

  const handleClientChange = (clientId: string) => {
    if (clientId === 'all') {
      onChange([], [])
    } else {
      onChange([clientId], [])
    }
  }

  const handleAgentChange = (agentId: string) => {
    if (agentId === 'all') {
      onChange(selectedClientIds, [])
    } else {
      onChange(selectedClientIds, [agentId])
    }
  }

  return (
    <div className="flex flex-col sm:flex-row gap-3">
      <div className="w-full sm:w-56">
        <label className="block text-xs font-medium text-white/80 mb-1.5">
          Entreprise
        </label>
        <div className="relative">
          <select
            value={selectedClientIds[0] || 'all'}
            onChange={(e) => handleClientChange(e.target.value)}
            disabled={isLoadingClients}
            className="w-full px-2 py-1.5 text-sm border border-white/20 rounded-lg bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-purple-500 appearance-none cursor-pointer disabled:opacity-50 [&>option]:bg-black [&>option]:text-white"
          >
            <option value="all">Toutes les entreprises</option>
            {clients?.map((client) => (
              <option key={client.client_id} value={client.client_id}>
                {client.client_name}
              </option>
            ))}
          </select>
          <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-3 h-3 text-white/60 pointer-events-none" />
        </div>
      </div>

      <div className="w-full sm:w-64">
        <label className="block text-xs font-medium text-white/80 mb-1.5">
          Agent
        </label>
        <div className="relative">
          <select
            value={selectedAgentIds[0] || 'all'}
            onChange={(e) => handleAgentChange(e.target.value)}
            disabled={isLoadingAgents || !agents || agents.length === 0}
            className="w-full px-2 py-1.5 text-sm border border-white/20 rounded-lg bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-purple-500 appearance-none cursor-pointer disabled:opacity-50 [&>option]:bg-black [&>option]:text-white"
          >
            <option value="all">Tous les agents</option>
            {agents?.map((agent) => (
              <option key={agent.deployment_id} value={agent.deployment_id}>
                {agent.deployment_name} - {agent.client_name}
              </option>
            ))}
          </select>
          <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-3 h-3 text-white/60 pointer-events-none" />
        </div>
      </div>
    </div>
  )
}
