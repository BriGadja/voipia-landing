import { Suspense } from 'react'
import { redirect, notFound } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { Loader2 } from 'lucide-react'
import { LouisDashboardClient } from './LouisDashboardClient'
import { ArthurDashboardClient } from './ArthurDashboardClient'

export const metadata = {
  title: 'Dashboard Agent | Voipia',
  description: 'Analysez les performances de vos agents vocaux IA',
}

interface AgentTypeDashboardPageProps {
  params: Promise<{
    agentType: string
  }>
}

/**
 * Agent Type Dashboard Page - Server Component
 * Dynamic route for agent-specific dashboards
 * Supports: /dashboard/louis, /dashboard/arthur, /dashboard/alexandra
 */
export default async function AgentTypeDashboardPage({
  params,
}: AgentTypeDashboardPageProps) {
  const { agentType } = await params
  const supabase = await createClient()

  // Server-side authentication check
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  // Validate agent type
  const validAgentTypes = ['louis', 'arthur', 'alexandra']
  if (!validAgentTypes.includes(agentType)) {
    notFound()
  }

  // Render appropriate dashboard component based on agent type
  return (
    <Suspense
      fallback={
        <div className="flex h-screen items-center justify-center">
          <Loader2 className="h-8 w-8 animate-spin text-purple-500" />
        </div>
      }
    >
      {agentType === 'louis' && (
        <LouisDashboardClient userEmail={user.email || ''} />
      )}
      {agentType === 'arthur' && (
        <ArthurDashboardClient userEmail={user.email || ''} />
      )}
      {agentType === 'alexandra' && (
        <div className="flex h-screen items-center justify-center">
          <div className="text-center space-y-4">
            <h2 className="text-2xl font-bold text-white">
              Dashboard Alexandra
            </h2>
            <p className="text-white/60">
              Le dashboard pour Alexandra sera bientôt disponible.
            </p>
          </div>
        </div>
      )}
    </Suspense>
  )
}

/**
 * Generate static params for known agent types
 * This enables static generation at build time
 */
export async function generateStaticParams() {
  return [
    { agentType: 'louis' },
    { agentType: 'arthur' },
    { agentType: 'alexandra' },
  ]
}
