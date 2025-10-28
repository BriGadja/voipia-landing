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
import { CTAFinalLouis } from '@/components/landing/CTAFinalLouis';
import { faqs } from '@/lib/data/faqs';

export default function LouisPage() {
  return (
    <main className="overflow-x-hidden">
      <HeroLouis />
      <IntegrationBar />
      <HowItWorksLouis />
      <UseCasesLouis />
      <BenefitsTable />
      <CTAIntermediate />
      <ComparisonTable />
      <TestimonialLouis />
      <PricingLouis />
      <FAQAccordion faqs={faqs.louis} />
      <CTAFinalLouis />
    </main>
  );
}
