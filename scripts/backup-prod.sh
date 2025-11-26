#!/bin/bash

# ========================================
# Supabase Production Backup Script
# ========================================
# Description: Automated backup script for Voipia Production Database
# Author: Claude Code
# Date: 2025-11-20
# Usage: ./scripts/backup-prod.sh [--schema-only|--data-only]

set -e  # Exit on error

# ========================================
# Configuration
# ========================================

BACKUP_DIR="dbDump"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_ONLY=$(date +%Y%m%d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ========================================
# Functions
# ========================================

print_header() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Supabase Production Backup${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_requirements() {
    print_info "Vérification des prérequis..."

    # Check if supabase CLI is installed
    if ! command -v supabase &> /dev/null; then
        print_error "Supabase CLI n'est pas installé"
        print_info "Installation: npm install -g supabase"
        exit 1
    fi

    print_success "Supabase CLI trouvé: $(supabase --version)"

    # Check if backup directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        print_info "Création du dossier de backup: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi

    print_success "Dossier de backup: $BACKUP_DIR/"
}

create_backup() {
    local backup_type=$1
    local filename=""
    local options=""

    case "$backup_type" in
        "full")
            filename="backup_prod_${TIMESTAMP}.sql"
            options=""
            print_info "Création d'un backup COMPLET..."
            ;;
        "schema")
            filename="schema_prod_${TIMESTAMP}.sql"
            options="--schema-only"
            print_info "Création d'un backup SCHÉMA uniquement..."
            ;;
        "data")
            filename="data_prod_${TIMESTAMP}.sql"
            options="--data-only"
            print_info "Création d'un backup DONNÉES uniquement..."
            ;;
        *)
            print_error "Type de backup invalide: $backup_type"
            exit 1
            ;;
    esac

    local filepath="$BACKUP_DIR/$filename"

    # Execute backup
    print_info "Fichier: $filepath"

    if supabase db dump $options -f "$filepath"; then
        print_success "Backup créé avec succès"

        # Verify backup
        verify_backup "$filepath"

        # Display file size
        local filesize=$(ls -lh "$filepath" | awk '{print $5}')
        print_success "Taille du fichier: $filesize"

        return 0
    else
        print_error "Échec de la création du backup"
        return 1
    fi
}

verify_backup() {
    local filepath=$1

    print_info "Vérification du backup..."

    # Check if file exists
    if [ ! -f "$filepath" ]; then
        print_error "Le fichier de backup n'existe pas"
        return 1
    fi

    # Check if file is not empty
    if [ ! -s "$filepath" ]; then
        print_error "Le fichier de backup est vide"
        return 1
    fi

    # Count tables (should be 11)
    local table_count=$(grep -c "CREATE TABLE" "$filepath" || true)
    if [ "$table_count" -eq 0 ]; then
        print_warning "Aucune table trouvée dans le backup"
    else
        print_success "Tables trouvées: $table_count"
    fi

    # Check for errors in backup
    local error_count=$(grep -i "error\|warning" "$filepath" | wc -l || true)
    if [ "$error_count" -gt 0 ]; then
        print_warning "Avertissements/erreurs détectés: $error_count"
    else
        print_success "Aucune erreur détectée dans le backup"
    fi

    print_success "Vérification terminée"
}

list_backups() {
    print_info "Liste des backups existants:"
    echo ""

    if ls -lh "$BACKUP_DIR"/*.sql 2>/dev/null | grep -v "^total"; then
        echo ""
        print_success "Backups listés ci-dessus"
    else
        print_warning "Aucun backup trouvé dans $BACKUP_DIR/"
    fi
}

cleanup_old_backups() {
    local keep_days=30

    print_info "Nettoyage des backups de plus de ${keep_days} jours..."

    local deleted=0
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            rm "$file"
            print_success "Supprimé: $(basename "$file")"
            ((deleted++))
        fi
    done < <(find "$BACKUP_DIR" -name "*.sql" -type f -mtime +${keep_days})

    if [ $deleted -eq 0 ]; then
        print_info "Aucun backup ancien à supprimer"
    else
        print_success "Supprimés: $deleted fichier(s)"
    fi
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --full          Backup complet (schéma + données) [DEFAULT]
    --schema-only   Backup du schéma uniquement
    --data-only     Backup des données uniquement
    --list          Lister les backups existants
    --cleanup       Nettoyer les backups de plus de 30 jours
    --help          Afficher cette aide

Examples:
    $0                    # Backup complet
    $0 --schema-only      # Schéma uniquement
    $0 --list             # Lister les backups
    $0 --cleanup          # Nettoyer les vieux backups

EOF
}

# ========================================
# Main Script
# ========================================

main() {
    print_header

    # Parse arguments
    local backup_type="full"

    case "${1:-}" in
        --full)
            backup_type="full"
            ;;
        --schema-only)
            backup_type="schema"
            ;;
        --data-only)
            backup_type="data"
            ;;
        --list)
            list_backups
            exit 0
            ;;
        --cleanup)
            cleanup_old_backups
            exit 0
            ;;
        --help)
            show_usage
            exit 0
            ;;
        "")
            # Default: full backup
            backup_type="full"
            ;;
        *)
            print_error "Option invalide: $1"
            show_usage
            exit 1
            ;;
    esac

    # Check requirements
    check_requirements

    # Create backup
    if create_backup "$backup_type"; then
        echo ""
        print_success "==================================="
        print_success "  Backup terminé avec succès ! "
        print_success "==================================="
        echo ""

        # Show last 3 backups
        print_info "Derniers backups:"
        ls -lht "$BACKUP_DIR"/*.sql 2>/dev/null | head -n 4 | tail -n 3 || true

        echo ""
        print_info "Pour restaurer ce backup, consultez: docs/DATABASE_BACKUP_GUIDE.md"

        exit 0
    else
        echo ""
        print_error "==================================="
        print_error "  Échec de la création du backup"
        print_error "==================================="
        exit 1
    fi
}

# Run main function
main "$@"
