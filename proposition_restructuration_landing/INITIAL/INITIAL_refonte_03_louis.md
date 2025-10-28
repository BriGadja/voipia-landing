# PHASE 3 : LANDING PAGE LOUIS

## 🎯 Objectif de la Phase

Créer la landing page dédiée à Louis (Rappel automatique de leads).

**Durée estimée** : 3-4 jours
**Priorité** : 🟠 MOYENNE (après Phase 1)
**Source** : `proposition_restructuration_landing/LP Louis.txt`

---

## 📋 Structure de la Page Louis (/louis)

```
Louis LP
├── 1. Hero Section - "Rencontrez Louis"
├── 2. Barre d'intégrations
├── 3. Comment fonctionne Louis (4 étapes)
├── 4. Cas d'utilisation (6 cartes)
├── 5. Bénéfices mesurables (tableau stats)
├── 6. CTA Intermédiaire
├── 7. Pourquoi Louis (Avant/Après)
├── 8. Témoignage Stefano Design
├── 9. Tarification (190€/mois)
└── 10. FAQ (9 questions) + CTA Final
```

---

## 📦 Micro-tâches Principales

### Tâche 3.1 : Hero Louis
- Titre : "Rencontrez Louis."
- Sous-titre : "Votre agent IA personnel, qui rappelle, qualifie et planifie chaque nouveau lead automatiquement."
- Description : Rappel <60s, 24/7, 20+ langues
- CTA : "Tester Louis gratuitement" + "Écouter un appel de Louis"
- Composant : `components/landing/HeroLouis.tsx`

### Tâche 3.2 : Barre intégrations
- Logos : Pipedrive, HubSpot, Salesforce, Google Calendar, Outlook, Calendly, Make, Zapier, Meta Ads, Google Ads
- Composant : Réutiliser `IntegrationBar.tsx` avec props

### Tâche 3.3 : Comment fonctionne Louis (4 étapes)
1. Détection instantanée des leads entrants
2. Rappel automatique et conversation intelligente
3. Qualification intelligente et scoring automatique
4. Planification et suivi automatique
- Composant : `components/landing/HowItWorksLouis.tsx`

### Tâche 3.4 : Cas d'utilisation (6 cartes)
1. Qualification des leads entrants 24/7
2. Prise de rendez-vous automatique
3. Scoring avancé des prospects
4. Envoi de SMS automatique
5. Transcription des appels
6. Dashboard & reporting transparent
- Composant : `components/landing/UseCasesLouis.tsx`

### Tâche 3.5 : Bénéfices mesurables
Tableau avec :
- Délai moyen de rappel : < 60 secondes
- Taux de contact : +72%
- Taux de conversion en RDV : x3
- Temps gagné : +21h/semaine
- Réduction du taux de perte : -87%
- Composant : `components/landing/BenefitsTable.tsx`

### Tâche 3.6 : CTA Intermédiaire
- "Découvrez Louis en action"
- CTA : "Appeler Louis maintenant" + "Écouter un exemple d'appel"
- Composant : `components/landing/CTAIntermediate.tsx`

### Tâche 3.7 : Pourquoi Louis (Comparatif Avant/Après)
Tableau 2 colonnes :
- Sans Louis : Leads perdus, temps de réponse lent, commerciaux surchargés
- Avec Louis : Rappel instantané <60s, équipe concentrée sur vente
- Composant : `components/landing/ComparisonTable.tsx`

### Tâche 3.8 : Témoignage Stefano Design
- Citation de Valentin (Dirigeant)
- Statistiques : -87% perte leads, x3 RDV, +21h/semaine
- Composant : `components/landing/TestimonialLouis.tsx`

### Tâche 3.9 : Tarification Louis
- 190€ HT/mois
- Inclusions + consommation
- Exemple de calcul pour 300 leads/mois : 357,60€ HT/mois
- Composant : `components/landing/PricingLouis.tsx`

### Tâche 3.10 : FAQ Louis (9 questions)
Questions spécifiques à Louis :
1. Que fait exactement Louis ?
2. En combien de temps Louis rappelle-t-il un lead ?
3. En combien de temps peut-on déployer Louis ?
4. Quels outils sont compatibles ?
5. Louis parle-t-il plusieurs langues ?
6. Peut-on écouter les appels ?
7. Que se passe-t-il si un prospect ne répond pas ?
8. Louis est-il conforme RGPD ?
9. Que se passe-t-il si un lead pose une question complexe ?
- Composant : Réutiliser `FAQAccordion.tsx` avec data

### Tâche 3.11 : CTA Final
- Titre : "Automatisez votre rappel de leads dès aujourd'hui"
- CTA : "Tester gratuitement Louis"
- Composant : `components/landing/CTAFinalLouis.tsx`

### Tâche 3.12 : Assembler la page
**Fichier** : `app/(marketing)/louis/page.tsx`
```typescript
import { HeroLouis } from '@/components/landing/HeroLouis';
import { IntegrationBar } from '@/components/landing/IntegrationBar';
// ... autres imports

export default function LouisPage() {
  return (
    <>
      <HeroLouis />
      <IntegrationBar agent="louis" />
      <HowItWorksLouis />
      {/* ... autres sections */}
    </>
  );
}
```

---

## ✅ Validation de la Phase

### Tests Visuels (MCP Playwright)
- [ ] Navigate to `http://localhost:3000/louis`
- [ ] Take browser snapshot
- [ ] Vérifier : 10 sections présentes
- [ ] Vérifier : couleur bleue dominante
- [ ] Vérifier : responsive mobile

### Tests Fonctionnels
- [ ] Audio player fonctionne
- [ ] FAQ accordion s'ouvre/ferme
- [ ] CTAs cliquables
- [ ] Statistiques affichées correctement

### Tests de Performance
- [ ] Lighthouse score > 85
- [ ] Pas d'erreur console
- [ ] Build réussi

---

## 📊 Critères de Succès

1. ✅ Page `/louis` complète avec 10 sections
2. ✅ Design cohérent avec la couleur bleue de Louis
3. ✅ Tous les contenus du fichier source intégrés
4. ✅ FAQ spécifique (9 questions)
5. ✅ Témoignage Stefano Design visible
6. ✅ Responsive parfait

---

## 🔗 Dépendances

**Avant cette phase** :
- Phase 1 : Fondations (composants de base)

**Après cette phase** :
- Phase 6 : Navigation (cross-selling vers Arthur/Alexandra)

---

**Dernière mise à jour** : 2025-10-28
**Statut** : 📋 Prêt pour génération PRP
