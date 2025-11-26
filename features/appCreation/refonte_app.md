# Architecture et navigation pour refonte SaaS multi-tenant Voipia

**Recommandation principale** : Conserver le routing path-based (`voipia.fr/dashboard/*`) avec une architecture flat utilisant Supabase RLS pour le filtrage des données et l'UI conditionnelle pour la différenciation des rôles. Cette approche offre la simplicité d'implémentation, la compatibilité optimale avec votre stack actuel, et une évolutivité vers le subdomain si nécessaire dans le futur.

Le choix d'une sidebar collapsible shadcn/ui avec groupement logique (Platform, Analytics, Administration) permettra une navigation intuitive pour les deux rôles. L'état des filtres persisté en URL via `nuqs` garantira une expérience fluide lors des drill-through entre dashboards.

---

## Path-based routing : le choix pragmatique pour démarrer

Le débat subdomain (`app.voipia.fr`) vs path-based (`voipia.fr/dashboard/*`) se résout clairement en faveur du path-based pour votre contexte actuel. Les SaaS modernes comme **Vercel**, **Linear** et **Notion** utilisent tous une approche path-based unifiée, tandis que les subdomains (Stripe, Intercom) sont privilégiés par des entreprises plus matures avec des équipes séparées pour le marketing et l'application.

L'avantage décisif du path-based réside dans la **simplicité de la gestion d'authentification** avec Supabase. Les cookies de session fonctionnent nativement sans configuration de domaine. En subdomain, il faudrait configurer `cookieOptions.domain = '.voipia.fr'` dans le client Supabase, modifier le middleware pour propager les cookies correctement, et gérer les complexités du développement local (localhost ne supporte pas les subdomains).

| Critère | Path-based `/dashboard/*` | Subdomain `app.voipia.fr` |
|---------|---------------------------|---------------------------|
| **Auth Supabase** | Configuration native | Cookie domain requis |
| **SEO** | Hérite de l'autorité du domaine | Construit sa propre autorité |
| **Dev local** | Simple (localhost:3000) | Complexe (/etc/hosts) |
| **OAuth** | URL unique à whitelister | Multiple URLs |
| **Maintenance** | Codebase unifié | Potentiellement séparé |
| **Migration future** | Vers subdomain possible | Déjà en place |

La configuration Next.js reste standard avec le path-based. Si vous migrez vers subdomain ultérieurement, un middleware de rewrite suffit :

```typescript
// middleware.ts - Migration future vers subdomain
export function middleware(req: NextRequest) {
  const hostname = req.headers.get('host') || ''
  if (hostname.startsWith('app.')) {
    const url = req.nextUrl.clone()
    url.pathname = `/dashboard${url.pathname}`
    return NextResponse.rewrite(url)
  }
}
```

**Recommandation** : Restez sur `voipia.fr/dashboard/*`. Prévoyez une migration subdomain uniquement si vous séparez l'équipe marketing de l'équipe produit, ou si vous implémentez des subdomains par tenant (`client.voipia.fr`).

---

## Architecture des routes Next.js 15 App Router

La structure flat sous `/dashboard/*` avec Supabase RLS représente l'architecture optimale. Les route groups `()` permettent d'organiser le code sans affecter les URLs, tandis que RLS filtre automatiquement les données selon le rôle de l'utilisateur connecté.

### Structure de dossiers recommandée

```
app/
├── (auth)/                          # Pages publiques
│   ├── login/page.tsx
│   └── layout.tsx
├── dashboard/
│   ├── layout.tsx                   # Shell principal + sidebar
│   ├── page.tsx                     # /dashboard - Overview
│   ├── loading.tsx
│   ├── error.tsx
│   │
│   ├── performance/
│   │   ├── page.tsx                 # /dashboard/performance
│   │   └── loading.tsx
│   │
│   ├── billing/
│   │   ├── page.tsx                 # /dashboard/billing
│   │   └── [invoiceId]/page.tsx     # /dashboard/billing/[invoiceId]
│   │
│   ├── costs/
│   │   └── page.tsx                 # /dashboard/costs
│   │
│   ├── agents/
│   │   ├── page.tsx                 # /dashboard/agents
│   │   └── [agentId]/
│   │       ├── page.tsx             # /dashboard/agents/[agentId]
│   │       └── calls/
│   │           └── page.tsx         # Historique appels agent
│   │
│   ├── clients/                     # Section admin (filtré par UI)
│   │   ├── page.tsx                 # /dashboard/clients
│   │   └── [clientId]/
│   │       ├── page.tsx             # /dashboard/clients/[clientId]
│   │       ├── performance/page.tsx
│   │       └── agents/
│   │           └── [agentId]/page.tsx
│   │
│   ├── settings/
│   │   ├── page.tsx                 # /dashboard/settings
│   │   ├── profile/page.tsx
│   │   └── notifications/page.tsx
│   │
│   └── @modal/                      # Parallel route pour modales
│       ├── (.)agents/[agentId]/calls/[callId]/page.tsx
│       └── default.tsx
└── middleware.ts
```

La protection des routes admin s'effectue à deux niveaux. Le **middleware** gère les redirections d'authentification générales, tandis que les **layouts** vérifient les permissions spécifiques par section :

```typescript
// app/dashboard/clients/layout.tsx
export default async function ClientsLayout({ children }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user?.id)
    .single()
  
  if (profile?.role !== 'admin_voipia') {
    notFound() // Client ne voit jamais cette section
  }
  
  return <>{children}</>
}
```

Les breadcrumbs dynamiques utilisent un parallel route catch-all qui reconstruit automatiquement le chemin depuis les segments URL :

```typescript
// app/dashboard/@breadcrumbs/[...catchAll]/page.tsx
const labelMap = {
  'dashboard': 'Dashboard',
  'performance': 'Performance', 
  'clients': 'Clients',
  'agents': 'Agents',
  'settings': 'Paramètres'
}
```

---

## Structure de sidebar avec navigation contextuelle

La sidebar shadcn/ui en mode `collapsible="icon"` offre le meilleur compromis : elle préserve la visibilité des icônes en mode réduit tout en maximisant l'espace de contenu. L'état de collapse se persiste via cookies pour compatibilité SSR.

### Configuration des groupements

```typescript
const sidebarConfig = {
  header: {
    // Admin: TenantSwitcher (dropdown de sélection client)
    // Client: AgentSelector (si multi-agents)
    component: role === 'admin' ? TenantSwitcher : AgentSelector
  },
  
  groups: [
    {
      label: "Platform",
      items: [
        { title: "Overview", icon: LayoutDashboard, href: "/dashboard" },
        { title: "Performance", icon: TrendingUp, href: "/dashboard/performance" },
        { title: "Agents", icon: Bot, href: "/dashboard/agents" },
      ]
    },
    {
      label: "Financier",
      items: [
        { title: "Facturation", icon: Receipt, href: "/dashboard/billing" },
        { title: "Coûts", icon: DollarSign, href: "/dashboard/costs" },
      ]
    },
    {
      label: "Administration",  // Visible uniquement pour admin
      adminOnly: true,
      items: [
        { title: "Clients", icon: Building2, href: "/dashboard/clients" },
        { title: "Analytics globales", icon: BarChart3, href: "/dashboard/analytics" },
        { title: "Logs d'audit", icon: History, href: "/dashboard/logs" },
      ]
    }
  ],
  
  footer: {
    component: UserNavMenu // Profil, Settings, Sign Out
  }
}
```

### Implémentation du context switcher

Pour les admins, un **TenantSwitcher** en haut de sidebar permet de basculer entre les vues client :

```tsx
<DropdownMenu>
  <DropdownMenuTrigger asChild>
    <SidebarMenuButton size="lg">
      <div className="flex aspect-square size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
        {currentClient?.name.charAt(0) || 'V'}
      </div>
      <div className="flex flex-col gap-0.5 leading-none">
        <span className="font-semibold">
          {currentClient?.name || 'Vue globale'}
        </span>
        <span className="text-xs text-muted-foreground">
          {currentClient ? 'Client' : 'Admin Voipia'}
        </span>
      </div>
      <ChevronsUpDown className="ml-auto" />
    </SidebarMenuButton>
  </DropdownMenuTrigger>
  <DropdownMenuContent align="start" className="w-[--radix-dropdown-menu-trigger-width]">
    <DropdownMenuItem onClick={() => setClient(null)}>
      <Globe className="mr-2 h-4 w-4" />
      Vue globale (Admin)
    </DropdownMenuItem>
    <DropdownMenuSeparator />
    {clients.map(client => (
      <DropdownMenuItem key={client.id} onClick={() => setClient(client)}>
        {client.name}
      </DropdownMenuItem>
    ))}
  </DropdownMenuContent>
</DropdownMenu>
```

Pour les clients avec plusieurs agents, un sélecteur similaire mais simplifié permet de filtrer la vue par agent spécifique.

---

## Parcours utilisateur Admin vs Client

### Flow Admin Voipia

Le parcours admin suit une logique de **drill-down hiérarchique** : vue globale → client spécifique → agent → détails appels.

```
Login
  │
  ▼
Dashboard Global (/dashboard)
  ├── KPIs système : clients actifs, appels totaux, revenus
  ├── Alertes urgentes (clients à risque, anomalies)
  └── Vue agrégée performances
        │
        ▼ [Click "Voir tous les clients"]
Clients List (/dashboard/clients)
  ├── Tableau filtrable/triable
  └── Cards métriques par client
        │
        ▼ [Click ligne client]
Client Detail (/dashboard/clients/[clientId])
  ├── KPIs client spécifique
  ├── Liste des agents
  └── Historique facturation
        │
        ▼ [Click agent]
Agent Detail (/dashboard/clients/[clientId]/agents/[agentId])
  ├── Performance agent
  ├── Historique appels
  └── Configuration
        │
        ▼ [Click appel → Modal]
Call Recording (Modal overlay)
  ├── Player audio
  ├── Métadonnées
  └── Transcript
```

Le **context switching** via TenantSwitcher permet à l'admin de basculer en "vue client" : la sidebar affiche alors uniquement les sections accessibles au client, avec un bandeau indicateur clair :

```html
<div className="bg-amber-100 border-b border-amber-200 px-4 py-2 flex items-center justify-between">
  <span className="text-sm">Visualisation : <strong>Client ABC Corp</strong></span>
  <Button variant="ghost" size="sm" onClick={exitClientView}>
    Retour vue admin
  </Button>
</div>
```

### Flow Client

Le parcours client est **centré sur ses agents** avec accès direct aux métriques de performance :

```
Login
  │
  ▼
Dashboard Personnel (/dashboard)
  ├── KPIs personnels : mes appels, ma facturation
  ├── Mes agents (cards cliquables)
  └── Activité récente
        │
        ▼ [Click card agent]
Agent Detail (/dashboard/agents/[agentId])
  ├── Performance détaillée
  ├── Historique appels (tableau paginé)
  └── Actions : modifier config, voir recordings
        │
        ▼ [Click ligne appel]
Call Detail (Modal)
  ├── Recording player
  ├── Durée, coût, statut
  └── Transcript si disponible
```

### Logique de redirection post-login

```typescript
function getPostLoginRedirect(user: User): string {
  if (user.isFirstLogin) {
    return '/onboarding'
  }
  
  if (user.role === 'admin_voipia') {
    return user.lastVisitedPage || '/dashboard'
  }
  
  // Client
  if (user.agents.length === 0) {
    return '/dashboard/setup' // Guide création premier agent
  }
  return user.lastVisitedPage || '/dashboard'
}
```

---

## Layout des dashboards avec KPIs et filtres

La structure de page suit le pattern **F-scan** : KPIs critiques en haut à gauche, filtres sticky, puis graphiques organisés en grille responsive.

### Structure de page type

```tsx
function DashboardPage() {
  return (
    <div className="space-y-6">
      {/* Sticky Filter Bar */}
      <div className="sticky top-0 z-10 bg-background/95 backdrop-blur border-b py-3">
        <DashboardFilters />
      </div>
      
      {/* KPI Row: 4 colonnes desktop, 2 tablet, 1 mobile */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard title="Appels totaux" value="12,847" change={8.2} trend="up" 
                 onClick={() => router.push('/dashboard/performance?metric=calls')} />
        <KPICard title="Durée moyenne" value="4:32" change={-2.1} trend="down" />
        <KPICard title="Taux résolution" value="87%" change={3.4} trend="up" />
        <KPICard title="Coût total" value="€2,340" change={5.1} trend="up" />
      </div>
      
      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="lg:col-span-2">
          <CardHeader><CardTitle>Volume d'appels</CardTitle></CardHeader>
          <CardContent><VolumeChart /></CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle>Par type d'agent</CardTitle></CardHeader>
          <CardContent><AgentTypeChart /></CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle>Distribution horaire</CardTitle></CardHeader>
          <CardContent><HourlyDistribution /></CardContent>
        </Card>
      </div>
    </div>
  )
}
```

### Gestion des filtres avec nuqs

L'URL devient la source de vérité pour les filtres, permettant le partage de vues et la persistance lors de la navigation :

```typescript
// lib/search-params.ts
import { parseAsString, parseAsIsoDateTime, createSearchParamsCache } from 'nuqs/server'

export const dashboardFilters = {
  dateFrom: parseAsIsoDateTime.withDefault(subDays(new Date(), 30)),
  dateTo: parseAsIsoDateTime.withDefault(new Date()),
  preset: parseAsString.withDefault('last30days'),
  agentType: parseAsString,
  status: parseAsString
}

// components/dashboard-filters.tsx
'use client'
export function DashboardFilters() {
  const [filters, setFilters] = useQueryStates(dashboardFilters, { shallow: false })
  
  const handlePresetChange = (preset: string) => {
    const ranges = {
      'last7days': { from: subDays(new Date(), 7), to: new Date() },
      'last30days': { from: subDays(new Date(), 30), to: new Date() },
      'thisMonth': { from: startOfMonth(new Date()), to: new Date() }
    }
    setFilters({ ...ranges[preset], preset })
  }
  
  return (
    <div className="flex flex-wrap gap-3">
      <Select value={filters.preset} onValueChange={handlePresetChange}>
        <SelectTrigger className="w-[160px]">
          <SelectValue placeholder="Période" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="last7days">7 derniers jours</SelectItem>
          <SelectItem value="last30days">30 derniers jours</SelectItem>
          <SelectItem value="thisMonth">Ce mois</SelectItem>
          <SelectItem value="custom">Personnalisé</SelectItem>
        </SelectContent>
      </Select>
      
      {filters.preset === 'custom' && (
        <DatePickerWithRange 
          from={filters.dateFrom} 
          to={filters.dateTo}
          onSelect={({ from, to }) => setFilters({ dateFrom: from, dateTo: to })}
        />
      )}
      
      <ActiveFilterChips filters={filters} onClear={setFilters} />
    </div>
  )
}
```

Les filtres se propagent automatiquement lors des drill-through. Un clic sur un KPI card navigue vers la page détaillée en préservant les paramètres :

```typescript
const handleKPIClick = (metric: string) => {
  const params = new URLSearchParams(searchParams.toString())
  params.set('source', 'overview')
  router.push(`/dashboard/performance?${params.toString()}`)
}
```

---

## Patterns de drill-through et navigation contextuelle

Le drill-through suit des règles claires selon la complexité du contenu cible :

| Source | Cible | Pattern | Préservation contexte |
|--------|-------|---------|----------------------|
| KPI card | Page détaillée | Navigation complète | Filtres en URL |
| Ligne tableau | Détail entité | Navigation complète | ID + filtres |
| Segment graphique | Vue filtrée | Navigation + params | Segment + dates |
| Appel dans liste | Recording | **Modal overlay** | Parent visible |
| Quick action | Formulaire | Modal ou drawer | État courant |

Les modales pour les recordings utilisent les **intercepting routes** de Next.js 15, permettant une URL partageable tout en maintenant le contexte parent :

```
app/dashboard/
├── agents/[agentId]/calls/
│   ├── page.tsx                      # Liste des appels
│   └── [callId]/
│       └── page.tsx                  # Page complète call (accès direct)
├── @modal/
│   ├── (.)agents/[agentId]/calls/[callId]/
│   │   └── page.tsx                  # Intercepte pour afficher en modal
│   └── default.tsx
└── layout.tsx                        # Inclut {modal} slot
```

Le breadcrumb dynamique reconstruit le chemin depuis les segments URL et affiche les noms d'entités :

```tsx
// Breadcrumb dynamique avec noms
<Breadcrumb>
  <BreadcrumbList>
    <BreadcrumbItem>
      <BreadcrumbLink href="/dashboard">Dashboard</BreadcrumbLink>
    </BreadcrumbItem>
    <BreadcrumbSeparator />
    <BreadcrumbItem>
      <BreadcrumbLink href="/dashboard/clients">Clients</BreadcrumbLink>
    </BreadcrumbItem>
    <BreadcrumbSeparator />
    <BreadcrumbItem>
      <BreadcrumbPage>{client.name}</BreadcrumbPage>
    </BreadcrumbItem>
  </BreadcrumbList>
</Breadcrumb>
```

---

## Checklist d'implémentation et priorités

### Phase 1 : Fondations (Semaine 1-2)

- [x] Configurer la structure de routes `/dashboard/*` avec layouts partagés *(existant, conservé)*
- [x] Implémenter le middleware d'authentification Supabase *(existant)*
- [x] Créer le composant Sidebar shadcn/ui avec groupements *(FAIT - 2025-11-26)*
- [x] Ajouter le système de permissions via Context + RLS *(existant + UI conditionnelle)*
- [ ] Mettre en place nuqs pour la gestion des filtres URL

### Phase 2 : Navigation et UX (Semaine 3-4)

- [x] Implémenter TenantSwitcher pour admins *(FAIT - 2025-11-26)*
- [x] Créer les breadcrumbs dynamiques *(FAIT - 2025-11-26, approche simplifiée)*
- [ ] Développer les KPI cards cliquables avec drill-through
- [ ] Configurer les intercepting routes pour modales

### Phase 3 : Dashboards (Semaine 5-6)

- [x] Dashboard Overview avec KPIs et graphiques *(REFACTORISÉ - 2025-11-26)*
- [x] Page Performance avec filtres avancés *(FAIT - 2025-11-26)*
- [ ] Section Clients (admin) avec liste et détails
- [x] Pages Agent avec historique appels *(FAIT - 2025-11-26: /agents + /agents/[agentId])*

### Composants shadcn/ui requis

```bash
npx shadcn@latest add sidebar card button select tabs table badge
npx shadcn@latest add sheet popover calendar breadcrumb skeleton
npx shadcn@latest add dropdown-menu avatar separator
```

### Stack recommandée complémentaire

- **Charts** : Tremor (design cohérent avec shadcn) ou Recharts
- **État URL** : nuqs pour type-safe searchParams
- **Data fetching** : React Query + Supabase client
- **Formulaires** : React Hook Form + Zod

Cette architecture garantit une **évolutivité naturelle** : l'ajout de nouvelles fonctionnalités (notifications, settings avancés, intégrations) s'insère dans la structure existante sans refactoring majeur. Le pattern flat avec RLS centralise la logique de sécurité côté base de données, tandis que l'UI conditionnelle offre une expérience adaptée à chaque rôle sans duplication de code.