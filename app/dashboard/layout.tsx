import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { Loader2 } from 'lucide-react'

export const metadata = {
  title: 'Dashboard | Voipia',
  description: 'Tableau de bord analytique pour vos agents vocaux IA',
  robots: {
    index: false,
    follow: false,
  },
}

/**
 * Dashboard Layout - Shared layout for all dashboard pages
 * Handles authentication and provides common dashboard structure
 */
export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  // Server-side authentication check
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Redirect to login if not authenticated
  if (!user) {
    redirect('/login')
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-black via-purple-950/20 to-black">
      <Suspense
        fallback={
          <div className="flex h-screen items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-purple-500" />
          </div>
        }
      >
        {children}
      </Suspense>
    </div>
  )
}
