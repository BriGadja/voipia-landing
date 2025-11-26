import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { Loader2 } from 'lucide-react'
import { LouisDashboardClient } from './LouisDashboardClient'

export const metadata = {
  title: 'Dashboard Louis | Voipia',
  description: 'Analysez les performances de votre agent vocal Louis',
}

/**
 * Louis Dashboard Page - Server Component
 * Static route for Louis agent dashboard
 */
export default async function LouisDashboardPage() {
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
      <LouisDashboardClient userEmail={user.email || ''} />
    </Suspense>
  )
}
