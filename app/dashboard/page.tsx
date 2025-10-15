import { DashboardClient } from './DashboardClient'
import './styles.css'

export const metadata = {
  title: 'Dashboard Analytics | Voipia',
  description: 'Analysez les performances de vos agents vocaux IA',
}

export default function DashboardPage() {
  return <DashboardClient />
}
