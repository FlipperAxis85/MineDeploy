#!/bin/bash

# Configuration des Chemins & Variables
# ==============================================================================

# Récupère le répertoire personnel de l'utilisateur (ex: /home/user)
USER_HOME=$(eval echo ~)
# Répertoire principal des serveurs (votre dossier de référence : home/username/servers)
SERVERS_DIR="$USER_HOME/servers" 

# Variables spécifiques au serveur Minecraft
MINECRAFT_USER=$(whoami)
# 🚨 CORRECTION : Le dossier du serveur est directement SERVERS_DIR
MINECRAFT_DIR="$SERVERS_DIR" 
JAR_FILE="server.jar" 
SESSION_NAME="minecraft"
MIN_RAM="4G"
MAX_RAM="10G"
STARTUP_DELAY=30

# Variables d'environnement pour cron
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Fonctions de Vérification
# ==============================================================================

# Vérifie si une session screen est déjà active
check_screen_session() {
    screen -ls | grep -q "$SESSION_NAME"
    return $?
}

# Vérifie l'existence du répertoire et du fichier JAR
check_minecraft_files() {
    if [ ! -d "$MINECRAFT_DIR" ]; then
        echo "Erreur : Le répertoire $MINECRAFT_DIR n'existe pas."
        return 1
    fi
    # Vérifie la présence de server.jar dans $MINECRAFT_DIR (c-à-d $USER_HOME/servers)
    if [ ! -f "$MINECRAFT_DIR/$JAR_FILE" ]; then
        echo "Erreur : Le fichier JAR $MINECRAFT_DIR/$JAR_FILE n'existe pas."
        return 1
    fi
    return 0
}

# Logique Principale
# ==============================================================================

echo "=== Démarrage du serveur Minecraft ==="

# Attente pour stabilisation système
if [ $STARTUP_DELAY -gt 0 ]; then
    echo "Attente de $STARTUP_DELAY secondes..."
    sleep $STARTUP_DELAY
fi

# 1. Vérifie si le serveur est déjà démarré
if check_screen_session; then
    echo "Une session '$SESSION_NAME' est déjà en cours. Serveur déjà démarré."
    exit 0
fi

# 2. Vérifie l'existence des fichiers
if ! check_minecraft_files; then
    echo "Démarrage impossible (fichiers manquants)."
    exit 1
fi

# 3. Accède au répertoire du serveur
echo "Navigation vers le répertoire : $MINECRAFT_DIR"
cd "$MINECRAFT_DIR" || {
    echo "Erreur : Impossible d'accéder à $MINECRAFT_DIR."
    exit 1
}

# 4. Vérifie la présence de Java
if ! command -v java &> /dev/null; then
    echo "Erreur : Java non installé."
    exit 1
fi

echo "Démarrage du serveur ($JAR_FILE) avec $MIN_RAM/$MAX_RAM RAM."

# 5. Lance le serveur dans une nouvelle session screen
screen -dmS "$SESSION_NAME" java -Xmx"$MAX_RAM" -Xms"$MIN_RAM" -jar "$JAR_FILE" nogui

# 6. Vérifie le succès du lancement
sleep 2
if check_screen_session; then
    echo "✓ Serveur démarré (session '$SESSION_NAME')."
    exit 0
else
    echo "✗ Erreur : Session screen non créée."
    exit 1
fi