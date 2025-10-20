'use client'

import Link from 'next/link'
import { Users, Target, Sparkles, Phone, TrendingUp, Calendar, Clock, Activity, Layers, ArrowRight } from 'lucide-react'
import { AgentTypeCardData } from '@/lib/types/dashboard'
import { cn } from '@/lib/utils'

interface AgentTypeCardProps {
  agentType: AgentTypeCardData
}

/**
 * Formats a date to relative time (e.g., "Il y a 2 jours")
 */
function formatRelativeTime(date: string | null): string {
  if (!date) return 'Jamais'

  const now = new Date()
  const past = new Date(date)
  const diffMs = now.getTime() - past.getTime()
  const diffSec = Math.floor(diffMs / 1000)
  const diffMin = Math.floor(diffSec / 60)
  const diffHour = Math.floor(diffMin / 60)
  const diffDay = Math.floor(diffHour / 24)

  if (diffSec < 60) return 'À l\'instant'
  if (diffMin < 60) return `Il y a ${diffMin}min`
  if (diffHour < 24) return `Il y a ${diffHour}h`
  if (diffDay === 1) return 'Hier'
  if (diffDay < 7) return `Il y a ${diffDay}j`
  if (diffDay < 30) return `Il y a ${Math.floor(diffDay / 7)}sem`
  return `Il y a ${Math.floor(diffDay / 30)}mois`
}

/**
 * Agent Type Card Component
 * Displays aggregated metrics for ALL deployments of a specific agent type
 * (e.g., one card for all "Louis" agents, one for all "Arthur" agents)
 */
export function AgentTypeCard({ agentType }: AgentTypeCardProps) {
  const hasData = agentType.total_calls > 0

  // Agent type configuration
  const agentConfig = {
    louis: {
      icon: Users,
      color: 'from-blue-500/20 to-blue-500/5 border-blue-500/30',
      iconColor: 'text-blue-400',
      description: 'Rappel de leads',
    },
    arthur: {
      icon: Target,
      color: 'from-orange-500/20 to-orange-500/5 border-orange-500/30',
      iconColor: 'text-orange-400',
      description: 'Prospection active',
    },
    alexandra: {
      icon: Sparkles,
      color: 'from-green-500/20 to-green-500/5 border-green-500/30',
      iconColor: 'text-green-400',
      description: 'SAV & Support',
    },
  }

  const config = agentConfig[agentType.agent_type_name]
  const Icon = config.icon

  return (
    <Link
      href={`/dashboard/${agentType.agent_type_name}`}
      className={cn(
        'group relative overflow-hidden rounded-xl border bg-gradient-to-br backdrop-blur-sm transition-all hover:scale-[1.02] block min-h-[420px]',
        config.color
      )}
    >
      <div className="p-6 space-y-4">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className={cn('p-3 rounded-lg bg-white/10', config.iconColor)}>
              <Icon className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-white">
                {agentType.agent_display_name}
              </h3>
              <p className="text-sm text-white/60">{config.description}</p>
            </div>
          </div>
          <ArrowRight className="w-5 h-5 text-white/40 group-hover:text-white/80 transition-colors" />
        </div>

        {/* Deployments Count */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs text-white/60">
            <Layers className="w-3 h-3" />
            <span>
              {agentType.active_deployments} actif{agentType.active_deployments > 1 ? 's' : ''} / {agentType.total_deployments} déploiement{agentType.total_deployments > 1 ? 's' : ''}
            </span>
          </div>
        </div>

        {/* Last Activity Badge */}
        <div className="flex items-center justify-between pt-2">
          <div className="flex items-center gap-2 text-xs text-white/60">
            <Activity className="w-3 h-3" />
            <span>Dernière activité: {formatRelativeTime(agentType.last_call_at)}</span>
          </div>
        </div>

        {/* Stats */}
        {hasData ? (
          <div className="space-y-4 pt-4 border-t border-white/10">
            {/* Main Metrics Grid */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <div className="flex items-center gap-1 text-white/60 mb-1">
                  <Phone className="w-3 h-3" />
                  <p className="text-xs">Appels</p>
                </div>
                <p className="text-xl font-bold text-white">
                  {agentType.total_calls.toLocaleString()}
                </p>
              </div>
              <div>
                <div className="flex items-center gap-1 text-white/60 mb-1">
                  <TrendingUp className="w-3 h-3" />
                  <p className="text-xs">Taux réponse</p>
                </div>
                <p className="text-xl font-bold text-white">
                  {agentType.answer_rate.toFixed(1)}%
                </p>
              </div>
              <div>
                <div className="flex items-center gap-1 text-white/60 mb-1">
                  <Calendar className="w-3 h-3" />
                  <p className="text-xs">Conversion</p>
                </div>
                <p className="text-xl font-bold text-white">
                  {agentType.conversion_rate.toFixed(1)}%
                </p>
              </div>
              <div>
                <div className="flex items-center gap-1 text-white/60 mb-1">
                  <Clock className="w-3 h-3" />
                  <p className="text-xs">Durée moy.</p>
                </div>
                <p className="text-xl font-bold text-white">
                  {Math.floor(agentType.avg_duration / 60)}m{agentType.avg_duration % 60}s
                </p>
              </div>
            </div>
          </div>
        ) : (
          <div className="pt-4 border-t border-white/10">
            <p className="text-sm text-white/40 text-center">
              Aucune donnée pour cette période
            </p>
          </div>
        )}
      </div>
    </Link>
  )
}
