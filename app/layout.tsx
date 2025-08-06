import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ 
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap'
})

export const metadata: Metadata = {
  title: 'Voipia - Agents Vocaux IA 24/7 | Louis, Arthur & Alexandra',
  description: 'Transformez vos appels en opportunités avec nos agents vocaux IA. Louis pour les rappels de leads, Arthur pour la prospection, Alexandra comme standardiste. Performance garantie 24/7.',
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
    description: 'Transformez vos appels en opportunités avec Louis, Arthur & Alexandra - vos agents vocaux IA disponibles 24/7',
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
    description: 'Transformez vos appels en opportunités avec Louis, Arthur & Alexandra',
    images: ['/twitter-image.jpg'],
  },
  icons: {
    icon: '/favicon.ico',
    shortcut: '/favicon-16x16.png',
    apple: '/apple-touch-icon.png',
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
        {children}
      </body>
    </html>
  )
}