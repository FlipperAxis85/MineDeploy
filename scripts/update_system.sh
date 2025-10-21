#!/bin/bash

# Configuration
# ==============================================================================

# Chemin du fichier de log. Nécessite des droits root si dans /var/log/ et non lancé par root.
LOG_FILE="/var/log/system_update.log" 
# Fichier standard utilisé par Debian/Ubuntu/Mint pour indiquer un besoin de redémarrage
REBOOT_REQUIRED_FILE="/var/run/reboot-required"

# Variables d'environnement pour cron
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Fonction de Log
# ==============================================================================

# Fonction pour logger un message avec un horodatage
log_message() {
    # Écrit dans le fichier de log (avec sudo pour garantir l'écriture dans /var/log)
    # et affiche le message sur la sortie standard
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"
    echo "$1" # Affiche aussi sur la sortie standard
}

# Fonction de Vérification
# ==============================================================================

# Vérifie l'existence du fichier standard de redémarrage nécessaire
check_reboot_required() {
    if [ -f "$REBOOT_REQUIRED_FILE" ]; then
        return 0  # Redémarrage nécessaire
    else
        return 1  # Pas de redémarrage nécessaire
    fi
}

# Logique Principale
# ==============================================================================

echo "=== Démarrage de la mise à jour du système (Ubuntu/Mint) ==="
log_message "Début de la mise à jour du système"

# 1. Mise à jour de la liste des paquets
log_message "Mise à jour de la liste des paquets..."
# 'sudo apt update' est la commande standard sur Ubuntu/Mint
if sudo apt update; then
    log_message "✓ Liste des paquets mise à jour avec succès"
else
    log_message "✗ Erreur lors de la mise à jour de la liste des paquets"
    exit 1 # Quitte en cas d'échec critique
fi

# 2. Vérifier s'il y a des mises à jour disponibles
# 'apt list --upgradable' liste les paquets, 'wc -l' compte les lignes
# On soustrait 1 car la première ligne est l'en-tête
UPGRADABLE=$(apt list --upgradable 2>/dev/null | wc -l)
if [ "$UPGRADABLE" -le 1 ]; then
    log_message "Aucune mise à jour disponible. Le système est déjà à jour."
    log_message "Mise à jour du système terminée."
    exit 0 
fi

log_message "$(($UPGRADABLE - 1)) paquet(s) à mettre à jour"

# 3. Effectuer la mise à jour
log_message "Installation des mises à jour en mode automatique..."
# 'sudo apt upgrade' pour installer, '-y' pour accepter, '-q' pour silencieux
if sudo apt upgrade -y -q; then
    log_message "✓ Mises à jour installées avec succès"
else
    log_message "✗ Erreur lors de l'installation des mises à jour"
    exit 1 # Quitte en cas d'erreur
fi

# 4. Nettoyer les paquets obsolètes
log_message "Nettoyage des paquets obsolètes..."
# 'sudo apt autoremove' pour supprimer les dépendances inutiles
# 'sudo apt autoclean' pour nettoyer le cache des paquets
if sudo apt autoremove -y && sudo apt autoclean; then
    log_message "✓ Nettoyage terminé"
else
    log_message "⚠ Avertissement : Erreur lors du nettoyage (non critique)"
fi

log_message "Mise à jour du système terminée avec succès"

# 5. Vérifier si un redémarrage est nécessaire
if check_reboot_required; then
    log_message "Un redémarrage serait nécessaire pour finaliser les mises à jour"
else
    log_message "Aucun redémarrage n'est nécessaire après cette mise à jour"
fi

echo "=== Fin de la mise à jour du système ==="