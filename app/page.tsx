import type { Metadata } from 'next';
import { Header } from '@/components/shared/Header';
import { HeroHome } from '@/components/landing/HeroHome';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { AgentsGridHome } from '@/components/landing/AgentsGridHome';
import { HowItWorksHome } from '@/components/landing/HowItWorksHome';
import { PricingCardsHome } from '@/components/landing/PricingCardsHome';
import { SDRComparison } from '@/components/landing/SDRComparison';
import { BundlePricing } from '@/components/landing/BundlePricing';
import { CustomDevelopment } from '@/components/landing/CustomDevelopment';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { CTAFinal } from '@/components/landing/CTAFinal';
import { faqs } from '@/lib/data/faqs';
import { getOrganizationSchema } from '@/lib/seo/structured-data';

export const metadata: Metadata = {
  title: 'VoIPIA - Agents IA Vocaux pour Automatiser vos Prospects | Louis, Arthur, Alexandra',
  description: 'Déléguez le traitement de vos prospects à nos agents IA : Louis rappelle vos leads, Alexandra répond 24/7, Arthur réactive vos bases dormantes. Déploiement en 5 jours.',
  keywords: [
    'agent IA vocal',
    'rappel automatique leads',
    'réception appels IA',
    'réactivation prospects',
    'automatisation commerciale',
    'prospection IA',
  ],
  openGraph: {
    title: 'VoIPIA - Agents IA Vocaux pour Automatiser vos Prospects',
    description: 'Louis, Alexandra et Arthur travaillent 24/7 pour traiter 100% de vos leads. Sans vacances. Sans turnover. Sans oubli.',
    url: 'https://voipia.com',
    siteName: 'VoIPIA',
    images: [
      {
        url: 'https://voipia.com/og-home.png',
        width: 1200,
        height: 630,
        alt: 'VoIPIA - Agents IA Vocaux',
      },
    ],
    type: 'website',
    locale: 'fr_FR',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'VoIPIA - Agents IA Vocaux',
    description: 'Automatisez le traitement de vos prospects avec nos agents IA vocaux',
    images: ['https://voipia.com/og-home.png'],
  },
};

export default function Home() {
  const organizationSchema = getOrganizationSchema();

  return (
    <>
      <Header />
      <main className="overflow-x-hidden pt-16">
        {/* JSON-LD Structured Data */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(organizationSchema) }}
        />
        {/* Hero Section */}
        <HeroHome />

      {/* Integration Bar */}
      <IntegrationBar />

      {/* Agents Grid */}
      <AgentsGridHome />

      {/* How It Works */}
      <HowItWorksHome />

      {/* Pricing Cards */}
      <PricingCardsHome />

      {/* SDR Comparison */}
      <SDRComparison />

      {/* Bundle Pricing */}
      <BundlePricing />

      {/* Custom Development */}
      <CustomDevelopment />

      {/* FAQ Accordion */}
      <FAQAccordion faqs={faqs.home} />

      {/* Final CTA */}
        <CTAFinal />
      </main>
    </>
  );
}
