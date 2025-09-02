'use client'

import dynamic from 'next/dynamic'

// Lazy load chatbot widget for performance
const ChatbotWidget = dynamic(
  () => import('./ChatbotWidget'),
  { 
    ssr: false,
    loading: () => null
  }
)

export default function ClientChatbot() {
  return <ChatbotWidget />
}