# 🔮 Roadmap : Tracking Avancé des Emails

## Vue d'ensemble

Ce document décrit le plan d'implémentation du **tracking avancé des emails** (v2.0) pour aller au-delà du simple suivi d'envoi et mesurer l'engagement réel des destinataires.

**Date** : 2025-11-14
**Version actuelle** : 1.0 (Tracking basique : sent/failed)
**Version cible** : 2.0 (Tracking avancé : opens/clicks/bounces/spam)
**Effort estimé** : 3-5 jours de développement

---

## 🎯 Objectifs v2.0

### Métriques Cibles

1. **📬 Taux d'Ouverture (Open Rate)**
   - Mesurer combien de destinataires ouvrent les emails
   - Benchmark : 20-30% pour emails transactionnels, 15-25% pour cold emails

2. **🖱️ Taux de Clic (Click-Through Rate - CTR)**
   - Mesurer combien de destinataires cliquent sur les liens
   - Benchmark : 2-5% du total envoyé, 10-20% des ouvertures

3. **⚠️ Taux de Bounce**
   - Identifier les emails invalides (hard bounce) ou temporairement injoignables (soft bounce)
   - Objectif : < 2% de bounces

4. **🚫 Taux de Spam Report**
   - Détecter les plaintes spam pour ajuster la stratégie
   - Objectif : < 0.1% de spam reports

---

## 🏗️ Architecture v2.0

### Colonnes Déjà Préparées (v1.0)

Ces colonnes existent déjà dans `agent_emails` mais sont NULL en v1.0 :

```sql
-- Tracking metrics (FUTURES - NULL pour l'instant)
opened_at TIMESTAMP WITH TIME ZONE,        -- Première ouverture
first_clicked_at TIMESTAMP WITH TIME ZONE, -- Premier clic sur un lien
bounce_type TEXT CHECK (bounce_type IN ('hard', 'soft', 'none', NULL)),
spam_reported_at TIMESTAMP WITH TIME ZONE  -- Marqué comme spam
```

**✅ Aucune migration nécessaire pour ajouter ces colonnes - elles sont déjà prêtes !**

### Nouvelles Colonnes Nécessaires (v2.0)

```sql
-- Ajouts v2.0
open_count INTEGER DEFAULT 0,              -- Nombre total d'ouvertures (multi-ouvertures)
click_count INTEGER DEFAULT 0,             -- Nombre total de clics
unique_clicks INTEGER DEFAULT 0,           -- Nombre de liens uniques cliqués
last_opened_at TIMESTAMP WITH TIME ZONE,   -- Dernière ouverture (re-ouverture)
links_data JSONB,                          -- Tracking détaillé des clics par lien
```

**Migration v2.0** : `20251114_add_email_advanced_tracking.sql`

---

## 🔧 Technologies & Solutions

### Option 1 : Gmail API + Webhooks (Recommandé pour Gmail)

**Avantages** :
- ✅ Gratuit (inclus dans Google Workspace)
- ✅ Intégration native avec n8n (déjà utilisé)
- ✅ Fiable pour les emails transactionnels

**Limitations** :
- ❌ Pas de tracking natif des ouvertures/clics (besoin de pixel tracking + link tracking custom)
- ❌ Nécessite un serveur pour les webhooks

**Solution** :
- **Pixel Tracking** : Insérer une image 1x1px dans le HTML de l'email
- **Link Tracking** : Remplacer tous les liens par des redirections trackées
- **Webhooks Gmail** : Recevoir notifications de bounces via Gmail API

### Option 2 : SendGrid API (Recommandé pour Volume & Analytics)

**Avantages** :
- ✅ Tracking natif des ouvertures/clics (automatique)
- ✅ Webhooks pour tous les événements (open, click, bounce, spam)
- ✅ Dashboard analytics intégré
- ✅ Gestion automatique des bounces (suppression auto des emails invalides)

**Limitations** :
- ❌ Coût : 19.95$/mois (15000 emails) ou 0.0013$/email au-delà
- ❌ Nécessite une migration de Gmail à SendGrid

**Pricing** :
- Plan **Essentials** : 19.95$/mois → 15000 emails/mois (≈ 0.0013$/email)
- Plan **Pro** : 89.95$/mois → 100000 emails/mois (≈ 0.0009$/email)

### Option 3 : Mailgun API (Alternative SendGrid)

**Avantages** :
- ✅ Tracking natif + webhooks
- ✅ Pricing flexible (pay-as-you-go)
- ✅ Excellente délivrabilité

**Limitations** :
- ❌ Coût : 35$/mois (50000 emails) ou 0.0008$/email

### Option 4 : Postmark API (Spécialisé Transactionnel)

**Avantages** :
- ✅ Tracking natif
- ✅ Excellente délivrabilité (focus transactionnel)
- ✅ Support réactif

**Limitations** :
- ❌ Coût : 15$/mois (10000 emails) ou 0.0015$/email
- ❌ Moins adapté pour le cold email (focus transactionnel)

---

## 📊 Comparatif des Solutions

| Critère | Gmail + Custom | SendGrid | Mailgun | Postmark |
|---------|----------------|----------|---------|----------|
| **Tracking natif** | ❌ (custom) | ✅ | ✅ | ✅ |
| **Webhooks** | ⚠️ (limité) | ✅ | ✅ | ✅ |
| **Coût/mois (15K emails)** | 0€ | 19.95$ | 35$ | 15$ |
| **Délivrabilité** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Cold email** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Analytics dashboard** | ❌ | ✅ | ✅ | ✅ |
| **Intégration n8n** | ✅ (existant) | ✅ | ✅ | ✅ |

**Recommandation** :
- **Court terme (v2.0)** : Gmail + Pixel/Link Tracking custom (0€, proof of concept)
- **Moyen terme (v2.5)** : Migrer vers SendGrid (meilleur ROI pour volume moyen)

---

## 🛠️ Implémentation v2.0 - Pixel & Link Tracking

### Étape 1 : Pixel Tracking (Ouvertures)

#### 1.1 Générer un Token Unique par Email

```javascript
// Node n8n : Generate Tracking Token
const crypto = require('crypto');

const emailId = '{{ $("Insert Email").item.json.id }}'; // UUID de l'email dans agent_emails
const token = crypto.createHash('sha256').update(emailId).digest('hex');

return { email_id: emailId, tracking_token: token };
```

#### 1.2 Insérer le Pixel dans le HTML

```html
<!-- Dans email_body_html -->
<img src="https://voipia.app/api/track/open?t={{ tracking_token }}"
     width="1" height="1" style="display:none;" alt="" />
```

#### 1.3 Endpoint API `/api/track/open`

**Route** : `app/api/track/open/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(req: NextRequest) {
  const token = req.nextUrl.searchParams.get('t');

  if (!token) {
    return new NextResponse(null, { status: 400 });
  }

  // 1. Hash le token pour retrouver l'email_id (si besoin de mapping DB)
  // 2. Ou utiliser directement le token = email_id (plus simple)

  const supabase = createClient();

  // Update agent_emails : SET opened_at = NOW(), open_count = open_count + 1
  await supabase
    .from('agent_emails')
    .update({
      opened_at: new Date().toISOString(),
      open_count: supabase.rpc('increment', { column: 'open_count' })
    })
    .eq('id', token)
    .is('opened_at', null); // Seulement si jamais ouvert (première ouverture)

  // Si déjà ouvert, incrémenter seulement open_count + last_opened_at
  await supabase
    .from('agent_emails')
    .update({
      last_opened_at: new Date().toISOString(),
      open_count: supabase.rpc('increment', { column: 'open_count' })
    })
    .eq('id', token)
    .not('opened_at', 'is', null);

  // Retourner un pixel transparent 1x1px (GIF)
  const pixel = Buffer.from(
    'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    'base64'
  );

  return new NextResponse(pixel, {
    status: 200,
    headers: {
      'Content-Type': 'image/gif',
      'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0'
    }
  });
}
```

### Étape 2 : Link Tracking (Clics)

#### 2.1 Remplacer les Liens dans l'Email

```javascript
// Node n8n : Wrap Links with Tracking
const emailHtml = $('Prepare Email').item.json.body_html;
const emailId = $("Insert Email").item.json.id;

const trackedHtml = emailHtml.replace(
  /<a\s+href="([^"]+)"/gi,
  (match, url) => {
    const encodedUrl = encodeURIComponent(url);
    return `<a href="https://voipia.app/api/track/click?t=${emailId}&u=${encodedUrl}"`;
  }
);

return { body_html_tracked: trackedHtml };
```

#### 2.2 Endpoint API `/api/track/click`

**Route** : `app/api/track/click/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(req: NextRequest) {
  const token = req.nextUrl.searchParams.get('t'); // email_id
  const url = req.nextUrl.searchParams.get('u');   // target URL

  if (!token || !url) {
    return new NextResponse('Missing parameters', { status: 400 });
  }

  const supabase = createClient();

  // Update agent_emails : SET first_clicked_at = NOW(), click_count++
  await supabase
    .from('agent_emails')
    .update({
      first_clicked_at: new Date().toISOString(),
      click_count: 1
    })
    .eq('id', token)
    .is('first_clicked_at', null); // Première fois

  // Si déjà cliqué, incrémenter seulement click_count
  await supabase
    .from('agent_emails')
    .update({
      click_count: supabase.rpc('increment', { column: 'click_count' })
    })
    .eq('id', token)
    .not('first_clicked_at', 'is', null);

  // Log dans links_data (JSONB) pour tracking détaillé
  const linkData = {
    url: decodeURIComponent(url),
    clicked_at: new Date().toISOString()
  };

  await supabase
    .from('agent_emails')
    .update({
      links_data: supabase.rpc('jsonb_append', {
        column: 'links_data',
        value: linkData
      })
    })
    .eq('id', token);

  // Rediriger vers l'URL cible
  return NextResponse.redirect(decodeURIComponent(url), 302);
}
```

### Étape 3 : Bounce Detection (Gmail API Webhooks)

#### 3.1 Activer Gmail API Pub/Sub

**Documentation** : https://developers.google.com/gmail/api/guides/push

**Steps** :
1. Créer un topic Pub/Sub dans Google Cloud Console
2. Configurer Gmail API pour publier les événements (bounces)
3. Créer un endpoint webhook `/api/webhooks/gmail` pour recevoir les notifications
4. Parser les événements bounce et mettre à jour `agent_emails`

#### 3.2 Endpoint Webhook `/api/webhooks/gmail`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(req: NextRequest) {
  const payload = await req.json();

  // Parser le message Pub/Sub
  const message = JSON.parse(
    Buffer.from(payload.message.data, 'base64').toString()
  );

  // Si bounce détecté
  if (message.labelIds.includes('BOUNCE')) {
    const emailId = message.historyId; // Mapper avec workflow_message_id

    const supabase = createClient();

    await supabase
      .from('agent_emails')
      .update({
        bounce_type: message.bounceType === 'permanent' ? 'hard' : 'soft',
        status: 'failed',
        failed_at: new Date().toISOString(),
        failure_reason: message.bounceReason
      })
      .eq('workflow_message_id', emailId);
  }

  return NextResponse.json({ success: true });
}
```

---

## 📈 Nouvelles Métriques Analytics (v2.0)

### Fonction RPC `get_email_metrics()` - Mise à Jour

**Ajouts v2.0** :
```json
{
  "current_period": {
    // ... métriques v1.0 existantes ...

    // 🆕 Nouvelles métriques v2.0
    "opened_emails": 1234,
    "open_rate": 23.45,                // (opened_emails / sent_emails) * 100
    "clicked_emails": 456,
    "click_rate": 8.67,                // (clicked_emails / sent_emails) * 100
    "click_to_open_rate": 36.98,       // (clicked_emails / opened_emails) * 100
    "bounced_emails": 23,
    "bounce_rate": 0.44,               // (bounced_emails / sent_emails) * 100
    "hard_bounces": 15,
    "soft_bounces": 8,
    "spam_reports": 2,
    "spam_rate": 0.04,                 // (spam_reports / sent_emails) * 100
    "avg_opens_per_email": 1.8,        // AVG(open_count)
    "avg_clicks_per_email": 0.3        // AVG(click_count)
  },
  "previous_period": {...},
  "comparison": {...}
}
```

### Nouveaux Charts Dashboard

1. **📊 Engagement Funnel**
   ```
   Sent → Delivered → Opened → Clicked
   5000 → 4977     → 1169   → 434
   100%   99.54%     23.45%   8.67%
   ```

2. **📈 Open Rate by Email Type**
   ```
   follow_up              : 28.5%
   appointment_confirmation : 35.2%
   cold_email             : 18.3%
   sequence_step          : 22.1%
   ```

3. **🖱️ Click Heatmap by Link**
   ```
   JSON links_data analysis:
   - "Voir le devis" : 234 clicks
   - "Confirmer RDV" : 189 clicks
   - "En savoir plus" : 67 clicks
   ```

---

## ✅ Plan de Migration v2.0

### Phase 1 : Préparation (1 jour)
- [ ] Créer migration `20251114_add_email_advanced_tracking.sql`
- [ ] Ajouter colonnes `open_count`, `click_count`, `unique_clicks`, `last_opened_at`, `links_data`
- [ ] Créer routes API `/api/track/open` et `/api/track/click`
- [ ] Tester en local avec emails de test

### Phase 2 : Pixel & Link Tracking (2 jours)
- [ ] Modifier workflows n8n pour insérer pixel tracking
- [ ] Modifier workflows n8n pour wrapper les liens
- [ ] Déployer routes API en production
- [ ] Tester avec 50-100 emails réels (staging)
- [ ] Valider que `opened_at` et `first_clicked_at` se mettent à jour

### Phase 3 : Bounce Detection (1 jour)
- [ ] Configurer Gmail API Pub/Sub
- [ ] Créer endpoint webhook `/api/webhooks/gmail`
- [ ] Tester avec emails invalides (bounce test)
- [ ] Valider que `bounce_type` se met à jour

### Phase 4 : Analytics & Dashboard (1 jour)
- [ ] Mettre à jour RPC function `get_email_metrics()`
- [ ] Créer charts dashboard (open rate, click rate, funnel)
- [ ] Tester avec données réelles
- [ ] Documenter dans `IMPLEMENTATION_SUMMARY.md`

---

## 🚀 Alternatives Futures (v3.0)

### Migration vers SendGrid (Recommandé Long Terme)

**Avantages** :
- ✅ Tracking automatique (aucun code custom)
- ✅ Webhooks natifs (open, click, bounce, spam)
- ✅ Meilleure délivrabilité
- ✅ Analytics dashboard intégré

**Effort** : 2-3 jours de migration
**Coût** : 19.95$/mois (15000 emails)

**ROI** :
- Si volume > 10000 emails/mois → SendGrid devient rentable (économie de temps dev)
- Si cold email important → SendGrid améliore la délivrabilité (moins de spam)

---

## 📚 Ressources

- **Gmail API Push** : https://developers.google.com/gmail/api/guides/push
- **SendGrid API** : https://docs.sendgrid.com/api-reference
- **Mailgun API** : https://documentation.mailgun.com/en/latest/
- **Postmark API** : https://postmarkapp.com/developer
- **Email Tracking Best Practices** : https://www.litmus.com/blog/the-ultimate-guide-to-email-tracking

---

## 📞 Support

En cas de questions sur la v2.0 :
1. Consulter ce document (`TRACKING_FUTURE.md`)
2. Référencer `SCHEMA.md` pour la structure de la table
3. Tester en staging avant production
4. Documenter les résultats dans `features/email-tracking/notes/`
