import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { getDashboardDestination } from '@/lib/queries/global'
import { GlobalDashboardClient } from './GlobalDashboardClient'
import { Loader2 } from 'lucide-react'
import './styles.css'

export const metadata = {
  title: 'Dashboard Global | Voipia',
  description: 'Vue d\'ensemble de tous vos agents vocaux IA',
}

/**
 * Global Dashboard Page - Server Component
 * Verifies authentication and intelligently routes user to appropriate dashboard:
 * - If user has 2+ clients or 2+ agents → Global dashboard
 * - If user has exactly 1 agent → Redirect to that agent's dashboard
 * - Otherwise → Global dashboard
 */
export default async function GlobalDashboardPage() {
  const supabase = await createClient()

  // Server-side authentication check
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  // Determine appropriate dashboard destination
  const destination = await getDashboardDestination()

  // Redirect to specific agent dashboard if user has only 1 agent
  if (destination.shouldRedirect && destination.agentType) {
    redirect(`/dashboard/${destination.agentType}`)
  }

  // Otherwise, show global dashboard
  return (
    <Suspense
      fallback={
        <div className="flex h-screen items-center justify-center">
          <Loader2 className="h-8 w-8 animate-spin text-purple-500" />
        </div>
      }
    >
      <GlobalDashboardClient userEmail={user.email || ''} />
    </Suspense>
  )
}
