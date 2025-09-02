name: "Testimonials Section PRP - Add social proof to Voipia landing"
description: |

## Purpose
Add a testimonials section to the Voipia landing page showcasing customer success stories and feedback to build trust and credibility.

## Core Principles
1. **Context is King**: Using existing Voipia patterns and components
2. **Validation Loops**: Browser testing and lint checks
3. **Information Dense**: Following established design system
4. **Progressive Success**: Start with static, then add animations
5. **Global rules**: Follow CLAUDE.md workflows
6. **Visual Verification**: Test with MCP Playwright

---

## Goal
Create a testimonials section that displays customer reviews with company logos, ratings, and quotes in a visually appealing carousel or grid layout that matches the existing Voipia design system.

## Why
- **Business value**: Increase conversion by showing social proof
- **Integration**: Fits between Metrics and DemoSection for logical flow
- **Problems solved**: Addresses trust concerns for potential customers

## What
A responsive testimonials section featuring:
- Customer quotes with attribution
- Company logos
- Star ratings
- Smooth animations on scroll
- Mobile-optimized layout
- Dark theme consistent with site design

### Success Criteria
- [ ] Section renders correctly on all breakpoints
- [ ] Animations trigger smoothly on viewport entry
- [ ] TypeScript/ESLint checks pass
- [ ] Integrates seamlessly with existing sections
- [ ] Accessible with proper ARIA labels
- [ ] Browser snapshot confirms visual design

## All Needed Context

### Documentation & References
```yaml
- file: CLAUDE.md
  why: Project rules and UI verification workflow
  
- file: app/page.tsx
  why: Where to add the new section import
  
- file: components/sections/Metrics.tsx
  why: Reference for animation patterns and section structure
  
- file: components/sections/AgentsGrid.tsx
  why: Card layout and responsive grid patterns
  
- file: lib/constants.ts
  why: Where to add testimonial data
  
- file: tailwind.config.ts
  why: Custom animations and color variables
  
- file: components/ui/Card.tsx
  why: Existing card component to potentially reuse
```

### Codebase Structure
```
components/sections/
├── Hero.tsx          # Reference for section spacing
├── AgentsGrid.tsx    # Grid layout patterns
├── Metrics.tsx       # Animation on scroll patterns
├── [Testimonials.tsx] # New file to create
```

### Key Technologies & Patterns
- Framer Motion for scroll animations
- Grid/Flexbox for responsive layout
- cn() utility for conditional styling
- Dark gradients matching site theme
- Consistent padding/margins (py-24, container mx-auto)

### Gotchas & Critical Info
- Must use viewport-based animations like Metrics section
- Follow exact gradient patterns from other sections
- Maintain consistent section spacing (py-24)
- Use proper TypeScript interfaces for testimonial data
- Test quote marks rendering on different browsers

---

## Implementation Blueprint

### Data Models & Types
```typescript
// Add to lib/constants.ts
export interface Testimonial {
  id: string;
  quote: string;
  author: string;
  role: string;
  company: string;
  companyLogo?: string;
  rating: number;
  agentUsed?: 'louis' | 'arthur' | 'alexandra';
}

export const testimonials: Testimonial[] = [
  {
    id: 'testimonial-1',
    quote: 'Voipia transformed our customer support...',
    author: 'Marie Dubois',
    role: 'Head of Customer Success',
    company: 'TechCorp',
    rating: 5,
    agentUsed: 'louis'
  },
  // ... more testimonials
];
```

### Task Breakdown
1. [ ] Add testimonial data structure to lib/constants.ts
2. [ ] Create Testimonials.tsx component with base structure
3. [ ] Implement responsive grid/carousel layout
4. [ ] Add Framer Motion animations on scroll
5. [ ] Style with existing gradients and colors
6. [ ] Import and add to app/page.tsx
7. [ ] Test responsive design at all breakpoints
8. [ ] Verify with browser snapshot
9. [ ] Run lint and build checks

### Pseudocode
```typescript
// components/sections/Testimonials.tsx
'use client';

import { motion } from 'framer-motion';
import { Star } from 'lucide-react';
import { testimonials } from '@/lib/constants';
import { cn } from '@/lib/utils';

export function Testimonials() {
  return (
    <section className={cn(
      "relative py-24",
      "bg-gradient-to-b from-purple-950/20 to-black"
    )}>
      <div className="container mx-auto px-6">
        {/* Section header like other sections */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
        >
          <h2 className="text-4xl md:text-5xl font-bold text-center mb-4">
            Ce que disent nos clients
          </h2>
          <p className="text-gray-400 text-center mb-16">
            Des entreprises qui font confiance à Voipia
          </p>
        </motion.div>

        {/* Testimonial grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {testimonials.map((testimonial, index) => (
            <TestimonialCard 
              key={testimonial.id}
              testimonial={testimonial}
              index={index}
            />
          ))}
        </div>
      </div>
    </section>
  );
}
```

---

## Integration Points

### Where This Fits
- [ ] Add between Metrics and DemoSection in app/page.tsx
- [ ] Add testimonial data to lib/constants.ts
- [ ] Export from components/sections/index.ts if exists

### Dependencies
- Framer Motion for animations
- Lucide React for star icons
- Existing utility functions
- Tailwind custom animations

---

## Validation Loops

### Commands to Run
```bash
# Start dev server
npm run dev

# After implementation
npm run lint        # Must pass
npm run build      # Must succeed

# Browser testing checklist
1. Navigate to http://localhost:3000
2. Take full page snapshot
3. Resize to mobile (375px)
4. Resize to tablet (768px)
5. Resize to desktop (1440px)
6. Verify animations trigger on scroll
7. Check hover states on cards
```

### Expected Outcomes
- Clean TypeScript compilation
- No ESLint errors or warnings
- Smooth animations at 60fps
- Proper text truncation on mobile
- Accessible star ratings
- Consistent visual design

---

## Anti-Patterns to Avoid
❌ Using different gradient patterns than existing sections
❌ Inconsistent spacing/padding
❌ Loading all testimonials at once (consider pagination)
❌ Missing hover states on interactive elements
❌ Not testing with long quotes
❌ Forgetting viewport-based animation triggers
❌ Using absolute positioning that breaks responsive
❌ Hard-coding colors instead of using theme

---

## Confidence Score: 9/10
*High confidence due to clear patterns in existing sections and well-defined design system*

## Additional Notes
- Consider lazy loading images for company logos
- May want to add autoplay carousel on desktop
- Could integrate with agent colors for themed testimonials
- Future enhancement: video testimonials