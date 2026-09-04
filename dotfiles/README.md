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
| `sway` | `.config/sway/config` | WM tuilant Wayland, **tuilage seul** — le shell est à Noctalia. Config **possédée**, plus héritée : depuis le 2026-09-01 elle n'inclut plus `/etc/sway/config`, seulement `/etc/sway/config.d/*` (la ligne vitale, qui charge `sway-systemd`). Contient aussi la disposition `fr/azerty`, que Sway ne récupère nulle part ailleurs, et les liaisons en `bindcode`. |
| `nas` | `.config/systemd/user/nas-infoadmin.service` | Montage automatique du partage SMB au login, sous GNOME **et** Sway. Crée aussi le lien `~/nas`. Le mot de passe n'est **pas** dans ce fichier — voir ci-dessous. |
| `desktop` | `.local/share/applications/*.desktop` | Entrées de lanceur maison, visibles dans le lanceur Noctalia (`Super+d`). Une seule à ce jour : la VM Windows d'administration. |
| `hypr` | `.config/hypr/hyprland.lua` | Compositeur, **tuilage seul** — le shell est à Noctalia. **En Lua, pas en `.conf`** : hyprlang est déprécié depuis Hyprland 0.55. Porte la disposition `fr/azerty`, les trois écrans et les liaisons `noctalia msg …`. Les espaces sont liés aux **symboles de niveau 1** de la rangée AZERTY (`ampersand`, `eacute`…) et non à `code:NN`, qui échoue silencieusement dans la config Lua. Remplace `sway` sur le poste de référence ; `sway` est gardé pour le lab. |
| `foot` | `.config/foot/foot.ini` | Terminal Wayland. Corrige le défaut `size=8`, illisible à `scale=1`, que le zoom de foot ne persiste pas. **Ajouté au dépôt le 2026-09-04, après avoir failli être perdu** : il existait depuis le 2026-09-01 sans jamais avoir été commité. Terminal susceptible de changer (kitty envisagé) ; ce qui doit survivre est le raisonnement `dpi-aware` / échelle du fichier, pas la valeur. |

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
stow -v -t ~ bash git sway nas desktop
```

> Les paquets `sway`, `nas` et `desktop` ne servent que sur une machine où ils ont un
> sens (compositeur Wayland, accès au partage, lanceur graphique). Sur une machine sans
> session graphique, `stow -v -t ~ bash git` suffit.

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
- **Trousseau `gnome-keyring`** (`~/.local/share/keyrings/`) : chiffré par le mot de
  passe de session, non transposable d'une installation à l'autre. Conséquence pour le
  paquet `nas` : `stow` remet l'unité en place, mais le mot de passe du partage doit être
  **réenregistré une fois** après chaque réinstallation, en montant le partage depuis
  Nautilus et en choisissant « se souvenir pour toujours ». `gio mount` en ligne de
  commande ne sait pas écrire dans le trousseau — seul le dialogue GTK le fait.
- **Attention aux liens de dossier** (`~/.bashrc.d/`, `~/.config/sway/`) : Stow les a
  posés en *tree folding*, c'est-à-dire un
  lien vers le dossier entier du dépôt, pas un dossier réel. Tout fichier déposé
  dedans est donc **directement dans le dépôt** et sera versionné au prochain commit.
  Jamais de token ni de mot de passe là-dedans — pour ça, un fichier hors dépôt
  (`~/.secrets.sh`, ignoré par git) sourcé depuis un fragment.
  Stow pose le lien **le plus haut possible** : `~/.bashrc.d` a pu être pris en entier,
  mais pour `sway` il a dû descendre jusqu'à `~/.config/sway` — `~/.config` contenait
  déjà les dossiers de GNOME. Même mécanisme, profondeur différente selon la cible.
- **Config spécifique à une distro** : si un paquet devient incompatible d'une distro à
  l'autre, le scinder (`bash-fedora`, `bash-debian`) plutôt que d'empiler les `if`.
