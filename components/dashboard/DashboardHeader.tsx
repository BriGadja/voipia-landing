'use client'

import { User } from 'lucide-react'
import { LogoutButton } from '@/components/auth/LogoutButton'
import { DashboardBreadcrumb } from './DashboardBreadcrumb'

interface DashboardHeaderProps {
  userEmail: string
  title?: string
}

/**
 * Dashboard Header Component
 * Displays user info, breadcrumb navigation, and logout button
 */
export function DashboardHeader({ userEmail, title }: DashboardHeaderProps) {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-white/10 bg-black/50 backdrop-blur-lg">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between gap-4">
          {/* Left: Breadcrumb */}
          <div className="flex-1 min-w-0">
            <DashboardBreadcrumb title={title} />
          </div>

          {/* Right: User info + Logout */}
          <div className="flex items-center gap-4">
            {/* User Email */}
            <div className="hidden md:flex items-center gap-2 text-sm text-white/70">
              <User className="w-4 h-4" />
              <span className="truncate max-w-[200px]">{userEmail}</span>
            </div>

            {/* Logout Button */}
            <LogoutButton />
          </div>
        </div>
      </div>
    </header>
  )
}
