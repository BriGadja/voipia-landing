# Voipia Landing Page

Une landing page moderne pour Voipia, spécialisée dans les agents vocaux IA. Construite avec Next.js 15, TypeScript, Tailwind CSS et Framer Motion.

## 🚀 Fonctionnalités

- **Stack moderne**: Next.js 15 avec App Router, TypeScript, Tailwind CSS
- **Animations fluides**: Framer Motion pour les micro-interactions
- **Design responsive**: Mobile-first avec breakpoints adaptatifs
- **Performance optimisée**: Partial Prerendering (PPR), lazy loading, Core Web Vitals
- **Accessibilité**: ARIA labels, navigation clavier, contraste AAA
- **SEO optimisé**: Métadonnées complètes, structured data, sitemap

## 🎯 Sections principales

1. **Hero Section**: Présentation principale avec CTA
2. **Agents Grid**: Présentation des 3 agents IA (Louis, Arthur, Alexandra)
3. **How It Works**: Processus en 3 étapes avec timeline animée
4. **Metrics**: Statistiques et bénéfices avec animations
5. **Demo Interactive**: Simulation de conversations en temps réel
6. **Footer CTA**: Double call-to-action avec contacts

## 🛠️ Installation

```bash
# Installer les dépendances
npm install

# Lancer le serveur de développement
npm run dev

# Construire pour la production
npm run build

# Lancer en production
npm start
```

## 📱 Technologies utilisées

- **Next.js 15**: Framework React avec App Router
- **TypeScript**: Typage statique pour plus de robustesse
- **Tailwind CSS**: Utility-first CSS framework
- **Framer Motion**: Librairie d'animations React
- **Lucide React**: Icônes SVG modernes
- **Partial Prerendering (PPR)**: Optimisation des performances

## 🎨 Design System

### Couleurs
- **Primary**: #6B46C1 (Violet)
- **Secondary**: #3B82F6 (Bleu)
- **Louis**: #3B82F6 (Bleu)
- **Arthur**: #FB923C (Orange)
- **Alexandra**: #10B981 (Vert)

### Typographie
- **Font**: Inter (Variable font)
- **Sizes**: 5xl-7xl pour les titres, xl-2xl pour les sous-titres

### Animations
- **Fade in up**: Entrée des sections
- **Scale on hover**: Interactions buttons/cards
- **Breathing**: Animation subtile des avatars
- **Wave**: Visualisation audio

## 🚀 Optimisations

- **Images**: next/image avec placeholder blur
- **Fonts**: next/font pour éviter FOUT
- **Lazy loading**: Sections non-critiques
- **CSS splitting**: Chunks séparés
- **Bundle analysis**: Optimisation des imports

## 📊 Performance

- **Core Web Vitals**: Score visé 95+
- **Lighthouse**: Performance, Accessibility, Best Practices, SEO
- **Bundle size**: Optimisé avec tree-shaking

## 🔧 Structure du projet

```
src/
├── app/
│   ├── layout.tsx        # Layout principal
│   ├── page.tsx          # Page d'accueil
│   └── globals.css       # Styles globaux
├── components/
│   ├── ui/               # Composants réutilisables
│   ├── sections/         # Sections de la page
│   └── animations/       # Wrappers Framer Motion
└── lib/
    ├── constants.ts      # Données statiques
    └── utils.ts          # Utilitaires
```

## 🎭 Agents IA

### Louis - Spécialiste rappel & RDV
- Qualification de leads en < 5 minutes
- Prise de RDV automatique
- Relances intelligentes

### Arthur - Expert prospection
- Réactivation base dormante
- Prospection ciblée ICP
- Scripts adaptatifs

### Alexandra - Standardiste IA
- Accueil professionnel 24/7
- Transferts intelligents
- Gestion des urgences

## 📈 Métriques

- **+31%** de contacts qualifiés
- **24/7** disponibilité totale
- **<2s** latence conversation
- **98.7%** taux de satisfaction

## 🌐 Déploiement

Le projet est optimisé pour Vercel avec:
- Déploiement automatique
- Analytics intégrés
- Edge Functions
- Image Optimization

## 📞 Contact

- **Email**: contact@voipia.fr
- **Site**: https://voipia.fr
- **Localisation**: Paris, France