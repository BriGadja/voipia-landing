# PHASE 4 : LANDING PAGE ARTHUR

## 🎯 Objectif de la Phase

Créer la landing page dédiée à Arthur (Réactivation de bases dormantes).

**Durée estimée** : 3-4 jours
**Priorité** : 🟠 MOYENNE (après Phase 1)
**Source** : `proposition_restructuration_landing/LP Arthur.txt`

---

## 📋 Structure de la Page Arthur (/arthur)

```
Arthur LP
├── 1. Hero Section - "Rencontrez Arthur"
├── 2. Barre d'intégrations
├── 3. Comment fonctionne Arthur (4 étapes)
├── 4. Cas d'utilisation (6 cartes)
├── 5. Bénéfices mesurables (tableau stats)
├── 6. CTA Intermédiaire
├── 7. Arthur, l'agent qui ne s'essouffle jamais
├── 8. Témoignage Norloc
├── 9. Tarification (490€/mois)
└── 10. FAQ (9 questions) + CTA Final
```

---

## 📦 Micro-tâches Principales

### Tâche 4.1 : Hero Arthur
- Titre : "Rencontrez Arthur."
- Sous-titre : "Votre agent de réactivation IA qui redonne vie à vos prospects oubliés"
- Description : Relance automatique 24/7, approche douce et progressive
- CTA : "Tester gratuitement Arthur" + "Écouter un appel d'Arthur"
- Composant : `components/landing/HeroArthur.tsx`

### Tâche 4.2 : Barre intégrations
- Logos spécifiques Arthur : Pipedrive, HubSpot, Salesforce, Google Sheets, Excel, Base CRM, Google Calendar, Outlook, Make, Zapier
- Composant : Réutiliser `IntegrationBar.tsx` avec props

### Tâche 4.3 : Comment fonctionne Arthur (4 étapes)
1. Détection automatique des opportunités oubliées
2. Relances naturelles et multicanales
3. Priorisation automatique des leads prometteurs
4. Conversion et libération de temps pour vos équipes
- Composant : `components/landing/HowItWorksArthur.tsx`

### Tâche 4.4 : Cas d'utilisation (6 cartes)
1. Réactivation automatique des bases dormantes
2. Approche naturelle et personnalisée
3. Priorisation des leads chauds
4. Vos commerciaux ne gèrent plus les rappels manuels
5. Handover fluide vers votre équipe
6. Reporting simple et transparent
- Composant : `components/landing/UseCasesArthur.tsx`

### Tâche 4.5 : Bénéfices mesurables
Tableau avec :
- Taux de réactivation : +65%
- Leads qualifiés générés : +180%
- CA généré sur base dormante : +40 000€/mois
- Temps gagné : +40h/semaine
- Leads traités par commercial : x3 par semaine
- Composant : Réutiliser `BenefitsTable.tsx`

### Tâche 4.6 : CTA Intermédiaire
- "Découvrez Arthur en action"
- CTA : "Appeler Arthur maintenant" + "Écouter un appel de réactivation"
- Composant : Réutiliser `CTAIntermediate.tsx`

### Tâche 4.7 : Arthur ne s'essouffle jamais (section unique)
3 blocs :
1. Approche douce qui respecte vos prospects
2. Capacité de traiter des milliers de contacts par mois
3. IA qui adapte sa relance selon la réaction du lead
- Composant : `components/landing/ArthurStrength.tsx`

### Tâche 4.8 : Témoignage Norloc
- Citation de Yassine (Fondateur)
- Statistiques : +65% base réactivée, x3 leads traités, 40h gagnées/semaine
- Composant : `components/landing/TestimonialArthur.tsx`

### Tâche 4.9 : Tarification Arthur
- 490€ HT/mois
- Inclusions + consommation
- Exemple de calcul pour 1000 leads dormants/mois : 923€ HT/mois
- ROI : +40 000€ CA généré potentiel
- Composant : `components/landing/PricingArthur.tsx`

### Tâche 4.10 : FAQ Arthur (9 questions)
Questions spécifiques à Arthur :
1. Que fait exactement Arthur ?
2. Qu'est-ce qu'un "lead dormant" ?
3. Arthur peut-il gérer ma base Excel/CRM ?
4. Arthur peut-il s'adapter à notre ton/marque ?
5. Combien de leads Arthur peut-il traiter par mois ?
6. Que se passe-t-il si un lead répond positivement ?
7. Arthur est-il intrusif ou agressif ?
8. Peut-on personnaliser la stratégie de relance ?
9. Quel ROI puis-je espérer avec Arthur ?
- Composant : Réutiliser `FAQAccordion.tsx`

### Tâche 4.11 : CTA Final
- Titre : "Redonnez vie à vos opportunités oubliées dès aujourd'hui"
- CTA : "Tester gratuitement Arthur"
- Composant : `components/landing/CTAFinalArthur.tsx`

### Tâche 4.12 : Assembler la page
**Fichier** : `app/(marketing)/arthur/page.tsx`

---

## ✅ Validation de la Phase

### Tests Visuels (MCP Playwright)
- [ ] Navigate to `http://localhost:3000/arthur`
- [ ] Take browser snapshot
- [ ] Vérifier : 10 sections présentes
- [ ] Vérifier : couleur orange/ambre dominante
- [ ] Vérifier : responsive mobile

### Tests Fonctionnels
- [ ] Audio player fonctionne
- [ ] FAQ accordion s'ouvre/ferme
- [ ] CTAs cliquables
- [ ] Statistiques "+40k€ CA/mois" visible

### Tests de Performance
- [ ] Lighthouse score > 85
- [ ] Pas d'erreur console
- [ ] Build réussi

---

## 📊 Critères de Succès

1. ✅ Page `/arthur` complète avec 10 sections
2. ✅ Design cohérent avec la couleur orange d'Arthur
3. ✅ Tous les contenus du fichier source intégrés
4. ✅ FAQ spécifique (9 questions)
5. ✅ Témoignage Norloc visible
6. ✅ Section unique "Arthur ne s'essouffle jamais"
7. ✅ Responsive parfait

---

## 🔗 Dépendances

**Avant cette phase** :
- Phase 1 : Fondations (composants de base)

**Après cette phase** :
- Phase 6 : Navigation (cross-selling vers Louis/Alexandra)

---

**Dernière mise à jour** : 2025-10-28
**Statut** : 📋 Prêt pour génération PRP
