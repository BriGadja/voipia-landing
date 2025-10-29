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

export default function LouisPage() {
  return (
    <main className="overflow-x-hidden">
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
      <CTAIntermediate />
      <ComparisonTable />
      <TestimonialLouis />
      <PricingLouis />
      <FAQAccordion faqs={faqs.louis} />
      <OtherAgents currentAgent="louis" />
      <CTAFinalLouis />
    </main>
  );
}
