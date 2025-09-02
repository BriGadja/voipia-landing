# PRP: Voipia AI Chatbot Widget

## 🎯 Purpose & Goal

### Feature Definition
Implement an embedded AI chatbot widget for the Voipia landing page that integrates seamlessly with the existing dark theme design and provides real-time conversational AI capabilities through n8n webhook integration.

### Business Value
- **Instant Engagement**: Capture visitor interest with immediate AI-powered assistance
- **Lead Qualification**: Automatically qualify visitors while they browse
- **24/7 Availability**: Provide instant responses without human intervention
- **Integration Ready**: Direct connection to Voipia's existing n8n workflow infrastructure

### User Impact
- Immediate answers to questions about Voipia's AI agents
- Personalized guidance for choosing the right agent (Louis, Arthur, or Alexandra)
- Seamless experience matching the premium feel of the landing page
- Mobile-optimized conversation interface

## 📚 Context & References

```yaml
required_files:
  - file: CLAUDE.md
    why: Project conventions, UI verification workflow, and PRP system
  - file: INITIAL_chatbot.md
    why: Complete feature requirements and technical specifications
  - file: components/ui/ContactModal.tsx
    why: Modal patterns and n8n webhook integration reference
  - file: components/ui/Button.tsx
    why: Button component patterns and styling conventions
  - file: lib/constants.ts
    why: Agent data and color schemes for contextual responses
  - file: tailwind.config.ts
    why: Animation keyframes and color palette
  - file: lib/utils.ts
    why: cn utility for conditional styling
  - file: app/page.tsx
    why: Integration point for chatbot initialization

external_docs:
  - n8n Webhook Documentation: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
  - n8n Respond to Webhook: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.respondtowebhook/
  - WCAG Guidelines for Chat Interfaces
  - Performance Budget Best Practices for Third-party Widgets
```

## 🏗️ Implementation Blueprint

### 1. Data Structures

```typescript
// types/chatbot.ts
interface ChatMessage {
  id: string
  type: 'user' | 'bot' | 'system'
  content: string
  timestamp: Date
  metadata?: {
    agent?: 'chatbot-iapreneurs'
    confidence?: number
    error?: boolean
  }
}

interface ChatSession {
  sessionId: string
  messages: ChatMessage[]
  startedAt: Date
  metadata: {
    userAgent: string
    referrer: string
    chatId: string
  }
}

interface ChatbotState {
  isOpen: boolean
  isLoading: boolean
  isTyping: boolean
  session: ChatSession | null
  error: string | null
}

interface WebhookPayload {
  message: string
  sessionId: string
  timestamp: string
  metadata: {
    userAgent: string
    referrer: string
    chatId: string
  }
}

interface WebhookResponse {
  response: string
  type: 'text' | 'typing' | 'error'
  metadata: {
    agent: string
    confidence: number
  }
}
```

### 2. Component Architecture

```
components/
├── chatbot/
│   ├── ChatbotWidget.tsx        # Main widget container
│   ├── ChatbotTrigger.tsx       # Floating button with pulse animation
│   ├── ChatbotWindow.tsx        # Chat window with messages
│   ├── ChatbotHeader.tsx        # Header with title and close
│   ├── ChatbotMessages.tsx      # Message list with auto-scroll
│   ├── ChatbotInput.tsx         # Input field with send button
│   ├── ChatbotMessage.tsx       # Individual message component
│   ├── ChatbotTypingIndicator.tsx # Typing animation
│   └── hooks/
│       ├── useChatbot.ts        # Main chatbot logic hook
│       ├── useWebhook.ts        # n8n webhook integration
│       └── useSessionStorage.ts # Session persistence
```

### 3. Core Implementation Steps

#### Step 1: Create Chatbot Context and Provider
```typescript
// contexts/ChatbotContext.tsx
const ChatbotContext = createContext<{
  state: ChatbotState
  sendMessage: (message: string) => Promise<void>
  toggleChat: () => void
  clearSession: () => void
}>()
```

#### Step 2: Implement Webhook Integration Hook
```typescript
// components/chatbot/hooks/useWebhook.ts
const WEBHOOK_URL = 'https://n8n.voipia.fr/webhook/chatbot-iapreneurs'
const TIMEOUT_MS = 10000 // 10 seconds timeout

async function sendToWebhook(payload: WebhookPayload): Promise<WebhookResponse> {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS)
  
  try {
    const response = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal
    })
    
    if (!response.ok) throw new Error('Webhook error')
    return await response.json()
  } finally {
    clearTimeout(timeout)
  }
}
```

#### Step 3: Create Main Widget Component
```typescript
// components/chatbot/ChatbotWidget.tsx
export default function ChatbotWidget() {
  return (
    <ChatbotProvider>
      <AnimatePresence>
        {!isOpen && <ChatbotTrigger />}
        {isOpen && <ChatbotWindow />}
      </AnimatePresence>
    </ChatbotProvider>
  )
}
```

#### Step 4: Implement Responsive Chat Window
```typescript
// Breakpoints and responsive behavior
const windowStyles = {
  desktop: 'fixed bottom-4 right-4 w-96 h-[600px]',
  mobile: 'fixed inset-0 w-full h-full',
  tablet: 'fixed bottom-4 right-4 w-80 h-[500px]'
}
```

#### Step 5: Add Animations and Transitions
```typescript
// Animation variants
const chatVariants = {
  hidden: { opacity: 0, scale: 0.8, y: 20 },
  visible: { 
    opacity: 1, 
    scale: 1, 
    y: 0,
    transition: { type: 'spring', damping: 25 }
  },
  exit: { opacity: 0, scale: 0.8, y: 20 }
}
```

### 4. Styling Guidelines

```css
/* Chatbot-specific Tailwind classes */
.voipia-chatbot-trigger  /* Floating button */
.voipia-chatbot-window   /* Main window */
.voipia-chatbot-header   /* Header bar */
.voipia-chatbot-messages /* Messages container */
.voipia-chatbot-input    /* Input area */
.voipia-chatbot-message  /* Individual message */

/* Z-index hierarchy */
z-[9998] /* Backdrop */
z-[9999] /* Chat window */
z-[10000] /* Critical overlays */
```

### 5. Performance Optimizations

```typescript
// Lazy load chatbot components
const ChatbotWidget = dynamic(
  () => import('@/components/chatbot/ChatbotWidget'),
  { 
    ssr: false,
    loading: () => null
  }
)

// Message virtualization for long conversations
import { FixedSizeList } from 'react-window'

// Debounced typing indicator
const debouncedTyping = useMemo(
  () => debounce(setIsTyping, 300),
  []
)
```

## ✅ Validation Loops

### Development Testing
```bash
# Start development server
npm run dev

# Verify no console errors
# Check network tab for webhook calls
# Test responsive breakpoints
```

### Browser Testing with MCP Playwright
```javascript
// Navigate to site
await browser.navigate('http://localhost:3000')

// Test chatbot trigger
await browser.snapshot()
await browser.click('Chatbot trigger button', '.voipia-chatbot-trigger')

// Verify window opens
await browser.wait_for({ text: 'Comment puis-je vous aider?' })
await browser.snapshot()

// Test message sending
await browser.type('Input field', '.voipia-chatbot-input input', 'Parlez-moi de Louis')
await browser.press_key('Enter')

// Verify response
await browser.wait_for({ time: 5 })
await browser.snapshot()

// Test responsive design
await browser.resize(375, 667) // iPhone SE
await browser.snapshot()

await browser.resize(768, 1024) // iPad
await browser.snapshot()

await browser.resize(1920, 1080) // Desktop
await browser.snapshot()
```

### Code Quality Checks
```bash
# ESLint check
npm run lint

# TypeScript check
npx tsc --noEmit

# Build verification
npm run build

# Bundle size check
npx next-bundle-analyzer
```

### Accessibility Testing
```javascript
// Check keyboard navigation
await browser.press_key('Tab')
await browser.press_key('Enter')

// Verify ARIA labels
await browser.evaluate(() => {
  const trigger = document.querySelector('.voipia-chatbot-trigger')
  return trigger?.getAttribute('aria-label')
})
```

### Performance Metrics
```javascript
// Measure Time to Interactive
await browser.evaluate(() => {
  return performance.timing.domInteractive - performance.timing.navigationStart
})

// Check bundle size
// Should be < 50KB compressed
```

## ⚠️ Anti-patterns to Avoid

### ❌ Don't Do This:
1. **Creating unnecessary files** - Use existing patterns and components
2. **Blocking main thread** - Widget loads asynchronously
3. **Global CSS pollution** - Use scoped `.voipia-chatbot-*` classes
4. **Synchronous webhook calls** - Always use async/await with timeout
5. **Missing error boundaries** - Wrap in error boundary component
6. **Ignoring mobile UX** - Full-screen on mobile, window on desktop
7. **No loading states** - Always show typing/loading indicators
8. **Unescaped HTML** - Sanitize all webhook responses
9. **Memory leaks** - Clean up listeners and intervals
10. **No session persistence** - Use sessionStorage for conversation history

### ✅ Do This Instead:
1. **Reuse existing components** - Button, animations from existing code
2. **Non-blocking initialization** - Dynamic import with lazy loading
3. **Namespaced CSS** - Prefix all classes with `.voipia-chatbot-`
4. **Async with timeout** - 10-second max webhook timeout
5. **Graceful degradation** - Site works even if chatbot fails
6. **Responsive design** - Adapt to all screen sizes
7. **Clear feedback** - Loading, typing, error states
8. **XSS prevention** - Use React's built-in escaping
9. **Cleanup on unmount** - useEffect cleanup functions
10. **Session management** - Persist conversation during session

## 🎯 Success Criteria

### Functional Requirements
- [ ] Chatbot trigger button appears on all pages
- [ ] Smooth open/close animations
- [ ] Messages send to n8n webhook successfully
- [ ] Responses display correctly
- [ ] Session persists during navigation
- [ ] Error states handled gracefully

### Performance Requirements
- [ ] Bundle size < 50KB compressed
- [ ] Time to Interactive < 2 seconds
- [ ] No impact on Core Web Vitals
- [ ] Smooth 60fps animations

### UX Requirements
- [ ] Mobile-optimized full-screen mode
- [ ] Desktop floating window
- [ ] Keyboard navigation support
- [ ] Screen reader compatible
- [ ] Clear loading indicators
- [ ] Professional dark theme matching site

### Technical Requirements
- [ ] TypeScript types complete
- [ ] No ESLint errors
- [ ] Build passes without warnings
- [ ] Browser compatibility (Chrome, Firefox, Safari, Edge)
- [ ] CORS handled properly

## 🚀 Integration Steps

1. **Add ChatbotWidget to app/layout.tsx**
```tsx
import ChatbotWidget from '@/components/chatbot/ChatbotWidget'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <ChatbotWidget />
      </body>
    </html>
  )
}
```

2. **Update tailwind.config.ts safelist**
```typescript
safelist: [
  // ... existing
  'voipia-chatbot-trigger',
  'voipia-chatbot-window',
  // ... other chatbot classes
]
```

3. **Add chatbot data to lib/constants.ts**
```typescript
export const chatbotConfig = {
  webhookUrl: process.env.NEXT_PUBLIC_CHATBOT_WEBHOOK_URL || 'https://n8n.voipia.fr/webhook/chatbot-iapreneurs',
  welcomeMessage: 'Bonjour ! Je suis l\'assistant IA de Voipia. Comment puis-je vous aider ?',
  placeholder: 'Écrivez votre message...',
  // ... other config
}
```

## 📊 Confidence Score: 9/10

### Strengths:
- Complete understanding of existing codebase patterns
- Clear webhook integration path with n8n
- Comprehensive responsive design approach
- Solid error handling and fallback strategies
- Performance optimization techniques defined

### Minor Uncertainties:
- Exact n8n response format may need adjustment based on actual webhook configuration
- Session storage strategy might need refinement based on user navigation patterns

## 🔄 Next Steps

1. Execute this PRP with `/execute-prp PRPs/chatbot-widget.md`
2. Test webhook integration with actual n8n endpoint
3. Gather user feedback on chat experience
4. Iterate on conversation flows based on analytics
5. Consider adding multilingual support