# PRP: Dashboard Louis Original - Reconstruction

## 🎯 Goal

Reconstruire le dashboard Louis pour qu'il corresponde exactement à la capture d'écran originale (`Dashboard/Louis/2025-10-16_06h48_15.png`), avec un design analytics complet, des KPIs spécifiques, et 4 graphiques distincts.

## 📸 Reference Screenshot

**Location**: `C:\Users\pc\Documents\Projets\voipia-landing\Dashboard\Louis\2025-10-16_06h48_15.png`

### Key Visual Elements Observed:

**Header**:
- Titre: "Dashboard Analytics" (pas "Dashboard Louis")
- Email utilisateur: "brice@voipia.fr"
- Bouton déconnexion à droite

**Filtres**:
- Sélecteurs de dates: du 15/09/2025 au 15/10/2025
- Boutons rapides: Aujourd'hui | 7 derniers jours | 30 derniers jours | Ce mois | Mois dernier | Cette année
- Filtres dropdown: "Toutes les entreprises" | "Tous les agents"

**KPIs (5 cartes)**:
1. **Total Appels**: 118 (bleu cyan #06b6d4)
2. **Taux de Décroché**: 23.7% (teal #14b8a6)
3. **Durée Moyenne**: 0:42 (ambre #f59e0b)
4. **RDV Pris**: 9 (violet #8b5cf6)
5. **Taux de Conversion**: 32.1% (bleu cyan #06b6d4)

**Graphiques (grille 2x2)**:

1. **Volume d'appels par jour** (top-left, area chart):
   - 3 séries de données empilées
   - Appels répondus: lime #84cc16
   - RDV pris: violet #d946ef
   - Total appels: cyan #06b6d4
   - Axe X: dates (25 sept - 15 oct)
   - Légende en bas

2. **Distribution des émotions** (top-right, donut chart):
   - Neutre: 81.4% (jaune #fbbf24)
   - Négatif: 8.5% (rose #fb7185)
   - Positif: 10.2% (vert #84cc16)
   - Légende à droite avec pourcentages

3. **Résultats d'appels** (bottom-left, bar chart vertical):
   - Messagerie: ~75 (cyan #06b6d4)
   - RDV refusé: ~15 (violet #8b5cf6)
   - TOO_CONF: ~15 (teal #10b981)
   - RDV PRIS: ~8 (orange #f59e0b)
   - Barres colorées individuellement

4. **Taux de messagerie par agent** (bottom-right, bar chart horizontal):
   - Voipia - Louis - setter: ~90% (cyan #06b6d4)
   - Norloc - Louis - setter: ~80% (violet #8b5cf6)
   - Exotlc Design - Louis - setter: ~60% (emerald #10b981)
   - Stefano Design - Louis - setter: ~20% (orange #f59e0b)
   - Barres horizontales colorées par agent

**Design System**:
- Fond: noir pur (#000000)
- Cartes: glassmorphism avec `bg-black/20 border border-white/20`
- Coins arrondis: `rounded-xl`
- Titres sections: blanc, font-semibold, text-sm
- Padding cartes: `p-3`
- Grille responsive: `grid-cols-1 lg:grid-cols-2 gap-6`

## 📚 Context & References

### Files to Understand

```yaml
- file: Dashboard/Louis/2025-10-16_06h48_15.png
  why: Référence visuelle exacte du design attendu

- file: app/dashboard/[agentType]/LouisDashboardClient.tsx
  why: Component client actuel à modifier

- file: components/dashboard/Charts/CallVolumeChart.tsx
  why: Chart existant à adapter (déjà conforme)

- file: components/dashboard/Charts/EmotionDistribution.tsx
  why: Chart existant à adapter (déjà conforme)

- file: components/dashboard/Charts/OutcomeBreakdown.tsx
  why: Chart à modifier pour afficher 4 résultats spécifiques

- file: components/dashboard/Charts/VoicemailByAgent.tsx
  why: Chart existant à adapter (déjà conforme au design)

- file: components/dashboard/KPIGrid.tsx
  why: Grille KPI à simplifier (5 KPIs au lieu de 8+)

- file: components/dashboard/Filters/DateRangeFilter.tsx
  why: Filtres de dates déjà conformes

- file: components/dashboard/DashboardHeader.tsx
  why: Header à modifier (titre "Dashboard Analytics")

- file: lib/hooks/useDashboardData.ts
  why: Hooks de data fetching

- file: CLAUDE.md
  why: Workflow avec vérification browser requise
```

## 🏗️ Implementation Blueprint

### Phase 1: Modifier le Header

**File**: `components/dashboard/DashboardHeader.tsx`

**Changes**:
```typescript
// Remplacer le titre dynamique par "Dashboard Analytics"
<h1 className="text-2xl font-bold text-white">Dashboard Analytics</h1>

// S'assurer que l'email utilisateur s'affiche
<p className="text-sm text-white/60">
  Connecté en tant que {userEmail}
</p>
```

### Phase 2: Créer KPIGrid Simplifié pour Louis

**File**: `components/dashboard/KPIGrid.tsx`

**Changes**:
```typescript
// Dans la logique pour agentType === 'louis'
// Afficher uniquement 5 KPIs spécifiques:

const louisKPIs = [
  {
    label: 'Total Appels',
    value: current_period.total_calls,
    previousValue: previous_period.total_calls,
    format: 'number',
    decorationColor: 'cyan', // #06b6d4
  },
  {
    label: 'Taux de Décroché',
    value: current_period.answer_rate,
    previousValue: previous_period.answer_rate,
    format: 'percentage',
    decorationColor: 'teal', // #14b8a6
  },
  {
    label: 'Durée Moyenne',
    value: current_period.avg_duration,
    previousValue: previous_period.avg_duration,
    format: 'duration',
    decorationColor: 'amber', // #f59e0b
  },
  {
    label: 'RDV Pris',
    value: current_period.appointments_scheduled,
    previousValue: previous_period.appointments_scheduled,
    format: 'number',
    decorationColor: 'violet', // #8b5cf6
  },
  {
    label: 'Taux de Conversion',
    value: current_period.conversion_rate,
    previousValue: previous_period.conversion_rate,
    format: 'percentage',
    decorationColor: 'cyan', // #06b6d4
  },
]

// Grid layout pour 5 KPIs
<div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-6">
```

### Phase 3: Ajuster OutcomeBreakdown Chart

**File**: `components/dashboard/Charts/OutcomeBreakdown.tsx`

**Changes**:
```typescript
// Filtrer et afficher uniquement 4 résultats spécifiques
const specificOutcomes = ['voicemail', 'appointment_refused', 'too_short', 'appointment_scheduled']

const chartData = data
  .filter(item => specificOutcomes.includes(item.outcome))
  .map((item) => ({
    outcome: outcomeLabels[item.outcome] || item.outcome,
    Appels: item.count,
  }))
  .sort((a, b) => b.Appels - a.Appels)

// Couleurs spécifiques pour chaque résultat
const outcomeColors: Record<string, string> = {
  'Messagerie': '#06b6d4',        // cyan
  'RDV refusé': '#8b5cf6',        // violet
  'Trop court': '#10b981',        // emerald (TOO_CONF)
  'RDV pris': '#f59e0b',          // orange
}
```

### Phase 4: Vérifier les Autres Charts

**Files**:
- `CallVolumeChart.tsx` ✅ Déjà conforme (3 séries: Total, Répondus, RDV)
- `EmotionDistribution.tsx` ✅ Déjà conforme (donut chart)
- `VoicemailByAgent.tsx` ✅ Déjà conforme (bar horizontal)

### Phase 5: Ajuster le Layout Principal

**File**: `app/dashboard/[agentType]/LouisDashboardClient.tsx`

**Structure**:
```tsx
<>
  {/* Header: Dashboard Analytics */}
  <DashboardHeader userEmail={userEmail} title="Dashboard Analytics" />

  <div className="container mx-auto px-4 py-8 space-y-8">
    {/* Filters Row */}
    <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
      <div className="flex flex-col sm:flex-row gap-4 w-full lg:w-auto">
        <DateRangeFilter ... />
        <ClientAgentFilter ... />
      </div>
      <ExportCSVButton ... />
    </div>

    {/* KPIs Grid - 5 KPIs en une ligne sur desktop */}
    <KPIGrid data={kpiData} isLoading={isLoadingKPIs} agentType="louis" />

    {/* Charts Grid - 2x2 */}
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <CallVolumeChart data={chartData?.call_volume_by_day || []} />
      <EmotionDistribution data={chartData?.emotion_distribution || []} />
      <OutcomeBreakdown data={chartData?.outcome_distribution || []} />
      <VoicemailByAgent data={chartData?.voicemail_by_agent || []} />
    </div>
  </div>
</>
```

### Phase 6: Supprimer la Table Performance Agent

**File**: `app/dashboard/[agentType]/LouisDashboardClient.tsx`

**Action**: Supprimer complètement le bloc de la table "Performance par agent" (lignes 82-146).

## 🔄 Validation Loops

### 1. Code Quality
```bash
npm run lint
npm run build
```

### 2. Visual Verification (REQUIRED)

**Playwright MCP Testing**:
```bash
# 1. Start dev server
npm run dev

# 2. Use Playwright MCP to navigate
mcp__playwright__browser_navigate(url: "http://localhost:3000/dashboard/louis")

# 3. Take screenshot
mcp__playwright__browser_take_screenshot(filename: "louis-dashboard-rebuilt.png")

# 4. Compare with original
# Compare: Dashboard/Louis/2025-10-16_06h48_15.png
# vs: louis-dashboard-rebuilt.png
```

**Verification Checklist**:
- [ ] Header affiche "Dashboard Analytics"
- [ ] Email utilisateur visible
- [ ] 5 KPIs affichés horizontalement
- [ ] KPI couleurs correctes (cyan, teal, amber, violet, cyan)
- [ ] 4 graphiques en grille 2x2
- [ ] Volume d'appels: 3 séries area chart
- [ ] Émotions: donut chart avec légende
- [ ] Résultats: 4 barres verticales colorées
- [ ] Messagerie: barres horizontales par agent
- [ ] Fond noir avec glassmorphism
- [ ] Coins arrondis et bordures subtiles

### 3. Responsive Testing
```bash
# Test mobile
mcp__playwright__browser_resize(width: 375, height: 667)
mcp__playwright__browser_take_screenshot(filename: "louis-mobile.png")

# Test tablet
mcp__playwright__browser_resize(width: 768, height: 1024)
mcp__playwright__browser_take_screenshot(filename: "louis-tablet.png")

# Test desktop
mcp__playwright__browser_resize(width: 1920, height: 1080)
mcp__playwright__browser_take_screenshot(filename: "louis-desktop.png")
```

### 4. Data Verification

**Check Data Fetching**:
```typescript
// Vérifier dans la console browser que les données sont correctement chargées
// useLouisKPIs devrait retourner les 5 métriques
// useLouisChartData devrait retourner:
//   - call_volume_by_day: array avec total_calls, answered_calls, appointments
//   - emotion_distribution: array avec emotion, count
//   - outcome_distribution: array avec outcome, count (filtré sur 4 types)
//   - voicemail_by_agent: array avec agent, rate
```

## ⚠️ Anti-patterns

❌ **Ne pas faire**:
- Changer le titre à autre chose que "Dashboard Analytics"
- Afficher plus de 5 KPIs dans la grille principale
- Modifier les couleurs des KPIs (respecter: cyan, teal, amber, violet, cyan)
- Garder la table "Performance par agent"
- Afficher tous les outcomes dans OutcomeBreakdown (seulement 4)
- Modifier la grille des charts (doit rester 2x2)

✅ **Faire**:
- Respecter exactement les couleurs de la capture d'écran
- Utiliser la grille 5 colonnes pour les KPIs sur desktop
- Filtrer les outcomes à 4 types spécifiques
- Supprimer la table agent performance
- Garder le design glassmorphism noir
- Tester visuellement avec Playwright

## 📋 Task Breakdown

### Step 1: Header Update
- [ ] Modifier `DashboardHeader.tsx` pour forcer titre "Dashboard Analytics"
- [ ] Vérifier affichage email utilisateur

### Step 2: KPIs Simplification
- [ ] Modifier `KPIGrid.tsx` pour mode "louis-original"
- [ ] Définir exactement 5 KPIs avec couleurs correctes
- [ ] Changer grid layout à `lg:grid-cols-5`
- [ ] Tester l'affichage responsive

### Step 3: OutcomeBreakdown Filter
- [ ] Modifier `OutcomeBreakdown.tsx`
- [ ] Filtrer sur 4 outcomes spécifiques
- [ ] Assigner couleurs exactes par outcome
- [ ] Vérifier ordre des barres

### Step 4: Layout Cleanup
- [ ] Modifier `LouisDashboardClient.tsx`
- [ ] Supprimer table "Performance par agent"
- [ ] Organiser charts en grille 2x2
- [ ] Vérifier espacement et responsive

### Step 5: Visual Testing
- [ ] Run `npm run dev`
- [ ] Navigate avec Playwright MCP
- [ ] Prendre screenshots à différentes résolutions
- [ ] Comparer avec screenshot original
- [ ] Ajuster si nécessaire

### Step 6: Build & Deploy
- [ ] Run `npm run lint`
- [ ] Run `npm run build`
- [ ] Vérifier aucune erreur
- [ ] Commit changes

## 🎨 Design Tokens

```typescript
// KPI Colors
const kpiColors = {
  totalCalls: '#06b6d4',      // cyan
  answerRate: '#14b8a6',      // teal
  avgDuration: '#f59e0b',     // amber
  appointments: '#8b5cf6',    // violet
  conversionRate: '#06b6d4',  // cyan
}

// Chart Series Colors
const chartColors = {
  totalCalls: '#06b6d4',      // cyan
  answeredCalls: '#84cc16',   // lime
  appointments: '#d946ef',    // fuchsia

  emotionNeutral: '#fbbf24',  // amber/yellow
  emotionNegative: '#fb7185', // rose
  emotionPositive: '#84cc16', // lime

  outcomeVoicemail: '#06b6d4',    // cyan
  outcomeRefused: '#8b5cf6',      // violet
  outcomeTooShort: '#10b981',     // emerald
  outcomeScheduled: '#f59e0b',    // amber
}

// Card Styling
const cardStyle = "bg-black/20 border border-white/20 rounded-xl p-3"
```

## 📊 Expected Data Structures

### KPI Data
```typescript
interface LouisKPIData {
  current_period: {
    total_calls: number           // 118
    answer_rate: number           // 23.7
    avg_duration: number          // 42 (seconds)
    appointments_scheduled: number // 9
    conversion_rate: number       // 32.1
  }
  previous_period: {
    // same structure
  }
}
```

### Chart Data
```typescript
interface CallVolumeData {
  date: string
  total_calls: number
  answered_calls: number
  appointments: number
}

interface EmotionData {
  emotion: 'positive' | 'neutral' | 'negative'
  count: number
}

interface OutcomeData {
  outcome: 'voicemail' | 'appointment_refused' | 'too_short' | 'appointment_scheduled'
  count: number
}

interface VoicemailAgentData {
  agent: string  // "Voipia - Louis - setter"
  rate: number   // 90.5
}
```

## 🎯 Success Criteria

✅ Dashboard reconstruit affiche:
1. Titre "Dashboard Analytics" dans le header
2. Email utilisateur visible
3. Exactement 5 KPIs avec les bonnes couleurs
4. 4 graphiques en grille 2×2
5. Design glassmorphism noir avec bordures subtiles
6. Responsive sur mobile/tablet/desktop
7. Pas de table "Performance par agent"
8. Charts conformes au screenshot original

## 🔗 Related Documentation

- Next.js App Router: https://nextjs.org/docs/app
- Recharts Documentation: https://recharts.org/
- React DatePicker: https://reactdatepicker.com/
- Tailwind CSS: https://tailwindcss.com/docs

## 💡 Notes

- Cette reconstruction vise à restaurer l'ancien dashboard Louis visible dans la capture d'écran
- Le dashboard actuel a été modifié et contient des fonctionnalités supplémentaires
- Cette version "originale" est plus simple et focalisée sur les métriques essentielles
- Les données Supabase actuelles peuvent nécessiter des ajustements pour correspondre exactement aux valeurs de la capture
