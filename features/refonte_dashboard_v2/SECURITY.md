# Checklist Securite - Refonte Dashboard V2

## Donnees Sensibles (Admin Only)

| Champ | Table/Vue | Raison |
|-------|-----------|--------|
| `provider_cost` | agent_calls, agent_sms, agent_emails | Cout fournisseur |
| `margin` | v_financial_metrics_enriched | Marge calculee |
| `margin_percentage` | v_financial_metrics_enriched | % de marge |
| `stt_cost` | agent_calls | Cout Speech-to-Text |
| `tts_cost` | agent_calls | Cout Text-to-Speech |
| `llm_cost` | agent_calls | Cout LLM |
| `telecom_cost` | agent_calls | Cout telecom |
| `dipler_commission` | agent_calls | Commission Dipler |
| `total_cost` | agent_calls | Cout total fournisseur |

## Checklist par Fonction SQL

### get_company_agent_hierarchy()

- [ ] Utilise `SECURITY DEFINER SET search_path = public`
- [ ] Verifie `auth.uid()` pour utilisateur connecte
- [ ] Admin: retourne TOUTES les entreprises
- [ ] Utilisateur: filtre par `user_client_permissions`
- [ ] Ne retourne que les agents `status = 'active'`
- [ ] N'expose pas `client.status` aux non-admins

### get_user_consumption_metrics()

- [ ] Utilise `SECURITY DEFINER SET search_path = public`
- [ ] Filtre par `user_client_permissions + auth.uid()`
- [ ] NE retourne PAS `provider_cost`
- [ ] NE retourne PAS `margin`
- [ ] NE retourne PAS `margin_percentage`
- [ ] Retourne uniquement `billed_cost` (cout client)
- [ ] Calcule consommation depuis `cost_per_min * duration`

### get_admin_billing_summary()

- [ ] Utilise `SECURITY DEFINER SET search_path = public`
- [ ] Verifie `is_admin()` EN PREMIER
- [ ] Raise exception si non-admin
- [ ] Peut retourner toutes les donnees financieres

## Checklist par Composant React

### AgentTree.tsx

- [ ] Utilise `useAgentHierarchy()` hook
- [ ] Affiche uniquement les entreprises accessibles
- [ ] Ne montre aucune donnee financiere

### UserConsumptionDashboardClient.tsx

- [ ] N'affiche PAS de marges
- [ ] N'affiche PAS de couts fournisseur
- [ ] Affiche uniquement: volumes, prix unitaires, cout client
- [ ] Filtre de date par defaut: debut mois -> aujourd'hui

### FinancialDashboardClient.tsx

- [ ] Verifie `isAdmin` avant de rendre le composant
- [ ] Redirige vers consommation si non-admin
- [ ] Peut afficher marges et couts fournisseur

## Checklist par Route

### /dashboard/consumption

- [ ] Accessible a tous les utilisateurs authentifies
- [ ] Donnees filtrees par permissions utilisateur
- [ ] Aucune marge visible

### /dashboard/financial

- [ ] Verifie `isAdmin` dans layout ou page
- [ ] Affiche vue complete avec marges pour admin
- [ ] Alternative: rediriger non-admin vers /consumption

### /dashboard/clients

- [ ] Route admin-only (existant)
- [ ] Verifie `isAdmin` dans layout

## Tests de Securite

### Test 1: Utilisateur Standard
1. Connexion avec compte utilisateur (ex: valentin@...)
2. Verifier sidebar: ne voit que ses 2 entreprises
3. Aller sur /dashboard/consumption
4. Verifier: aucune marge visible
5. Tenter /dashboard/financial -> doit etre redirige ou refuse

### Test 2: Admin
1. Connexion avec compte admin
2. Verifier sidebar: voit TOUTES les entreprises
3. Aller sur /dashboard/financial
4. Verifier: marges visibles
5. Verifier: couts fournisseur visibles

### Test 3: Injection
1. Tester appel direct RPC avec utilisateur standard
2. `get_admin_billing_summary()` doit echouer
3. `get_user_consumption_metrics()` ne doit pas retourner de marge

## Validation Finale

- [ ] Audit code: aucun champ sensible expose aux non-admins
- [ ] Test manuel: parcours utilisateur standard
- [ ] Test manuel: parcours admin
- [ ] Verification logs Supabase: pas d'erreurs RLS
