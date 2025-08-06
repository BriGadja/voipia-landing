import Navigation from '@/components/sections/Navigation'
import Hero from '@/components/sections/Hero'
import AgentsGrid from '@/components/sections/AgentsGrid'
import HowItWorks from '@/components/sections/HowItWorks'
import Metrics from '@/components/sections/Metrics'
import DemoSection from '@/components/sections/DemoSection'
import Footer from '@/components/sections/Footer'

export default function Home() {
  return (
    <main className="relative">
      <Navigation />
      <Hero />
      <AgentsGrid />
      <HowItWorks />
      <Metrics />
      <DemoSection />
      <Footer />
    </main>
  )
}