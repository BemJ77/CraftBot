# Publication de CraftBot sur GitHub

## 1. Créer le dépôt

Créez un nouveau dépôt GitHub, par exemple :

```text
CraftBot
```

Le dépôt doit être **public** pour que ComputerCraft puisse télécharger les fichiers
bruts sans authentification.

Ne cochez pas l'ajout automatique d'un README si vous souhaitez envoyer directement
tout le contenu de cette archive.

## 2. Envoyer les fichiers

Décompressez l'archive, puis envoyez **le contenu du dossier**, pas le dossier parent.

La racine du dépôt doit directement contenir :

```text
README.md
install.lua
manager.lua
manifest.lua
catalog.lua
packages/
core/
config/
ui/
```

Vous pouvez utiliser l'interface GitHub avec **Add file > Upload files**, GitHub Desktop,
ou Git en ligne de commande.

## 3. Installation dans ComputerCraft

Après publication, utilisez :

```text
wget run https://raw.githubusercontent.com/UTILISATEUR/CraftBot/main/install.lua UTILISATEUR CraftBot main
```

Exemple fictif pour l'utilisateur `Benjamin` :

```text
wget run https://raw.githubusercontent.com/Benjamin/CraftBot/main/install.lua Benjamin CraftBot main
```

## 4. Publier une nouvelle version d'un paquet

1. Modifiez les fichiers dans `packages/<paquet>/files/`.
2. Augmentez la version dans `packages/<paquet>/package.lua`.
3. Ajoutez les changements dans `packages/<paquet>/changelog.lua`.
4. Régénérez `catalog.lua` et `manifest.lua`.
5. Envoyez les modifications sur GitHub.

Au prochain démarrage, le Manager téléchargera automatiquement la nouvelle version du
paquet. L'utilisateur pourra ensuite choisir **Mise à jour**.

## 5. Publier une nouvelle version du Manager

1. Modifiez les fichiers du Manager.
2. Changez `MANAGER_VERSION` dans `manager.lua`.
3. Changez `managerVersion` dans `manifest.lua`.
4. Envoyez les modifications sur GitHub.
5. Sur ComputerCraft, lancez :

```text
update-manager
```

## 6. Configuration HTTP

L'API HTTP de CC:Tweaked doit être autorisée. Les domaines GitHub utilisés sont :

```text
raw.githubusercontent.com
github.com
```
