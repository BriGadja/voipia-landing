# 📊 Dashboard Financier Voipia

> **Suivi en temps réel de la marge Voipia et consommation par client**

## 🎯 Objectifs

Le dashboard financier permet de :
- **Suivre la marge Voipia** en temps réel (revenue - coûts provider)
- **Analyser la rentabilité** par client, agent type, et canal
- **Comparer les périodes** (période actuelle vs période précédente)
- **Identifier les tendances** et optimiser les coûts

## 📋 Fonctionnalités

### KPIs Principaux
1. **Marge Totale** (€) - Profit net après coûts provider
2. **Marge %** - Pourcentage de marge sur le revenue
3. **Revenue / Client** - Revenue moyen par client
4. **Marge / Client** - Marge moyenne par client
5. **Revenue Total** - Revenue total toutes sources confondues
6. **Coûts Provider** - Coûts totaux des fournisseurs (VAPI, SMS, Email)

### Sources de Données
- **Appels** : `agent_calls` (coûts VAPI via `total_cost`)
- **SMS** : `agent_sms` (coûts et revenue via `billed_cost` et `provider_cost`)
- **Emails** : `agent_emails` (coûts et revenue via `billed_cost` et `provider_cost`)
- **Leasing** : `agent_deployments` (abonnement mensuel pro-raté par jour)

### Breakdown Multi-Niveau
- **Par Client** : Performance financière de chaque entreprise
- **Par Agent Type** : Louis vs Arthur vs Alexandra
- **Par Déploiement** : Détail par instance d'agent
- **Par Canal** : Calls vs SMS vs Email vs Leasing

## 🗂️ Structure du Projet

```
features/financialDashboard/
├── README.md                           # Ce fichier
├── ARCHITECTURE.md                     # Documentation technique
├── FORMULAS.md                         # Formules de calcul
├── sql/
│   ├── v_financial_metrics_enriched.sql    # Vue principale
│   ├── get_financial_kpi_metrics.sql       # Fonction KPI
│   └── get_financial_drilldown.sql         # Fonction drilldown

lib/
├── types/financial.ts                  # Types TypeScript
├── queries/financial.ts                # Query functions
└── hooks/useFinancialData.ts           # React hooks

components/dashboard/Financial/
├── FinancialKPIGrid.tsx               # Grille KPI
└── ClientBreakdownTable.tsx           # Table breakdown clients

app/dashboard/financial/
├── page.tsx                            # Page Next.js
└── FinancialDashboardClient.tsx       # Composant client

supabase/migrations/
└── 20251116_create_financial_dashboard.sql  # Migration production
```

## 🚀 Installation & Déploiement

### 1. Appliquer la Migration en Production

**⚠️ IMPORTANT**: Vérifier d'abord en staging !

```sql
-- Exécuter dans Supabase Dashboard > SQL Editor
-- Fichier: supabase/migrations/20251116_create_financial_dashboard.sql
```

### 2. Vérifier la Migration

```sql
-- Test 1: Vérifier la vue
SELECT * FROM v_financial_metrics_enriched
ORDER BY metric_date DESC
LIMIT 5;

-- Test 2: Tester la fonction KPI (30 derniers jours)
SELECT get_financial_kpi_metrics(
  (CURRENT_DATE - 30)::date,
  CURRENT_DATE::date,
  NULL::uuid,
  NULL::text,
  NULL::uuid
);

-- Test 3: Vérifier les permissions
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'v_financial_metrics_enriched';
```

### 3. Accéder au Dashboard

```
URL: https://votre-domaine.com/dashboard/financial
```

## 📊 Utilisation

### Filtres Disponibles
- **Date Range** : Période d'analyse (date début + date fin)
- **Client** (à venir) : Filtrer par client spécifique
- **Agent Type** (à venir) : Filtrer par type d'agent

### Navigation
1. Sélectionner la période d'analyse
2. Consulter les KPIs principaux
3. Analyser le breakdown par client
4. Identifier les clients les plus/moins rentables

### Interprétation des Métriques

#### Marge %
- **> 95%** : Excellent (vert)
- **90-95%** : Bon (ambre)
- **< 90%** : À surveiller (rouge)

#### Revenue par Client
- Indicateur de la valeur moyenne d'un client
- Utile pour identifier les "gros clients"

#### Comparaison de Période
- **Vert** : Amélioration vs période précédente
- **Rouge** : Baisse vs période précédente

## 🔧 Formules de Calcul

### Revenue Total
```
Revenue = Call Revenue + SMS Revenue + Email Revenue + Leasing Revenue
```

### Call Revenue
```
Call Revenue = SUM(duration_seconds / 60 × cost_per_min)
```

### SMS/Email Revenue
```
SMS/Email Revenue = SUM(billed_cost)
```

### Leasing Revenue (Pro-rated)
```
Leasing Revenue Daily = (deployment.leasing / 30) × jours_dans_période
```

### Marge
```
Marge (€) = Revenue Total - Coûts Provider Total
Marge (%) = (Marge € / Revenue Total) × 100
```

### Moyennes par Client
```
Revenue/Client = SUM(revenue) / COUNT(DISTINCT client_id)
Marge/Client = SUM(marge) / COUNT(DISTINCT client_id)
```

## 🔐 Sécurité & RLS

- **RLS (Row Level Security)** : Activé via colonne `user_has_access` dans la vue
- **Permissions** : Seuls les utilisateurs avec accès client peuvent voir les données
- **SECURITY DEFINER** : Fonctions RPC exécutées avec privilèges sécurisés

## 🎨 Design & UI

- **Thème** : Dark mode avec glassmorphism
- **Couleurs KPI** :
  - Emerald : Marge totale
  - Teal : Marge %
  - Blue : Revenue par client
  - Violet : Marge par client
  - Amber : Revenue total
  - Red : Coûts provider
- **Animations** : Framer Motion pour transitions fluides
- **Responsive** : Mobile-first design

## 📈 Évolutions Futures (Phase 2)

### Dashboard Client Simplifié
- Vue limitée sans marge Voipia visible
- Focus sur coûts et consommation uniquement
- RLS strict par client

### Export & Alertes
- Export CSV/PDF des données
- Alertes sur seuils (marge < X%, coûts > Y€)
- Notifications email automatiques

### Graphiques Avancés
- Tendances temporelles (évolution jour/semaine/mois)
- Graphiques de comparaison par canal
- Heatmap de performance par période

### Fonctionnalités Analytiques
- Prévisions de marge
- Détection d'anomalies de coûts
- Recommandations d'optimisation

## 🐛 Troubleshooting

### Erreur: "Column does not exist"
- Vérifier que la migration a été appliquée
- Vérifier les noms de colonnes dans les tables sources

### Données vides
- Vérifier la période sélectionnée
- Vérifier les permissions RLS (user_has_access)
- Vérifier que les tables sources ont des données

### Performance lente
- Ajouter des index sur `metric_date`, `client_id`, `deployment_id`
- Limiter la période d'analyse (max 90 jours recommandé)

## 📞 Support

Pour toute question ou problème :
1. Consulter `ARCHITECTURE.md` pour détails techniques
2. Consulter `FORMULAS.md` pour formules de calcul
3. Vérifier les logs Supabase pour erreurs SQL
4. Contacter l'équipe dev Voipia

---

**Version**: 1.0.0
**Date**: 2025-11-16
**Auteur**: Claude (Financial Dashboard Implementation)
