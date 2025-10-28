# PHASE 5 : LANDING PAGE ALEXANDRA

## 🎯 Objectif de la Phase

Créer la landing page dédiée à Alexandra (Réception d'appels 24/7).

**Durée estimée** : 3-4 jours
**Priorité** : 🟠 MOYENNE (après Phase 1)
**Source** : `proposition_restructuration_landing/LP Alexandra.txt`

---

## 📋 Structure de la Page Alexandra (/alexandra)

```
Alexandra LP
├── 1. Hero Section - "Rencontrez Alexandra"
├── 2. Barre d'intégrations
├── 3. Comment fonctionne Alexandra (4 étapes)
├── 4. Cas d'utilisation (6 cartes)
├── 5. Bénéfices mesurables (tableau stats)
├── 6. CTA Intermédiaire
├── 7. Pourquoi Alexandra (Avant/Après)
├── 8. Témoignage Stefano Design
├── 9. Tarification (290€/mois)
└── 10. FAQ (9 questions) + CTA Final
```

---

## 📦 Micro-tâches Principales

### Tâche 5.1 : Hero Alexandra
- Titre : "Rencontrez Alexandra."
- Sous-titre : "Votre agent de réception IA qui répond, filtre et oriente chaque appel entrant automatiquement."
- Description : Décroche en <3 sonneries, 24/7, plusieurs langues
- CTA : "Tester gratuitement Alexandra" + "Écouter un appel d'Alexandra"
- Composant : `components/landing/HeroAlexandra.tsx`

### Tâche 5.2 : Barre intégrations
- Logos : Pipedrive, HubSpot, Salesforce, Google Calendar, Outlook, Calendly, Make, Zapier, Notion, Slack
- Composant : Réutiliser `IntegrationBar.tsx` avec props

### Tâche 5.3 : Comment fonctionne Alexandra (4 étapes)
1. Réception instantanée de tous les appels entrants
2. Réponse personnalisée grâce à votre base de connaissances
3. Filtrage intelligent et qualification automatique
4. Prise de rendez-vous, transfert et suivi continu
- Composant : `components/landing/HowItWorksAlexandra.tsx`

### Tâche 5.4 : Cas d'utilisation (6 cartes)
1. Réception d'appels 24/7 sans interruption
2. Réponse aux questions grâce à votre base de connaissances
3. Filtrage automatique des appels
4. Prise de rendez-vous automatique
5. Transfert et dispatch des appels
6. Dashboard & reporting transparent
- Composant : `components/landing/UseCasesAlexandra.tsx`

### Tâche 5.5 : Bénéfices mesurables
Tableau avec :
- Taux de réponse : 100%
- Temps de réponse : <3 sonneries
- Appels manqués éliminés : -100%
- Temps gagné : +30h/semaine
- Satisfaction client : +45%
- Composant : Réutiliser `BenefitsTable.tsx`

### Tâche 5.6 : CTA Intermédiaire
- "Découvrez Alexandra en action"
- CTA : "Appeler Alexandra maintenant" + "Écouter un exemple d'appel"
- Composant : Réutiliser `CTAIntermediate.tsx`

### Tâche 5.7 : Pourquoi Alexandra (Comparatif Avant/Après)
Tableau 2 colonnes :
- Sans Alexandra : Appels manqués, équipe interrompue, infos perdues
- Avec Alexandra : 100% appels décrochés, disponibilité 24/7, filtrage intelligent
- Composant : Réutiliser `ComparisonTable.tsx`

### Tâche 5.8 : Témoignage Stefano Design
- Citation de Valentin (Dirigeant)
- Statistiques : 100% taux de réponse, +45% satisfaction, +30h gagnées/semaine
- Composant : `components/landing/TestimonialAlexandra.tsx`

### Tâche 5.9 : Tarification Alexandra
- 290€ HT/mois
- Inclusions + consommation
- Exemple de calcul pour 400 appels/mois : 621€ HT/mois
- Comparaison : Réceptionniste temps plein ~2500€ charges comprises
- Composant : `components/landing/PricingAlexandra.tsx`

### Tâche 5.10 : FAQ Alexandra (9 questions)
Questions spécifiques à Alexandra :
1. Que fait exactement Alexandra ?
2. Comment Alexandra répond-elle aux questions sur mon entreprise ?
3. Alexandra peut-elle vraiment filtrer les appels indésirables ?
4. En combien de temps peut-on déployer Alexandra ?
5. Quels outils sont compatibles ?
6. Alexandra parle-t-elle plusieurs langues ?
7. Peut-on écouter les appels traités ?
8. Que se passe-t-il quand Alexandra ne peut pas répondre ?
9. Alexandra est-elle conforme RGPD ?
- Composant : Réutiliser `FAQAccordion.tsx`

### Tâche 5.11 : CTA Final
- Titre : "Ne manquez plus jamais un appel dès aujourd'hui"
- CTA : "Tester gratuitement Alexandra"
- Composant : `components/landing/CTAFinalAlexandra.tsx`

### Tâche 5.12 : Assembler la page
**Fichier** : `app/(marketing)/alexandra/page.tsx`

---

## ✅ Validation de la Phase

### Tests Visuels (MCP Playwright)
- [ ] Navigate to `http://localhost:3000/alexandra`
- [ ] Take browser snapshot
- [ ] Vérifier : 10 sections présentes
- [ ] Vérifier : couleur verte dominante
- [ ] Vérifier : responsive mobile

### Tests Fonctionnels
- [ ] Audio player fonctionne
- [ ] FAQ accordion s'ouvre/ferme
- [ ] CTAs cliquables
- [ ] Statistiques "100% taux de réponse" visible

### Tests de Performance
- [ ] Lighthouse score > 85
- [ ] Pas d'erreur console
- [ ] Build réussi

---

## 📊 Critères de Succès

1. ✅ Page `/alexandra` complète avec 10 sections
2. ✅ Design cohérent avec la couleur verte d'Alexandra
3. ✅ Tous les contenus du fichier source intégrés
4. ✅ FAQ spécifique (9 questions)
5. ✅ Témoignage Stefano Design visible
6. ✅ Comparaison avec réceptionniste humain
7. ✅ Responsive parfait

---

## 🔗 Dépendances

**Avant cette phase** :
- Phase 1 : Fondations (composants de base)

**Après cette phase** :
- Phase 6 : Navigation (cross-selling vers Louis/Arthur)

---

**Dernière mise à jour** : 2025-10-28
**Statut** : 📋 Prêt pour génération PRP
