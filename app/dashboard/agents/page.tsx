import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { Loader2 } from 'lucide-react'
import { AgentsListClient } from './AgentsListClient'

export const metadata = {
  title: 'Agents | Voipia Dashboard',
  description: 'Liste de tous vos agents vocaux IA déployés',
}

/**
 * Agents List Page - Server Component
 * Displays all agent deployments accessible to the user
 */
export default async function AgentsPage() {
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
      <AgentsListClient />
    </Suspense>
  )
}
