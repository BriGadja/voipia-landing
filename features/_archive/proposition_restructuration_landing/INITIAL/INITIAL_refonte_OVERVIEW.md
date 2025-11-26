# REFONTE LANDING PAGE VOIPIA - VUE D'ENSEMBLE

## 🎯 Objectif Global

Restructurer la landing page Voipia en une architecture **Home + 3 Landing Pages dédiées** (Louis, Arthur, Alexandra) pour améliorer le ciblage, les conversions et le SEO.

---

## 📊 Architecture Cible

**IMPORTANT** : Pour ne pas impacter la Home actuelle, la nouvelle Home sera développée sur `/landingv2` jusqu'à validation complète.

```
/landingv2           → Nouvelle Home (en développement, remplacera / après validation)
/louis               → Landing Page Louis (Rappel automatique)
/arthur              → Landing Page Arthur (Réactivation)
/alexandra           → Landing Page Alexandra (Réception 24/7)
```

**Plan de migration** :
1. Phases 1-7 : Développer sur `/landingv2` + pages agents
2. Validation complète de la refonte
3. Migration : `/landingv2` → `/` (remplace la home actuelle)
4. Suppression de `/landingv2`

---

## 🗓️ Plan de Refonte en 7 Phases

### Phase 1 : Fondations et Architecture ✅
**Fichier** : `INITIAL_refonte_01_fondations.md`
**Durée estimée** : 2-3 jours
**Objectif** : Créer la structure technique et les composants réutilisables

**Livrables** :
- Structure de routing Next.js
- Composants UI réutilisables
- Système de données centralisé
- Types TypeScript

---

### Phase 2 : Page Home (Restructurée) 🏠
**Fichier** : `INITIAL_refonte_02_home.md`
**Durée estimée** : 3-4 jours
**Objectif** : Créer la nouvelle page d'accueil comme "router" principal

**Livrables** :
- Hero section repensée
- Section "Les 3 Agents" avec badges
- Comparatif SDR vs VoIPIA
- Section tarifs globale
- FAQ générale
- Développements sur-mesure

---

### Phase 3 : Landing Page Louis 🔵
**Fichier** : `INITIAL_refonte_03_louis.md`
**Durée estimée** : 3-4 jours
**Objectif** : Créer la LP dédiée à Louis (Rappel automatique)

**Livrables** :
- Page `/louis` complète
- 10 sections spécialisées
- Intégrations visuelles
- FAQ spécifique (9 questions)
- Audio player démo

---

### Phase 4 : Landing Page Arthur 🟠
**Fichier** : `INITIAL_refonte_04_arthur.md`
**Durée estimée** : 3-4 jours
**Objectif** : Créer la LP dédiée à Arthur (Réactivation)

**Livrables** :
- Page `/arthur` complète
- 10 sections spécialisées
- Témoignage Norloc
- FAQ spécifique (9 questions)
- Audio player démo

---

### Phase 5 : Landing Page Alexandra 🟢
**Fichier** : `INITIAL_refonte_05_alexandra.md`
**Durée estimée** : 3-4 jours
**Objectif** : Créer la LP dédiée à Alexandra (Réception 24/7)

**Livrables** :
- Page `/alexandra` complète
- 10 sections spécialisées
- Base de connaissances
- FAQ spécifique (9 questions)
- Audio player démo

---

### Phase 6 : Navigation et Cross-Selling 🔗
**Fichier** : `INITIAL_refonte_06_navigation.md`
**Durée estimée** : 2-3 jours
**Objectif** : Connecter toutes les pages et optimiser les parcours

**Livrables** :
- Header avec dropdown "Solutions"
- Quiz de qualification sur Home
- Sections "Découvrez nos autres agents"
- Liens croisés intelligents
- Bundles tarifaires

---

### Phase 7 : SEO, Analytics et Optimisations 📈
**Fichier** : `INITIAL_refonte_07_seo_analytics.md`
**Durée estimée** : 2 jours
**Objectif** : Optimiser pour les moteurs de recherche et le tracking

**Livrables** :
- Meta descriptions uniques par page
- Structured data (JSON-LD)
- Sitemap.xml mis à jour
- Google Analytics 4 tracking
- Tests A/B setup
- Performance optimizations

---

## 📦 Dépendances Entre Phases

```
Phase 1 (Fondations)
    ↓
Phase 2 (Home) + Phase 3 (Louis) + Phase 4 (Arthur) + Phase 5 (Alexandra)
    ↓ (parallèles, peuvent être faites simultanément)
Phase 6 (Navigation)
    ↓
Phase 7 (SEO/Analytics)
```

**Important** :
- Phase 1 doit être terminée avant toutes les autres
- Phases 2-5 peuvent être réalisées en parallèle après Phase 1
- Phase 6 nécessite que les pages principales soient créées
- Phase 7 finalise l'ensemble

---

## 🎯 KPIs de Succès

**Conversions** :
- ✅ +30-50% taux de conversion vs landing actuelle
- ✅ -20% coût d'acquisition client

**SEO** :
- ✅ +40% trafic organique sur 3 mois
- ✅ Position #1-3 sur requêtes ciblées

**Technique** :
- ✅ Score Lighthouse > 90 (Performance, SEO, Accessibility)
- ✅ Time to Interactive < 2s
- ✅ 0 erreur console

**Business** :
- ✅ Tracking précis par source/agent
- ✅ ROI publicitaire amélioré de 25%

---

## 🛠️ Protocole PRP

Chaque phase suivra le protocole PRP :

1. **Génération du PRP** : `/generate-prp "description de la phase"`
2. **Review du PRP** : Validation de la structure et du contenu
3. **Exécution du PRP** : `/execute-prp PRPs/phase-X.md`
4. **Validation** : Tests + Browser snapshots
5. **Commit** : Git commit avec message descriptif

---

## 📚 Documentation de Référence

- `proposition_restructuration_landing/Home.txt` - Contenu Home
- `proposition_restructuration_landing/LP Louis.txt` - Contenu Louis
- `proposition_restructuration_landing/LP Arthur.txt` - Contenu Arthur
- `proposition_restructuration_landing/LP Alexandra.txt` - Contenu Alexandra
- `CLAUDE.md` - Instructions projet
- `lib/constants.ts` - Données agents actuelles
- `components/sections/` - Composants existants

---

## ⚠️ Points d'Attention

1. **Cohérence de marque** : Maintenir l'identité visuelle entre toutes les pages
2. **Performance** : Optimiser les images et animations
3. **Mobile-first** : Responsive design sur tous les breakpoints
4. **SEO** : Éviter le duplicate content entre les pages
5. **Maintenance** : Composants réutilisables pour faciliter les mises à jour futures
6. **Accessibilité** : WCAG 2.1 AA compliance

---

## 📁 Conventions de Fichiers et Suivi

### Rangement des Fichiers Générés

**IMPORTANT** : Tous les nouveaux fichiers créés pendant la refonte (PRPs, documentation, notes) doivent être rangés dans :
```
C:\Users\pc\Documents\Projets\voipia-landing\proposition_restructuration_landing\
```

**Structure recommandée** :
```
proposition_restructuration_landing/
├── INITIAL/                  # Fichiers de planification (existants)
├── PRPs/                     # PRPs générés pour chaque phase
│   ├── refonte-phase-1.md
│   ├── refonte-phase-2.md
│   └── ...
├── PROGRESS_REFONTE.md      # Fichier de suivi (créé automatiquement)
├── assets/                   # Screenshots, designs, mockups
└── notes/                    # Notes diverses
```

### Fichier de Suivi des Évolutions

Un fichier **`PROGRESS_REFONTE.md`** sera créé et **mis à jour automatiquement à la fin de chaque PRP exécuté**.

Ce fichier contiendra :
- Date de complétion de chaque phase
- Composants créés
- Tests effectués
- Problèmes rencontrés et solutions
- Liens vers les commits Git
- Captures d'écran de validation

**Format du suivi** :
```markdown
## Phase X : [Nom de la phase]
- **Date de début** : YYYY-MM-DD
- **Date de fin** : YYYY-MM-DD
- **Statut** : ✅ Terminé / 🟡 En cours / ❌ Bloqué
- **Composants créés** : Liste des fichiers
- **Tests réussis** : Build, Playwright, Lighthouse
- **Commit Git** : [hash] Description
- **Screenshots** : Lien vers les captures
- **Notes** : Remarques importantes
```

---

## 🚀 Prochaines Étapes

1. ✅ Lire et valider tous les fichiers INITIAL_refonte_X.md
2. ✅ Mettre à jour CLAUDE.md avec ce plan
3. ✅ Générer le PRP de la Phase 1
4. ✅ Exécuter le PRP de la Phase 1
5. ⏳ Répéter pour les phases suivantes

---

**Dernière mise à jour** : 2025-10-28
**Auteur** : Claude Code
**Statut** : 📝 Planification complète
