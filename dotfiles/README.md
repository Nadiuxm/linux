# Dotfiles — gérés avec GNU Stow

Configuration portable, réappliquée sur machine nue après chaque réinstallation.

## Pourquoi Stow

En bare-metal successif, le problème n'est pas de sauvegarder les configs : c'est de
les **remettre en place vite et sans en oublier** sur un système fraîchement installé.

Stow résout ça avec des liens symboliques. Chaque sous-dossier de `dotfiles/` est un
**paquet** dont l'arborescence interne reflète celle de `$HOME`. Stow lit le paquet et
crée les liens correspondants.

```
dotfiles/bash/.bashrc   ──stow──▶   ~/.bashrc -> ~/linux/dotfiles/bash/.bashrc
```

L'intérêt concret : le fichier réel vit dans le dépôt git. Quand je modifie `~/.bashrc`,
je modifie en fait le fichier versionné — `git status` le voit tout de suite, sans copie
manuelle ni script de synchronisation à maintenir. Et `stow -D` défait tout proprement.

## Paquets disponibles

| Paquet | Contenu | Notes |
|---|---|---|
| `bash` | `.bashrc`, `.bash_profile`, `.bashrc.d/` | Rendu portable : gère `/etc/bashrc` (Fedora/RHEL) **et** `/etc/bash.bashrc` (Debian/Ubuntu). Historique élargi et horodaté. |
| `git` | `.gitconfig` | Identité, `main` par défaut, quelques alias. |

## Installation sur une machine neuve

```bash
# 1. Stow (nom du paquet identique sur la plupart des distros)
sudo dnf install stow      # Fedora / RHEL
sudo apt install stow      # Debian / Ubuntu
sudo pacman -S stow        # Arch

# 2. Le dépôt, en tout premier geste après l'install
git clone <url-du-depot> ~/linux
cd ~/linux/dotfiles

# 3. Écarter les fichiers par défaut de la distro, sinon Stow refuse
#    (il ne remplace jamais un vrai fichier — c'est une sécurité, pas un bug)
mkdir -p ~/.dotfiles-backup
for f in .bashrc .bash_profile .gitconfig; do
    [ -f ~/"$f" ] && [ ! -L ~/"$f" ] && mv ~/"$f" ~/.dotfiles-backup/
done

# 4. Poser les liens
stow -v -t ~ bash git
```

## Usage courant

```bash
cd ~/linux/dotfiles

stow -n -v -t ~ bash     # simulation : montre ce qui serait fait, ne fait rien
stow    -v -t ~ bash     # poser les liens du paquet bash
stow -R -v -t ~ bash     # re-stow, après avoir ajouté un fichier au paquet
stow -D -v -t ~ bash     # retirer les liens
```

`-t ~` désigne la cible. Sans lui, Stow vise le **parent** du dossier courant, ce qui
depuis `~/linux/dotfiles` donnerait `~/linux/` — pas `$HOME`. À toujours préciser.

## Ajouter une config au dépôt

```bash
mkdir -p ~/linux/dotfiles/vim
mv ~/.vimrc ~/linux/dotfiles/vim/.vimrc     # déplacer, pas copier
cd ~/linux/dotfiles && stow -v -t ~ vim     # le lien remplace le fichier
```

Le `mv` compte : il ne doit rester **qu'un seul** exemplaire du fichier, celui du dépôt.
Une copie laissée dans `$HOME` et l'on ne sait plus laquelle des deux fait foi.

## Limites — ce que Stow ne couvre pas

- **`~/.config/dconf/user`** : base binaire de GNOME. Ne se versionne pas utilement.
  Utiliser `dconf dump /org/gnome/ > gnome-settings.ini` et `dconf load` pour recharger.
- **Secrets** : clés SSH/GPG, base KeePassXC. Exclus par le `.gitignore`, à sauvegarder
  hors du dépôt.
- **Config spécifique à une distro** : si un paquet devient incompatible d'une distro à
  l'autre, le scinder (`bash-fedora`, `bash-debian`) plutôt que d'empiler les `if`.
