import { HeroHome } from '@/components/landing/HeroHome';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { AgentsGridHome } from '@/components/landing/AgentsGridHome';
import { QualificationQuiz } from '@/components/landing/QualificationQuiz';
import { HowItWorksHome } from '@/components/landing/HowItWorksHome';
import { PricingCardsHome } from '@/components/landing/PricingCardsHome';
import { SDRComparison } from '@/components/landing/SDRComparison';
import { BundlePricing } from '@/components/landing/BundlePricing';
import { CustomDevelopment } from '@/components/landing/CustomDevelopment';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { CTAFinal } from '@/components/landing/CTAFinal';
import { faqs } from '@/lib/data/faqs';

export default function LandingV2Page() {
  return (
    <main className="overflow-x-hidden">
      {/* Hero Section */}
      <HeroHome />

      {/* Integration Bar */}
      <IntegrationBar />

      {/* Agents Grid */}
      <AgentsGridHome />

      {/* Qualification Quiz */}
      <QualificationQuiz />

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
  );
}
