## 🔧 Implémentation des Coûts Détaillés par Technologie

**Date**: 2025-01-17
**Statut**: ✅ PRÊT À APPLIQUER
**Objectif**: Ajouter le détail des coûts par technologie (STT, TTS, LLM, Telecom, Commission Dipler)

---

## 📊 Contexte

La table `agent_calls` contient des colonnes détaillées pour chaque composant du coût :
- `stt_cost` : Speech-to-Text (transcription)
- `tts_cost` : Text-to-Speech (synthèse vocale)
- `llm_cost` : Large Language Model (IA conversationnelle)
- `telecom_cost` : Coûts télécom (Twilio, etc.)
- `dipler_commission` : Commission Dipler
- `total_cost` : STT + TTS + LLM + Telecom (sans la commission)

**Actuellement** : La vue `v_financial_metrics_enriched` agrège seulement `total_cost` sans détailler les technologies.

**Problème** : Impossible de voir la répartition des coûts par technologie dans le dashboard.

---

## ✅ Solution Implémentée

### Migration 1 : Enrichir la vue avec colonnes détaillées

**Fichier**: `supabase/migrations/20250117_add_detailed_costs_to_financial_view.sql`

**Modifications** :
1. Drop et recréation de `v_financial_metrics_enriched`
2. Ajout de 5 nouvelles colonnes dans la vue :
   - `call_stt_cost`
   - `call_tts_cost`
   - `call_llm_cost`
   - `call_telecom_cost`
   - `call_dipler_commission`

3. Agrégation des coûts détaillés dans le CTE `call_metrics` :
```sql
SUM(COALESCE(ac.stt_cost, 0)) AS call_stt_cost,
SUM(COALESCE(ac.tts_cost, 0)) AS call_tts_cost,
SUM(COALESCE(ac.llm_cost, 0)) AS call_llm_cost,
SUM(COALESCE(ac.telecom_cost, 0)) AS call_telecom_cost,
SUM(COALESCE(ac.dipler_commission, 0)) AS call_dipler_commission
```

**Impact** : Toutes les requêtes utilisant `v_financial_metrics_enriched` auront accès aux coûts détaillés

---

### Migration 2 : Fonction pour exposer le breakdown

**Fichier**: `supabase/migrations/20250117_create_cost_breakdown_function.sql`

**Fonction créée**: `get_cost_breakdown(p_start_date, p_end_date, p_client_id, p_agent_type_name, p_deployment_id)`

**Retour JSONB** :
```json
{
  "call_costs": {
    "total": 37.24,
    "stt": 0.80,
    "tts": 3.75,
    "llm": 2.09,
    "telecom": 3.78,
    "dipler_commission": 3.20
  },
  "sms_costs": {
    "total": 2.13
  },
  "email_costs": {
    "total": 0.00
  },
  "total_costs": {
    "provider_cost": 39.37,
    "stt": 0.80,
    "tts": 3.75,
    "llm": 2.09,
    "telecom": 3.78,
    "dipler_commission": 3.20,
    "all_channels": 42.57
  },
  "volume": {
    "calls": 649,
    "sms": 33,
    "emails": 2
  }
}
```

**Utilité** : Permet d'afficher un graphique ou une table de répartition des coûts par technologie

---

## 🚀 Application des Migrations

### Étape 1 : Appliquer les 2 migrations en ordre

**Via Supabase Dashboard** :
1. Ouvrir https://supabase.com/dashboard (projet production)
2. SQL Editor → Nouvelle query
3. **Migration 1** : Copier-coller `20250117_add_detailed_costs_to_financial_view.sql` → Run
4. **Migration 2** : Copier-coller `20250117_create_cost_breakdown_function.sql` → Run

**Via CLI** :
```bash
cd C:\Users\pc\Documents\Projets\voipia-landing

# Migration 1 : Vue enrichie
supabase db push --file supabase/migrations/20250117_add_detailed_costs_to_financial_view.sql

# Migration 2 : Fonction de breakdown
supabase db push --file supabase/migrations/20250117_create_cost_breakdown_function.sql
```

**⚠️ IMPORTANT** : Appliquer les migrations dans cet ordre exact (1 puis 2)

---

## ✅ Vérification Post-Migration

### Test 1 : Vérifier que la vue a les nouvelles colonnes

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'v_financial_metrics_enriched'
  AND column_name LIKE '%cost%'
ORDER BY column_name;
```

**Résultat attendu** : Doit inclure les 5 nouvelles colonnes :
- `call_dipler_commission`
- `call_llm_cost`
- `call_provider_cost`
- `call_stt_cost`
- `call_telecom_cost`
- `call_tts_cost`

---

### Test 2 : Tester les données de la vue

```sql
SELECT
  metric_date,
  call_count,
  call_provider_cost,
  call_stt_cost,
  call_tts_cost,
  call_llm_cost,
  call_telecom_cost,
  call_dipler_commission
FROM v_financial_metrics_enriched
WHERE metric_date >= CURRENT_DATE - 30
  AND call_count > 0
ORDER BY metric_date DESC
LIMIT 10;
```

**Résultat attendu** : Voir les coûts détaillés par technologie pour les appels récents

---

### Test 3 : Tester la fonction get_cost_breakdown

```sql
SELECT jsonb_pretty(
  get_cost_breakdown(
    CURRENT_DATE - 30,
    CURRENT_DATE,
    NULL,  -- tous les clients
    NULL,  -- tous les agent types
    NULL   -- tous les déploiements
  )
);
```

**Résultat attendu** : JSONB avec la structure complète des coûts

---

## 📊 Impact sur le Dashboard

### Ce qui fonctionne déjà (sans changement frontend)

- ✅ Les fonctions existantes (`get_financial_timeseries`, `get_client_deployments_breakdown`, etc.) fonctionnent toujours
- ✅ Le dashboard affiche les totaux corrects (pas de breaking change)
- ✅ La vue enrichie est utilisée automatiquement

### Ce qui devient possible (avec ajout frontend)

- 📊 Graphique de répartition des coûts par technologie (Pie chart ou Bar chart)
- 📋 Table détaillée des coûts par technologie
- 💰 KPI "Coût moyen par technologie"
- 🔍 Drill down par technologie (ex: voir tous les appels avec coût LLM élevé)

---

## 🎨 Proposition d'Intégration Frontend (optionnel)

### Option 1 : Ajouter un nouveau graphique "Répartition des Coûts"

**Emplacement** : Section "Coûts Provider" du dashboard

**Composant** : `<CostBreakdownChart />`

**Données** : Appel à `get_cost_breakdown()`

**Affichage** : Donut chart ou Bar chart avec :
- 🗣️ STT (Speech-to-Text)
- 🔊 TTS (Text-to-Speech)
- 🤖 LLM (IA Conversationnelle)
- 📞 Telecom (Twilio/SIP)
- 💼 Commission Dipler

---

### Option 2 : Ajouter une tooltip sur les coûts

**Comportement** : Hover sur "Coûts Provider" → Affiche le détail par technologie

**Exemple** :
```
Coûts Provider: 42,57 €
├─ STT:        0,80 € (1.9%)
├─ TTS:        3,75 € (8.8%)
├─ LLM:        2,09 € (4.9%)
├─ Telecom:    3,78 € (8.9%)
└─ Commission: 3,20 € (7.5%)
```

---

## 📝 Statistiques Actuelles (30 derniers jours)

D'après les données de production :
- **649 appels** au total
- **70 appels** avec coûts détaillés (10.8%)
- **Répartition des coûts détaillés** :
  - STT : 0,80 € (5.9%)
  - TTS : 3,75 € (27.5%)
  - LLM : 2,09 € (15.3%)
  - Telecom : 3,78 € (27.7%)
  - Commission : 3,20 € (23.5%)

**Note** : Seulement 10.8% des appels ont des coûts détaillés. Les autres 579 appels (89.2%) n'ont que `total_cost` renseigné.

---

## ⚠️ Points d'Attention

1. **Coûts partiels** : Tous les appels n'ont pas les colonnes détaillées renseignées
   - Solution : Afficher "N/A" ou "Non détaillé" quand les colonnes sont NULL

2. **Total_cost vs Somme détaillée** :
   - `total_cost` = STT + TTS + LLM + Telecom (sans commission)
   - Commission Dipler est en plus

3. **Rétrocompatibilité** : La vue actuelle continue de fonctionner
   - Pas de breaking change sur le frontend existant

---

## 📋 Checklist d'Application

- [ ] **Migration 1** : Appliquer `20250117_add_detailed_costs_to_financial_view.sql`
- [ ] **Migration 1** : Vérifier que la vue a les 5 nouvelles colonnes
- [ ] **Migration 1** : Tester requête SELECT sur la vue
- [ ] **Migration 2** : Appliquer `20250117_create_cost_breakdown_function.sql`
- [ ] **Migration 2** : Tester la fonction `get_cost_breakdown`
- [ ] **Vérification** : Dashboard existant fonctionne toujours (pas de régression)
- [ ] **Optionnel** : Ajouter composant frontend pour afficher le breakdown

---

## 🎯 Résultat Attendu

Après application des migrations :
- ✅ Vue `v_financial_metrics_enriched` enrichie avec 5 colonnes de coûts détaillés
- ✅ Fonction `get_cost_breakdown` disponible pour requêtes frontend
- ✅ Dashboard existant fonctionne sans changement
- ✅ Base technique prête pour afficher le détail des coûts dans l'UI

---

**Temps estimé** : 10 minutes (application + tests)

**Priorité** : 🟡 **Moyenne** - Amélioration (pas de bug critique)

**Date de création** : 2025-01-17
**Auteur** : Claude (Financial Dashboard Team)
