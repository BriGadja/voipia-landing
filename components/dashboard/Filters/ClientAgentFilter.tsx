'use client'

import { useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { fetchClients, fetchAgents } from '@/lib/queries/dashboard'
import { ChevronDown } from 'lucide-react'

interface ClientAgentFilterProps {
  selectedClientIds: string[]
  selectedAgentIds: string[]
  onChange: (clientIds: string[], agentIds: string[]) => void
}

export function ClientAgentFilter({
  selectedClientIds,
  selectedAgentIds,
  onChange,
}: ClientAgentFilterProps) {
  const { data: clients, isLoading: isLoadingClients } = useQuery({
    queryKey: ['clients'],
    queryFn: fetchClients,
  })

  const { data: agents, isLoading: isLoadingAgents } = useQuery({
    queryKey: ['agents', selectedClientIds],
    queryFn: () => fetchAgents(selectedClientIds.length > 0 ? selectedClientIds : undefined),
    enabled: !!clients && clients.length > 0,
  })

  // Reset agents selection if clients change
  useEffect(() => {
    if (selectedClientIds.length > 0 && agents) {
      const validAgentIds = agents.map((a) => a.id)
      const newAgentIds = selectedAgentIds.filter((id) => validAgentIds.includes(id))
      if (newAgentIds.length !== selectedAgentIds.length) {
        onChange(selectedClientIds, newAgentIds)
      }
    }
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
    <div className="flex flex-col sm:flex-row gap-4">
      <div className="w-full sm:w-64">
        <label className="block text-sm font-medium text-white/80 mb-2">
          Client
        </label>
        <div className="relative">
          <select
            value={selectedClientIds[0] || 'all'}
            onChange={(e) => handleClientChange(e.target.value)}
            disabled={isLoadingClients}
            className="w-full px-3 py-2 border border-white/20 rounded-lg bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-purple-500 appearance-none cursor-pointer disabled:opacity-50"
          >
            <option value="all">Tous les clients</option>
            {clients?.map((client) => (
              <option key={client.id} value={client.id}>
                {client.name}
              </option>
            ))}
          </select>
          <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-white/60 pointer-events-none" />
        </div>
      </div>

      <div className="w-full sm:w-64">
        <label className="block text-sm font-medium text-white/80 mb-2">
          Agent
        </label>
        <div className="relative">
          <select
            value={selectedAgentIds[0] || 'all'}
            onChange={(e) => handleAgentChange(e.target.value)}
            disabled={isLoadingAgents || !agents || agents.length === 0}
            className="w-full px-3 py-2 border border-white/20 rounded-lg bg-black/20 text-white focus:outline-none focus:ring-2 focus:ring-purple-500 appearance-none cursor-pointer disabled:opacity-50"
          >
            <option value="all">Tous les agents</option>
            {agents?.map((agent) => (
              <option key={agent.id} value={agent.id}>
                {agent.name}
              </option>
            ))}
          </select>
          <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-white/60 pointer-events-none" />
        </div>
      </div>
    </div>
  )
}
