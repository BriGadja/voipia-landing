import { Metadata } from 'next'
import { FinancialDashboardClient } from './FinancialDashboardClient'

export const metadata: Metadata = {
  title: 'Dashboard Financier | Voipia',
  description: 'Suivi financier en temps réel : marge, coûts, revenue par client',
}

export default function FinancialDashboardPage() {
  return <FinancialDashboardClient />
}
