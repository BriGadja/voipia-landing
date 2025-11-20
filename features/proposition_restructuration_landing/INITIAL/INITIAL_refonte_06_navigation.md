# PHASE 6 : NAVIGATION ET CROSS-SELLING

## 🎯 Objectif de la Phase

Connecter toutes les pages et optimiser les parcours utilisateurs avec navigation inter-pages, cross-selling et quiz de qualification.

**Durée estimée** : 2-3 jours
**Priorité** : 🟡 IMPORTANTE (après les pages principales)

---

## 📋 Contexte

Actuellement (après Phases 1-5) :
- 4 pages indépendantes : Home, Louis, Arthur, Alexandra
- Navigation basique via URL
- Pas de suggestion d'autres agents
- Pas de quiz pour orienter les visiteurs

**Besoin** : Créer des passerelles entre les pages pour maximiser la découverte et les conversions.

---

## 🎯 Livrables de la Phase

### 1. Header avec Dropdown "Solutions"
- Menu déroulant affichant les 3 agents
- Visuel avec icon + nom + tagline
- Lien direct vers chaque LP

### 2. Quiz de Qualification (Home)
- 3-4 questions pour identifier le besoin
- Orientation automatique vers la LP appropriée
- Optionnel mais recommandé

### 3. Section "Découvrez nos autres agents" (sur chaque LP)
- Sur LP Louis : suggestions Arthur + Alexandra
- Sur LP Arthur : suggestions Louis + Alexandra
- Sur LP Alexandra : suggestions Louis + Arthur

### 4. Bundles Tarifaires
- Offre "Pack Complet" : 3 agents à prix réduit
- Calculateur d'économies
- CTA "Découvrir les bundles"

### 5. Liens Croisés Intelligents
- Suggestions contextuelles dans le contenu
- "Vous avez aussi une base dormante ? Découvrez Arthur"
- "Besoin de traiter vos leads chauds ? Rencontrez Louis"

---

## 📦 Micro-tâches Détaillées

### Tâche 6.1 : Header avec Dropdown

**Composant** : `components/shared/Header.tsx` (mise à jour)

```typescript
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { getAllAgents } from '@/lib/data/agents';

export function Header() {
  const [isOpen, setIsOpen] = useState(false);
  const agents = getAllAgents();

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-lg border-b border-white/10">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="text-2xl font-bold">
            VoIPIA
          </Link>

          {/* Menu principal */}
          <nav className="hidden md:flex items-center gap-8">
            {/* Dropdown Solutions */}
            <div
              className="relative"
              onMouseEnter={() => setIsOpen(true)}
              onMouseLeave={() => setIsOpen(false)}
            >
              <button className="flex items-center gap-2 text-gray-300 hover:text-white transition">
                Solutions
                <span className="text-xs">▼</span>
              </button>

              {/* Dropdown menu */}
              {isOpen && (
                <div className="absolute top-full left-0 mt-2 w-80 bg-black/95 backdrop-blur-lg border border-white/10 rounded-lg p-4 shadow-2xl">
                  <div className="space-y-3">
                    {agents.map((agent) => (
                      <Link
                        key={agent.id}
                        href={`/${agent.id}`}
                        className="flex items-start gap-3 p-3 rounded-lg hover:bg-white/5 transition"
                      >
                        <span className="text-3xl">{agent.icon}</span>
                        <div>
                          <p className="font-semibold text-white">{agent.displayName}</p>
                          <p className="text-sm text-gray-400">{agent.tagline}</p>
                        </div>
                      </Link>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <Link href="/#tarifs" className="text-gray-300 hover:text-white transition">
              Tarifs
            </Link>
          </nav>

          {/* CTAs */}
          <div className="flex items-center gap-4">
            <Link
              href="/dashboard"
              className="text-sm text-gray-300 hover:text-white transition"
            >
              Espace client
            </Link>
            <button className="px-4 py-2 bg-gradient-to-r from-violet-600 to-purple-600 rounded-lg text-sm font-semibold hover:from-violet-700 hover:to-purple-700 transition">
              Tester gratuitement
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
```

**Validation** :
- [ ] Dropdown s'ouvre au hover
- [ ] 3 agents affichés avec icon + tagline
- [ ] Navigation fonctionnelle
- [ ] Responsive (mobile hamburger menu)

---

### Tâche 6.2 : Quiz de Qualification

**Composant** : `components/landing/QualificationQuiz.tsx`

```typescript
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/shared/Button';
import { Card } from '@/components/shared/Card';

export function QualificationQuiz() {
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [answers, setAnswers] = useState<Record<number, string>>({});

  const questions = [
    {
      question: 'Quel est votre principal défi ?',
      options: [
        { label: 'Rappeler rapidement mes nouveaux leads', value: 'louis' },
        { label: 'Réactiver mes prospects dormants', value: 'arthur' },
        { label: 'Répondre à tous mes appels entrants', value: 'alexandra' },
      ],
    },
  ];

  const handleAnswer = (value: string) => {
    setAnswers({ ...answers, [step]: value });

    // Si c'est la dernière question, rediriger
    if (step === questions.length - 1) {
      router.push(`/${value}`);
    } else {
      setStep(step + 1);
    }
  };

  return (
    <section className="py-20">
      <div className="container mx-auto px-4">
        <Card variant="gradient" className="max-w-2xl mx-auto p-8">
          <h3 className="text-2xl font-bold mb-6 text-center">
            Quel agent répond le mieux à votre besoin ?
          </h3>

          <div className="space-y-4">
            <p className="text-lg mb-6">{questions[step].question}</p>

            {questions[step].options.map((option) => (
              <button
                key={option.value}
                onClick={() => handleAnswer(option.value)}
                className="w-full p-4 text-left rounded-lg border border-white/20 hover:border-white/40 hover:bg-white/5 transition"
              >
                {option.label}
              </button>
            ))}
          </div>
        </Card>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Quiz affiché sur Home
- [ ] Clic sur option → redirige vers LP
- [ ] Animation smooth

---

### Tâche 6.3 : Section "Découvrez nos autres agents"

**Composant** : `components/landing/OtherAgents.tsx`

```typescript
import { getAgent } from '@/lib/data/agents';
import { Card } from '@/components/shared/Card';
import Link from 'next/link';

interface OtherAgentsProps {
  currentAgent: 'louis' | 'arthur' | 'alexandra';
}

export function OtherAgents({ currentAgent }: OtherAgentsProps) {
  const allAgents = ['louis', 'arthur', 'alexandra'];
  const otherAgents = allAgents.filter(id => id !== currentAgent);

  return (
    <section className="py-20 bg-gradient-to-b from-black to-violet-950/20">
      <div className="container mx-auto px-4">
        <div className="max-w-3xl mx-auto text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Découvrez nos autres agents IA
          </h2>
          <p className="text-gray-400">
            Maximisez votre efficacité avec une équipe complète d'agents IA
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {otherAgents.map((agentId) => {
            const agent = getAgent(agentId);
            if (!agent) return null;

            return (
              <Link key={agent.id} href={`/${agent.id}`}>
                <Card variant="hover" className="p-6 h-full">
                  <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium mb-4 bg-gradient-to-r ${agent.color.gradient} bg-opacity-10`}>
                    <span>{agent.icon}</span>
                    <span>{agent.badge}</span>
                  </div>

                  <h3 className="text-xl font-bold mb-3">{agent.displayName}</h3>
                  <p className="text-gray-400 mb-4">{agent.description}</p>

                  <span className="text-sm text-violet-400 hover:underline">
                    En savoir plus →
                  </span>
                </Card>
              </Link>
            );
          })}
        </div>

        {/* CTA Bundle */}
        <div className="text-center mt-12">
          <p className="text-lg text-gray-300 mb-4">
            Combinez les 3 agents et économisez 10%
          </p>
          <Button variant="primary" size="lg">
            Découvrir le Pack Complet
          </Button>
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Section affichée en bas de chaque LP
- [ ] 2 agents alternatifs affichés
- [ ] Liens fonctionnels
- [ ] CTA bundle visible

---

### Tâche 6.4 : Bundles Tarifaires

**Composant** : `components/landing/BundlePricing.tsx`

```typescript
import { Card } from '@/components/shared/Card';
import { Button } from '@/components/shared/Button';

export function BundlePricing() {
  const bundle = {
    name: 'Pack Complet',
    agents: ['Louis', 'Arthur', 'Alexandra'],
    normalPrice: 970,
    bundlePrice: 890,
    savings: 80,
    savingsPercent: 8,
  };

  return (
    <section className="py-20">
      <div className="container mx-auto px-4">
        <div className="max-w-2xl mx-auto">
          <Card variant="gradient" className="p-8 text-center bg-gradient-to-r from-violet-600/20 to-purple-600/20">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-500/20 text-green-400 font-semibold mb-6">
              💰 Économisez {bundle.savingsPercent}%
            </div>

            <h3 className="text-3xl font-bold mb-4">{bundle.name}</h3>
            <p className="text-gray-400 mb-6">
              Les 3 agents IA pour une couverture complète de vos besoins commerciaux
            </p>

            {/* Prix */}
            <div className="mb-6">
              <p className="text-gray-400 line-through text-lg">{bundle.normalPrice}€ HT/mois</p>
              <p className="text-5xl font-bold text-white">{bundle.bundlePrice}€ <span className="text-xl text-gray-400">HT/mois</span></p>
              <p className="text-green-400 font-semibold mt-2">Soit {bundle.savings}€ d'économie par mois</p>
            </div>

            {/* Agents inclus */}
            <div className="space-y-2 mb-8">
              {bundle.agents.map((agent) => (
                <p key={agent} className="flex items-center justify-center gap-2 text-gray-300">
                  <span className="text-green-400">✓</span>
                  <span>{agent}</span>
                </p>
              ))}
            </div>

            <Button variant="primary" size="lg">
              Démarrer avec le Pack Complet
            </Button>
          </Card>
        </div>
      </div>
    </section>
  );
}
```

**Validation** :
- [ ] Card bundle affichée
- [ ] Calcul des économies correct
- [ ] CTA fonctionnel

---

### Tâche 6.5 : Liens Croisés Intelligents

**Dans les composants existants, ajouter des suggestions contextuelles**

Exemples :
- Sur LP Louis, dans la section "Pourquoi Louis" :
  ```
  "💡 Vous avez aussi une base de leads dormants ? Découvrez Arthur →"
  ```

- Sur LP Arthur, dans la section témoignage :
  ```
  "💡 Besoin de traiter vos nouveaux leads ? Rencontrez Louis →"
  ```

- Sur LP Alexandra, dans la FAQ :
  ```
  "💡 Vous générez beaucoup de leads ? Laissez Louis les rappeler automatiquement →"
  ```

**Validation** :
- [ ] 2-3 suggestions par LP
- [ ] Liens cliquables
- [ ] Style cohérent (💡 + texte + →)

---

### Tâche 6.6 : Intégrer tous les composants

**Mettre à jour les pages existantes** :
- `app/(marketing)/louis/page.tsx` : ajouter `<OtherAgents currentAgent="louis" />`
- `app/(marketing)/arthur/page.tsx` : ajouter `<OtherAgents currentAgent="arthur" />`
- `app/(marketing)/alexandra/page.tsx` : ajouter `<OtherAgents currentAgent="alexandra" />`
- `app/(marketing)/page.tsx` : ajouter `<QualificationQuiz />` et `<BundlePricing />`

---

## ✅ Validation de la Phase

### Tests de Navigation
- [ ] Dropdown header fonctionne sur toutes les pages
- [ ] Quiz redirige correctement
- [ ] Section "Autres agents" visible sur toutes les LP
- [ ] Liens croisés cliquables

### Tests de Conversion
- [ ] Bundle pricing visible sur Home
- [ ] CTAs "Pack Complet" trackés
- [ ] Parcours utilisateur fluide

### Tests Visuels (MCP Playwright)
- [ ] Navigate entre toutes les pages
- [ ] Take snapshots de chaque page mise à jour
- [ ] Vérifier : header cohérent, cross-selling visible

---

## 📊 Critères de Succès

1. ✅ Header avec dropdown fonctionnel
2. ✅ Quiz de qualification sur Home
3. ✅ Section "Autres agents" sur toutes les LP
4. ✅ Bundles tarifaires proposés
5. ✅ Liens croisés intelligents intégrés
6. ✅ Navigation fluide entre toutes les pages

---

## 🔗 Dépendances

**Avant cette phase** :
- Phase 1 : Fondations
- Phase 2 : Home
- Phase 3 : Louis
- Phase 4 : Arthur
- Phase 5 : Alexandra

**Après cette phase** :
- Phase 7 : SEO & Analytics (optimisations finales)

---

**Dernière mise à jour** : 2025-10-28
**Statut** : 📋 Prêt pour génération PRP
