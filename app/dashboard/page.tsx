import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { GlobalDashboardClient } from './GlobalDashboardClient'
import { Loader2 } from 'lucide-react'
import './styles.css'

export const metadata = {
  title: 'Dashboard Global | Voipia',
  description: 'Vue d\'ensemble de tous vos agents vocaux IA',
}

/**
 * Global Dashboard Page - Server Component
 * Verifies authentication and renders the global dashboard
 * Shows aggregated metrics across all agents and clients
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
