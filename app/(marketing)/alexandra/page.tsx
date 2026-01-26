import type { Metadata } from 'next';
import { HeroAlexandra } from '@/components/landing/HeroAlexandra';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { HowItWorksAlexandra } from '@/components/landing/HowItWorksAlexandra';
import { UseCasesAlexandra } from '@/components/landing/UseCasesAlexandra';
import { BenefitsTable } from '@/components/landing/BenefitsTable';
import { TestimonialAlexandra } from '@/components/landing/TestimonialAlexandra';
import { PricingAlexandra } from '@/components/landing/PricingAlexandra';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { OtherAgents } from '@/components/landing/OtherAgents';
import { CrossSellHintDual } from '@/components/landing/CrossSellHintDual';
import { CTAFinalAlexandra } from '@/components/landing/CTAFinalAlexandra';
import { faqs } from '@/lib/data/faqs';
import { alexandraBenefits } from '@/lib/data/benefits';
import { getProductSchema, getFAQSchema, jsonLdScriptProps } from '@/lib/seo/structured-data';

export const metadata: Metadata = {
  title: "Alexandra - Agent IA de Réception d'Appels 24/7 | Sablia Vox",
  description: "Alexandra répond à 100% de vos appels en <3 sonneries, 24/7. Filtrage intelligent, prise de RDV automatique. +45% satisfaction client. À partir de 290€/mois.",
  keywords: [
    'réception appels IA',
    'standard téléphonique IA',
    'agent IA accueil',
    'Alexandra Sablia Vox',
    'réceptionniste virtuelle',
    'accueil téléphonique IA',
  ],
  openGraph: {
    title: "Alexandra - Réception d'Appels 24/7",
    description: 'Ne manquez plus jamais un appel. 100% taux de réponse, disponibilité 24/7.',
    url: 'https://vox.sablia.io/alexandra',
    siteName: 'Sablia Vox',
    images: [
      {
        url: 'https://vox.sablia.io/og-alexandra.png',
        width: 1200,
        height: 630,
        alt: "Alexandra - Agent IA de Réception 24/7",
      },
    ],
    type: 'website',
    locale: 'fr_FR',
  },
  twitter: {
    card: 'summary_large_image',
    title: "Alexandra - Réception d'Appels 24/7",
    description: "Alexandra répond à 100% de vos appels en <3 sonneries, 24/7",
    images: ['https://vox.sablia.io/og-alexandra.png'],
  },
};

export default function AlexandraPage() {
  const productSchema = getProductSchema('alexandra');
  const faqSchema = getFAQSchema(faqs.alexandra);

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
        <HeroAlexandra />
      <IntegrationBar />
      <HowItWorksAlexandra />
      <UseCasesAlexandra />
      <BenefitsTable
        benefits={alexandraBenefits}
        title="Des résultats qui parlent d'eux-mêmes"
        subtitle="Chaque appel est traité. Chaque client est pris en charge."
        gradientFrom="from-green-400"
        gradientTo="to-emerald-400"
      />
      <div className="container mx-auto px-4 py-8">
        <CrossSellHintDual
          leftAgent={{
            text: "Vous générez des nouveaux leads ?",
            agentName: "Louis",
            agentLink: "/louis",
            icon: "📞",
            variant: "blue",
          }}
          rightAgent={{
            text: "Vous avez une base dormante ?",
            agentName: "Arthur",
            agentLink: "/arthur",
            icon: "🔄",
            variant: "orange",
          }}
        />
      </div>
      <TestimonialAlexandra />
      <PricingAlexandra />
      <FAQAccordion faqs={faqs.alexandra} />
      <OtherAgents currentAgent="alexandra" />
        <CTAFinalAlexandra />
      </main>
    </>
  );
}
