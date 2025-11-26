import {
  LayoutDashboard,
  TrendingUp,
  Users,
  Receipt,
  Building2,
  Settings,
  type LucideIcon,
} from 'lucide-react'

export interface NavItem {
  title: string
  href: string
  icon: LucideIcon
  badge?: string
  adminOnly?: boolean
}

export interface NavGroup {
  label: string
  items: NavItem[]
  adminOnly?: boolean
}

export const sidebarConfig: NavGroup[] = [
  {
    label: 'Platform',
    items: [
      {
        title: 'Overview',
        href: '/dashboard',
        icon: LayoutDashboard,
      },
      {
        title: 'Performance',
        href: '/dashboard/performance',
        icon: TrendingUp,
      },
      {
        title: 'Agents',
        href: '/dashboard/agents',
        icon: Users,
      },
    ],
  },
  {
    label: 'Financier',
    items: [
      {
        title: 'Vue Financière',
        href: '/dashboard/financial',
        icon: Receipt,
      },
    ],
  },
  {
    label: 'Administration',
    adminOnly: true,
    items: [
      {
        title: 'Clients',
        href: '/dashboard/clients',
        icon: Building2,
      },
    ],
  },
]

export const settingsNavItem: NavItem = {
  title: 'Paramètres',
  href: '/dashboard/settings',
  icon: Settings,
}
