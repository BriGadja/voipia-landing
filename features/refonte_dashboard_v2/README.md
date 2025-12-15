# Refonte Dashboard V2

## Objectif

Restructurer l'interface des dashboards pour :
1. Remplacer la navigation par types d'agents (Louis/Arthur/Alexandra) par un arbre depliable Entreprise > Agent
2. Separer les vues Admin (avec marges) et Utilisateur (consommation uniquement)
3. Ajouter un suivi de facturation du mois precedent pour l'admin

## Nouvelle Structure de Navigation

```
Platform
  - Vue d'ensemble (existant, inchange)

Mes Agents (arbre depliable)
  - [Entreprise A]
    - Nom Agent 1 (ex: "Louis (setter)")
    - Nom Agent 2
  - [Entreprise B]
    - Nom Agent 3

Financier
  - Ma Consommation (utilisateurs)
  - Dashboard Financier (admin uniquement)

Administration (admin uniquement)
  - Clients
```

## Phases d'Implementation

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Migration SQL | En cours |
| 2 | Types TypeScript | En attente |
| 3 | Queries et Hooks | En attente |
| 4 | Composants Sidebar | En attente |
| 5 | Page Consommation | En attente |
| 6 | Dashboard Admin | En attente |
| 7 | Nettoyage | En attente |

## Fichiers Crees

- `features/refonte_dashboard_v2/README.md` - Ce fichier
- `features/refonte_dashboard_v2/CLAUDE.md` - Instructions pour Claude
- `features/refonte_dashboard_v2/SECURITY.md` - Checklist securite
- `features/refonte_dashboard_v2/sql/` - Scripts de migration

## Securite

Voir `SECURITY.md` pour la checklist complete des points de securite.

**Points critiques:**
- Les utilisateurs ne voient JAMAIS les marges
- Chaque fonction SQL verifie les permissions
- Les fonctions admin verifient `is_admin()` en premier
