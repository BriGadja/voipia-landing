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
      <CTAIntermediate />
      <ArthurStrength />
      <TestimonialArthur />
      <PricingArthur />
      <FAQAccordion faqs={faqs.arthur} />
      <OtherAgents currentAgent="arthur" />
      <CTAFinalArthur />
    </main>
  );
}
