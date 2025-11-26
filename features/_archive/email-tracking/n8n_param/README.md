# 📦 n8n Parameters - Email Tracking

**Dossier de configuration** pour les workflows n8n d'envoi et tracking d'emails.

---

## 📁 Contenu du Dossier

### 🚀 [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
**Guide express** pour démarrer rapidement (5 min)

**Contenu** :
- ✅ Les 3 nodes essentielles
- ✅ Tableau de mapping copier/coller
- ✅ Liste des `email_type` valides
- ✅ Checklist rapide
- ✅ Template JSON prêt à l'emploi

**À utiliser quand** : Vous connaissez déjà le système et voulez juste les configs

---

### 📚 [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md)
**Guide complet** de l'architecture des workflows (30 min de lecture)

**Contenu** :
- 📊 Architecture workflow (3 nodes)
- 🔧 Configuration détaillée de chaque node
- 📧 33 champs de mapping expliqués
- 🧪 3 exemples de workflows complets
- 💰 Explications pricing dynamique
- 🚨 Pièges courants et solutions

**À utiliser quand** : Vous créez votre premier workflow email ou voulez comprendre en profondeur

---

### 📋 [MAPPING_EXAMPLES.md](MAPPING_EXAMPLES.md)
**Exemples concrets** de mapping pour 5 cas d'usage (45 min de lecture)

**Contenu** :
- 📧 **Exemple 1** : Follow-up après appel (Louis)
- 📧 **Exemple 2** : Cold email prospection (Arthur)
- 📧 **Exemple 3** : Sequence step relance (Arthur)
- 📧 **Exemple 4** : Email gratuit test/internal
- 📧 **Exemple 5** : Email avec pièce jointe

Chaque exemple inclut :
- Contexte
- Données d'entrée (JSON)
- Configuration complète des 3 nodes
- Résultat attendu dans la base

**À utiliser quand** : Vous voulez voir des exemples réels avant d'implémenter

---

### 🔧 [SUPABASE_INSERT_EMAIL_CONFIG.json](SUPABASE_INSERT_EMAIL_CONFIG.json)
**Configuration JSON** de la node Supabase Insert (copier/coller dans n8n)

**Contenu** :
- Node Supabase pré-configurée
- 21 champs mappés
- Expressions n8n prêtes à l'emploi
- Compatible n8n 1.0+

**À utiliser quand** : Vous voulez importer la config directement dans n8n

---

## 🎯 Parcours Recommandé

### Si vous débutez avec les emails Voipia :
1. Lire **WORKFLOW_GUIDE.md** (30 min) → Comprendre l'architecture
2. Consulter **MAPPING_EXAMPLES.md** → Voir un exemple qui correspond à votre cas
3. Utiliser **QUICK_REFERENCE.md** → Copier le template JSON
4. Tester avec **SUPABASE_INSERT_EMAIL_CONFIG.json** → Importer dans n8n

### Si vous avez déjà fait des workflows SMS :
1. Lire **QUICK_REFERENCE.md** (5 min) → Différences SMS vs Email
2. Copier le template JSON
3. Adapter à votre cas d'usage

### Si vous cherchez juste un exemple :
1. Ouvrir **MAPPING_EXAMPLES.md**
2. Chercher le cas d'usage (Ctrl+F : "Follow-up", "Cold email", etc.)
3. Copier le mapping

---

## 📊 Différences Clés SMS vs Email

| Aspect | SMS (agent_sms) | Email (agent_emails) |
|--------|-----------------|----------------------|
| **Provider** | Twilio (externe) | Gmail (interne) |
| **Provider ID** | `provider_message_sid` | `workflow_message_id` + `gmail_thread_id` |
| **Contenu** | 1 champ (`message_content`) | 3 champs (`subject`, `body_text`, `body_html`) |
| **Colonnes auto** | `character_count`, `num_segments` | `word_count`, `html_size_bytes` |
| **Pricing** | 3 colonnes (provider_cost, billed_cost, margin) | **Identique** (3 colonnes) |
| **Delivery tracking** | Webhooks Twilio | Pas encore (future v2.0) |

**Points communs** :
- ✅ Structure financière identique (3 colonnes)
- ✅ Pricing dynamique depuis `agent_deployments`
- ✅ Margin auto-calculée (GENERATED)
- ✅ Workflow n8n similaire (Get Deployment → Send → Insert)

---

## 🔗 Liens Utiles

### Documentation Feature Email Tracking

- **Vue d'ensemble** : `../README.md`
- **Schéma table** : `../documentation/SCHEMA.md`
- **Intégration n8n** : `../documentation/N8N_INTEGRATION.md`
- **Pricing model** : `../documentation/PRICING_MODEL.md`
- **Tests staging** : `../MIGRATION_TESTED.md`

### Documentation Supabase

- **Base staging** : Tests et développement
- **Base production** : Données réelles

---

## ⚡ Quick Start (5 minutes)

### Étape 1 : Copier le Template

Ouvrir **QUICK_REFERENCE.md** → Section "Template Copier/Coller"

### Étape 2 : Créer 3 Nodes dans n8n

1. **Node 1** : Supabase (Get Rows)
   - Table : `agent_deployments`
   - Filter : `id = deploymentId`
   - Select : `id, name, cost_per_email`

2. **Node 2** : Gmail (Send Email)
   - To : `{{ $json.recipient.email }}`
   - Subject : `{{ $json.emailSubject }}`
   - Message : `{{ $json.emailBody }}`

3. **Node 3** : Supabase (Insert Rows)
   - Table : `agent_emails`
   - Fields : *Coller le template JSON*

### Étape 3 : Tester

1. Trigger manuel avec données test
2. Vérifier l'email dans `agent_emails`
3. Vérifier `margin` auto-calculée
4. Vérifier métriques avec `get_email_metrics()`

---

## 🎉 Vous êtes prêt !

Tous les fichiers nécessaires sont dans ce dossier pour configurer vos workflows n8n d'email tracking avec **pricing dynamique**.

**Bon développement !** 🚀

---

**Version** : 1.0
**Date** : 2025-11-14
**Auteur** : Claude
**Compatibilité** : n8n 1.0+, Supabase PostgreSQL 15+
