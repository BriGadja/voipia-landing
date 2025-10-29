# PRP - Phase 7 : SEO, Analytics et Optimisations

**Date de création** : 2025-10-29
**Phase** : 7/7 - SEO, Analytics et Optimisations
**Durée estimée** : 2 jours
**Priorité** : 🟢 FINALE

---

## 🎯 Purpose & Goal

### Objectif Principal
Finaliser le site Voipia en optimisant pour les moteurs de recherche, en configurant le tracking analytics, et en maximisant les performances techniques pour garantir une expérience utilisateur optimale et une visibilité SEO maximale.

### Business Value
- **SEO** : Améliorer le référencement naturel pour attirer du trafic organique qualifié
- **Analytics** : Mesurer précisément les conversions et l'engagement pour optimiser les campagnes
- **Performance** : Garantir une expérience utilisateur rapide et fluide (score Lighthouse > 90)
- **Production-Ready** : Site complet, testé et prêt pour le déploiement en production

### Contexte
Après les Phases 1-6, le site dispose de :
- ✅ 4 pages complètes : Home (`/landingv2`), Louis (`/louis`), Arthur (`/arthur`), Alexandra (`/alexandra`)
- ✅ Navigation inter-pages avec Header global et cross-selling
- ✅ Contenu complet et composants fonctionnels

**Besoin** : Optimiser SEO, configurer analytics, et maximiser les performances avant migration de `/landingv2` → `/`.

---

## 📋 Context & References

### Documentation Source
```yaml
- file: proposition_restructuration_landing/INITIAL/INITIAL_refonte_07_seo_analytics.md
  why: Spécifications détaillées de la Phase 7

- file: CLAUDE.md
  why: Règles du projet, workflows, conventions de développement

- file: proposition_restructuration_landing/PROGRESS_REFONTE.md
  why: Suivi de progression globale du projet (actuellement à 86%)

- file: app/layout.tsx
  why: Root layout avec metadata existante à conserver pour compatibilité

- file: app/(marketing)/layout.tsx
  why: Marketing layout où intégrer Google Analytics

- file: lib/data/faqs.ts
  why: Source des FAQs pour structured data

- file: lib/data/agents.ts
  why: Données des agents pour structured data produits
```

### Technologies & Standards
- **Next.js 15** : App Router avec support natif sitemap/robots
- **Schema.org** : Structured data (Organization, Product, FAQPage)
- **Google Analytics 4** : Event tracking et conversions
- **Lighthouse** : Performance auditing (target > 90)
- **Core Web Vitals** : LCP < 2.5s, FID < 100ms, CLS < 0.1

### Existing Patterns
- Metadata dans `app/layout.tsx` (root) - à ne PAS modifier
- Metadata dans `app/(marketing)/layout.tsx` - à enrichir
- Font optimization déjà configuré (Inter avec display: swap)
- Vercel Analytics déjà installé dans root layout

---

## 🏗️ Implementation Blueprint

### Phase 7 Overview

```
Phase 7 : SEO, Analytics et Optimisations
├── Task 7.1 : Meta Tags Uniques (Pages agents)
├── Task 7.2 : Structured Data (JSON-LD)
├── Task 7.3 : Sitemap & Robots.txt
├── Task 7.4 : Google Analytics 4
├── Task 7.5 : Performance Optimizations
└── Task 7.6 : Tests Finaux & Lighthouse Audit
```

---

### Task 7.1 : Meta Tags Uniques par Page

**Objectif** : Chaque page agent doit avoir des meta tags uniques et optimisés pour SEO.

**⚠️ IMPORTANT** : Ne PAS modifier `app/layout.tsx` (root) - il contient les metadata par défaut. Ajouter les metadata spécifiques dans chaque page agent.

#### Fichier : `app/(marketing)/landingv2/page.tsx`

```typescript
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'VoIPIA - Agents IA Vocaux pour Automatiser vos Prospects | Louis, Arthur, Alexandra',
  description: 'Déléguez le traitement de vos prospects à nos agents IA : Louis rappelle vos leads, Alexandra répond 24/7, Arthur réactive vos bases dormantes. Déploiement en 5 jours.',
  keywords: [
    'agent IA vocal',
    'rappel automatique leads',
    'réception appels IA',
    'réactivation prospects',
    'automatisation commerciale',
    'prospection IA',
  ],
  openGraph: {
    title: 'VoIPIA - Agents IA Vocaux pour Automatiser vos Prospects',
    description: 'Louis, Alexandra et Arthur travaillent 24/7 pour traiter 100% de vos leads. Sans vacances. Sans turnover. Sans oubli.',
    url: 'https://voipia.com',
    siteName: 'VoIPIA',
    images: [
      {
        url: 'https://voipia.com/og-home.png',
        width: 1200,
        height: 630,
        alt: 'VoIPIA - Agents IA Vocaux',
      },
    ],
    type: 'website',
    locale: 'fr_FR',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'VoIPIA - Agents IA Vocaux',
    description: 'Automatisez le traitement de vos prospects avec nos agents IA vocaux',
    images: ['https://voipia.com/og-home.png'],
  },
};

// ... reste du composant
```

#### Fichier : `app/(marketing)/louis/page.tsx`

```typescript
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Louis - Agent IA de Rappel Automatique de Leads | VoIPIA',
  description: 'Louis rappelle vos leads en moins de 60 secondes, 24/7. +72% taux de contact, x3 rendez-vous qualifiés. Déploiement en 5 jours. À partir de 190€/mois.',
  keywords: [
    'rappel automatique leads',
    'agent IA vocal',
    'qualification leads',
    'prise rendez-vous automatique',
    'Louis VoIPIA',
    'agent rappel IA',
  ],
  openGraph: {
    title: 'Louis - Rappel Automatique de Leads en <60s',
    description: 'Louis rappelle, qualifie et planifie chaque nouveau lead automatiquement. +72% taux de contact.',
    url: 'https://voipia.com/louis',
    siteName: 'VoIPIA',
    images: [
      {
        url: 'https://voipia.com/og-louis.png',
        width: 1200,
        height: 630,
        alt: 'Louis - Agent IA de Rappel Automatique',
      },
    ],
    type: 'website',
    locale: 'fr_FR',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Louis - Rappel Automatique de Leads',
    description: 'Louis rappelle vos leads en moins de 60 secondes, 24/7',
    images: ['https://voipia.com/og-louis.png'],
  },
};

// ... reste du composant
```

#### Fichier : `app/(marketing)/arthur/page.tsx`

```typescript
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Arthur - Agent IA de Réactivation de Bases Dormantes | VoIPIA',
  description: 'Arthur réactive vos prospects dormants et génère +40k€ CA/mois en moyenne. +65% taux de réactivation. Relance automatique 24/7. À partir de 490€/mois.',
  keywords: [
    'réactivation prospects',
    'relance base dormante',
    'agent IA réactivation',
    'Arthur VoIPIA',
    'prospection automatique',
    'réactivation leads',
  ],
  openGraph: {
    title: 'Arthur - Réactivation de Bases Dormantes',
    description: 'Redonnez vie à vos opportunités oubliées. +40k€ CA/mois en moyenne.',
    url: 'https://voipia.com/arthur',
    siteName: 'VoIPIA',
    images: [
      {
        url: 'https://voipia.com/og-arthur.png',
        width: 1200,
        height: 630,
        alt: 'Arthur - Agent IA de Réactivation',
      },
    ],
    type: 'website',
    locale: 'fr_FR',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Arthur - Réactivation de Bases Dormantes',
    description: 'Arthur réactive vos prospects dormants et génère +40k€ CA/mois',
    images: ['https://voipia.com/og-arthur.png'],
  },
};

// ... reste du composant
```

#### Fichier : `app/(marketing)/alexandra/page.tsx`

```typescript
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: "Alexandra - Agent IA de Réception d'Appels 24/7 | VoIPIA",
  description: "Alexandra répond à 100% de vos appels en <3 sonneries, 24/7. Filtrage intelligent, prise de RDV automatique. +45% satisfaction client. À partir de 290€/mois.",
  keywords: [
    'réception appels IA',
    'standard téléphonique IA',
    'agent IA accueil',
    'Alexandra VoIPIA',
    'réceptionniste virtuelle',
    'accueil téléphonique IA',
  ],
  openGraph: {
    title: "Alexandra - Réception d'Appels 24/7",
    description: 'Ne manquez plus jamais un appel. 100% taux de réponse, disponibilité 24/7.',
    url: 'https://voipia.com/alexandra',
    siteName: 'VoIPIA',
    images: [
      {
        url: 'https://voipia.com/og-alexandra.png',
        width: 1200,
        height: 630,
        alt: "Alexandra - Agent IA de Réception 24/7",
      },
    ],
    type: 'website',
    locale: 'fr_FR',
  },
  twitter: {
    card: 'summary_large_image',
    title: "Alexandra - Réception d'Appels 24/7",
    description: "Alexandra répond à 100% de vos appels en <3 sonneries, 24/7",
    images: ['https://voipia.com/og-alexandra.png'],
  },
};

// ... reste du composant
```

**Validation** :
- [ ] Metadata ajoutée sur `/landingv2`, `/louis`, `/arthur`, `/alexandra`
- [ ] Pas de duplicate content entre les pages
- [ ] Keywords uniques et pertinents par page
- [ ] OG images créées (og-home.png, og-louis.png, og-arthur.png, og-alexandra.png) - 1200x630px

---

### Task 7.2 : Structured Data (JSON-LD)

**Objectif** : Ajouter des données structurées Schema.org pour améliorer l'affichage dans les SERP.

#### Fichier : `lib/seo/structured-data.ts` (nouveau)

```typescript
/**
 * Structured Data (JSON-LD) generators for SEO
 * Schema.org types: Organization, Product, FAQPage
 */

export function getOrganizationSchema() {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: 'VoIPIA',
    url: 'https://voipia.com',
    logo: 'https://voipia.com/logo.png',
    description: 'Agents IA vocaux pour automatiser le traitement de vos prospects',
    contactPoint: {
      '@type': 'ContactPoint',
      email: 'remi@voipia.com',
      contactType: 'Sales',
      availableLanguage: ['fr'],
    },
    sameAs: [
      'https://www.linkedin.com/company/voipia',
      'https://twitter.com/voipia',
    ],
    address: {
      '@type': 'PostalAddress',
      addressCountry: 'FR',
    },
  };
}

export function getProductSchema(agent: 'louis' | 'arthur' | 'alexandra') {
  const products = {
    louis: {
      name: 'Louis - Agent IA de Rappel Automatique',
      description: 'Agent IA vocal qui rappelle vos leads en moins de 60 secondes, 24/7. Qualification automatique et prise de rendez-vous.',
      url: 'https://voipia.com/louis',
      image: 'https://voipia.com/og-louis.png',
      price: '190',
      features: [
        'Rappel en moins de 60 secondes',
        '+72% taux de contact',
        'x3 rendez-vous qualifiés',
        'Déploiement en 5 jours',
      ],
    },
    arthur: {
      name: 'Arthur - Agent IA de Réactivation de Bases Dormantes',
      description: 'Agent IA vocal qui réactive vos bases de prospects dormants et génère +40k€ CA/mois en moyenne.',
      url: 'https://voipia.com/arthur',
      image: 'https://voipia.com/og-arthur.png',
      price: '490',
      features: [
        '+65% taux de réactivation',
        '+40k€ CA/mois en moyenne',
        'Relance automatique 24/7',
        'Multi-canaux (appel, SMS, email)',
      ],
    },
    alexandra: {
      name: "Alexandra - Agent IA de Réception d'Appels 24/7",
      description: "Agent IA vocal qui répond à tous vos appels entrants en moins de 3 sonneries, 24/7.",
      url: 'https://voipia.com/alexandra',
      image: 'https://voipia.com/og-alexandra.png',
      price: '290',
      features: [
        '100% taux de réponse',
        'Réponse en <3 sonneries',
        'Disponibilité 24/7',
        '+45% satisfaction client',
      ],
    },
  };

  const product = products[agent];

  return {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    description: product.description,
    url: product.url,
    image: product.image,
    brand: {
      '@type': 'Brand',
      name: 'VoIPIA',
    },
    offers: {
      '@type': 'Offer',
      price: product.price,
      priceCurrency: 'EUR',
      availability: 'https://schema.org/InStock',
      priceValidUntil: new Date(
        new Date().setFullYear(new Date().getFullYear() + 1)
      )
        .toISOString()
        .split('T')[0],
      url: product.url,
    },
    aggregateRating: {
      '@type': 'AggregateRating',
      ratingValue: '4.8',
      reviewCount: '50',
      bestRating: '5',
      worstRating: '1',
    },
  };
}

export function getFAQSchema(faqs: { question: string; answer: string }[]) {
  return {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faqs.map((faq) => ({
      '@type': 'Question',
      name: faq.question,
      acceptedAnswer: {
        '@type': 'Answer',
        text: faq.answer,
      },
    })),
  };
}

/**
 * Helper to safely stringify JSON-LD
 */
export function jsonLdScriptProps(data: object) {
  return {
    type: 'application/ld+json' as const,
    dangerouslySetInnerHTML: {
      __html: JSON.stringify(data),
    },
  };
}
```

#### Intégration dans les Pages

**Fichier : `app/(marketing)/landingv2/page.tsx`** (mise à jour)

```typescript
import { getOrganizationSchema, jsonLdScriptProps } from '@/lib/seo/structured-data';

export default function HomePage() {
  const organizationSchema = getOrganizationSchema();

  return (
    <>
      <script {...jsonLdScriptProps(organizationSchema)} />

      {/* Reste du contenu */}
    </>
  );
}
```

**Fichier : `app/(marketing)/louis/page.tsx`** (mise à jour)

```typescript
import { getProductSchema, getFAQSchema, jsonLdScriptProps } from '@/lib/seo/structured-data';
import { faqs } from '@/lib/data/faqs';

export default function LouisPage() {
  const productSchema = getProductSchema('louis');
  const faqSchema = getFAQSchema(faqs.louis);

  return (
    <>
      <script {...jsonLdScriptProps(productSchema)} />
      <script {...jsonLdScriptProps(faqSchema)} />

      {/* Reste du contenu */}
    </>
  );
}
```

**Répéter pour Arthur et Alexandra** avec `getProductSchema('arthur')` et `getProductSchema('alexandra')`.

**Validation** :
- [ ] JSON-LD présent sur toutes les pages
- [ ] Validation avec [Google Rich Results Test](https://search.google.com/test/rich-results)
- [ ] Pas d'erreur de schema dans la console

---

### Task 7.3 : Sitemap & Robots.txt

**Objectif** : Générer automatiquement un sitemap.xml et configurer robots.txt pour l'indexation.

#### Fichier : `app/sitemap.ts` (nouveau)

```typescript
import { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = 'https://voipia.com';
  const now = new Date();

  return [
    {
      url: baseUrl,
      lastModified: now,
      changeFrequency: 'monthly',
      priority: 1.0,
    },
    {
      url: `${baseUrl}/louis`,
      lastModified: now,
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/arthur`,
      lastModified: now,
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/alexandra`,
      lastModified: now,
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    // Note: Dashboard n'est PAS dans le sitemap (privé, derrière auth)
  ];
}
```

**⚠️ IMPORTANT** : `/landingv2` n'est PAS dans le sitemap car c'est une route temporaire. Après la migration finale (Phase 7 complète), `/landingv2` sera supprimé et remplacé par `/` comme route principale.

#### Fichier : `app/robots.ts` (nouveau)

```typescript
import { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: [
          '/dashboard/',
          '/api/',
          '/landingv2/', // Temporaire, sera retiré après migration
        ],
      },
    ],
    sitemap: 'https://voipia.com/sitemap.xml',
  };
}
```

**Validation** :
- [ ] Sitemap généré et accessible à `http://localhost:3000/sitemap.xml`
- [ ] Robots.txt accessible à `http://localhost:3000/robots.txt`
- [ ] Dashboard et API exclus de l'indexation
- [ ] Sitemap à soumettre à Google Search Console après déploiement

---

### Task 7.4 : Google Analytics 4

**Objectif** : Configurer GA4 pour tracker les pages vues, événements et conversions.

#### Fichier : `lib/analytics/gtag.ts` (nouveau)

```typescript
/**
 * Google Analytics 4 helpers
 * Docs: https://developers.google.com/analytics/devguides/collection/gtagjs
 */

export const GA_MEASUREMENT_ID = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID || '';

/**
 * Track page view
 */
export const pageview = (url: string) => {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('config', GA_MEASUREMENT_ID, {
      page_path: url,
    });
  }
};

/**
 * Track custom event
 */
export const event = ({
  action,
  category,
  label,
  value,
}: {
  action: string;
  category: string;
  label?: string;
  value?: number;
}) => {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('event', action, {
      event_category: category,
      event_label: label,
      value: value,
    });
  }
};

// ============================================
// Predefined Events for Voipia
// ============================================

/**
 * Track CTA button click
 */
export const trackCTAClick = (ctaName: string, location: string) => {
  event({
    action: 'cta_click',
    category: 'Conversion',
    label: `${ctaName} - ${location}`,
  });
};

/**
 * Track agent page view (for funnel analysis)
 */
export const trackAgentPageView = (agent: 'louis' | 'arthur' | 'alexandra') => {
  event({
    action: 'agent_page_view',
    category: 'Navigation',
    label: agent,
  });
};

/**
 * Track audio demo play
 */
export const trackAudioPlay = (agent: string) => {
  event({
    action: 'audio_play',
    category: 'Engagement',
    label: agent,
  });
};

/**
 * Track quiz interaction
 */
export const trackQuizSelection = (selectedAgent: string) => {
  event({
    action: 'quiz_selection',
    category: 'Engagement',
    label: selectedAgent,
  });
};

/**
 * Track cross-sell click
 */
export const trackCrossSellClick = (fromAgent: string, toAgent: string) => {
  event({
    action: 'cross_sell_click',
    category: 'Navigation',
    label: `${fromAgent} -> ${toAgent}`,
  });
};
```

#### Fichier : `lib/analytics/gtag.d.ts` (nouveau)

```typescript
/**
 * TypeScript definitions for gtag
 */

declare global {
  interface Window {
    gtag?: (
      command: 'config' | 'event',
      targetId: string,
      config?: Record<string, any>
    ) => void;
    dataLayer?: any[];
  }
}

export {};
```

#### Fichier : `app/(marketing)/layout.tsx` (mise à jour)

```typescript
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
```

#### Utilisation dans les Composants

**Exemple : Button avec tracking CTA**

```typescript
'use client';

import { trackCTAClick } from '@/lib/analytics/gtag';

export function CTAButton({ ctaName, location }: { ctaName: string; location: string }) {
  const handleClick = () => {
    trackCTAClick(ctaName, location);
    // ... reste de la logique (navigation, etc.)
  };

  return (
    <button onClick={handleClick}>
      {ctaName}
    </button>
  );
}
```

**Exemple : AudioPlayer avec tracking**

```typescript
'use client';

import { trackAudioPlay } from '@/lib/analytics/gtag';

export function AudioPlayer({ agent }: { agent: string }) {
  const handlePlay = () => {
    trackAudioPlay(agent);
  };

  return <audio onPlay={handlePlay} />;
}
```

**Validation** :
- [ ] GA4 configuré avec ID correct dans `.env.local`
- [ ] Scripts chargés uniquement si GA_MEASUREMENT_ID est défini
- [ ] Events trackés : CTAs, navigation, audio, quiz, cross-sell
- [ ] Vérification en temps réel dans GA4 (Realtime view)
- [ ] Pas d'erreur console liée à gtag

**Configuration `.env.local`** :
```bash
NEXT_PUBLIC_GA_MEASUREMENT_ID=G-XXXXXXXXXX
```

---

### Task 7.5 : Performance Optimizations

**Objectif** : Maximiser les performances pour atteindre un score Lighthouse > 90.

#### 5.1 - Image Optimization

**Utiliser `next/image` partout** :

```typescript
import Image from 'next/image';

// ✅ Correct
<Image
  src="/logos/elevenlabs.svg"
  alt="Eleven Labs"
  width={120}
  height={40}
  loading="lazy"
/>

// ❌ Incorrect
<img src="/logos/elevenlabs.svg" alt="Eleven Labs" />
```

**Créer OG Images optimisées** :
- Taille : 1200x630px
- Format : PNG ou WebP
- Poids : < 300KB
- Fichiers : `public/og-home.png`, `public/og-louis.png`, etc.

#### 5.2 - Font Optimization

**Déjà configuré dans `app/layout.tsx`** :
```typescript
const inter = Inter({
  subsets: ['latin'],
  display: 'swap', // ✅ Évite FOUT (Flash of Unstyled Text)
  variable: '--font-inter',
});
```

#### 5.3 - Code Splitting & Lazy Loading

**Lazy load composants lourds** :

```typescript
import dynamic from 'next/dynamic';

// Lazy load AudioPlayer (non critique au first render)
const AudioPlayer = dynamic(() => import('@/components/shared/AudioPlayer'), {
  loading: () => <div className="animate-pulse h-12 bg-gray-800 rounded" />,
  ssr: false, // Client-side only si nécessaire
});

// Lazy load composants de démonstration
const DemoSection = dynamic(() => import('@/components/sections/DemoSection'));
```

#### 5.4 - Preload Critical Resources

**Dans `app/(marketing)/layout.tsx`** :

```typescript
import { Suspense } from 'react';

export default function MarketingLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {/* Preload hero images */}
      <link rel="preload" as="image" href="/hero-bg.webp" />

      <Header />
      <Suspense fallback={<div>Chargement...</div>}>
        <main className="pt-16">{children}</main>
      </Suspense>
    </>
  );
}
```

#### 5.5 - Reduce JavaScript Bundle Size

**Audit des imports** :
```typescript
// ❌ Importer toute la lib
import _ from 'lodash';

// ✅ Import spécifique
import debounce from 'lodash/debounce';
```

**Validation** :
- [ ] Toutes les images utilisent `next/image`
- [ ] Composants lourds lazy-loadés
- [ ] Pas d'import inutile de libs complètes
- [ ] Bundle size analysé avec `@next/bundle-analyzer`

---

### Task 7.6 : Tests Finaux & Lighthouse Audit

**Objectif** : Valider toutes les optimisations avec des tests complets.

#### 6.1 - Lighthouse Audit

**Commandes** :
```bash
npm run build
npm run start

# Ouvrir http://localhost:3000
# DevTools → Lighthouse → Generate report (Desktop + Mobile)
```

**Objectifs à atteindre** :

| Métrique | Objectif |
|----------|----------|
| Performance | > 90 |
| Accessibility | > 95 |
| Best Practices | > 95 |
| SEO | 100 |

#### 6.2 - Core Web Vitals

**Métriques critiques** :

| Métrique | Objectif | Description |
|----------|----------|-------------|
| LCP (Largest Contentful Paint) | < 2.5s | Vitesse d'affichage du plus gros élément |
| FID (First Input Delay) | < 100ms | Réactivité aux interactions utilisateur |
| CLS (Cumulative Layout Shift) | < 0.1 | Stabilité visuelle (pas de jump de layout) |

**Outils de mesure** :
- Chrome DevTools → Performance
- [PageSpeed Insights](https://pagespeed.web.dev/)
- [WebPageTest](https://www.webpagetest.org/)

#### 6.3 - Tests Cross-Browser

**Browsers à tester** :
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)

**Tests fonctionnels** :
- [ ] Header dropdown fonctionne
- [ ] Quiz de qualification fonctionne
- [ ] Navigation inter-pages fluide
- [ ] AudioPlayer fonctionne
- [ ] CTAs tracés correctement
- [ ] Responsive design parfait (mobile, tablet, desktop)

#### 6.4 - SEO Validation

**Google Rich Results Test** :
- [ ] Tester chaque page sur [Google Rich Results Test](https://search.google.com/test/rich-results)
- [ ] Pas d'erreur de structured data

**Validation Meta Tags** :
- [ ] Tester OG tags avec [OpenGraph.xyz](https://www.opengraph.xyz/)
- [ ] Tester Twitter Cards avec [Twitter Card Validator](https://cards-dev.twitter.com/validator)

**Validation** :
- [ ] Lighthouse score > 90 sur toutes les pages
- [ ] Core Web Vitals dans les seuils
- [ ] Pas d'erreur console
- [ ] SEO 100/100
- [ ] Structured data valide

---

## ✅ Validation Loops

### Build & Dev Server
```bash
# 1. Build Next.js
npm run build

# 2. Start production server
npm run start

# 3. Ouvrir http://localhost:3000
```

### SEO Validation
```bash
# 1. Vérifier sitemap
curl http://localhost:3000/sitemap.xml

# 2. Vérifier robots.txt
curl http://localhost:3000/robots.txt

# 3. Valider structured data
# → Copier source HTML de chaque page
# → Tester sur https://search.google.com/test/rich-results
```

### Analytics Validation
```bash
# 1. Ouvrir http://localhost:3000
# 2. Ouvrir DevTools → Console
# 3. Vérifier que gtag est défini :
window.gtag

# 4. Déclencher des events (CTAs, navigation)
# 5. Vérifier dans GA4 → Realtime → Events
```

### Performance Validation
```bash
# 1. Build production
npm run build

# 2. Lighthouse audit
npm run start
# → DevTools → Lighthouse → Generate report

# 3. Vérifier Core Web Vitals
# → DevTools → Performance
# → Enregistrer un chargement de page
```

### Browser Testing (MCP Playwright)
```bash
# 1. Start dev server
npm run dev

# 2. Test Home page
mcp__playwright__browser_navigate(url: "http://localhost:3000/landingv2")
mcp__playwright__browser_snapshot()

# 3. Test Louis page
mcp__playwright__browser_navigate(url: "http://localhost:3000/louis")
mcp__playwright__browser_snapshot()

# 4. Test Arthur page
mcp__playwright__browser_navigate(url: "http://localhost:3000/arthur")
mcp__playwright__browser_snapshot()

# 5. Test Alexandra page
mcp__playwright__browser_navigate(url: "http://localhost:3000/alexandra")
mcp__playwright__browser_snapshot()

# 6. Test responsive
mcp__playwright__browser_resize(width: 375, height: 667)  # Mobile
mcp__playwright__browser_snapshot()
```

---

## 🚫 Anti-patterns

### SEO Anti-patterns
- ❌ Duplicate meta descriptions entre pages
- ❌ Keywords stuffing (bourrage de mots-clés)
- ❌ Structured data invalide ou incomplet
- ❌ Sitemap avec URLs mortes ou privées
- ❌ Robots.txt bloquant des pages publiques

### Analytics Anti-patterns
- ❌ Hardcoder le GA ID dans le code (utiliser `.env.local`)
- ❌ Tracker des events sans labels descriptifs
- ❌ Charger GA en mode `beforeInteractive` (ralentit FCP)
- ❌ Oublier de tester en temps réel avant déploiement
- ❌ Tracker des données sensibles (emails, téléphones)

### Performance Anti-patterns
- ❌ Utiliser `<img>` au lieu de `<Image>`
- ❌ Charger toutes les libs sans code splitting
- ❌ Images non optimisées (> 500KB)
- ❌ Fonts sans `display: swap`
- ❌ JavaScript bloquant le first render

### General Anti-patterns
- ❌ Modifier `app/layout.tsx` (root) - garder compatibilité avec dashboard
- ❌ Oublier de tester cross-browser
- ❌ Déployer sans audit Lighthouse
- ❌ Ne pas valider structured data avec Google Rich Results Test

---

## 📊 Success Criteria

### SEO Success
- ✅ Meta tags uniques sur toutes les pages
- ✅ Structured data valide (Organization, Product, FAQ)
- ✅ Sitemap.xml généré et soumis
- ✅ Robots.txt configuré correctement
- ✅ SEO score Lighthouse : 100/100

### Analytics Success
- ✅ GA4 configuré et fonctionnel
- ✅ Events trackés : CTAs, navigation, audio, quiz, cross-sell
- ✅ Realtime view affiche les events correctement
- ✅ Pas d'erreur console liée à gtag

### Performance Success
- ✅ Lighthouse Performance > 90
- ✅ Lighthouse Accessibility > 95
- ✅ Lighthouse Best Practices > 95
- ✅ Core Web Vitals : LCP < 2.5s, FID < 100ms, CLS < 0.1
- ✅ Bundle size optimisé
- ✅ Images optimisées (next/image partout)

### Production Ready
- ✅ Toutes les pages testées (Home, Louis, Arthur, Alexandra)
- ✅ Cross-browser testé (Chrome, Firefox, Safari, Edge)
- ✅ Responsive design validé (mobile, tablet, desktop)
- ✅ Pas d'erreur console
- ✅ Site prêt pour migration `/landingv2` → `/`

---

## 📝 Notes & Considerations

### Environment Variables Required
```bash
# .env.local
NEXT_PUBLIC_GA_MEASUREMENT_ID=G-XXXXXXXXXX
```

### Post-Deployment Checklist
- [ ] Soumettre sitemap à Google Search Console
- [ ] Vérifier indexation des pages (site:voipia.com)
- [ ] Configurer alertes GA4 pour conversions
- [ ] Monitorer Core Web Vitals avec Google Search Console
- [ ] Configurer dashboard GA4 personnalisé

### Migration Finale (`/landingv2` → `/`)
Après validation complète de la Phase 7 :
1. Renommer `app/(marketing)/page.tsx` (old home) → `app/(marketing)/page.old.tsx`
2. Copier `app/(marketing)/landingv2/page.tsx` → `app/(marketing)/page.tsx`
3. Supprimer le dossier `app/(marketing)/landingv2/`
4. Mettre à jour sitemap.ts (retirer `/landingv2`, ajouter `/`)
5. Mettre à jour robots.txt (retirer `/landingv2/` du disallow)
6. Build, test, commit, deploy

---

## 🔗 Related Files & Dependencies

### Files to Create
```
lib/
  seo/
    structured-data.ts
  analytics/
    gtag.ts
    gtag.d.ts

app/
  sitemap.ts
  robots.ts

public/
  og-home.png
  og-louis.png
  og-arthur.png
  og-alexandra.png
```

### Files to Update
```
app/(marketing)/landingv2/page.tsx  → Add metadata + structured data
app/(marketing)/louis/page.tsx      → Add metadata + structured data
app/(marketing)/arthur/page.tsx     → Add metadata + structured data
app/(marketing)/alexandra/page.tsx  → Add metadata + structured data
app/(marketing)/layout.tsx          → Add GA4 scripts

.env.local                          → Add GA_MEASUREMENT_ID
```

### Dependencies Required
- ✅ Next.js 15 (déjà installé)
- ✅ TypeScript (déjà installé)
- ✅ Vercel Analytics (déjà installé dans root layout)
- 🆕 Google Analytics 4 (via script tag, pas de package)

---

## 🎯 Execution Checklist

### Task 7.1 : Meta Tags
- [ ] Add metadata to `/landingv2/page.tsx`
- [ ] Add metadata to `/louis/page.tsx`
- [ ] Add metadata to `/arthur/page.tsx`
- [ ] Add metadata to `/alexandra/page.tsx`
- [ ] Create OG images (1200x630px)
- [ ] Validate no duplicate content

### Task 7.2 : Structured Data
- [ ] Create `lib/seo/structured-data.ts`
- [ ] Add JSON-LD to Home
- [ ] Add JSON-LD to Louis (Product + FAQ)
- [ ] Add JSON-LD to Arthur (Product + FAQ)
- [ ] Add JSON-LD to Alexandra (Product + FAQ)
- [ ] Validate with Google Rich Results Test

### Task 7.3 : Sitemap & Robots
- [ ] Create `app/sitemap.ts`
- [ ] Create `app/robots.ts`
- [ ] Test `/sitemap.xml` accessible
- [ ] Test `/robots.txt` accessible

### Task 7.4 : Analytics
- [ ] Create `lib/analytics/gtag.ts`
- [ ] Create `lib/analytics/gtag.d.ts`
- [ ] Update `app/(marketing)/layout.tsx` with GA4
- [ ] Add `.env.local` with GA_MEASUREMENT_ID
- [ ] Test events in GA4 Realtime

### Task 7.5 : Performance
- [ ] Audit all images → replace with `<Image>`
- [ ] Lazy load AudioPlayer component
- [ ] Optimize bundle imports
- [ ] Create OG images optimized

### Task 7.6 : Tests
- [ ] Run Lighthouse audit (4 pages)
- [ ] Test Core Web Vitals
- [ ] Test cross-browser (Chrome, Firefox, Safari, Edge)
- [ ] Test responsive (mobile, tablet, desktop)
- [ ] Validate SEO with Google tools

### Finalization
- [ ] Update `PROGRESS_REFONTE.md` (Phase 7: 100%, Global: 100%)
- [ ] Create Git commit
- [ ] Prepare for production deployment

---

**End of PRP - Phase 7**
