# 🧱 MineDeploy - Free Version (Vanilla)

MineDeploy est un outil d'installation et d'automatisation pour serveurs **Minecraft Vanilla** sous Linux (Ubuntu / Linux Mint).  
Le but : permettre à tout le monde de déployer un serveur Minecraft fonctionnel en quelques minutes, sans ligne de commande compliquée.

---

## 🚀 Fonctionnalités principales

- Installation automatique des dépendances (Java, Screen, Curl, Wget...)
- Téléchargement automatique du bon `server.jar` selon la version Minecraft choisie
- Création automatique des dossiers (`servers`, `scripts`, `logs`)
- Gestion du serveur avec des scripts simples :
  - `start_minecraft.sh` → Démarrer le serveur
  - `stop_minecraft.sh` → Arrêter proprement le serveur
  - `update_system.sh` → Mise à jour du système (version premium uniquement)
  - `shutdown_system.sh` → Éteindre le PC à l’heure programmée
- Configuration automatique du **crontab** (arrêt, mise à jour et extinction programmée)
- Interface simple et interactive en terminal

---

## 📂 Structure du projet

```
MineDeploy/
 ├── minedeploy-vanilla.sh
 └── scripts/
      ├── start_minecraft.sh
      ├── stop_minecraft.sh
      ├── update_system.sh
      └── shutdown_system.sh
```

---

## ⚙️ Installation

1. Clone le dépôt :
   ```bash
   git clone https://github.com/FlipperAxis85/MineDeploy.git
   cd MineDeploy
   ```

2. Rends le script exécutable :
   ```bash
   chmod +x minedeploy-vanilla.sh
   ```

3. Lance l’installation :
   ```bash
   ./minedeploy-vanilla.sh
   ```

4. Suis les instructions :
   - Choisis la version Minecraft à installer (ex : `1.21.1`)
   - Indique l’heure d’arrêt automatique (ex : `16:00`)
   - Le script configure tout automatiquement 🪄

---

## 🧠 Notes importantes

- Le script **accepte automatiquement la EULA de Minecraft**.
- Tous les chemins sont dynamiques (`$HOME` et `$USER`).
- Testé sur **Ubuntu 22.04** et **Linux Mint 21**.
- La **version gratuite** ne contient pas les sauvegardes automatiques ni la mise à jour du système.

---

## 💎 Version Premium

La version **MineDeploy Pro** inclura :
- Sauvegardes automatiques quotidiennes
- Mises à jour système automatiques
- Support multi-version (Fabric, Spigot, Purpur, etc.)
- Interface web simplifiée

---

## 🧩 Auteur

**Projet développé par [FlipperAxou](https://github.com/FlipperAxis85)**  
→ [https://github.com/FlipperAxis85/MineDeploy](https://github.com/FlipperAxis85/MineDeploy)

---

### 📜 Licence
Projet open-source sous licence MIT — utilisation libre et modifications autorisées.

---

✨ *“MineDeploy - Faites tourner votre serveur Minecraft comme un pro, sans galérer.”*
