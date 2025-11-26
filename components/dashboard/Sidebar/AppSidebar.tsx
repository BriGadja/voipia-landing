'use client'

import Link from 'next/link'
import { usePathname, useSearchParams } from 'next/navigation'
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
  useSidebar,
} from '@/components/ui/sidebar'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { sidebarConfig, settingsNavItem, type NavGroup } from './SidebarConfig'
import { TenantSwitcher } from './TenantSwitcher'
import { LogOut, ChevronsUpDown, User } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

interface AppSidebarProps {
  userEmail: string
  isAdmin: boolean
}

export function AppSidebar({ userEmail, isAdmin }: AppSidebarProps) {
  const pathname = usePathname()
  const router = useRouter()
  const searchParams = useSearchParams()
  const { state } = useSidebar()

  // Check if viewing as a specific client (tenant mode)
  const currentTenantId = searchParams.get('tenant')
  const isInClientView = !!currentTenantId

  const handleLogout = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/login')
  }

  // Filter navigation based on admin status
  // Hide admin-only sections when viewing as a specific client
  const showAdminSections = isAdmin && !isInClientView
  const filteredConfig = sidebarConfig
    .filter((group) => !group.adminOnly || showAdminSections)
    .map((group) => ({
      ...group,
      items: group.items.filter((item) => !item.adminOnly || showAdminSections),
    }))

  const userInitials = userEmail
    .split('@')[0]
    .slice(0, 2)
    .toUpperCase()

  return (
    <Sidebar collapsible="icon" className="border-r border-white/10">
      <SidebarHeader className="border-b border-white/10">
        <SidebarMenu>
          <SidebarMenuItem>
            <TenantSwitcher isAdmin={isAdmin} />
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>

      <SidebarContent>
        {filteredConfig.map((group) => (
          <SidebarGroup key={group.label}>
            <SidebarGroupLabel className="text-white/50 uppercase text-xs tracking-wider">
              {group.label}
            </SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {group.items.map((item) => {
                  const isActive = pathname === item.href ||
                    (item.href !== '/dashboard' && pathname.startsWith(item.href))

                  return (
                    <SidebarMenuItem key={item.href}>
                      <SidebarMenuButton
                        asChild
                        isActive={isActive}
                        tooltip={item.title}
                        className="text-white/70 hover:text-white hover:bg-white/10 data-[active=true]:bg-white/10 data-[active=true]:text-white"
                      >
                        <Link href={item.href}>
                          <item.icon className="size-4" />
                          <span>{item.title}</span>
                        </Link>
                      </SidebarMenuButton>
                    </SidebarMenuItem>
                  )
                })}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        ))}
      </SidebarContent>

      <SidebarFooter className="border-t border-white/10">
        <SidebarMenu>
          <SidebarMenuItem>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <SidebarMenuButton
                  size="lg"
                  className="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground text-white/70 hover:text-white hover:bg-white/10"
                >
                  <Avatar className="h-8 w-8 rounded-lg">
                    <AvatarFallback className="rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 text-white text-xs">
                      {userInitials}
                    </AvatarFallback>
                  </Avatar>
                  <div className="grid flex-1 text-left text-sm leading-tight">
                    <span className="truncate font-semibold text-white">
                      {userEmail.split('@')[0]}
                    </span>
                    <span className="truncate text-xs text-white/60">
                      {userEmail}
                    </span>
                  </div>
                  <ChevronsUpDown className="ml-auto size-4 text-white/60" />
                </SidebarMenuButton>
              </DropdownMenuTrigger>
              <DropdownMenuContent
                className="w-[--radix-dropdown-menu-trigger-width] min-w-56 rounded-lg bg-zinc-900 border-white/10"
                side={state === 'collapsed' ? 'right' : 'top'}
                align="end"
                sideOffset={4}
              >
                <DropdownMenuItem asChild className="text-white/70 hover:text-white hover:bg-white/10 focus:bg-white/10 focus:text-white cursor-pointer">
                  <Link href={settingsNavItem.href}>
                    <User className="mr-2 h-4 w-4" />
                    {settingsNavItem.title}
                  </Link>
                </DropdownMenuItem>
                <DropdownMenuSeparator className="bg-white/10" />
                <DropdownMenuItem
                  onClick={handleLogout}
                  className="text-red-400 hover:text-red-300 hover:bg-red-500/10 focus:bg-red-500/10 focus:text-red-300 cursor-pointer"
                >
                  <LogOut className="mr-2 h-4 w-4" />
                  Déconnexion
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>

      <SidebarRail />
    </Sidebar>
  )
}
