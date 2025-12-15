# CLAUDE.md - Refonte Dashboard V2

## Contexte

Cette feature restructure la navigation du dashboard pour passer d'une navigation par type d'agent (Louis/Arthur/Alexandra) a un arbre hierarchique Entreprise > Agent.

## Regles Critiques

### Securite - NE JAMAIS exposer aux utilisateurs

```typescript
// Ces champs sont INTERDITS dans les reponses utilisateur
provider_cost
margin
margin_percentage
stt_cost
tts_cost
llm_cost
telecom_cost
dipler_commission
total_cost // de agent_calls - c'est le provider cost
```

### Securite - OK pour les utilisateurs

```typescript
// Ces champs sont autorises
billed_cost        // Ce que le client paie
cost_per_min       // Config deployment
cost_per_sms       // Config deployment
cost_per_email     // Config deployment
duration_seconds   // Volumes
// Tous les compteurs de volume
```

## Structure des Fichiers

### Types
- `lib/types/navigation.ts` - Types pour hierarchie entreprise/agent
- `lib/types/consumption.ts` - Types pour consommation utilisateur

### Queries
- `lib/queries/hierarchy.ts` - Fetch hierarchie
- `lib/queries/consumption.ts` - Fetch consommation utilisateur

### Hooks
- `lib/hooks/useAgentHierarchy.ts`
- `lib/hooks/useUserConsumption.ts`

### Composants
- `components/dashboard/Sidebar/AgentTree.tsx` - Arbre depliable

### Pages
- `app/dashboard/consumption/` - Dashboard consommation utilisateur

## Fonctions SQL

### get_company_agent_hierarchy()
- Retourne hierarchie entreprise -> agents
- Admin voit tout, utilisateur voit ses entreprises uniquement
- Filtre agents actifs

### get_user_consumption_metrics()
- Metriques consommation sans marge
- Filtre par user_client_permissions

### get_admin_billing_summary()
- Resume facturation avec marges
- Verifie is_admin() en premier

## Patterns a Suivre

### Verification Admin SQL
```sql
IF NOT is_admin() THEN
  RAISE EXCEPTION 'Access denied: Admin permission required'
    USING ERRCODE = 'P0001';
END IF;
```

### Filtrage Utilisateur SQL
```sql
SELECT ARRAY_AGG(DISTINCT client_id)
INTO v_accessible_client_ids
FROM user_client_permissions
WHERE user_id = auth.uid();
```

### Conditional Rendering React
```tsx
// Dans les composants
if (!isAdmin) {
  return <UserConsumptionView />
}
return <AdminFinancialView />
```

## Tests a Effectuer

1. Connexion utilisateur standard -> ne voit que ses entreprises
2. Connexion admin -> voit toutes les entreprises
3. Verification qu'aucune marge n'apparait pour utilisateur
4. Navigation arbre fonctionne correctement
5. Filtres de date fonctionnent
