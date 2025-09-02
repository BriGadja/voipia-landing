# Generate PRP for Voipia Feature

Generate a comprehensive Product Requirements Proposal (PRP) for implementing a new feature in the Voipia landing page.

## Input: $ARGUMENTS

## Generation Process

### 1. Research Phase

#### Codebase Analysis
- Examine existing components in `components/sections/` for patterns
- Review `lib/constants.ts` for data structures
- Check `tailwind.config.ts` for custom animations and theme
- Analyze `app/page.tsx` for section integration points
- Study similar features for implementation patterns

#### External Research (if needed)
- Next.js 15 App Router documentation
- Framer Motion animation patterns
- Accessibility best practices
- Performance optimization techniques

#### Clarification
- Ask user for any missing requirements
- Confirm integration points
- Verify design expectations

### 2. PRP Generation

Create a comprehensive PRP including:

#### Required Sections
1. **Purpose & Goal**
   - Clear feature definition
   - Business value and user impact
   - Integration with existing Voipia features

2. **Context & References**
   ```yaml
   - file: CLAUDE.md
     why: Project rules and workflows
   - file: [relevant component files]
     why: [patterns to follow]
   - file: lib/constants.ts
     why: Data structure integration
   ```

3. **Implementation Blueprint**
   - TypeScript interfaces for new data
   - Component structure with Voipia patterns
   - Animation requirements using Framer Motion
   - Responsive design considerations

4. **Validation Loops**
   ```bash
   npm run dev          # Development server
   npm run lint         # Code quality
   npm run build        # Build verification
   
   # Browser testing with MCP Playwright
   - Navigate to http://localhost:3000
   - Take snapshots at multiple breakpoints
   - Verify animations and interactions
   ```

5. **Integration Points**
   - Where in `app/page.tsx` to add the feature
   - Data additions to `lib/constants.ts`
   - New UI components needed
   - Animation wrappers required

6. **Anti-patterns for Voipia**
   - ❌ Creating unnecessary files
   - ❌ Inconsistent gradients/spacing
   - ❌ Missing responsive design
   - ❌ Skipping browser verification
   - ❌ Not using cn() utility
   - ❌ Ignoring dark theme

### 3. Output Requirements

#### File Location
Save as: `PRPs/{feature-name}.md`

#### Quality Checklist
- [ ] All Voipia-specific patterns referenced
- [ ] Browser testing steps included
- [ ] Responsive design addressed
- [ ] Animation requirements defined
- [ ] TypeScript types specified
- [ ] Integration points clear
- [ ] Validation commands provided

#### Confidence Score
Rate confidence (1-10) based on:
- Completeness of context
- Clarity of implementation path
- Validation coverage
- Pattern consistency with existing code

### 4. Voipia-Specific Considerations

#### Design System
- Agent colors: Louis (blue), Arthur (orange), Alexandra (green)
- Dark theme with purple/violet gradients
- Consistent section spacing (py-24)
- Container patterns (mx-auto px-6)

#### Animation Patterns
- Viewport-based triggers
- Smooth scroll behaviors
- Hover state transitions
- Loading state animations

#### Performance
- Image optimization requirements
- Code splitting considerations
- Font loading strategies
- Bundle size impacts

### Example Usage
```
/generate-prp "Add a pricing section with tiered plans for each agent"
```

This will create a comprehensive PRP at `PRPs/pricing-section.md` with all context needed for implementation.