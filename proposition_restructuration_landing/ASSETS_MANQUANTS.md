# Assets Manquants - Refonte Landing V3

## 🎵 Fichiers Audio

### Louis Demo (PRIORITÉ HAUTE)
- **Chemin**: `/public/demos/louis-demo.mp3`
- **Durée**: 1:47 (1 minute 47 secondes)
- **Description**: Exemple d'appel de Louis rappelant un lead immobilier
- **Utilisé dans**: Section Hero (components/sections/Hero.tsx:55)
- **Format**: MP3, qualité 128kbps minimum
- **Contenu suggéré**:
  - Introduction professionnelle de Louis
  - Qualification du lead (besoin, budget, timing)
  - Prise de rendez-vous
  - Confirmation des coordonnées

### Arthur Demo (PRIORITÉ MOYENNE)
- **Chemin**: `/public/demos/arthur-demo.mp3`
- **Durée**: ~2:00 (suggéré)
- **Description**: Exemple d'appel d'Arthur relançant un prospect dormant
- **Utilisé dans**: Non utilisé actuellement, mais prévu pour la section Solutions
- **Format**: MP3, qualité 128kbps minimum
- **Contenu suggéré**:
  - Rappel du contexte précédent
  - Proposition de valeur adaptée
  - Gestion des objections
  - Prise de rendez-vous ou demande de callback

---

## 🎥 Fichiers Vidéo

### Workflow CRM Video (PRIORITÉ HAUTE)
- **Chemin**: `/public/videos/workflow-crm.mp4`
- **Durée**: 30-60 secondes
- **Description**: Vidéo explicative montrant le processus complet du lead entrant au RDV posé
- **Utilisé dans**: Section HowItWorks (components/sections/HowItWorks.tsx:60)
- **Format**: MP4, codec H.264, résolution 1920x1080 ou 1280x720
- **Contenu suggéré**:
  1. Lead arrive sur le site (formulaire de contact)
  2. Notification instantanée dans le système
  3. Louis appelle automatiquement en < 30s
  4. Conversation qualificative
  5. RDV posé et synchronisé dans le CRM
  6. SMS de confirmation envoyé
  7. Si NRP: Arthur reprend en relance automatique
- **Style**: Motion design ou screencapture avec animations

---

## 🖼️ Images Clients (PRIORITÉ BASSE)

### Photos Testimonials
**Chemin de base**: `/public/avatars/clients/`

**Actuellement utilisés** (placeholders):
- Thomas Dubois (CEO, Immobilier Plus)
- Sophie Martin (Directrice Commerciale, TechSolutions)
- Marc Lefebvre (Fondateur, Energy Consult)

**Format suggéré**:
- Extension: `.webp` (optimisé) ou `.jpg`
- Dimensions: 80x80px minimum (affichage), 160x160px recommandé (Retina)
- Poids: < 20KB par image
- Style: Photo professionnelle, fond neutre ou flou

**Alternatives** (si pas de vraies photos):
- Utiliser un service comme UI Avatars: `https://ui-avatars.com/api/?name=Thomas+Dubois&size=160&background=667eea&color=fff`
- Générer avec des avatars IA (This Person Does Not Exist, Generated Photos)
- Utiliser des illustrations (Humaaans, Open Peeps)

---

## 🎨 Images d'Illustration (OPTIONNEL)

### Icônes Section Problem
**Chemin actuel**: Emojis utilisés (🕐 💔 ⏱️)
**Alternative**: Créer des icônes custom SVG dans `/public/icons/`
- `clock-urgent.svg` - Pour "Rappel trop tardif"
- `heart-broken.svg` - Pour "Relances oubliées"
- `time-wasted.svg` - Pour "Temps perdu"

### Avatars Agents (OPTIONNEL - Déjà gérés)
Les avatars de Louis, Arthur, et Alexandra sont gérés via CSS (initiales + couleur de fond). Pas besoin de fichiers supplémentaires sauf si vous voulez des vraies photos des agents IA.

---

## 📋 Checklist de Création d'Assets

### Étape 1: Audio (Louis Demo)
- [ ] Enregistrer ou générer la voix de Louis (text-to-speech professionnel)
- [ ] Éditer l'audio (couper silences, ajuster volume)
- [ ] Exporter en MP3 128kbps
- [ ] Renommer en `louis-demo.mp3`
- [ ] Placer dans `/public/demos/`
- [ ] Tester dans le navigateur (section Hero)

### Étape 2: Vidéo (Workflow CRM)
- [ ] Écrire le storyboard (7 scènes de 5-8s chacune)
- [ ] Créer les visuels (motion design ou screencapture)
- [ ] Ajouter les textes/callouts
- [ ] Exporter en MP4 H.264 1080p
- [ ] Optimiser le poids (< 5MB si possible)
- [ ] Renommer en `workflow-crm.mp4`
- [ ] Placer dans `/public/videos/`
- [ ] Tester dans le navigateur (section HowItWorks)

### Étape 3: Photos Clients (Optionnel)
- [ ] Obtenir les photos des clients (avec autorisation) OU
- [ ] Générer des photos IA/avatars professionnels
- [ ] Redimensionner à 160x160px
- [ ] Convertir en WebP (compression optimale)
- [ ] Nommer selon le pattern: `thomas-dubois.webp`, `sophie-martin.webp`, etc.
- [ ] Placer dans `/public/avatars/clients/`
- [ ] Mettre à jour les imports dans Testimonials.tsx

---

## 🛠️ Outils Recommandés

### Pour l'Audio
- **Text-to-Speech**: ElevenLabs, Play.ht, WellSaid Labs (voix réalistes)
- **Édition**: Audacity (gratuit), Adobe Audition
- **Compression**: Handbrake, FFmpeg

### Pour la Vidéo
- **Motion Design**: After Effects, Premiere Pro
- **Screencapture**: Loom, OBS Studio
- **Montage simple**: DaVinci Resolve (gratuit), Kapwing
- **Optimisation**: Handbrake, FFmpeg

### Pour les Images
- **Conversion WebP**: Squoosh.app, ImageMagick
- **Génération Avatars**: UI Avatars, DiceBear Avatars
- **Photos IA**: This Person Does Not Exist, Generated.photos

---

## 📍 Emplacements dans le Code

### Louis Demo Audio
```typescript
// components/sections/Hero.tsx (ligne ~55)
<audio
  controls
  className="w-full"
  src="/demos/louis-demo.mp3"  // ← Asset manquant
>
  Votre navigateur ne supporte pas l'élément audio.
</audio>
```

### Workflow CRM Video
```typescript
// components/sections/HowItWorks.tsx (ligne ~60)
<p className="text-gray-400">
  Vidéo à venir : /public/videos/workflow-crm.mp4  // ← Asset manquant
</p>
```

### Photos Clients
```typescript
// components/sections/Testimonials.tsx (lignes 40-60)
// Actuellement: avatars avec initiales générés en CSS
// Pour utiliser de vraies photos, remplacer par:
<img
  src="/avatars/clients/thomas-dubois.webp"
  alt="Thomas Dubois"
  className="w-full h-full object-cover"
/>
```

---

## ⏱️ Estimation Temps de Production

| Asset | Temps estimé | Priorité |
|-------|--------------|----------|
| Louis Demo Audio | 2-4 heures | 🔴 Haute |
| Workflow CRM Video | 6-12 heures | 🔴 Haute |
| Arthur Demo Audio | 2-4 heures | 🟡 Moyenne |
| Photos Clients (3x) | 1-2 heures | 🟢 Basse |
| **TOTAL** | **11-22 heures** | |

---

## 🎯 Impact sans les Assets

**Sans les assets, le site fonctionne mais**:
- ❌ Pas de démo audio de Louis dans le Hero (perte d'engagement majeure)
- ❌ Pas de vidéo explicative du workflow (perte de clarté)
- ✅ Les avatars textuels des clients fonctionnent (acceptable)
- ✅ Tous les textes, layouts, et interactions sont opérationnels

**Recommandation**: Créer au minimum le **Louis Demo Audio** avant le lancement en production. La vidéo peut suivre dans une V2.

---

**Besoin d'aide pour la création d'assets ?**
- Text-to-Speech: Je peux fournir des scripts optimisés pour Louis et Arthur
- Storyboard vidéo: Je peux détailler scène par scène ce qui doit apparaître
- Specs techniques: Tous les détails sont dans ce document
