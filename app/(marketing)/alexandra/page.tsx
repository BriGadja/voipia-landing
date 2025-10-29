import { HeroAlexandra } from '@/components/landing/HeroAlexandra';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
import { HowItWorksAlexandra } from '@/components/landing/HowItWorksAlexandra';
import { UseCasesAlexandra } from '@/components/landing/UseCasesAlexandra';
import { BenefitsTable } from '@/components/landing/BenefitsTable';
import { TestimonialAlexandra } from '@/components/landing/TestimonialAlexandra';
import { PricingAlexandra } from '@/components/landing/PricingAlexandra';
import { FAQAccordion } from '@/components/landing/FAQAccordion';
import { CTAFinalAlexandra } from '@/components/landing/CTAFinalAlexandra';
import { faqs } from '@/lib/data/faqs';
import { alexandraBenefits } from '@/lib/data/benefits';

export default function AlexandraPage() {
  return (
    <main className="overflow-x-hidden">
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
      <TestimonialAlexandra />
      <PricingAlexandra />
      <FAQAccordion faqs={faqs.alexandra} />
      <CTAFinalAlexandra />
    </main>
  );
}
