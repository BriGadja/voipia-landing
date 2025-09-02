name: "Voipia PRP Template v1 - Context-Rich with Validation Loops"
description: |

## Purpose
Template optimized for AI agents to implement features in the Voipia landing page with sufficient context and self-validation capabilities to achieve working code through iterative refinement.

## Core Principles
1. **Context is King**: Include ALL necessary documentation, examples, and caveats
2. **Validation Loops**: Provide executable tests/lints the AI can run and fix
3. **Information Dense**: Use keywords and patterns from the Voipia codebase
4. **Progressive Success**: Start simple, validate, then enhance
5. **Global rules**: Follow all rules in CLAUDE.md (especially UI verification workflow)
6. **Visual Verification**: Use MCP Playwright for browser testing after UI changes

---

## Goal
[What needs to be built - be specific about the end state and desired functionality]

## Why
- [Business value and user impact]
- [Integration with existing Voipia features]
- [Problems this solves and for whom]

## What
[User-visible behavior and technical requirements]

### Success Criteria
- [ ] [Specific measurable outcomes]
- [ ] UI changes verified with browser snapshot
- [ ] Responsive design tested (mobile/desktop)
- [ ] Animations working correctly
- [ ] TypeScript/ESLint checks passing

## All Needed Context

### Documentation & References
```yaml
# MUST READ - Include these in your context window
- file: CLAUDE.md
  why: Project-specific rules and workflows
  
- file: app/page.tsx
  why: Main page structure and section ordering
  
- file: lib/constants.ts
  why: Agent data, metrics, workflow steps
  
- file: tailwind.config.ts
  why: Custom animations and color palette
  
- url: [Next.js 15 docs if needed]
  section: [Specific App Router features]
  
- docfile: [PRPs/ai_docs/file.md]
  why: [Additional context documentation]
```

### Codebase Structure
```
voipia-landing/
├── app/                     # Next.js App Router
│   ├── layout.tsx          # Root layout with metadata
│   └── page.tsx           # Main landing page
├── components/
│   ├── sections/          # Page sections
│   │   ├── Hero.tsx
│   │   ├── AgentsGrid.tsx
│   │   ├── HowItWorks.tsx
│   │   ├── Metrics.tsx
│   │   ├── DemoSection.tsx
│   │   └── Footer.tsx
│   ├── ui/               # Reusable components
│   └── animations/       # Framer Motion wrappers
├── lib/
│   ├── constants.ts     # Centralized data
│   └── utils.ts        # cn() utility
└── public/             # Static assets
```

### Key Technologies & Patterns
- **Framework**: Next.js 15 with App Router, TypeScript
- **Styling**: Tailwind CSS with custom animations
- **Animations**: Framer Motion for transitions
- **Icons**: Lucide React
- **Utilities**: clsx + tailwind-merge via cn()
- **Font**: Inter variable font
- **Theme**: Dark theme with purple/violet primary

### Agent Color Schemes
- Louis: Blue (#3B82F6)
- Arthur: Orange (#F97316)
- Alexandra: Green (#10B981)

### Gotchas & Critical Info
- Always use cn() utility for conditional classes
- Follow mobile-first responsive design
- Verify UI changes with Playwright browser snapshot
- Never create files unless necessary - prefer editing
- Run npm run lint after code changes
- Test animations at different viewport sizes

---

## Implementation Blueprint

### Data Models & Types
```typescript
// Example structures from lib/constants.ts
interface Agent {
  id: string;
  name: string;
  role: string;
  avatar: string;
  color: string;
  capabilities: string[];
  audioDemo?: string;
}

interface Metric {
  value: string;
  label: string;
  description: string;
}
```

### Task Breakdown
1. [ ] Research existing patterns in codebase
2. [ ] Plan component structure
3. [ ] Implement core functionality
4. [ ] Add animations with Framer Motion
5. [ ] Test responsive design
6. [ ] Verify with browser snapshot
7. [ ] Run lint and type checks
8. [ ] Fix any issues

### Pseudocode
```typescript
// Component structure example
export function NewFeature() {
  // 1. Use existing patterns from components/sections/
  // 2. Import from components/ui/ for reusables
  // 3. Use lib/constants for data
  // 4. Apply animations from components/animations/
  
  return (
    <section className={cn(
      "relative py-24",
      "bg-gradient-to-b from-black to-purple-950/20"
    )}>
      {/* Implementation */}
    </section>
  );
}
```

---

## Integration Points

### Where This Fits
- [ ] Update app/page.tsx if adding new section
- [ ] Add data to lib/constants.ts if needed
- [ ] Create animation wrapper if complex animations
- [ ] Update navigation if new section added

### Dependencies
- Existing UI components from components/ui/
- Animation patterns from components/animations/
- Utility functions from lib/utils.ts
- Constants from lib/constants.ts

---

## Validation Loops

### Commands to Run
```bash
# Development
npm run dev           # Start dev server
# Open http://localhost:3000

# Linting & Type Checking
npm run lint         # Must pass
npm run build       # Must succeed

# Browser Testing (via MCP Playwright)
# 1. Navigate to http://localhost:3000
# 2. Take snapshot
# 3. Test responsive (resize to mobile/tablet/desktop)
# 4. Verify animations
```

### Expected Outcomes
- No TypeScript errors
- No ESLint warnings
- UI renders correctly at all breakpoints
- Animations smooth and functional
- Build succeeds without errors

---

## Anti-Patterns to Avoid
❌ Creating new files when editing existing ones would work
❌ Adding comments unless requested
❌ Skipping browser verification for UI changes
❌ Using inline styles instead of Tailwind classes
❌ Hardcoding values instead of using constants
❌ Ignoring responsive design
❌ Not using cn() for conditional classes
❌ Creating documentation files without request

---

## Confidence Score: [X]/10
*Rate your confidence that this PRP contains everything needed for successful implementation*

## Additional Notes
[Any extra context, edge cases, or considerations]