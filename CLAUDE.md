# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server  
- `npm run lint` - Run ESLint for code quality

## UI Verification Workflow

**IMPORTANT**: After making any UI modifications, you MUST:
1. Use the MCP Playwright server to navigate to the site (locally on `http://localhost:3000` or production URL)
2. Take a browser snapshot to verify the visual changes
3. Check that the updates correspond to the expected behavior
4. Test responsive design by resizing the browser window
5. Verify animations and interactions are working correctly

This visual verification ensures that all changes are properly rendered and functioning as intended before committing.

## Project Architecture

This is a Voipia landing page built with Next.js 15 App Router, showcasing three AI voice agents (Louis, Arthur, Alexandra). The application uses a component-based architecture with clear separation of concerns.

### Core Structure

- **`app/`** - Next.js App Router structure with layout and main page
- **`components/sections/`** - Main page sections (Hero, AgentsGrid, HowItWorks, etc.)
- **`components/ui/`** - Reusable UI components
- **`components/animations/`** - Framer Motion animation wrappers
- **`lib/`** - Utilities and constants

### Key Components Flow

The main page (`app/page.tsx`) renders sections in order:
1. Navigation - Fixed header with smooth scrolling
2. Hero - Main value proposition with CTA
3. AgentsGrid - Three AI agents with individual capabilities
4. HowItWorks - 3-step process timeline
5. Metrics - Performance statistics with animations
6. DemoSection - Interactive conversation simulation
7. Footer - Contact information and final CTA

### Data Management

Agent data, metrics, and workflow steps are centralized in `lib/constants.ts`. Each agent has:
- Unique color scheme (louis: blue, arthur: orange, alexandra: green)
- Specific capabilities and use cases
- Associated audio demo paths
- Performance statistics

### Design System

**Colors**: Custom color palette with agent-specific colors defined in Tailwind config
**Typography**: Inter variable font with comprehensive size scale
**Animations**: Framer Motion for smooth transitions and micro-interactions

Custom animations include:
- `breathing` - Subtle avatar animation
- `wave` - Audio visualization
- `fade-in-up` - Section entrance animations
- `glow` - Button hover effects

### Technology Stack

- **Next.js 15** with App Router and TypeScript
- **Tailwind CSS** for styling with custom animations
- **Framer Motion** for advanced animations
- **Lucide React** for consistent iconography
- **clsx + tailwind-merge** for conditional styling via `cn()` utility

### Performance Optimizations

- Next.js Image optimization with WebP/AVIF formats
- Inter font loaded with `display: swap`
- Component-based architecture for code splitting
- Comprehensive SEO metadata in layout.tsx

### Styling Conventions

- Uses `cn()` utility for conditional classes
- Follows mobile-first responsive design
- Dark theme as default with purple/violet primary colors
- Gradient backgrounds extensively used for visual appeal
- Consistent spacing using Tailwind's scale

## PRP (Product Requirements Proposal) System

This project uses a PRP system for planning and implementing features with comprehensive context and validation loops.

### Quick Commands

- **`/generate-prp "feature description"`** - Generate a comprehensive PRP for a new feature
- **`/execute-prp PRPs/feature-name.md`** - Execute an existing PRP with full validation

### PRP Workflow

#### 1. Creating a PRP
When planning a new feature:
1. Use `/generate-prp "your feature description"` OR
2. Manually use the base template at `PRPs/templates/prp_base.md`
3. Fill in all sections with specific details about the feature
4. Include all necessary context, references, and validation steps
5. Save the PRP in the `PRPs/` directory with a descriptive name

#### 2. PRP Structure
- **Goal**: Clear definition of what needs to be built
- **Context**: All documentation, files, and references needed
- **Implementation Blueprint**: Step-by-step plan with pseudocode
- **Validation Loops**: Commands to verify the implementation
- **Anti-patterns**: Common mistakes to avoid

#### 3. Using PRPs

**Method 1: Automated Commands**
1. Generate: `/generate-prp "Add testimonials section with carousel"`
2. Execute: `/execute-prp PRPs/testimonials-section.md`

**Method 2: Manual Process**
1. **Planning Phase**: Create a PRP document for complex features
2. **Implementation**: Follow the PRP's task breakdown and pseudocode
3. **Validation**: Run all commands in the validation loops section
4. **Iteration**: Fix issues based on validation results

#### 4. Example PRPs
- See `PRPs/EXAMPLE_testimonials_section.md` for a complete feature PRP
- Reference `INITIAL.md` for overall project context and requirements

### PRP Best Practices
- Include ALL necessary context upfront
- Define clear success criteria with measurable outcomes
- Provide executable validation commands
- Reference existing code patterns and components
- Always verify UI changes with browser snapshots
- Run lint and build checks as part of validation

### Directory Structure
```
PRPs/
├── templates/
│   └── prp_base.md         # Base template for new PRPs
├── ai_docs/                # Additional documentation for AI context
└── [feature-name].md       # Individual feature PRPs

.claude/
└── commands/
    ├── generate-prp.md     # Command to generate new PRPs
    └── execute-prp.md      # Command to execute PRPs
```

### Command Examples

```bash
# Generate a new PRP for a pricing section
/generate-prp "Add a pricing section with three tiers for each agent"

# Execute an existing PRP
/execute-prp PRPs/pricing-section.md

# Generate and execute in sequence
/generate-prp "Add FAQ section with collapsible questions"
/execute-prp PRPs/faq-section.md
```

This system ensures consistent, high-quality implementations with proper context and validation at every step.