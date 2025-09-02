# INITIAL.md - Voipia Landing Page Project Context

## Project Overview
Voipia is an AI voice agent platform showcasing three specialized agents (Louis, Arthur, Alexandra) with unique capabilities for customer service, technical support, and sales assistance.

## Core Requirements

### Business Goals
- Present Voipia's AI voice agent capabilities professionally
- Drive conversions through clear CTAs and demonstrations
- Showcase performance metrics and use cases
- Build trust through interactive demos

### Technical Stack
- **Framework**: Next.js 15 with App Router
- **Language**: TypeScript with strict mode
- **Styling**: Tailwind CSS with custom animations
- **Animations**: Framer Motion for smooth transitions
- **Icons**: Lucide React for consistent iconography
- **Performance**: Optimized with Next.js Image, font swapping

### Design System

#### Color Palette
- **Primary**: Purple/Violet gradients
- **Background**: Dark theme (black to purple gradients)
- **Agent Colors**:
  - Louis (Support): Blue (#3B82F6)
  - Arthur (Technical): Orange (#F97316)
  - Alexandra (Sales): Green (#10B981)

#### Typography
- Font: Inter variable font
- Responsive sizing with Tailwind scale
- High contrast for readability on dark backgrounds

#### Animation Patterns
- `breathing`: Subtle avatar animations
- `wave`: Audio visualization effects
- `fade-in-up`: Section entrance animations
- `glow`: Interactive hover effects
- Smooth scroll behaviors

### Component Architecture

#### Page Sections (in order)
1. **Navigation**: Fixed header with smooth scroll navigation
2. **Hero**: Main value proposition with primary CTA
3. **AgentsGrid**: Three AI agents with capabilities showcase
4. **HowItWorks**: 3-step timeline process visualization
5. **Metrics**: Animated performance statistics
6. **DemoSection**: Interactive conversation simulation
7. **Footer**: Contact CTA and company information

#### Reusable Components
- UI components in `components/ui/`
- Animation wrappers in `components/animations/`
- Section components in `components/sections/`

### Development Workflow

#### Commands
```bash
npm run dev    # Development server on :3000
npm run build  # Production build
npm run lint   # Code quality checks
npm run start  # Production server
```

#### Quality Checklist
- [ ] TypeScript compilation without errors
- [ ] ESLint passing with no warnings
- [ ] Responsive design (mobile-first)
- [ ] Animations performant at 60fps
- [ ] Accessibility standards met
- [ ] SEO metadata properly configured

### Best Practices

#### Code Style
- Use `cn()` utility for conditional classes
- Follow existing component patterns
- Maintain consistent file structure
- Keep components focused and reusable

#### Performance
- Lazy load heavy components
- Optimize images with Next.js Image
- Use CSS animations where possible
- Minimize JavaScript bundle size

#### Testing Requirements
- Visual regression with browser snapshots
- Responsive design verification
- Animation performance testing
- Cross-browser compatibility

### PRP Workflow Integration

When implementing new features:
1. Create a PRP document using the base template
2. Include all necessary context and validation loops
3. Follow the implementation blueprint
4. Verify with browser testing via MCP Playwright
5. Run lint and build checks before completion

### Critical Rules
- **NEVER** create files unless absolutely necessary
- **ALWAYS** prefer editing existing files
- **MUST** verify UI changes with browser snapshots
- **ALWAYS** run lint after code changes
- **NEVER** add comments unless requested
- **FOLLOW** mobile-first responsive approach

### Data Management
All agent data, metrics, and content are centralized in `lib/constants.ts` for easy updates and consistency across the application.

### Integration Points
- Navigation smoothly scrolls to sections
- Forms integrate with backend APIs
- Audio demos play inline
- Metrics animate on viewport entry
- CTAs track conversion events

## Success Metrics
- Clean, professional appearance
- Smooth animations and transitions  
- Fast page load times (<2s)
- High Lighthouse scores (>90)
- Accessible to screen readers
- SEO optimized for voice AI keywords