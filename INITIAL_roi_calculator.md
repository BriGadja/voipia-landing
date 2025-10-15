# INITIAL.md - ROI & Mensualité Calculator pour Agents Vocaux

## 🎯 Feature Overview

Je souhaite implémenter une **fenêtre de simulation ROI et mensualité** pour la mise en place d'agents vocaux. Cette feature permettra aux prospects et clients de calculer précisément le coût et le retour sur investissement de l'implémentation d'agents vocaux Voipia, en fonction de leurs besoins spécifiques (agents inbound ou outbound).

### Objectif Business
- **Transparence tarifaire** : Permettre aux prospects de comprendre instantanément les coûts
- **Conversion** : Transformer les visiteurs en leads qualifiés via un outil interactif
- **Qualification** : Identifier les cas d'usage et volumes avant le premier contact commercial
- **Education** : Démontrer la flexibilité et l'adaptabilité des solutions Voipia

### Emplacement dans le site
Cette fonctionnalité doit être accessible depuis :
1. Une **section dédiée** sur la landing page (après Metrics, avant DemoSection)
2. Un **bouton CTA** dans la navigation ("Calculer mon ROI")
3. Possibilité d'ouverture en **modal/overlay** OU en **section inline** (à définir selon UX)

---

## 📋 Functional Requirements

### 1. Mode Inbound (Réception d'appels)

#### 1.1 Volume d'appels
**Comportement** : 3 champs synchronisés automatiquement
- **Appels par jour** : Input number (min: 0, max: 10000)
- **Appels par semaine** : Input number (min: 0, max: 70000)
- **Appels par mois** : Input number (min: 0, max: 300000)

**Logique de synchronisation** :
- Si l'utilisateur remplit "appels par jour" → calculer automatiquement semaine (x7) et mois (x30)
- Si l'utilisateur remplit "appels par semaine" → calculer automatiquement jour (/7) et mois (x4.33)
- Si l'utilisateur remplit "appels par mois" → calculer automatiquement jour (/30) et semaine (/4.33)
- Les champs calculés doivent être **arrondis à l'entier** et **clairement distingués visuellement** (par exemple, en lecture seule avec style différent)

#### 1.2 Durée moyenne d'appel
- Input number avec **slider associé** pour meilleure UX
- Valeur par défaut : **3 minutes**
- Min : 0.5 min | Max : 30 min
- Step : 0.5 min
- Affichage : "X minutes" à côté du slider

#### 1.3 Modèle de coût
**Deux options de tarification** (peuvent être combinées) :

**Option A - Coût par traitement** :
- Input number : Prix fixe par appel (€)
- Min : 0€ | Max : 50€
- Step : 0.01€
- Exemple : 0.15€ par appel

**Option B - Coût à la minute** :
- Input number : Prix par minute d'appel (€)
- Min : 0€ | Max : 5€
- Step : 0.01€
- Exemple : 0.08€ par minute

**Calcul du coût total par appel** :
```
Coût par appel = (Coût par traitement) + (Coût à la minute × Durée moyenne)
```

#### 1.4 Coûts additionnels

**Coût d'intégration (one-shot)** :
- Input number : Frais de mise en production (€)
- Min : 0€ | Max : 50000€
- Step : 100€
- Description : "Développement, configuration et mise en production de l'agent"
- Ce coût est **unique** et **amortissable** dans le calcul ROI

**Location mensuelle** :
- Input number : Coût mensuel fixe (€)
- Min : 0€ | Max : 10000€
- Step : 10€
- Description : "Hébergement, maintenance et support de l'agent"

---

### 2. Mode Outbound (Émission d'appels)

#### 2.1 Volume d'appels - Mode Simple
Identique au mode Inbound (3 champs synchronisés)

#### 2.2 Volume d'appels - Mode Planifié (Avancé)

**Toggle** : "Planifier des appels réguliers" (checkbox ou switch)

Lorsque activé, afficher les champs suivants :

**Fréquence d'appel** :
- Input number : "Lancer un appel toutes les X minutes"
- Min : 1 min | Max : 1440 min (24h)
- Step : 1 min
- Exemple : 5 minutes

**Plage horaire quotidienne** :
- Input time : "Heure de début" (format HH:MM)
- Input time : "Heure de fin" (format HH:MM)
- Validation : Heure de fin > Heure de début
- Exemple : 09:00 → 18:00

**Jours de la semaine** :
- Checkbox group : Lundi, Mardi, Mercredi, Jeudi, Vendredi, Samedi, Dimanche
- Par défaut : Lundi à Vendredi cochés
- Permettre la sélection multiple

**Calcul automatique** :
```javascript
// Calcul des minutes actives par jour
minutesActivesParJour = (heuresFin - heuresDebut) * 60

// Nombre d'appels par jour actif
appelsParJourActif = Math.floor(minutesActivesParJour / frequenceMinutes)

// Nombre de jours actifs par semaine
joursActifsParSemaine = nombre de jours cochés

// Calculs finaux
appelsParJour = (appelsParJourActif * joursActifsParSemaine) / 7
appelsParSemaine = appelsParJourActif * joursActifsParSemaine
appelsParMois = appelsParSemaine * 4.33
```

**Affichage des résultats** :
Présenter clairement :
- "Avec cette configuration, vous passerez :"
- **X appels par jour** (moyenne sur 7 jours)
- **X appels par semaine**
- **X appels par mois**

Ces valeurs calculées viennent **remplacer** ou **remplir automatiquement** les champs du mode simple.

#### 2.3 Autres paramètres
Identiques au mode Inbound :
- Durée moyenne d'appel
- Coût par traitement
- Coût à la minute
- Coût d'intégration
- Location mensuelle

---

## 🎨 UI/UX Requirements

### Design System Integration
Le calculateur doit s'intégrer parfaitement avec le design existant du site Voipia :

**Palette de couleurs** :
- Utiliser les couleurs existantes : Primary (#6B46C1), Secondary (#3B82F6)
- Backgrounds : Dark theme avec gradients purple/violet
- Inputs : style cohérent avec le reste du site

**Typographie** :
- Font : Inter (déjà utilisé sur le site)
- Tailles : cohérentes avec le design system existant

**Composants** :
- Réutiliser les composants UI existants dans `components/ui/`
- Créer de nouveaux composants si nécessaire (ex: `components/ui/slider.tsx`)
- Utiliser `cn()` pour les classes conditionnelles

**Animations** :
- Utiliser Framer Motion (déjà présent)
- Transitions fluides lors du changement de mode (Inbound ↔ Outbound)
- Animation lors du calcul des résultats
- Micro-interactions sur les inputs et boutons

### Layout Options

**Option A - Modal/Overlay** :
- Ouverture en modal fullscreen ou large modal
- Fermeture avec bouton X ou clic en dehors
- Scroll interne si contenu trop long
- Avantage : ne perturbe pas la navigation sur la page

**Option B - Section inline** :
- Section dédiée dans le flux de la page
- Scroll automatique vers la section lors de l'ouverture
- Avantage : meilleure visibilité, référencement

**Recommandation** : Commencer par l'option B (section inline) avec possibilité de l'extraire en modal ultérieurement.

### Structure visuelle

```
+------------------------------------------+
|  [Inbound] [Outbound]  <-- Tabs/Toggle  |
+------------------------------------------+
|                                          |
|  📊 Volume d'appels                      |
|  [Par jour] [Par semaine] [Par mois]    |
|                                          |
|  ⏱️ Durée moyenne : 3 min  [====|====]   |
|                                          |
|  💰 Modèle de coût                       |
|  Coût par traitement : [ 0.15 ] €       |
|  Coût à la minute : [ 0.08 ] €          |
|                                          |
|  🔧 Coûts additionnels                   |
|  Intégration (one-shot) : [ 2000 ] €    |
|  Location mensuelle : [ 299 ] €         |
|                                          |
+------------------------------------------+
|  📈 RÉSULTATS                            |
|                                          |
|  Coût par appel : 0.39 €                |
|  Coût mensuel total : 1,499 €           |
|  ROI estimé : +2,500 € / mois           |
|                                          |
|  [Obtenir un devis personnalisé]        |
+------------------------------------------+
```

### Responsive Design
- **Mobile-first** : S'assurer que le calculateur fonctionne parfaitement sur mobile
- **Breakpoints** :
  - Mobile : Inputs empilés verticalement
  - Tablet : 2 colonnes pour certains champs
  - Desktop : Layout optimal avec tous les champs visibles

---

## 📊 Calculation Logic & Results Display

### Calculs à effectuer

#### 1. Coût par appel
```javascript
coutParAppel = coutParTraitement + (coutALaMinute * dureeMoyenne)
```

#### 2. Coût mensuel opérationnel
```javascript
coutMensuelOperationnel = (coutParAppel * appelsParMois) + locationMensuelle
```

#### 3. Coût total première année
```javascript
coutTotalAnnee1 = coutIntegration + (coutMensuelOperationnel * 12)
```

#### 4. Coût total années suivantes
```javascript
coutAnnuelRecurrent = coutMensuelOperationnel * 12
```

#### 5. ROI estimé (optionnel, si on a des données de valeur)
Pour calculer le ROI, il faudrait :
- Soit demander à l'utilisateur la **valeur moyenne d'une conversion**
- Soit utiliser des **benchmarks Voipia** (ex: taux de conversion moyen, valeur client moyenne)

**Proposition** : Ajouter un champ optionnel
- "Valeur moyenne d'une vente/conversion" (€)
- "Taux de conversion estimé" (%)
- Calculer : `ROI = (appelsParMois × tauxConversion × valeurConversion) - coutMensuelOperationnel`

### Affichage des résultats

**Section résultats** (toujours visible, mise à jour en temps réel) :

**Bloc 1 - Coûts unitaires**
- Coût par appel : **X.XX €**
- Coût par minute : **X.XX €**

**Bloc 2 - Coûts mensuels**
- Coût opérationnel : **X,XXX €/mois**
- Location : **XXX €/mois**
- **Total mensuel : X,XXX €/mois**

**Bloc 3 - Coûts première année**
- Intégration (one-shot) : **X,XXX €**
- Opérationnel (12 mois) : **XX,XXX €**
- **Total année 1 : XX,XXX €**

**Bloc 4 - ROI (si calculable)**
- Appels/conversions : **XXX/mois**
- Revenus estimés : **X,XXX €/mois**
- **ROI mensuel : +X,XXX €**

**Graphique** (nice-to-have) :
- Évolution des coûts sur 12-24 mois
- Comparaison avec/sans agent vocal
- Point d'équilibre (break-even point)

### Actions CTA

**Bouton principal** : "Obtenir un devis personnalisé"
- Ouvre un formulaire de contact
- Pré-remplit avec les paramètres du calculateur
- Envoie les données à Voipia

**Bouton secondaire** : "Télécharger le rapport"
- Génère un PDF avec les résultats
- Include les paramètres et les calculs détaillés
- Branding Voipia

---

## 🔗 Examples & References

### Exemples de calculateurs similaires

**Calculateurs SaaS** :
- Calculateur de coût AWS : https://calculator.aws/
- Pricing calculator Twilio : https://www.twilio.com/en-us/voice/pricing
- ROI calculator HubSpot : https://www.hubspot.com/roi-calculator

**Patterns UI** :
- Slider + Input synchronisés
- Tabs/Toggle pour mode Inbound vs Outbound
- Real-time calculation (pas de bouton "Calculer")
- Highlight des résultats importants

### Composants existants à réutiliser

Dans le projet Voipia actuel :
- `components/ui/button.tsx` - Pour les CTAs
- `components/sections/Navigation.tsx` - Pour ajouter le CTA
- Style des cards dans `components/sections/AgentsGrid.tsx`
- Animations Framer Motion de `components/sections/Metrics.tsx`

---

## 📚 Documentation & Resources

### Technologies à utiliser

**Framework & Libraries** (déjà présentes) :
- Next.js 15 avec App Router
- React 19 avec hooks
- TypeScript pour le typage strict
- Tailwind CSS pour le styling
- Framer Motion pour les animations
- Lucide React pour les icônes

**Nouveaux composants potentiels** :
- Slider : `@radix-ui/react-slider` OU composant custom
- Tabs : `@radix-ui/react-tabs` OU composant custom
- Form handling : React Hook Form (optionnel)

**Documentation à consulter** :
- Next.js 15 App Router : https://nextjs.org/docs/app
- Tailwind CSS Forms : https://tailwindcss.com/docs/plugins#forms
- Framer Motion Animations : https://www.framer.com/motion/
- React Hooks : https://react.dev/reference/react/hooks

---

## ⚠️ Important Considerations & Gotchas

### 1. État et synchronisation
**Challenge** : Gérer la synchronisation bidirectionnelle entre les 3 champs de volume (jour/semaine/mois)

**Solution recommandée** :
- Utiliser un **seul state "appelsParMois"** comme source de vérité
- Les autres champs sont des **valeurs dérivées calculées**
- Permettre l'édition de n'importe quel champ mais toujours revenir à la source de vérité
- Utiliser `onChange` avec debounce (300ms) pour éviter les recalculs excessifs

```typescript
const [appelsParMois, setAppelsParMois] = useState(0)
const appelsParJour = Math.round(appelsParMois / 30)
const appelsParSemaine = Math.round(appelsParMois / 4.33)
```

### 2. Mode Planifié - Validation
**Gotchas potentiels** :
- L'utilisateur saisit une heure de fin < heure de début → **Validation en temps réel**
- Fréquence d'appel trop élevée pour la plage horaire → **Message d'avertissement**
- Aucun jour sélectionné → **Désactiver le calcul et afficher un message**

### 3. Arrondis et précision
**Règle** :
- Volumes d'appels : Toujours **arrondir à l'entier** (pas de 0.5 appel)
- Prix : Afficher avec **2 décimales** (0.15 €, pas 0.1 €)
- ROI : Afficher avec **0 décimales** si > 1000€, sinon 2 décimales

### 4. Performance
**Optimisations** :
- Utiliser `useMemo` pour les calculs lourds
- Debouncer les inputs pour éviter les recalculs à chaque frappe
- Éviter les re-renders inutiles avec `React.memo` sur les composants de résultats

### 5. Accessibilité
**Requis** :
- Labels explicites sur tous les inputs
- `aria-label` sur les sliders
- Focus states visibles
- Navigation au clavier complète
- Messages d'erreur accessibles via `aria-live`

### 6. Validation des données
**Règles de validation** :
- Volumes : Ne pas accepter de valeurs négatives
- Coûts : Ne pas accepter de valeurs négatives
- Durée : Min 0.5 min, Max 30 min
- Plage horaire : Cohérence début < fin
- Si un champ est vide → considérer comme 0 dans les calculs

### 7. Sauvegarde de la configuration
**Nice-to-have** :
- Sauvegarder la configuration dans `localStorage`
- Permettre de partager un lien avec les paramètres pré-remplis (query params)
- Export des résultats en PDF ou JSON

### 8. Responsive
**Points d'attention** :
- Sur mobile, le slider doit être facile à manipuler (zone de touch suffisante)
- Les inputs numériques doivent afficher le clavier numérique sur mobile
- Le toggle Inbound/Outbound doit être visible et accessible
- Les résultats doivent rester visibles même si l'utilisateur scroll

### 9. Intégration avec n8n (pour le futur)
**Préparer** :
- Structure des données exportées en JSON propre
- Endpoint API pour recevoir les soumissions du formulaire
- Webhook n8n pour capturer les leads qualifiés
- Tracking des interactions (Google Analytics events)

---

## ✅ Success Criteria

### Fonctionnalité
- [ ] Mode Inbound fonctionnel avec tous les champs
- [ ] Mode Outbound avec mode simple et mode planifié
- [ ] Synchronisation automatique des champs de volume
- [ ] Calculs en temps réel sans latence perceptible
- [ ] Validation de toutes les entrées utilisateur
- [ ] Affichage clair et compréhensible des résultats

### UX/UI
- [ ] Design cohérent avec le reste du site Voipia
- [ ] Animations fluides (60fps minimum)
- [ ] Responsive parfait (mobile → desktop)
- [ ] Accessibilité WCAG 2.1 niveau AA minimum
- [ ] Feedback visuel sur toutes les interactions

### Technique
- [ ] Code TypeScript sans erreurs
- [ ] Tests unitaires des fonctions de calcul
- [ ] Performance optimale (First Input Delay < 100ms)
- [ ] Pas de bugs sur les navigateurs majeurs (Chrome, Firefox, Safari, Edge)
- [ ] Code propre et maintenable (commentaires si nécessaire)

### Business
- [ ] Tracking des interactions (événements Analytics)
- [ ] CTA "Obtenir un devis" fonctionnel
- [ ] Export/partage des résultats possible
- [ ] Formulaire de contact pré-rempli avec les paramètres

---

## 🎯 Next Steps (for Claude Code)

### Phase 1 - Setup & Structure
1. Créer la structure de composants :
   - `components/sections/ROICalculator.tsx` - Composant principal
   - `components/ui/slider.tsx` - Composant slider réutilisable
   - `lib/calculatorUtils.ts` - Fonctions de calcul
   - `types/calculator.ts` - Types TypeScript
2. Intégrer le calculateur dans `app/page.tsx`
3. Ajouter le CTA dans `components/sections/Navigation.tsx`

### Phase 2 - Mode Inbound
1. Implémenter les champs de volume avec synchronisation
2. Ajouter le slider de durée moyenne
3. Implémenter les champs de coût
4. Créer la logique de calcul
5. Afficher les résultats

### Phase 3 - Mode Outbound
1. Ajouter le toggle Inbound/Outbound
2. Implémenter le mode planifié avec tous les champs
3. Créer la logique de calcul avancée
4. Valider les entrées et afficher les messages d'erreur

### Phase 4 - Polish & Integration
1. Animations Framer Motion
2. Responsive design
3. Accessibilité
4. Tests et debugging
5. Documentation finale

---

## 📝 Notes additionnelles

- **Itération** : Cette feature peut évoluer avec des retours utilisateurs. Prévoir une architecture modulaire.
- **Analytics** : Tracker les interactions pour comprendre les cas d'usage les plus fréquents
- **A/B Testing** : Tester différentes formulations, layouts, et CTAs
- **Internationalisation** : Prévoir la possibilité d'ajouter d'autres langues et devises

---

**Version** : 1.0
**Date** : 2025-09-30
**Auteur** : Voipia Team