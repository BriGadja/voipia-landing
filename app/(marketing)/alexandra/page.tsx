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
  );
}
