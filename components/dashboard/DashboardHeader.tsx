'use client'

import { LogoutButton } from '@/components/auth/LogoutButton'

interface DashboardHeaderProps {
  userEmail: string
  title?: string
}

/**
 * Dashboard Header Component
 * Displays user info, title, and logout button
 */
export function DashboardHeader({ userEmail, title = 'Dashboard Analytics' }: DashboardHeaderProps) {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-white/10 bg-black/50 backdrop-blur-lg">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between gap-4">
          {/* Left: Title and User */}
          <div className="flex-1 min-w-0">
            <h1 className="text-2xl font-bold text-white mb-1">{title}</h1>
            <p className="text-sm text-white/60">
              Connecté en tant que {userEmail}
            </p>
          </div>

          {/* Right: Logout Button */}
          <div className="flex items-center gap-4">
            <LogoutButton />
          </div>
        </div>
      </div>
    </header>
  )
}
