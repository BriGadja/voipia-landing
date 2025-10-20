'use client'

import Link from 'next/link'
import { ArrowLeft, LayoutDashboard } from 'lucide-react'
import { LogoutButton } from '@/components/auth/LogoutButton'

interface DashboardHeaderProps {
  userEmail: string
  title?: string
  backLink?: string
  backLabel?: string
}

/**
 * Dashboard Header Component
 * Displays user info, title, navigation, and logout button
 */
export function DashboardHeader({
  userEmail,
  title = 'Dashboard Analytics',
  backLink,
  backLabel = 'Dashboard Global'
}: DashboardHeaderProps) {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-white/10 bg-black/50 backdrop-blur-lg">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between gap-4">
          {/* Left: Navigation + Title and User */}
          <div className="flex items-center gap-4 flex-1 min-w-0">
            {/* Back Button */}
            {backLink && (
              <Link
                href={backLink}
                className="flex items-center gap-2 px-3 py-2 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 transition-colors text-sm text-white/80 hover:text-white shrink-0"
              >
                <ArrowLeft className="w-4 h-4" />
                <LayoutDashboard className="w-4 h-4" />
                <span className="hidden sm:inline">{backLabel}</span>
              </Link>
            )}

            <div className="flex-1 min-w-0">
              <h1 className="text-2xl font-bold text-white mb-1">{title}</h1>
              <p className="text-sm text-white/60 truncate">
                Connecté en tant que {userEmail}
              </p>
            </div>
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
