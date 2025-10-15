# PRP: ROI & Mensualité Calculator for Voipia Voice Agents

## 🎯 Purpose & Goal

### Primary Objective
Implement an **interactive ROI and monthly cost calculator** for Voipia voice agents that enables prospects to understand the costs and return on investment of implementing voice AI solutions, supporting both inbound and outbound agent configurations.

### Business Value
- **Transparency**: Clear, upfront pricing to build trust with prospects
- **Lead Generation**: Convert visitors into qualified leads through interactive engagement
- **Qualification**: Identify use cases and volumes before sales contact
- **Education**: Demonstrate Voipia's flexibility and value proposition

### User Impact
- Instant cost visualization without sales interaction
- Customized calculations based on specific business needs
- Clear ROI demonstration to support purchase decisions
- Exportable results for internal stakeholder discussions

### Integration with Voipia Features
- Seamlessly integrates into the existing landing page flow
- Complements the AgentsGrid by providing cost context for Louis and Arthur
- Enhances the Metrics section by quantifying potential improvements
- Provides concrete data to support the Hero section's value proposition

## 📁 Context & References

```yaml
Essential Files:
  - file: CLAUDE.md
    why: Project rules, workflows, UI verification requirements
  - file: INITIAL_roi_calculator.md
    why: Complete feature requirements and specifications
  - file: app/page.tsx
    why: Main page structure for integration placement
  - file: components/sections/Metrics.tsx
    why: Animation patterns, glass card styling, viewport-based triggers
  - file: components/sections/AgentsGrid.tsx
    why: Card layouts, agent color schemes, component structure
  - file: components/sections/Navigation.tsx
    why: CTA button integration pattern
  - file: lib/constants.ts
    why: Data structure patterns, agent information
  - file: tailwind.config.ts
    why: Custom animations, color schemes, theme configuration
  - file: components/ui/GlassCard.tsx
    why: Reusable glass morphism card component
  - file: components/animations/FadeIn.tsx
    why: Animation wrapper patterns
  - file: lib/cn.ts
    why: Conditional class utility function

External Resources:
  - Next.js 15 App Router: https://nextjs.org/docs/app
  - Framer Motion: https://www.framer.com/motion/
  - Tailwind Forms: https://tailwindcss.com/docs/plugins#forms
  - React Hook Form: https://react-hook-form.com/
  - Radix UI Slider: https://www.radix-ui.com/primitives/docs/components/slider
```

## 🏗️ Implementation Blueprint

### 1. Component Structure

```typescript
// types/calculator.ts
export interface CalculatorState {
  mode: 'inbound' | 'outbound'
  volume: {
    perDay: number
    perWeek: number
    perMonth: number // Source of truth
  }
  averageCallDuration: number // minutes
  pricing: {
    perProcessing: number // € per call
    perMinute: number // € per minute
  }
  additionalCosts: {
    integration: number // one-time €
    monthlyFee: number // recurring €
  }
  // Outbound specific
  plannedMode?: {
    enabled: boolean
    frequency: number // minutes between calls
    dailySchedule: {
      startTime: string // HH:MM
      endTime: string // HH:MM
    }
    activeDays: boolean[] // 0=Mon, 6=Sun
  }
  // ROI calculation (optional)
  roi?: {
    averageConversionValue: number // €
    conversionRate: number // %
  }
}

export interface CalculatorResults {
  costPerCall: number
  monthlyOperational: number
  monthlyTotal: number
  firstYearTotal: number
  recurringAnnual: number
  roi?: {
    monthlyConversions: number
    monthlyRevenue: number
    monthlyProfit: number
  }
}
```

### 2. Main Component Architecture

```typescript
// components/sections/ROICalculator.tsx
'use client'

import { useState, useMemo, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Calculator, TrendingUp, Clock, Euro } from 'lucide-react'
import FadeIn from '@/components/animations/FadeIn'
import GlassCard from '@/components/ui/GlassCard'
import { cn } from '@/lib/cn'
import { calculateROI } from '@/lib/calculatorUtils'
import CalculatorInputs from './calculator/CalculatorInputs'
import CalculatorResults from './calculator/CalculatorResults'
import CalculatorCTA from './calculator/CalculatorCTA'

export default function ROICalculator() {
  const [state, setState] = useState<CalculatorState>(defaultState)
  const results = useMemo(() => calculateROI(state), [state])

  return (
    <section id="roi-calculator" className="py-24 relative overflow-hidden">
      {/* Background gradient matching Metrics section */}
      <div className="absolute inset-0 bg-gradient-to-br from-purple-900/10 via-blue-900/5 to-pink-900/10" />

      <div className="container mx-auto px-6 relative">
        <FadeIn>
          <div className="text-center mb-12">
            <h2 className="text-4xl lg:text-5xl font-bold text-white mb-4">
              Calculez votre ROI
            </h2>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Découvrez le coût et le retour sur investissement de nos agents vocaux IA
            </p>
          </div>
        </FadeIn>

        <div className="max-w-6xl mx-auto grid lg:grid-cols-3 gap-8">
          {/* Left: Inputs */}
          <div className="lg:col-span-2">
            <CalculatorInputs state={state} onChange={setState} />
          </div>

          {/* Right: Results */}
          <div className="lg:col-span-1">
            <CalculatorResults results={results} />
            <CalculatorCTA data={state} results={results} />
          </div>
        </div>
      </div>
    </section>
  )
}
```

### 3. Slider Component

```typescript
// components/ui/slider.tsx
import * as React from "react"
import * as SliderPrimitive from "@radix-ui/react-slider"
import { cn } from "@/lib/cn"

const Slider = React.forwardRef<
  React.ElementRef<typeof SliderPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof SliderPrimitive.Root>
>(({ className, ...props }, ref) => (
  <SliderPrimitive.Root
    ref={ref}
    className={cn(
      "relative flex w-full touch-none select-none items-center",
      className
    )}
    {...props}
  >
    <SliderPrimitive.Track className="relative h-2 w-full grow overflow-hidden rounded-full bg-gray-800/50 backdrop-blur-sm">
      <SliderPrimitive.Range className="absolute h-full bg-gradient-to-r from-purple-500 to-blue-500" />
    </SliderPrimitive.Track>
    <SliderPrimitive.Thumb className="block h-5 w-5 rounded-full border-2 border-primary bg-white ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 cursor-grab active:cursor-grabbing" />
  </SliderPrimitive.Root>
))
Slider.displayName = SliderPrimitive.Root.displayName

export { Slider }
```

### 4. Calculation Utilities

```typescript
// lib/calculatorUtils.ts
export function calculateROI(state: CalculatorState): CalculatorResults {
  // Cost per call
  const costPerCall = state.pricing.perProcessing +
    (state.pricing.perMinute * state.averageCallDuration)

  // Monthly operational
  const monthlyOperational = (costPerCall * state.volume.perMonth) +
    state.additionalCosts.monthlyFee

  // Totals
  const firstYearTotal = state.additionalCosts.integration +
    (monthlyOperational * 12)
  const recurringAnnual = monthlyOperational * 12

  // ROI if data available
  let roi = undefined
  if (state.roi?.averageConversionValue && state.roi?.conversionRate) {
    const monthlyConversions = state.volume.perMonth *
      (state.roi.conversionRate / 100)
    const monthlyRevenue = monthlyConversions *
      state.roi.averageConversionValue
    const monthlyProfit = monthlyRevenue - monthlyOperational

    roi = { monthlyConversions, monthlyRevenue, monthlyProfit }
  }

  return {
    costPerCall,
    monthlyOperational,
    monthlyTotal: monthlyOperational,
    firstYearTotal,
    recurringAnnual,
    roi
  }
}

// Volume synchronization helpers
export function syncVolumeFromMonth(monthlyVolume: number) {
  return {
    perDay: Math.round(monthlyVolume / 30),
    perWeek: Math.round(monthlyVolume / 4.33),
    perMonth: monthlyVolume
  }
}

export function syncVolumeFromDay(dailyVolume: number) {
  const monthly = Math.round(dailyVolume * 30)
  return syncVolumeFromMonth(monthly)
}

export function syncVolumeFromWeek(weeklyVolume: number) {
  const monthly = Math.round(weeklyVolume * 4.33)
  return syncVolumeFromMonth(monthly)
}

// Planned mode calculations for outbound
export function calculatePlannedVolume(
  frequency: number,
  startTime: string,
  endTime: string,
  activeDays: boolean[]
) {
  const [startHour, startMin] = startTime.split(':').map(Number)
  const [endHour, endMin] = endTime.split(':').map(Number)

  const minutesPerDay = ((endHour - startHour) * 60) + (endMin - startMin)
  const callsPerDay = Math.floor(minutesPerDay / frequency)
  const activeDaysCount = activeDays.filter(Boolean).length

  const callsPerWeek = callsPerDay * activeDaysCount
  const callsPerMonth = Math.round(callsPerWeek * 4.33)

  return syncVolumeFromMonth(callsPerMonth)
}
```

### 5. Integration Points

#### Add to main page (app/page.tsx)
```typescript
import ROICalculator from '@/components/sections/ROICalculator'

export default function Home() {
  return (
    <main className="relative">
      <Navigation />
      <Hero />
      <AgentsGrid />
      <HowItWorks />
      <Metrics />
      <ROICalculator /> {/* Add here, after Metrics */}
      <Footer />
    </main>
  )
}
```

#### Add CTA to Navigation
```typescript
// In components/sections/Navigation.tsx
<Button
  onClick={() => scrollToSection('roi-calculator')}
  variant="outline"
  className="hidden md:inline-flex"
>
  <Calculator className="mr-2 h-4 w-4" />
  Calculer mon ROI
</Button>
```

#### Add calculator data to constants
```typescript
// In lib/constants.ts
export const calculatorDefaults = {
  volume: {
    perDay: 50,
    perWeek: 350,
    perMonth: 1500
  },
  averageCallDuration: 3,
  pricing: {
    perProcessing: 0.15,
    perMinute: 0.08
  },
  additionalCosts: {
    integration: 2000,
    monthlyFee: 299
  }
}

export const calculatorLimits = {
  volume: {
    max: 300000,
    min: 0
  },
  duration: {
    max: 30,
    min: 0.5,
    step: 0.5
  },
  pricing: {
    maxPerCall: 50,
    maxPerMinute: 5,
    step: 0.01
  },
  costs: {
    maxIntegration: 50000,
    maxMonthly: 10000
  }
}
```

## ✅ Validation Loops

### 1. Development Verification
```bash
# Start development server
npm run dev

# Verify no TypeScript errors
npx tsc --noEmit

# Check linting
npm run lint

# Build verification
npm run build
```

### 2. Browser Testing with MCP Playwright
```javascript
// Navigate to development site
await browser.navigate('http://localhost:3000')

// Take initial snapshot
await browser.snapshot()

// Scroll to calculator section
await browser.evaluate(() => {
  document.getElementById('roi-calculator')?.scrollIntoView()
})

// Test responsive breakpoints
await browser.resize(375, 812)  // Mobile
await browser.snapshot()
await browser.resize(768, 1024) // Tablet
await browser.snapshot()
await browser.resize(1920, 1080) // Desktop
await browser.snapshot()

// Test mode switching
await browser.click('Outbound tab')
await browser.snapshot()

// Test input interactions
await browser.type('Volume input', '100')
await browser.evaluate(() => {
  // Verify synchronization
  const inputs = document.querySelectorAll('input[name*="volume"]')
  return Array.from(inputs).map(i => i.value)
})

// Test slider interaction
await browser.click('Duration slider')
await browser.snapshot()

// Verify animations are smooth
await browser.wait_for(2) // Wait for animations
await browser.snapshot()
```

### 3. Functional Testing Checklist
- [ ] Volume fields synchronize correctly (day/week/month)
- [ ] Slider updates value and displays correctly
- [ ] Mode switch (Inbound/Outbound) transitions smoothly
- [ ] Planned mode calculations are accurate
- [ ] Results update in real-time
- [ ] CTA button opens contact form with pre-filled data
- [ ] Navigation CTA scrolls to calculator section
- [ ] All inputs validate correctly (no negative values)
- [ ] Mobile touch interactions work properly
- [ ] Keyboard navigation is fully functional

### 4. Performance Metrics
```bash
# Lighthouse audit
npx lighthouse http://localhost:3000 --view

# Bundle size check
npm run build
# Check .next/analyze for bundle analysis

# Key metrics to verify:
# - First Input Delay < 100ms
# - Cumulative Layout Shift < 0.1
# - Time to Interactive < 3s
# - Bundle size increase < 50KB
```

## ❌ Anti-patterns to Avoid

### Voipia-Specific
- ❌ **Creating unnecessary files** - Use existing components when possible
- ❌ **Inconsistent gradients** - Always use gradients from tailwind.config
- ❌ **Missing responsive design** - Test all breakpoints thoroughly
- ❌ **Skipping browser verification** - Always use MCP Playwright
- ❌ **Not using cn() utility** - Always use for conditional classes
- ❌ **Ignoring dark theme** - Ensure all elements work with dark background
- ❌ **Hardcoding colors** - Use theme colors from Tailwind config
- ❌ **Missing animations** - Add Framer Motion transitions

### Calculator-Specific
- ❌ **Direct state mutations** - Always use setState with new objects
- ❌ **Synchronous heavy calculations** - Use useMemo for calculations
- ❌ **No input debouncing** - Add 300ms debounce on text inputs
- ❌ **Missing validation** - Validate all inputs before calculation
- ❌ **Inaccessible sliders** - Ensure keyboard navigation works
- ❌ **No loading states** - Show loading during async operations
- ❌ **Fixed decimal display** - Format numbers appropriately (2 decimals for €)
- ❌ **No error boundaries** - Add error handling for edge cases

### Performance
- ❌ **Re-rendering entire calculator** - Use React.memo for result components
- ❌ **Blocking main thread** - Move heavy calculations to Web Workers if needed
- ❌ **Large bundle imports** - Use dynamic imports for heavy libraries
- ❌ **No code splitting** - Lazy load calculator if not immediately visible

## 📊 Success Metrics

### Technical Confidence: 9/10
- Clear implementation path with existing patterns
- All required components identified
- Calculation logic is straightforward
- Integration points are well-defined

### Implementation Complexity
- **Frontend**: Medium - Multiple interactive components
- **State Management**: Medium - Complex synchronization logic
- **Animations**: Low - Reuse existing patterns
- **Responsive**: Medium - Complex grid layouts
- **Accessibility**: High - Many interactive elements

### Estimated Timeline
- Phase 1 (Structure & Basic Inputs): 2-3 hours
- Phase 2 (Inbound Mode Complete): 2-3 hours
- Phase 3 (Outbound Mode): 3-4 hours
- Phase 4 (Polish & Testing): 2-3 hours
- **Total**: 9-13 hours

## 🚀 Next Steps

### Immediate Actions
1. Create component structure and TypeScript types
2. Implement basic calculator with inbound mode
3. Add volume synchronization logic
4. Create custom slider component
5. Implement results calculation and display

### Testing Priority
1. Browser testing at all breakpoints
2. Input validation and edge cases
3. Animation performance
4. Accessibility audit
5. Bundle size optimization

### Future Enhancements
- PDF export functionality
- URL parameter state persistence
- localStorage for saving configurations
- A/B testing different layouts
- Integration with n8n webhook for lead capture
- Multi-language support
- Currency selection
- Comparison with competitor pricing

## 📝 Notes

- Start with inline section (Option B) as recommended
- Focus on real-time calculations without "Calculate" button
- Ensure smooth animations matching existing Metrics section
- Maintain dark theme consistency throughout
- Consider adding tooltips for complex fields
- Plan for future API integration for dynamic pricing

---

**PRP Version**: 1.0.0
**Created**: 2025-09-30
**Status**: Ready for implementation
**Confidence**: 9/10 - High confidence with clear implementation path