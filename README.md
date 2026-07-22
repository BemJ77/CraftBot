# 🍔 CraftBot Manager

CraftBot est un système complet de gestion de restaurant pour **Minecraft** utilisant **CC:Tweaked** et **Applied Energistics 2**.

Le projet permet de gérer automatiquement des bornes de commande, des chefs, un serveur central et un moniteur de cuisine.

---

# ✨ Fonctionnalités

- 📦 Gestionnaire de paquets intégré
- 🔄 Installation et mises à jour automatiques
- ✅ Vérification de l'intégrité des fichiers
- 🔧 Réparation automatique des installations
- 💾 Sauvegarde avant chaque mise à jour
- 📜 Consultation des changelogs
- 🌐 Téléchargement des packages depuis GitHub

---

# 📋 Prérequis

- Minecraft
- CC:Tweaked
- Connexion HTTP activée
- Accès à Internet

---

# 🚀 Installation

Sur un ordinateur ComputerCraft neuf, exécutez simplement :

```lua
pastebin run T9FdVU8t
```

L'installateur va automatiquement :

1. Télécharger le dernier installateur depuis GitHub
2. Installer CraftBot Manager
3. Télécharger les fichiers nécessaires
4. Configurer le système
5. Proposer un redémarrage

Aucune autre manipulation n'est nécessaire.

---

# 📦 Mise à jour

Les mises à jour sont gérées directement depuis le CraftBot Manager.

Il suffit de choisir :

```
Packages
→ Mise à jour
```

Le Manager téléchargera automatiquement les nouvelles versions disponibles.

---

# 🖥️ Packages disponibles

- 🧑‍🍳 Chef
- 🖥️ Serveur
- 🛒 Borne de commande
- 📺 Moniteur de cuisine

Chaque package peut être :

- installé
- vérifié
- mis à jour
- désinstallé

indépendamment.

---

# 📂 Structure du dépôt

```
config/
core/
packages/
ui/

catalog.lua
install.lua
manager.lua
manifest.lua
startup
README.md
```

---

# 🔨 Développement

Le projet est développé en Lua pour CC:Tweaked.

Les packages sont automatiquement détectés depuis le dossier :

```
packages/
```

Chaque package possède son propre :

- package.lua
- changelog.lua
- fichiers

Le Manager construit automatiquement les informations nécessaires.

---

# 🌐 Dépôt GitHub

https://github.com/BemJ77/CraftBot

---

# 📄 Licence

Aucune licence n'est définie pour le moment.

Tous droits réservés © BemJ77.
