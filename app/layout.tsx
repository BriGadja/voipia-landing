import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import ClientChatbot from '@/components/chatbot/ClientChatbot'
import { Providers } from './providers'
import { AuthHashHandler } from '@/components/auth/AuthHashHandler'
import { Analytics } from '@vercel/analytics/next'

const inter = Inter({ 
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap'
})

export const metadata: Metadata = {
  title: 'Voipia - Agents Vocaux IA 24/7 | Louis & Arthur',
  description: 'Transformez vos appels en opportunités avec nos agents vocaux IA. Louis pour les rappels de leads, Arthur pour la prospection. Performance garantie 24/7.',
  keywords: ['agent vocal IA', 'intelligence artificielle', 'prospection téléphonique', 'CRM', 'automatisation commerciale'],
  authors: [{ name: 'Voipia', url: 'https://voipia.fr' }],
  creator: 'Voipia',
  publisher: 'Voipia',
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  openGraph: {
    type: 'website',
    locale: 'fr_FR',
    url: 'https://voipia.fr',
    siteName: 'Voipia',
    title: 'Voipia - Agents Vocaux IA 24/7',
    description: 'Transformez vos appels en opportunités avec Louis & Arthur - vos agents vocaux IA disponibles 24/7',
    images: [
      {
        url: '/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'Voipia - Agents Vocaux IA',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Voipia - Agents Vocaux IA 24/7',
    description: 'Transformez vos appels en opportunités avec Louis & Arthur',
    images: ['/twitter-image.jpg'],
  },
  icons: {
    icon: '/favicon.svg',
    shortcut: '/favicon.svg',
    apple: '/favicon.svg',
  },
  manifest: '/site.webmanifest',
  verification: {
    google: 'your-google-verification-code',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="fr" className="dark">
      <body className={`${inter.variable} font-inter antialiased bg-black text-white min-h-screen`}>
        <Providers>
          <AuthHashHandler />
          {children}
          <ClientChatbot />
        </Providers>
        <Analytics />
      </body>
    </html>
  )
}