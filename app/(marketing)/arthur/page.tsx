import type { Metadata } from 'next';
import { HeroArthur } from '@/components/landing/HeroArthur';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { HowItWorksArthur } from '@/components/landing/HowItWorksArthur';
import { UseCasesArthur } from '@/components/landing/UseCasesArthur';
import { BenefitsTable } from '@/components/landing/BenefitsTable';
import { CTAIntermediate } from '@/components/landing/CTAIntermediate';
import { ArthurStrength } from '@/components/landing/ArthurStrength';
import { TestimonialArthur } from '@/components/landing/TestimonialArthur';
import { PricingArthur } from '@/components/landing/PricingArthur';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { OtherAgents } from '@/components/landing/OtherAgents';
import { CrossSellHintDual } from '@/components/landing/CrossSellHintDual';
import { CTAFinalArthur } from '@/components/landing/CTAFinalArthur';
import { faqs } from '@/lib/data/faqs';
import { arthurBenefits } from '@/lib/data/benefits';
import { getProductSchema, getFAQSchema, jsonLdScriptProps } from '@/lib/seo/structured-data';

export const metadata: Metadata = {
  title: 'Arthur - Agent IA de Réactivation de Bases Dormantes | Sablia Vox',
  description: 'Arthur réactive vos prospects dormants et génère +40k€ CA/mois en moyenne. +65% taux de réactivation. Relance automatique 24/7. À partir de 490€/mois.',
  keywords: [
    'réactivation prospects',
    'relance base dormante',
    'agent IA réactivation',
    'Arthur Sablia Vox',
    'prospection automatique',
    'réactivation leads',
  ],
  openGraph: {
    title: 'Arthur - Réactivation de Bases Dormantes',
    description: 'Redonnez vie à vos opportunités oubliées. +40k€ CA/mois en moyenne.',
    url: 'https://vox.sablia.io/arthur',
    siteName: 'Sablia Vox',
    images: [
      {
        url: 'https://vox.sablia.io/og-arthur.png',
        width: 1200,
        height: 630,
        alt: 'Arthur - Agent IA de Réactivation',
      },
    ],
    type: 'website',
    locale: 'fr_FR',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Arthur - Réactivation de Bases Dormantes',
    description: 'Arthur réactive vos prospects dormants et génère +40k€ CA/mois',
    images: ['https://vox.sablia.io/og-arthur.png'],
  },
};

export default function ArthurPage() {
  const productSchema = getProductSchema('arthur');
  const faqSchema = getFAQSchema(faqs.arthur);

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
        <HeroArthur />
      <IntegrationBar />
      <HowItWorksArthur />
      <UseCasesArthur />
      <BenefitsTable
        benefits={arthurBenefits}
        title="Des résultats qui parlent d'eux-mêmes"
        subtitle="Arthur libère du temps à vos équipes et transforme vos fichiers en nouvelles ventes."
        gradientFrom="from-orange-400"
        gradientTo="to-amber-400"
      />
      <div className="container mx-auto px-4 py-8">
        <CrossSellHintDual
          leftAgent={{
            text: "Vous générez aussi des nouveaux leads chaque jour ?",
            agentName: "Louis",
            agentLink: "/louis",
            icon: "📞",
            variant: "blue",
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
        agentName="Arthur"
        gradient={{
          background: 'from-orange-900/20 via-amber-900/10 to-orange-900/20',
          button: 'from-orange-600 to-amber-600',
          buttonHover: 'from-orange-700 to-amber-700',
        }}
        secondaryCtaText="Écouter un appel de réactivation d'Arthur"
      />
      <ArthurStrength />
      <TestimonialArthur />
      <PricingArthur />
      <FAQAccordion faqs={faqs.arthur} />
      <OtherAgents currentAgent="arthur" />
        <CTAFinalArthur />
      </main>
    </>
  );
}
