# 🗄️ SQL Migrations à Appliquer en Production

**Date**: 2025-01-17
**Statut**: ⏳ En attente d'application en production

---

## 📋 Liste des Migrations

Voici la liste complète des migrations SQL à appliquer en production pour activer les fonctionnalités du Dashboard Financier avec drill down à 2 niveaux.

### ✅ Ordre d'Application

**IMPORTANT**: Appliquer les migrations dans cet ordre exact.

---

## 1️⃣ Phase 1 - Time Series (Graphique d'évolution) ✅

**Fichier**: `supabase/migrations/20250117_create_financial_timeseries_function.sql`

**Description**: Fonction pour afficher l'évolution temporelle des métriques financières (Revenue, Coûts, Marge) avec granularité jour/semaine/mois.

**Fonction créée**: `get_financial_timeseries(p_start_date, p_end_date, p_client_id, p_agent_type_name, p_deployment_id, p_granularity)`

**Impact**: Active le graphique "Évolution Financière" dans le dashboard

**Statut**: ⏳ À appliquer en production

---

## 2️⃣ Phase 3 - Drill Down Level 1 (Client → Déploiements) ✅

**Fichier**: `supabase/migrations/20250117_create_client_deployments_breakdown_function.sql`

**Description**: Fonction pour drill down du niveau client vers ses déploiements individuels. Affiche les métriques financières par déploiement.

**Fonction créée**: `get_client_deployments_breakdown(p_client_id, p_start_date, p_end_date)`

**Impact**: Active le modal de drill down niveau 1 (clic sur "Détail" dans la table des clients)

**Retourne**: Array JSONB de déploiements avec:
- Informations du déploiement (nom, agent type, statut)
- Métriques financières (revenue, coûts, marge, marge %)
- Volumes (appels, SMS, emails)
- KPIs (taux de décroché, taux de conversion, RDV)
- Unit economics (coût par appel, coût par RDV)

**Statut**: ⏳ À appliquer en production

---

## 3️⃣ Phase 4 - Drill Down Level 2 (Déploiement → Canaux) ✅

**Fichier**: `supabase/migrations/20250117_create_deployment_channels_breakdown_function.sql`

**Description**: Fonction pour drill down du niveau déploiement vers les canaux de communication (Calls, SMS, Email, Leasing). Affiche les métriques financières par canal.

**Fonction créée**: `get_deployment_channels_breakdown(p_deployment_id, p_start_date, p_end_date)`

**Impact**: Active le modal de drill down niveau 2 (clic sur une ligne de déploiement)

**Retourne**: Array JSONB de canaux avec:
- Identification du canal (nom, label, icon)
- Métriques financières (revenue, coûts, marge, marge %)
- Volumes par canal
- Métriques spécifiques aux calls (décrochés, RDV, durée moyenne, taux de décroché)
- Unit economics (coût par item, revenue par item)

**Canaux retournés**:
1. 📞 **Calls**: Appels VAPI avec marge
2. 💬 **SMS**: SMS avec marge
3. 📧 **Email**: Emails avec marge
4. 💰 **Leasing**: Abonnement mensuel pro-raté

**Statut**: ⏳ À appliquer en production

---

## 🚀 Comment Appliquer les Migrations

### Option 1: Via Supabase Dashboard (Recommandé)

1. Ouvrir Supabase Dashboard: https://supabase.com/dashboard
2. Sélectionner le projet production
3. Aller dans **SQL Editor**
4. Créer une nouvelle query
5. Copier-coller le contenu du fichier de migration
6. Exécuter la query
7. Vérifier le message de succès
8. Répéter pour chaque migration (dans l'ordre)

### Option 2: Via Supabase CLI

```bash
# Naviguer vers le dossier du projet
cd C:\Users\pc\Documents\Projets\voipia-landing

# Appliquer toutes les migrations en attente
supabase db push

# Ou appliquer une migration spécifique
supabase db push --file supabase/migrations/20250117_create_financial_timeseries_function.sql
```

---

## ✅ Vérification Post-Migration

Après avoir appliqué chaque migration, vérifier que la fonction a bien été créée :

### Vérifier Phase 1 (Time Series)
```sql
SELECT proname, proargnames
FROM pg_proc
WHERE proname = 'get_financial_timeseries';

-- Test rapide
SELECT jsonb_pretty(
  get_financial_timeseries(
    CURRENT_DATE - 30,
    CURRENT_DATE,
    NULL,  -- tous les clients
    NULL,  -- tous les agent types
    NULL,  -- tous les déploiements
    'day'  -- granularité jour
  )
);
```

### Vérifier Phase 3 (Client → Deployments)
```sql
SELECT proname, proargnames
FROM pg_proc
WHERE proname = 'get_client_deployments_breakdown';

-- Test avec un client existant (remplacer CLIENT_ID)
SELECT jsonb_pretty(
  get_client_deployments_breakdown(
    'CLIENT_ID_HERE'::uuid,
    CURRENT_DATE - 30,
    CURRENT_DATE
  )
);
```

### Vérifier Phase 4 (Deployment → Channels)
```sql
SELECT proname, proargnames
FROM pg_proc
WHERE proname = 'get_deployment_channels_breakdown';

-- Test avec un déploiement existant (remplacer DEPLOYMENT_ID)
SELECT jsonb_pretty(
  get_deployment_channels_breakdown(
    'DEPLOYMENT_ID_HERE'::uuid,
    CURRENT_DATE - 30,
    CURRENT_DATE
  )
);
```

---

## 🧪 Tests Frontend Après Migration

Une fois les migrations appliquées, tester les fonctionnalités dans l'interface :

### Test 1: Graphique d'évolution (Phase 1)
1. Aller sur `/dashboard/financial`
2. Vérifier que le graphique "Évolution Financière" affiche des données
3. Tester les boutons de filtre (Revenue, Coûts, Marge)
4. Changer la période et vérifier que le graphique se met à jour

### Test 2: Drill Down Level 1 (Phase 3)
1. Dans la table "Breakdown par Client", cliquer sur "Détail" pour un client
2. Vérifier que le modal s'ouvre avec:
   - Breadcrumb: Dashboard Financier > [Nom Client]
   - 4 KPI cards (Revenue, Marge, Appels, RDV)
   - Table des déploiements avec données
3. Tester le tri des colonnes
4. Tester l'export CSV
5. Fermer le modal (X ou backdrop)

### Test 3: Drill Down Level 2 (Phase 4)
1. Ouvrir le modal d'un client (Level 1)
2. Cliquer sur une ligne de déploiement dans la table
3. Vérifier que le second modal s'ouvre avec:
   - Breadcrumb: Dashboard Financier > [Client] > [Déploiement]
   - Badges (agent type, statut)
   - 4 KPI cards du déploiement
   - Table des canaux avec données (📞 💬 📧 💰)
4. Vérifier les icônes des canaux
5. Tester le tri et l'export CSV
6. Fermer les deux modals

---

## 📊 Résumé des Impacts

| Migration | Fonctionnalité Activée | Visibilité Utilisateur | Priorité |
|-----------|----------------------|----------------------|----------|
| Phase 1 - Time Series | Graphique d'évolution temporelle | Toujours visible sur dashboard principal | Moyenne |
| Phase 3 - Client → Deployments | Drill down niveau 1 | Clic "Détail" sur client | **Haute** |
| Phase 4 - Deployment → Channels | Drill down niveau 2 | Clic sur ligne de déploiement | **Haute** |

---

## 🔍 Dépendances

- **Phase 1** : Indépendante
- **Phase 3** : Indépendante
- **Phase 4** : Dépend de Phase 3 (le modal niveau 2 s'ouvre depuis le modal niveau 1)

**Recommandation**: Appliquer les 3 migrations en même temps pour activer toutes les fonctionnalités d'un coup.

---

## 🎯 Checklist d'Application

- [ ] **Phase 1**: Appliquer `20250117_create_financial_timeseries_function.sql`
- [ ] **Phase 1**: Vérifier fonction `get_financial_timeseries` existe
- [ ] **Phase 1**: Tester graphique d'évolution dans l'interface
- [ ] **Phase 3**: Appliquer `20250117_create_client_deployments_breakdown_function.sql`
- [ ] **Phase 3**: Vérifier fonction `get_client_deployments_breakdown` existe
- [ ] **Phase 3**: Tester drill down niveau 1 (client → deployments)
- [ ] **Phase 4**: Appliquer `20250117_create_deployment_channels_breakdown_function.sql`
- [ ] **Phase 4**: Vérifier fonction `get_deployment_channels_breakdown` existe
- [ ] **Phase 4**: Tester drill down niveau 2 (deployment → channels)
- [ ] **Tous**: Vérifier aucune erreur dans la console browser
- [ ] **Tous**: Tester sur différents clients/déploiements
- [ ] **Tous**: Tester export CSV à tous les niveaux

---

## 📝 Notes Importantes

### Performance
- Les 3 fonctions SQL sont optimisées avec:
  - Filtrage RLS (`user_has_access = true`)
  - Indexes sur les colonnes de jointure
  - JSONB_AGG pour agrégation efficace
  - SECURITY DEFINER pour performance

### Sécurité
- Toutes les fonctions respectent Row Level Security (RLS)
- Seules les données accessibles par l'utilisateur authentifié sont retournées
- Pas de risque de fuite de données entre clients

### Maintenance
- Les fonctions sont commentées avec description complète
- Queries de vérification incluses dans chaque migration
- Facile à rollback si nécessaire (DROP FUNCTION)

---

**Prêt pour application** ✅

Toutes les migrations sont testées en staging et prêtes pour la production. Le frontend est déjà déployé et attend simplement ces migrations pour s'activer.
