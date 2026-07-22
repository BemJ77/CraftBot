# CraftBot

CraftBot est un système de restaurant automatisé pour **Minecraft**, développé avec
**CC:Tweaked**, **Applied Energistics 2** et **Advanced Peripherals**.

Ce dépôt contient :

- le **CraftBot Manager** ;
- le paquet **Serveur** ;
- le paquet **Chef** ;
- le paquet **Borne** ;
- le paquet **Moniteur** ;
- les scripts d'installation et de mise à jour depuis GitHub.

## Installation dans ComputerCraft

Après avoir publié ce dossier dans un dépôt GitHub public, exécutez dans ComputerCraft :

```text
wget run https://raw.githubusercontent.com/UTILISATEUR/CraftBot/main/install.lua UTILISATEUR CraftBot main
```

Remplacez `UTILISATEUR` par votre nom d'utilisateur GitHub.

L'API HTTP doit être activée dans la configuration du serveur Minecraft.

## Mise à jour

Les nouvelles versions des paquets sont recherchées automatiquement au lancement du
Manager.

Pour mettre à jour uniquement le Manager :

```text
update-manager
```

## Organisation

```text
config/             Configuration du Manager et du dépôt GitHub
core/               Modules du Manager
ui/                 Interface
packages/           Paquets CraftBot
catalog.lua         Catalogue distant des paquets
manifest.lua        Liste des fichiers téléchargeables
install.lua         Installation initiale depuis GitHub
update-manager.lua  Mise à jour du Manager
```

## Versions incluses

- CraftBot Manager : **1.4.0**
- Paquets CraftBot : versions indiquées dans chaque `package.lua`
