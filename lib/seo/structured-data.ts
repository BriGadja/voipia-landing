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
      description:
        'Agent IA vocal qui rappelle vos leads en moins de 60 secondes, 24/7. Qualification automatique et prise de rendez-vous.',
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
      description:
        'Agent IA vocal qui réactive vos bases de prospects dormants et génère +40k€ CA/mois en moyenne.',
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
      description:
        'Agent IA vocal qui répond à tous vos appels entrants en moins de 3 sonneries, 24/7.',
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
      priceValidUntil: new Date(new Date().setFullYear(new Date().getFullYear() + 1))
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
