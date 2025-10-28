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
import { CTAFinalArthur } from '@/components/landing/CTAFinalArthur';
import { faqs } from '@/lib/data/faqs';
import { arthurBenefits } from '@/lib/data/benefits';

export default function ArthurPage() {
  return (
    <main className="overflow-x-hidden">
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
      <CTAIntermediate />
      <ArthurStrength />
      <TestimonialArthur />
      <PricingArthur />
      <FAQAccordion faqs={faqs.arthur} />
      <CTAFinalArthur />
    </main>
  );
}
