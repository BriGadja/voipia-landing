import { HeroHome } from '@/components/landing/HeroHome';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { AgentsGridHome } from '@/components/landing/AgentsGridHome';
import { HowItWorksHome } from '@/components/landing/HowItWorksHome';
import { PricingCardsHome } from '@/components/landing/PricingCardsHome';
import { SDRComparison } from '@/components/landing/SDRComparison';
import { CustomDevelopment } from '@/components/landing/CustomDevelopment';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { CTAFinal } from '@/components/landing/CTAFinal';

export default function LandingV2Page() {
  return (
    <main className="overflow-x-hidden">
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

      {/* Custom Development */}
      <CustomDevelopment />

      {/* FAQ Accordion */}
      <FAQAccordion />

      {/* Final CTA */}
      <CTAFinal />
    </main>
  );
}
