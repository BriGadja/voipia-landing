import Navigation from '@/components/sections/landingv2/Navigation';
import Hero from '@/components/sections/landingv2/Hero';
import Problem from '@/components/sections/Problem';
import Testimonials from '@/components/sections/Testimonials';
import Solutions from '@/components/sections/Solutions';
import Comparison from '@/components/sections/Comparison';
import ROICalculator from '@/components/sections/landingv2/ROICalculator';
import HowItWorks from '@/components/sections/landingv2/HowItWorks';
import Pricing from '@/components/sections/Pricing';
import CTAFinal from '@/components/sections/CTAFinal';
import Footer from '@/components/sections/landingv2/Footer';

export default function LandingV2Page() {
  return (
    <main className="min-h-screen bg-black text-white">
      <Navigation />
      <Hero />
      <Problem />
      <Testimonials />
      <Solutions />
      <Comparison />
      <ROICalculator />
      <HowItWorks />
      <Pricing />
      <CTAFinal />
      <Footer />
    </main>
  );
}
