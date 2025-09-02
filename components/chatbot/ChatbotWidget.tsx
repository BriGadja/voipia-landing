'use client'

import { AnimatePresence } from 'framer-motion'
import { ChatbotContextProvider } from '@/contexts/ChatbotContext'
import { useChatbot } from './hooks/useChatbot'
import ChatbotTrigger from './ChatbotTrigger'
import ChatbotWindow from './ChatbotWindow'

function ChatbotContent() {
  const chatbot = useChatbot()

  return (
    <ChatbotContextProvider value={chatbot}>
      <AnimatePresence mode="wait">
        {chatbot.state.isOpen ? (
          <ChatbotWindow key="window" />
        ) : (
          <ChatbotTrigger key="trigger" />
        )}
      </AnimatePresence>
    </ChatbotContextProvider>
  )
}

export default function ChatbotWidget() {
  return (
    <div className="voipia-chatbot-widget">
      <ChatbotContent />
    </div>
  )
}