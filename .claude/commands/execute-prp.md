# Execute Voipia PRP

Implement a Voipia feature using the specified PRP file with comprehensive validation and testing.

## PRP File: $ARGUMENTS

## Execution Process

### 1. Load PRP
- Read the specified PRP file from `PRPs/` directory
- Understand all context and requirements
- Load referenced files (CLAUDE.md, components, constants)
- Ensure all needed context is available
- Research any missing information

### 2. Planning Phase
- **Use TodoWrite tool** to create implementation plan
- Break down complex tasks into manageable steps
- Identify patterns from existing Voipia components
- Plan integration points with current architecture
- Consider responsive design from the start

### 3. Implementation

#### Component Development
1. Start with base structure following Voipia patterns
2. Implement core functionality
3. Add TypeScript types and interfaces
4. Integrate with `lib/constants.ts` if needed
5. Apply Tailwind classes using cn() utility

#### Animation & Styling
1. Add Framer Motion animations as specified
2. Implement viewport-based triggers
3. Apply consistent gradients and spacing
4. Ensure dark theme compatibility
5. Test hover states and transitions

#### Responsive Design
1. Mobile-first implementation
2. Test at key breakpoints (375px, 768px, 1440px)
3. Verify text truncation and overflow
4. Check touch targets on mobile

### 4. Validation

#### Code Quality
```bash
npm run lint         # Must pass with no errors
npm run build        # Must build successfully
```

#### Browser Testing (MCP Playwright)
1. Start dev server: `npm run dev`
2. Navigate to `http://localhost:3000`
3. Take full page snapshot
4. Test responsive design:
   - Mobile (375px width)
   - Tablet (768px width)  
   - Desktop (1440px width)
5. Verify animations trigger correctly
6. Test all interactive elements
7. Check accessibility with keyboard navigation

#### Performance Checks
- Verify smooth 60fps animations
- Check bundle size impact
- Test loading states
- Validate image optimization

### 5. Integration Testing
- Verify section flows correctly in page
- Test navigation if applicable
- Check data integration with constants
- Validate all CTAs and links

### 6. Final Verification
- Re-read PRP to ensure all requirements met
- Run through success criteria checklist
- Verify all anti-patterns were avoided
- Confirm visual design matches Voipia style

### 7. Completion Report
- List all implemented features
- Note any deviations from PRP
- Document any discovered edge cases
- Report final validation status

## Voipia-Specific Requirements

### Always Remember
- **UI Verification**: Use MCP Playwright for all UI changes
- **No Unnecessary Files**: Edit existing files when possible
- **Lint After Changes**: Always run `npm run lint`
- **Test Animations**: Verify at different viewport sizes
- **Follow Patterns**: Use existing components as reference

### Common Patterns
```typescript
// Section structure
<section className={cn(
  "relative py-24",
  "bg-gradient-to-b from-black to-purple-950/20"
)}>
  <div className="container mx-auto px-6">
    {/* Content */}
  </div>
</section>

// Animation pattern
<motion.div
  initial={{ opacity: 0, y: 20 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true }}
>
```

### Error Recovery
If validation fails:
1. Check error patterns in PRP
2. Review similar working components
3. Verify TypeScript types
4. Test in isolation
5. Re-run validation suite

## Example Usage
```
/execute-prp PRPs/testimonials-section.md
```

This will implement the feature following all Voipia conventions and validate thoroughly.