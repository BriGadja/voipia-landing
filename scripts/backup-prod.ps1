# ========================================
# Supabase Production Backup Script (PowerShell)
# ========================================
# Description: Automated backup script for Voipia Production Database
# Author: Claude Code
# Date: 2025-11-20
# Usage: .\scripts\backup-prod.ps1 [-SchemaOnly] [-DataOnly] [-List] [-Cleanup]

param(
    [switch]$SchemaOnly,
    [switch]$DataOnly,
    [switch]$List,
    [switch]$Cleanup,
    [switch]$Help
)

# Configuration
$BackupDir = "dbDump"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DateOnly = Get-Date -Format "yyyyMMdd"

# Functions
function Write-Header {
    Write-Host ""
    Write-Host "================================" -ForegroundColor Blue
    Write-Host "  Supabase Production Backup" -ForegroundColor Blue
    Write-Host "================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Test-Requirements {
    Write-Info "Vérification des prérequis..."

    # Check if supabase CLI is installed
    try {
        $supabaseVersion = & supabase --version 2>&1
        Write-Success "Supabase CLI trouvé: $supabaseVersion"
    }
    catch {
        Write-Error-Custom "Supabase CLI n'est pas installé"
        Write-Info "Installation: npm install -g supabase"
        exit 1
    }

    # Check if backup directory exists
    if (-not (Test-Path $BackupDir)) {
        Write-Info "Création du dossier de backup: $BackupDir"
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }

    Write-Success "Dossier de backup: $BackupDir\"
}

function New-Backup {
    param(
        [string]$BackupType
    )

    $filename = ""
    $options = ""

    switch ($BackupType) {
        "full" {
            $filename = "backup_prod_$Timestamp.sql"
            $options = ""
            Write-Info "Création d'un backup COMPLET..."
        }
        "schema" {
            $filename = "schema_prod_$Timestamp.sql"
            $options = "--schema-only"
            Write-Info "Création d'un backup SCHÉMA uniquement..."
        }
        "data" {
            $filename = "data_prod_$Timestamp.sql"
            $options = "--data-only"
            Write-Info "Création d'un backup DONNÉES uniquement..."
        }
        default {
            Write-Error-Custom "Type de backup invalide: $BackupType"
            exit 1
        }
    }

    $filepath = Join-Path $BackupDir $filename
    Write-Info "Fichier: $filepath"

    # Execute backup
    try {
        if ($options) {
            $command = "supabase db dump $options -f `"$filepath`""
        } else {
            $command = "supabase db dump -f `"$filepath`""
        }

        Invoke-Expression $command

        Write-Success "Backup créé avec succès"

        # Verify backup
        Test-Backup -FilePath $filepath

        # Display file size
        $filesize = (Get-Item $filepath).Length / 1MB
        Write-Success "Taille du fichier: $([math]::Round($filesize, 2)) MB"

        return $true
    }
    catch {
        Write-Error-Custom "Échec de la création du backup"
        Write-Error-Custom $_.Exception.Message
        return $false
    }
}

function Test-Backup {
    param([string]$FilePath)

    Write-Info "Vérification du backup..."

    # Check if file exists
    if (-not (Test-Path $FilePath)) {
        Write-Error-Custom "Le fichier de backup n'existe pas"
        return $false
    }

    # Check if file is not empty
    $filesize = (Get-Item $FilePath).Length
    if ($filesize -eq 0) {
        Write-Error-Custom "Le fichier de backup est vide"
        return $false
    }

    # Count tables
    $content = Get-Content $FilePath -Raw
    $tableMatches = [regex]::Matches($content, "CREATE TABLE")
    $tableCount = $tableMatches.Count

    if ($tableCount -eq 0) {
        Write-Warning-Custom "Aucune table trouvée dans le backup"
    } else {
        Write-Success "Tables trouvées: $tableCount"
    }

    # Check for errors
    $errorMatches = [regex]::Matches($content, "error|warning", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $errorCount = $errorMatches.Count

    if ($errorCount -gt 0) {
        Write-Warning-Custom "Avertissements/erreurs détectés: $errorCount"
    } else {
        Write-Success "Aucune erreur détectée dans le backup"
    }

    Write-Success "Vérification terminée"
    return $true
}

function Get-BackupList {
    Write-Info "Liste des backups existants:"
    Write-Host ""

    $backups = Get-ChildItem -Path $BackupDir -Filter "*.sql" -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending

    if ($backups) {
        $backups | Format-Table Name,
                                @{Label="Size (MB)"; Expression={[math]::Round($_.Length / 1MB, 2)}},
                                LastWriteTime -AutoSize
        Write-Success "Backups listés ci-dessus"
    } else {
        Write-Warning-Custom "Aucun backup trouvé dans $BackupDir\"
    }
}

function Remove-OldBackups {
    $keepDays = 30
    $cutoffDate = (Get-Date).AddDays(-$keepDays)

    Write-Info "Nettoyage des backups de plus de $keepDays jours..."

    $oldBackups = Get-ChildItem -Path $BackupDir -Filter "*.sql" -ErrorAction SilentlyContinue |
                  Where-Object { $_.LastWriteTime -lt $cutoffDate }

    if ($oldBackups) {
        $deletedCount = 0
        foreach ($backup in $oldBackups) {
            Remove-Item $backup.FullName -Force
            Write-Success "Supprimé: $($backup.Name)"
            $deletedCount++
        }
        Write-Success "Supprimés: $deletedCount fichier(s)"
    } else {
        Write-Info "Aucun backup ancien à supprimer"
    }
}

function Show-Usage {
    Write-Host @"

Usage: .\scripts\backup-prod.ps1 [OPTIONS]

Options:
    -Full           Backup complet (schéma + données) [DEFAULT]
    -SchemaOnly     Backup du schéma uniquement
    -DataOnly       Backup des données uniquement
    -List           Lister les backups existants
    -Cleanup        Nettoyer les backups de plus de 30 jours
    -Help           Afficher cette aide

Examples:
    .\scripts\backup-prod.ps1                # Backup complet
    .\scripts\backup-prod.ps1 -SchemaOnly    # Schéma uniquement
    .\scripts\backup-prod.ps1 -List          # Lister les backups
    .\scripts\backup-prod.ps1 -Cleanup       # Nettoyer les vieux backups

"@
}

# Main Script
function Main {
    Write-Header

    # Handle help
    if ($Help) {
        Show-Usage
        exit 0
    }

    # Handle list
    if ($List) {
        Get-BackupList
        exit 0
    }

    # Handle cleanup
    if ($Cleanup) {
        Remove-OldBackups
        exit 0
    }

    # Determine backup type
    $backupType = "full"
    if ($SchemaOnly) {
        $backupType = "schema"
    } elseif ($DataOnly) {
        $backupType = "data"
    }

    # Check requirements
    Test-Requirements

    # Create backup
    $success = New-Backup -BackupType $backupType

    if ($success) {
        Write-Host ""
        Write-Success "==================================="
        Write-Success "  Backup terminé avec succès ! "
        Write-Success "==================================="
        Write-Host ""

        # Show last 3 backups
        Write-Info "Derniers backups:"
        Get-ChildItem -Path $BackupDir -Filter "*.sql" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 3 |
            Format-Table Name,
                        @{Label="Size (MB)"; Expression={[math]::Round($_.Length / 1MB, 2)}},
                        LastWriteTime -AutoSize

        Write-Host ""
        Write-Info "Pour restaurer ce backup, consultez: docs\DATABASE_BACKUP_GUIDE.md"

        exit 0
    } else {
        Write-Host ""
        Write-Error-Custom "==================================="
        Write-Error-Custom "  Échec de la création du backup"
        Write-Error-Custom "==================================="
        exit 1
    }
}

# Run main function
Main
