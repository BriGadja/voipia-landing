import type { Metadata } from 'next';
import { HeroLouis } from '@/components/landing/HeroLouis';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { HowItWorksLouis } from '@/components/landing/HowItWorksLouis';
import { UseCasesLouis } from '@/components/landing/UseCasesLouis';
import { BenefitsTable } from '@/components/landing/BenefitsTable';
import { CTAIntermediate } from '@/components/landing/CTAIntermediate';
import { ComparisonTable } from '@/components/landing/ComparisonTable';
import { TestimonialLouis } from '@/components/landing/TestimonialLouis';
import { PricingLouis } from '@/components/landing/PricingLouis';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { OtherAgents } from '@/components/landing/OtherAgents';
import { CrossSellHintDual } from '@/components/landing/CrossSellHintDual';
import { CTAFinalLouis } from '@/components/landing/CTAFinalLouis';
import { faqs } from '@/lib/data/faqs';
import { louisBenefits } from '@/lib/data/benefits';
import { getProductSchema, getFAQSchema, jsonLdScriptProps } from '@/lib/seo/structured-data';

export const metadata: Metadata = {
  title: 'Louis - Agent IA de Rappel Automatique de Leads | VoIPIA',
  description: 'Louis rappelle vos leads en moins de 60 secondes, 24/7. +72% taux de contact, x3 rendez-vous qualifiés. Déploiement en 5 jours. À partir de 190€/mois.',
  keywords: [
    'rappel automatique leads',
    'agent IA vocal',
    'qualification leads',
    'prise rendez-vous automatique',
    'Louis VoIPIA',
    'agent rappel IA',
  ],
  openGraph: {
    title: 'Louis - Rappel Automatique de Leads en <60s',
    description: 'Louis rappelle, qualifie et planifie chaque nouveau lead automatiquement. +72% taux de contact.',
    url: 'https://voipia.com/louis',
    siteName: 'VoIPIA',
    images: [
      {
        url: 'https://voipia.com/og-louis.png',
        width: 1200,
        height: 630,
        alt: 'Louis - Agent IA de Rappel Automatique',
      },
    ],
    type: 'website',
    locale: 'fr_FR',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Louis - Rappel Automatique de Leads',
    description: 'Louis rappelle vos leads en moins de 60 secondes, 24/7',
    images: ['https://voipia.com/og-louis.png'],
  },
};

export default function LouisPage() {
  const productSchema = getProductSchema('louis');
  const faqSchema = getFAQSchema(faqs.louis);

  return (
    <>
      <main className="overflow-x-hidden">
        {/* JSON-LD Structured Data */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(productSchema) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
        />
        <HeroLouis />
      <IntegrationBar />
      <HowItWorksLouis />
      <UseCasesLouis />
      <BenefitsTable benefits={louisBenefits} />
      <div className="container mx-auto px-4 py-8">
        <CrossSellHintDual
          leftAgent={{
            text: "Vous avez aussi une base de leads dormants ?",
            agentName: "Arthur",
            agentLink: "/arthur",
            icon: "🔄",
            variant: "orange",
          }}
          rightAgent={{
            text: "Vous manquez des appels entrants ?",
            agentName: "Alexandra",
            agentLink: "/alexandra",
            icon: "☎️",
            variant: "green",
          }}
        />
      </div>
      <CTAIntermediate
        agentName="Louis"
        gradient={{
          background: 'from-blue-900/20 via-cyan-900/10 to-blue-900/20',
          button: 'from-blue-600 to-cyan-600',
          buttonHover: 'from-blue-700 to-cyan-700',
        }}
        secondaryCtaText="Écouter un exemple d'appel de Louis"
      />
      <ComparisonTable />
      <TestimonialLouis />
      <PricingLouis />
      <FAQAccordion faqs={faqs.louis} />
      <OtherAgents currentAgent="louis" />
        <CTAFinalLouis />
      </main>
    </>
  );
}
