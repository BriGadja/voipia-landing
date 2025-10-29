import Navigation from '@/components/sections/Navigation'
import Hero from '@/components/sections/Hero'
import { IntegrationBar } from '@/components/landing/IntegrationBar'
import AgentsGrid from '@/components/sections/AgentsGrid'
import HowItWorks from '@/components/sections/HowItWorks'
import Metrics from '@/components/sections/Metrics'
import ROICalculator from '@/components/sections/ROICalculator'
import Footer from '@/components/sections/Footer'

export default function Home() {
  return (
    <main className="relative">
      <Navigation />
      <Hero />
      <IntegrationBar />
      <AgentsGrid />
      <HowItWorks />
      <Metrics />
      <ROICalculator />
      <Footer />
    </main>
  )
}