#!/bin/bash

################################################################################
# MineDeploy Vanilla - Script d'installation automatique
# Version gratuite (Vanilla) uniquement
# Déploie un serveur Minecraft avec arrêt programmé
################################################################################

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables globales
GIST_URL="https://gist.githubusercontent.com/cliffano/77a982a7503669c3e1acb0a0cf6127e9/raw/minecraft-server-jar-downloads.md"
USER_HOME="$HOME"
SERVERS_DIR="$USER_HOME/servers"
SCRIPTS_DIR="$USER_HOME/scripts"
LOGS_DIR="$USER_HOME/logs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

################################################################################
# Fonction : Afficher les messages
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

################################################################################
# Fonction : Vérifier et installer les dépendances
################################################################################

install_dependencies() {
    log_info "Vérification et installation des dépendances..."
    
    local packages="curl wget jq screen openjdk-21-jre-headless"
    local missing=""
    
    for pkg in $packages; do
        if ! dpkg -l | grep -q "^ii  $pkg"; then
            missing="$missing $pkg"
        fi
    done
    
    if [ -n "$missing" ]; then
        log_warning "Paquets manquants :$missing"
        log_info "Mise à jour des dépôts..."
        sudo apt-get update -qq
        
        log_info "Installation des paquets..."
        sudo apt-get install -y $missing > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            log_success "Dépendances installées"
        else
            log_error "Erreur lors de l'installation des dépendances"
            exit 1
        fi
    else
        log_success "Toutes les dépendances sont présentes"
    fi
}

################################################################################
# Fonction : Demander les informations à l'utilisateur
################################################################################

get_user_input() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  MineDeploy Vanilla - Configuration${NC}${BLUE}           ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}\n"
    
    while true; do
        read -p "$(echo -e '${BLUE}[?]${NC} Version Minecraft (ex: 1.21.1) : ')" VERSION
        if [ -z "$VERSION" ]; then
            log_error "La version ne peut pas être vide"
            continue
        fi
        break
    done
    
    while true; do
        read -p "$(echo -e '${BLUE}[?]${NC} Heure d'\''arrêt du serveur (HH:MM, ex: 16:00) : ')" SHUTDOWN_TIME
        if [[ $SHUTDOWN_TIME =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
            break
        else
            log_error "Format invalide. Utilisez HH:MM (ex: 16:00)"
        fi
    done
    
    SHUTDOWN_HOUR="${SHUTDOWN_TIME%:*}"
    SHUTDOWN_MIN="${SHUTDOWN_TIME#*:}"
    
    UPDATE_HOUR=$SHUTDOWN_HOUR
    UPDATE_MIN=$((SHUTDOWN_MIN + 5))
    
    SYSTEM_HOUR=$SHUTDOWN_HOUR
    SYSTEM_MIN=$((SHUTDOWN_MIN + 10))
    
    if [ $UPDATE_MIN -ge 60 ]; then
        UPDATE_MIN=$((UPDATE_MIN - 60))
        UPDATE_HOUR=$((UPDATE_HOUR + 1))
        if [ $UPDATE_HOUR -eq 24 ]; then
            UPDATE_HOUR=0
        fi
    fi
    
    if [ $SYSTEM_MIN -ge 60 ]; then
        SYSTEM_MIN=$((SYSTEM_MIN - 60))
        SYSTEM_HOUR=$((SYSTEM_HOUR + 1))
        if [ $SYSTEM_HOUR -eq 24 ]; then
            SYSTEM_HOUR=0
        fi
    fi
    
    SHUTDOWN_MIN=$(printf "%02d" "$SHUTDOWN_MIN")
    UPDATE_MIN=$(printf "%02d" "$UPDATE_MIN")
    SYSTEM_MIN=$(printf "%02d" "$SYSTEM_MIN")
    SHUTDOWN_HOUR=$(printf "%02d" "$SHUTDOWN_HOUR")
    UPDATE_HOUR=$(printf "%02d" "$UPDATE_HOUR")
    SYSTEM_HOUR=$(printf "%02d" "$SYSTEM_HOUR")
    
    log_success "Configuration validée"
}

################################################################################
# Fonction : Créer les dossiers
################################################################################

create_directories() {
    log_info "Création de la structure des dossiers..."
    
    mkdir -p "$SERVERS_DIR"
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$LOGS_DIR"
    
    log_success "Dossiers créés"
}

################################################################################
# Fonction : Télécharger le server.jar
################################################################################

download_server_jar() {
    log_info "Téléchargement du server.jar pour la version $VERSION..."
    
    local jar_url
    local gist_content
    
    gist_content=$(curl -s "$GIST_URL")
    
    # Chercher la ligne exacte avec la version
    # Format : | 1.21.1 | https://... | https://...
    jar_url=$(echo "$gist_content" | grep "^| $VERSION " | awk -F'|' '{print $3}' | xargs | grep -o 'https[^ ]*server\.jar')
    
    # Si pas trouvé, chercher les snapshots
    if [ -z "$jar_url" ]; then
        jar_url=$(echo "$gist_content" | grep "^| $VERSION" | awk -F'|' '{print $3}' | xargs | grep -o 'https[^ ]*server\.jar' | head -1)
    fi
    
    if [ -z "$jar_url" ]; then
        log_error "Version introuvable. Vérifiez le numéro de version Minecraft."
        log_warning "Versions disponibles :"
        echo "$gist_content" | grep "^|" | grep -v "Version" | awk -F'|' '{print "  - " $2}' | head -15
        exit 1
    fi
    
    log_info "URL trouvée : $jar_url"
    log_info "Téléchargement en cours..."
    
    if curl -L "$jar_url" -o "$SERVERS_DIR/server.jar" -# 2>/dev/null; then
        log_success "server.jar téléchargé avec succès"
    else
        log_error "Erreur lors du téléchargement du server.jar"
        exit 1
    fi
    
    if [ ! -s "$SERVERS_DIR/server.jar" ]; then
        log_error "Le fichier server.jar est vide"
        rm -f "$SERVERS_DIR/server.jar"
        exit 1
    fi
}

################################################################################
# Fonction : Copier et configurer les scripts secondaires
################################################################################

setup_scripts() {
    log_info "Configuration des scripts secondaires..."
    
    local scripts="start_minecraft.sh stop_minecraft.sh update_system.sh shutdown_system.sh"
    
    for script in $scripts; do
        if [ -f "$SCRIPT_DIR/scripts/$script" ]; then
            cp "$SCRIPT_DIR/scripts/$script" "$SCRIPTS_DIR/$script"
            chmod +x "$SCRIPTS_DIR/$script"
            log_success "Script copié : $script"
        else
            log_warning "Script non trouvé : $script"
        fi
    done
}

################################################################################
# Fonction : Créer eula.txt
################################################################################

create_eula() {
    log_info "Création du fichier eula.txt..."
    echo "eula=true" > "$SERVERS_DIR/eula.txt"
    log_success "eula.txt créé"
}

################################################################################
# Fonction : Configurer sudoers pour sudo sans mot de passe
################################################################################

setup_sudoers() {
    log_info "Configuration de sudoers pour les commandes sans mot de passe..."
    
    local CURRENT_USER=$(whoami)
    local SUDOERS_ENTRY="# MineDeploy - Pas de mot de passe pour ces commandes
Defaults:$CURRENT_USER !authenticate
$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/apt-get update
$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/apt-get upgrade
$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/apt-get install
$CURRENT_USER ALL=(ALL) NOPASSWD: /sbin/shutdown"
    
    # Vérifier si déjà configuré
    if sudo grep -q "MineDeploy - Pas de mot de passe" /etc/sudoers 2>/dev/null; then
        log_warning "sudoers déjà configuré pour MineDeploy"
        return
    fi
    
    # Ajouter à sudoers de façon sécurisée
    echo "$SUDOERS_ENTRY" | sudo tee -a /etc/sudoers.d/minedeploy-nopasswd > /dev/null
    sudo chmod 0440 /etc/sudoers.d/minedeploy-nopasswd
    
    # Valider la syntaxe
    if sudo visudo -c -f /etc/sudoers.d/minedeploy-nopasswd > /dev/null 2>&1; then
        log_success "sudoers configuré correctement"
    else
        log_error "Erreur dans la configuration sudoers"
        sudo rm -f /etc/sudoers.d/minedeploy-nopasswd
        exit 1
    fi
}

################################################################################
# Fonction : Configurer le crontab
################################################################################

setup_crontab() {
    log_info "Configuration du crontab utilisateur..."
    
    local TEMP_CRON
    TEMP_CRON=$(mktemp)
    
    # Créer un crontab vierge sans aucune entrée MineDeploy
    crontab -l 2>/dev/null | sed '/# ========== MineDeploy Configuration ==========/,/# ===== Fin MineDeploy Configuration =====/d' > "$TEMP_CRON" 2>/dev/null || true
    
    # Supprimer les lignes vides excessives
    sed -i '/^[[:space:]]*$/d' "$TEMP_CRON"
    
    echo "" >> "$TEMP_CRON"
    echo "# ========== MineDeploy Configuration ==========" >> "$TEMP_CRON"
    echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> "$TEMP_CRON"
    echo "SHELL=/bin/bash" >> "$TEMP_CRON"
    echo "" >> "$TEMP_CRON"
    
    # === CYCLE QUOTIDIEN ===
    echo "# === CYCLE QUOTIDIEN ===" >> "$TEMP_CRON"
    echo "# Au démarrage du système : " >> "$TEMP_CRON"
    echo "# 1. Attendre 2 minutes pour la stabilité du système (120 secondes)" >> "$TEMP_CRON"
    echo "# 2. Faire la backup (non inclus dans la version Vanilla)" >> "$TEMP_CRON"
    echo "# 3. Lancer le serveur Minecraft" >> "$TEMP_CRON"
    # Utilisation de sleep 120s (2 minutes) et chemins d'accès corrects
    echo "@reboot sleep 120 && $SCRIPTS_DIR/start_minecraft.sh >> $LOGS_DIR/reboot.log 2>&1" >> "$TEMP_CRON"
    echo "" >> "$TEMP_CRON"
    # === FIN CYCLE QUOTIDIEN ===
    
    echo "# Arrêt du serveur Minecraft à $SHUTDOWN_HOUR:$SHUTDOWN_MIN" >> "$TEMP_CRON"
    echo "$SHUTDOWN_MIN $SHUTDOWN_HOUR * * * $SCRIPTS_DIR/stop_minecraft.sh >> $LOGS_DIR/stop.log 2>&1" >> "$TEMP_CRON"
    echo "" >> "$TEMP_CRON"
    echo "# Mise à jour système +5 min" >> "$TEMP_CRON"
    echo "$UPDATE_MIN $UPDATE_HOUR * * * $SCRIPTS_DIR/update_system.sh >> $LOGS_DIR/update.log 2>&1" >> "$TEMP_CRON"
    echo "" >> "$TEMP_CRON"
    echo "# Extinction du système +10 min" >> "$TEMP_CRON"
    echo "$SYSTEM_MIN $SYSTEM_HOUR * * * $SCRIPTS_DIR/shutdown_system.sh >> $LOGS_DIR/shutdown.log 2>&1" >> "$TEMP_CRON"
    echo "# ===== Fin MineDeploy Configuration =====" >> "$TEMP_CRON"
    
    crontab "$TEMP_CRON"
    rm -f "$TEMP_CRON"
    
    log_success "Crontab utilisateur configuré"
}

################################################################################
# Fonction : Afficher le résumé final
################################################################################

show_summary() {
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ✅ Installation terminée !${NC}${GREEN}                   ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BLUE}📦 Configuration${NC}"
    echo -e "  Version Minecraft  : ${YELLOW}$VERSION${NC}"
    echo -e "  Répertoire serveur : ${YELLOW}$SERVERS_DIR${NC}"
    echo -e "  Répertoire scripts : ${YELLOW}$SCRIPTS_DIR${NC}"
    echo -e "  Répertoire logs    : ${YELLOW}$LOGS_DIR${NC}"
    
    echo -e "\n${BLUE}⏰ Programmation automatique${NC}"
    echo -e "  Démarrage (Reboot) : ${YELLOW}2 min après (via @reboot)${NC}"
    echo -e "  Arrêt serveur      : ${YELLOW}$SHUTDOWN_HOUR:$SHUTDOWN_MIN${NC}"
    echo -e "  Mise à jour        : ${YELLOW}$UPDATE_HOUR:$UPDATE_MIN${NC}"
    echo -e "  Extinction système : ${YELLOW}$SYSTEM_HOUR:$SYSTEM_MIN${NC}"
    
    echo -e "\n${BLUE}🚀 Commandes utiles${NC}"
    echo -e "  Démarrer   : ${YELLOW}$SCRIPTS_DIR/start_minecraft.sh${NC}"
    echo -e "  Arrêter    : ${YELLOW}$SCRIPTS_DIR/stop_minecraft.sh${NC}"
    echo -e "  Voir cron  : ${YELLOW}crontab -l${NC}"
    echo -e "  Éditer     : ${YELLOW}crontab -e${NC}"
    
    echo -e "\n${BLUE}📋 Fichiers créés${NC}"
    echo -e "  ${YELLOW}$SERVERS_DIR/server.jar${NC}"
    echo -e "  ${YELLOW}$SERVERS_DIR/eula.txt${NC}"
    
    echo -e "\n${BLUE}🔐 Sécurité${NC}"
    echo -e "  ${YELLOW}/etc/sudoers.d/minedeploy-nopasswd${NC}"
    echo -e "  Commandes sudo configurées sans mot de passe"
    
    echo -e "\n${YELLOW}ℹ️  Note importante${NC}"
    echo -e "  Version gratuite de MineDeploy (Vanilla)."
    echo -e "  Les fonctions de sauvegarde et de mise à jour"
    echo -e "  automatique sont disponibles dans la version Pro.\n"
}

################################################################################
# Main
################################################################################

main() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  MineDeploy Vanilla v1.0${NC}${BLUE}                       ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}\n"
    
    log_info "Démarrage de l'installation..."
    
    if [ "$EUID" -eq 0 ]; then
        log_error "Ne pas exécuter ce script en tant que root"
        exit 1
    fi
    
    install_dependencies
    get_user_input
    create_directories
    download_server_jar
    setup_scripts
    create_eula
    setup_sudoers
    setup_crontab
    show_summary
}

main