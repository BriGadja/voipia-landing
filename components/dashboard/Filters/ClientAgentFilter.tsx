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
              <option key={client.id} value={client.id}>
                {client.name}
              </option>
            ))}
          </select>
          <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-3 h-3 text-white/60 pointer-events-none" />
        </div>
      </div>

      <div className="w-full sm:w-56">
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
              <option key={agent.id} value={agent.id}>
                {agent.name}
              </option>
            ))}
          </select>
          <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-3 h-3 text-white/60 pointer-events-none" />
        </div>
      </div>
    </div>
  )
}
