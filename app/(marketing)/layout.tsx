import type { Metadata } from 'next';
import Script from 'next/script';
import { Header } from '@/components/shared/Header';
import { GA_MEASUREMENT_ID } from '@/lib/analytics/gtag';

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
      {/* Google Analytics 4 */}
      {GA_MEASUREMENT_ID && (
        <>
          <Script
            strategy="afterInteractive"
            src={`https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`}
          />
          <Script
            id="google-analytics"
            strategy="afterInteractive"
            dangerouslySetInnerHTML={{
              __html: `
                window.dataLayer = window.dataLayer || [];
                function gtag(){dataLayer.push(arguments);}
                gtag('js', new Date());
                gtag('config', '${GA_MEASUREMENT_ID}', {
                  page_path: window.location.pathname,
                });
              `,
            }}
          />
        </>
      )}

      <Header />
      <main className="pt-16">{children}</main>
    </>
  );
}
