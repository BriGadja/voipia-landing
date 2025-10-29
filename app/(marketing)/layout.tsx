import type { Metadata } from 'next';
import { Header } from '@/components/shared/Header';

export const metadata: Metadata = {
  title: 'Voipia - Agents Vocaux IA 24/7',
  description: 'Automatisez vos appels sortants et entrants avec des agents IA ultra-réalistes.',
};

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <Header />
      <main className="pt-16">{children}</main>
    </>
  );
}
