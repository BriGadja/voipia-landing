import { Suspense } from 'react'
import { redirect, notFound } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { Loader2 } from 'lucide-react'
import { DeploymentDashboardClient } from './DeploymentDashboardClient'

// Type definitions
interface DeploymentInfo {
  deployment_id: string
  deployment_name: string
  slug: string
  client_id: string
  client_name: string
  agent_type_id: string
  agent_type_name: 'louis' | 'arthur' | 'alexandra'
  agent_display_name: string
  deployment_status: 'active' | 'paused' | 'archived'
  custom_kpis: Record<string, unknown> | null
  custom_charts: Record<string, unknown> | null
}

// Metadata generation
export async function generateMetadata({ params }: { params: Promise<{ deploymentId: string }> }) {
  const { deploymentId } = await params
  const supabase = await createClient()

  // Fetch deployment info for metadata
  const { data: deployment } = await supabase
    .from('v_user_accessible_agents')
    .select('deployment_name, client_name, agent_display_name')
    .eq('deployment_id', deploymentId)
    .single()

  if (!deployment) {
    return {
      title: 'Agent non trouvé | Sablia Vox',
      description: 'Cet agent n\'existe pas ou vous n\'avez pas les permissions pour y accéder',
    }
  }

  return {
    title: `${deployment.deployment_name} - ${deployment.client_name} | Sablia Vox`,
    description: `Dashboard de l'agent ${deployment.agent_display_name} pour ${deployment.client_name}`,
  }
}

/**
 * Fetch deployment info with access check
 * Uses v_user_accessible_agents view which has RLS
 */
async function fetchDeploymentInfo(
  supabase: Awaited<ReturnType<typeof createClient>>,
  deploymentId: string
): Promise<DeploymentInfo | null> {
  // First check if user has access via RLS view
  const { data: accessCheck, error: accessError } = await supabase
    .from('v_user_accessible_agents')
    .select('deployment_id')
    .eq('deployment_id', deploymentId)
    .single()

  if (accessError || !accessCheck) {
    return null
  }

  // Fetch full deployment info including custom configs
  const { data, error } = await supabase
    .from('agent_deployments')
    .select(`
      id,
      name,
      slug,
      client_id,
      status,
      custom_kpis,
      custom_charts,
      clients!inner(name),
      agent_types!inner(id, name, display_name)
    `)
    .eq('id', deploymentId)
    .single()

  if (error || !data) {
    console.error('Error fetching deployment info:', error)
    return null
  }

  // Type assertion for the joined tables (Supabase returns objects for !inner joins with .single())
  const clientData = data.clients as unknown as { name: string } | null
  const agentTypeData = data.agent_types as unknown as { id: string; name: string; display_name: string } | null

  return {
    deployment_id: data.id,
    deployment_name: data.name,
    slug: data.slug,
    client_id: data.client_id,
    client_name: clientData?.name || 'Unknown',
    agent_type_id: agentTypeData?.id || '',
    agent_type_name: (agentTypeData?.name || 'louis') as 'louis' | 'arthur' | 'alexandra',
    agent_display_name: agentTypeData?.display_name || 'Unknown',
    deployment_status: data.status as 'active' | 'paused' | 'archived',
    custom_kpis: data.custom_kpis as Record<string, unknown> | null,
    custom_charts: data.custom_charts as Record<string, unknown> | null,
  }
}

/**
 * Deployment Dashboard Page - Server Component
 * Displays a dashboard for a specific agent deployment
 *
 * Features:
 * - Access check via RLS (v_user_accessible_agents)
 * - Base KPIs for the agent type (Louis/Arthur/Alexandra)
 * - Custom KPIs from custom_kpis JSONB column
 * - Custom charts from custom_charts JSONB column
 */
export default async function DeploymentDashboardPage({
  params,
}: {
  params: Promise<{ deploymentId: string }>
}) {
  const { deploymentId } = await params

  // Validate UUID format
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!uuidRegex.test(deploymentId)) {
    notFound()
  }

  const supabase = await createClient()

  // Server-side authentication check
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  // Fetch deployment info with access check
  const deployment = await fetchDeploymentInfo(supabase, deploymentId)

  // If no access or deployment not found, show 404
  if (!deployment) {
    notFound()
  }

  return (
    <Suspense
      fallback={
        <div className="flex h-screen items-center justify-center">
          <Loader2 className="h-8 w-8 animate-spin text-purple-500" />
        </div>
      }
    >
      <DeploymentDashboardClient
        deployment={deployment}
        userEmail={user.email || ''}
      />
    </Suspense>
  )
}
