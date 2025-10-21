#!/bin/bash

# Configuration
# ==============================================================================

# Chemin du fichier de log pour l'extinction du système
# Nécessite des droits root pour écrire dans /var/log/
LOG_FILE="/var/log/system_shutdown.log"

# Fichier standard utilisé par Debian/Ubuntu/Mint pour indiquer un besoin de redémarrage
REBOOT_REQUIRED_FILE="/var/run/reboot-required" 

# Variables d'environnement pour cron : garantit que toutes les commandes sont trouvées
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Fonction de Log
# ==============================================================================

# Fonction pour logger un message avec un horodatage (timestamp)
log_message() {
    # Écrit dans le fichier de log (nécessite sudo car le fichier est dans /var/log)
    # et affiche le message sur la sortie standard (tee -a)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"
    # Affiche aussi le message sur la sortie standard sans timestamp
    # (utile si le script est lancé manuellement)
    echo "$1" 
}

# Fonction de Vérification
# ==============================================================================

# Vérifie l'existence du fichier standard de redémarrage nécessaire
check_reboot_required() {
    if [ -f "$REBOOT_REQUIRED_FILE" ]; then
        return 0  # Redémarrage nécessaire (retourne succès/vrai)
    else
        return 1  # Pas de redémarrage nécessaire (retourne échec/faux)
    fi
}

# Logique Principale
# ==============================================================================

echo "=== Préparation à l'extinction du système ==="
log_message "Début du script d'extinction."

# Information sur le besoin de redémarrage avant l'extinction
if check_reboot_required; then
    log_message "Note : Un redémarrage était nécessaire après les dernières mises à jour (noyau ou libs importantes)."
    log_message "Le système va maintenant s'éteindre complètement, annulant le besoin de redémarrage."
else
    log_message "Aucun redémarrage particulier n'était en attente avant l'extinction."
fi

log_message "Extinction complète du système dans 30 secondes..."
log_message "Le serveur restera éteint jusqu'au prochain démarrage manuel."

# Pause de 30 secondes pour permettre aux derniers processus de se terminer
sleep 30

# Extinction du système
# 'sudo poweroff' ou 'sudo shutdown -h now' sont les commandes standard pour éteindre
# Nécessite des droits root, d'où l'utilisation de 'sudo'
sudo poweroff