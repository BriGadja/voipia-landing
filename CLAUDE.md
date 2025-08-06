# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server  
- `npm run lint` - Run ESLint for code quality

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