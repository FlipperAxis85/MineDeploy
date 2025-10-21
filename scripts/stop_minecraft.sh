#!/bin/bash

# Configuration
# ==============================================================================

SESSION_NAME="minecraft" # Nom de la session screen à arrêter

# Variables d'environnement pour cron (nécessaire pour trouver 'screen')
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Fonction de Vérification
# ==============================================================================

# Vérifie si une session screen existe
check_screen_session() {
    screen -ls | grep -q "$SESSION_NAME"
    return $?
}

# Logique Principale
# ==============================================================================

echo "=== Arrêt du serveur Minecraft ==="

# 1. Vérifier si la session screen du serveur Minecraft est active
if check_screen_session; then
    echo "Session '$SESSION_NAME' trouvée. Préparation à l'arrêt du serveur Minecraft..."

    # 2. Envoyer la commande de sauvegarde
    echo "Sauvegarde forcée ('save-all') avant arrêt..."
    # 'screen -S session -p 0 -X stuff' envoie du texte au shell de la session
    # '^M' représente la touche Entrée pour exécuter la commande
    screen -S "$SESSION_NAME" -p 0 -X stuff "save-all^M"
    sleep 5 # Attendre que la sauvegarde soit (au moins en partie) lancée

    # 3. Envoyer la commande d'arrêt
    echo "Envoi de la commande 'stop' pour un arrêt propre..."
    screen -S "$SESSION_NAME" -p 0 -X stuff "stop^M"

    echo "Commande d'arrêt envoyée. Attente que le serveur ferme la session screen..."

    # 4. Boucle d'attente (jusqu'à 120 secondes)
    MAX_WAIT_SECONDS=120
    CHECK_INTERVAL=5
    MAX_ATTEMPTS=$((MAX_WAIT_SECONDS / CHECK_INTERVAL))

    for i in $(seq 1 "$MAX_ATTEMPTS"); do
        if ! check_screen_session; then
            echo "✓ Le serveur Minecraft est arrêté et la session screen '$SESSION_NAME' a été fermée."
            exit 0
        fi
        echo "Attente de l'arrêt du serveur... ($((i*CHECK_INTERVAL)) secondes écoulées / $MAX_WAIT_SECONDS total)"
        sleep "$CHECK_INTERVAL"
    done

    # 5. Échec si la boucle est terminée (Timeout)
    echo "Avertissement : La session screen '$SESSION_NAME' est toujours active après $MAX_WAIT_SECONDS secondes."
    echo "Le serveur prend trop de temps à s'arrêter. Vérifiez manuellement avec 'screen -r $SESSION_NAME'."
    exit 1
else
    # 6. Échec si le serveur n'était pas en cours d'exécution
    echo "Aucune session screen nommée '$SESSION_NAME' n'a été trouvée."
    echo "Le serveur Minecraft ne semble pas être en cours d'exécution."
    exit 1
fi