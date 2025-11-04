import type { Metadata } from 'next';
import TesterNosAgentsClient from './TesterNosAgentsClient';

export const metadata: Metadata = {
  title: 'Tester nos Agents IA Vocaux | VoIPIA',
  description: 'Testez gratuitement nos agents IA vocaux Louis, Arthur et Alexandra. Remplissez le formulaire et recevez un appel de démonstration en 30 secondes.',
  openGraph: {
    title: 'Tester nos Agents IA Vocaux | VoIPIA',
    description: 'Testez gratuitement nos agents IA vocaux. Recevez un appel de démonstration en 30 secondes.',
    url: 'https://voipia.com/tester-nos-agents',
    siteName: 'VoIPIA',
    type: 'website',
    locale: 'fr_FR',
  },
};

export default function TesterNosAgentsPage() {
  return <TesterNosAgentsClient />;
}
