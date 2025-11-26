# PHASE 7 : SEO, ANALYTICS ET OPTIMISATIONS

## 🎯 Objectif de la Phase

Optimiser le site pour les moteurs de recherche, configurer le tracking analytics et finaliser les optimisations de performance.

**Durée estimée** : 2 jours
**Priorité** : 🟢 FINALE (après toutes les pages)

---

## 📋 Contexte

Après les phases 1-6, le site est fonctionnel avec :
- 4 pages complètes : Home, Louis, Arthur, Alexandra
- Navigation inter-pages
- Contenu complet

**Besoin** : Optimiser pour SEO, configurer le tracking et améliorer les performances.

---

## 🎯 Livrables de la Phase

### 1. SEO On-Page
- Meta descriptions uniques par page
- Titles optimisés
- Open Graph tags
- Twitter Cards

### 2. Structured Data (JSON-LD)
- Schema.org Organization
- Schema.org Product pour chaque agent
- Schema.org FAQPage

### 3. Sitemap & Robots.txt
- Génération automatique du sitemap
- Configuration robots.txt

### 4. Analytics & Tracking
- Google Analytics 4
- Event tracking (CTA clicks, navigation)
- Conversion tracking

### 5. Performance Optimizations
- Image optimization
- Lazy loading
- Code splitting
- Font optimization

---

## 📦 Micro-tâches Détaillées

### Tâche 7.1 : Meta Tags Uniques

**Fichier** : `app/(marketing)/page.tsx` (Home)

```typescript
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'VoIPIA - Agents IA Vocaux pour Automatiser vos Prospects | Louis, Arthur, Alexandra',
  description: 'Déléguez le traitement de vos prospects à nos agents IA : Louis rappelle vos leads, Alexandra répond 24/7, Arthur réactive vos bases dormantes. Déploiement en 5 jours.',
  keywords: ['agent IA vocal', 'rappel automatique leads', 'réception appels IA', 'réactivation prospects', 'automatisation commerciale'],
  openGraph: {
    title: 'VoIPIA - Agents IA Vocaux pour Automatiser vos Prospects',
    description: 'Louis, Alexandra et Arthur travaillent 24/7 pour traiter 100% de vos leads. Sans vacances. Sans turnover. Sans oubli.',
    url: 'https://voipia.com',
    siteName: 'VoIPIA',
    images: [
      {
        url: 'https://voipia.com/og-image.png',
        width: 1200,
        height: 630,
        alt: 'VoIPIA - Agents IA Vocaux',
      },
    ],
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'VoIPIA - Agents IA Vocaux',
    description: 'Automatisez le traitement de vos prospects avec nos agents IA vocaux',
    images: ['https://voipia.com/og-image.png'],
  },
};
```

**Fichier** : `app/(marketing)/louis/page.tsx`

```typescript
export const metadata: Metadata = {
  title: 'Louis - Agent IA de Rappel Automatique de Leads | VoIPIA',
  description: 'Louis rappelle vos leads en moins de 60 secondes, 24/7. +72% taux de contact, x3 rendez-vous qualifiés. Déploiement en 5 jours. À partir de 190€/mois.',
  keywords: ['rappel automatique leads', 'agent IA vocal', 'qualification leads', 'prise rendez-vous automatique', 'Louis VoIPIA'],
  openGraph: {
    title: 'Louis - Rappel Automatique de Leads en <60s',
    description: 'Louis rappelle, qualifie et planifie chaque nouveau lead automatiquement. +72% taux de contact.',
    url: 'https://voipia.com/louis',
    images: [{ url: 'https://voipia.com/og-louis.png' }],
  },
};
```

**Fichier** : `app/(marketing)/arthur/page.tsx`

```typescript
export const metadata: Metadata = {
  title: 'Arthur - Agent IA de Réactivation de Bases Dormantes | VoIPIA',
  description: 'Arthur réactive vos prospects dormants et génère +40k€ CA/mois en moyenne. +65% taux de réactivation. Relance automatique 24/7. À partir de 490€/mois.',
  keywords: ['réactivation prospects', 'relance base dormante', 'agent IA réactivation', 'Arthur VoIPIA', 'prospection automatique'],
  openGraph: {
    title: 'Arthur - Réactivation de Bases Dormantes',
    description: 'Redonnez vie à vos opportunités oubliées. +40k€ CA/mois en moyenne.',
    url: 'https://voipia.com/arthur',
    images: [{ url: 'https://voipia.com/og-arthur.png' }],
  },
};
```

**Fichier** : `app/(marketing)/alexandra/page.tsx`

```typescript
export const metadata: Metadata = {
  title: 'Alexandra - Agent IA de Réception d\'Appels 24/7 | VoIPIA',
  description: 'Alexandra répond à 100% de vos appels en <3 sonneries, 24/7. Filtrage intelligent, prise de RDV automatique. +45% satisfaction client. À partir de 290€/mois.',
  keywords: ['réception appels IA', 'standard téléphonique IA', 'agent IA accueil', 'Alexandra VoIPIA', 'réceptionniste virtuelle'],
  openGraph: {
    title: 'Alexandra - Réception d\'Appels 24/7',
    description: 'Ne manquez plus jamais un appel. 100% taux de réponse, disponibilité 24/7.',
    url: 'https://voipia.com/alexandra',
    images: [{ url: 'https://voipia.com/og-alexandra.png' }],
  },
};
```

**Validation** :
- [ ] Meta tags uniques sur chaque page
- [ ] Pas de duplicate content
- [ ] OG images créées et optimisées

---

### Tâche 7.2 : Structured Data (JSON-LD)

**Fichier** : `lib/utils/structured-data.ts`

```typescript
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
    },
    sameAs: [
      'https://linkedin.com/company/voipia',
      'https://twitter.com/voipia',
    ],
  };
}

export function getProductSchema(agent: 'louis' | 'arthur' | 'alexandra') {
  const products = {
    louis: {
      name: 'Louis - Agent IA de Rappel Automatique',
      description: 'Agent IA vocal qui rappelle vos leads en moins de 60 secondes',
      offers: { price: '190', priceCurrency: 'EUR' },
    },
    arthur: {
      name: 'Arthur - Agent IA de Réactivation',
      description: 'Agent IA vocal qui réactive vos bases de prospects dormants',
      offers: { price: '490', priceCurrency: 'EUR' },
    },
    alexandra: {
      name: 'Alexandra - Agent IA de Réception 24/7',
      description: 'Agent IA vocal qui répond à tous vos appels entrants',
      offers: { price: '290', priceCurrency: 'EUR' },
    },
  };

  const product = products[agent];

  return {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: product.name,
    description: product.description,
    brand: {
      '@type': 'Brand',
      name: 'VoIPIA',
    },
    offers: {
      '@type': 'Offer',
      price: product.offers.price,
      priceCurrency: product.offers.priceCurrency,
      availability: 'https://schema.org/InStock',
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
```

**Intégrer dans les pages** :

```typescript
// Dans app/(marketing)/louis/page.tsx
import { getProductSchema, getFAQSchema } from '@/lib/utils/structured-data';

export default function LouisPage() {
  const productSchema = getProductSchema('louis');
  const faqSchema = getFAQSchema(louisFAQs);

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(productSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />
      {/* ... contenu de la page */}
    </>
  );
}
```

**Validation** :
- [ ] JSON-LD présent sur toutes les pages
- [ ] Validation avec Google Rich Results Test
- [ ] Pas d'erreur de schema

---

### Tâche 7.3 : Sitemap & Robots.txt

**Fichier** : `app/sitemap.ts`

```typescript
import { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = 'https://voipia.com';

  return [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 1.0,
    },
    {
      url: `${baseUrl}/louis`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/arthur`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/alexandra`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/dashboard`,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.5,
    },
  ];
}
```

**Fichier** : `app/robots.ts`

```typescript
import { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/dashboard/', '/api/'],
    },
    sitemap: 'https://voipia.com/sitemap.xml',
  };
}
```

**Validation** :
- [ ] Sitemap généré et accessible à `/sitemap.xml`
- [ ] Robots.txt accessible à `/robots.txt`
- [ ] Soumis à Google Search Console

---

### Tâche 7.4 : Google Analytics 4

**Fichier** : `lib/analytics/gtag.ts`

```typescript
export const GA_MEASUREMENT_ID = process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID;

export const pageview = (url: string) => {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('config', GA_MEASUREMENT_ID as string, {
      page_path: url,
    });
  }
};

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

// Events prédéfinis
export const trackCTAClick = (ctaName: string, location: string) => {
  event({
    action: 'cta_click',
    category: 'Conversion',
    label: `${ctaName} - ${location}`,
  });
};

export const trackAgentPageView = (agent: string) => {
  event({
    action: 'agent_page_view',
    category: 'Navigation',
    label: agent,
  });
};

export const trackAudioPlay = (agent: string) => {
  event({
    action: 'audio_play',
    category: 'Engagement',
    label: agent,
  });
};
```

**Fichier** : `app/(marketing)/layout.tsx` (mise à jour)

```typescript
import Script from 'next/script';
import { GA_MEASUREMENT_ID } from '@/lib/analytics/gtag';

export default function MarketingLayout({ children }) {
  return (
    <>
      {/* Google Analytics */}
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

      {/* Reste du layout */}
      <div className="...">
        <Header />
        <main>{children}</main>
        <Footer />
      </div>
    </>
  );
}
```

**Utilisation dans les composants** :

```typescript
'use client';

import { trackCTAClick } from '@/lib/analytics/gtag';

export function Button() {
  return (
    <button onClick={() => trackCTAClick('Tester Louis', 'Hero')}>
      Tester Louis gratuitement
    </button>
  );
}
```

**Validation** :
- [ ] GA4 configuré avec ID correct
- [ ] Events trackés (CTAs, navigation, audio)
- [ ] Vérification en temps réel dans GA4

---

### Tâche 7.5 : Performance Optimizations

**Image Optimization** :
```typescript
// Utiliser next/image partout
import Image from 'next/image';

<Image
  src="/logos/elevenlabs.svg"
  alt="Eleven Labs"
  width={120}
  height={40}
  loading="lazy"
  placeholder="blur"
/>
```

**Font Optimization** (déjà fait) :
```typescript
// app/(marketing)/layout.tsx
import { Inter } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
});
```

**Code Splitting** :
```typescript
// Lazy load composants lourds
import dynamic from 'next/dynamic';

const AudioPlayer = dynamic(() => import('@/components/shared/AudioPlayer'), {
  loading: () => <p>Chargement...</p>,
});
```

**Validation** :
- [ ] Toutes les images utilisent next/image
- [ ] Composants lourds lazy-loadés
- [ ] Lighthouse Performance > 90

---

### Tâche 7.6 : Tests Finaux

**Lighthouse Audit** :
```bash
npm run build
npm run start
# Ouvrir DevTools → Lighthouse → Generate report
```

Objectifs :
- [ ] Performance : > 90
- [ ] Accessibility : > 95
- [ ] Best Practices : > 95
- [ ] SEO : 100

**Core Web Vitals** :
- [ ] LCP (Largest Contentful Paint) : < 2.5s
- [ ] FID (First Input Delay) : < 100ms
- [ ] CLS (Cumulative Layout Shift) : < 0.1

**Tests Cross-Browser** :
- [ ] Chrome
- [ ] Firefox
- [ ] Safari
- [ ] Edge

---

## ✅ Validation de la Phase

### Tests SEO
- [ ] Meta tags présents et uniques
- [ ] Structured data valide
- [ ] Sitemap généré
- [ ] Robots.txt configuré
- [ ] Google Search Console configuré

### Tests Analytics
- [ ] GA4 tracking fonctionnel
- [ ] Events enregistrés correctement
- [ ] Real-time view opérationnel

### Tests Performance
- [ ] Lighthouse score > 90 sur toutes les pages
- [ ] Core Web Vitals dans les seuils
- [ ] Time to Interactive < 3s
- [ ] Pas d'erreur console

---

## 📊 Critères de Succès

1. ✅ SEO optimisé sur toutes les pages
2. ✅ Structured data implémenté
3. ✅ Analytics configuré et fonctionnel
4. ✅ Performance score > 90
5. ✅ Core Web Vitals validés
6. ✅ Site prêt pour production

---

## 🔗 Dépendances

**Avant cette phase** :
- Phase 1 : Fondations
- Phase 2 : Home
- Phase 3 : Louis
- Phase 4 : Arthur
- Phase 5 : Alexandra
- Phase 6 : Navigation

**Après cette phase** :
- 🎉 Site complet et prêt pour déploiement

---

**Dernière mise à jour** : 2025-10-28
**Statut** : 📋 Prêt pour génération PRP
