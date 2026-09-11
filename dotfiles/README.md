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
| `git` | `.gitconfig`, `.config/git/ignore` | Identité, `main` par défaut, quelques alias. **Pas de `core.editor`** : la ligne `editor = vim` a été retirée le 2026-09-07, `vim` n'existant pas sur une image minimale (`vim-minimal` fournit `vi`) — git suit `$VISUAL`/`$EDITOR`/`vi`, ce qui est portable. `.config/git/ignore` porte les exclusions globales, rapatriées du poste le 2026-09-07. |
| `sway` | `.config/sway/config` | WM tuilant Wayland, **tuilage seul** — le shell est à Noctalia. Config **possédée**, plus héritée : depuis le 2026-09-01 elle n'inclut plus `/etc/sway/config`, seulement `/etc/sway/config.d/*` (la ligne vitale, qui charge `sway-systemd`). Contient aussi la disposition `fr/azerty`, que Sway ne récupère nulle part ailleurs, et les liaisons en `bindcode`. |
| `nas` | `.config/systemd/user/nas-infoadmin.service` | Montage automatique du partage SMB au login. Crée aussi le lien `~/nas`. **Exige `graphical-session.target`, donc une session lancée par `uwsm`** — la mention « sous GNOME et Sway » qui figurait ici était périmée depuis le 2026-09-04 : le fichier de l'unité lui-même dit qu'avec « Hyprland » tout court la target reste inactive et l'unité ne démarre jamais. Le mot de passe n'est **pas** dans ce fichier — voir ci-dessous. |
| `desktop` | `.local/share/applications/*.desktop` | Entrées de lanceur maison, visibles dans le lanceur Noctalia. **Sans objet aujourd'hui, et non posé** : son unique entrée lance la VM via `virt-manager`, or la VM se retrouve par le lanceur Noctalia (`installation/mesures.md` §9). Paquet gardé comme emplacement, à reprendre quand on saura quoi y mettre — pas à poser pour cocher une case. |
| `hypr` | `.config/hypr/hyprland.lua` | Compositeur, **tuilage seul** — le shell est à Noctalia. **En Lua, pas en `.conf`** : hyprlang est déprécié depuis Hyprland 0.55. Porte la disposition `fr/azerty`, les trois écrans et les liaisons `noctalia msg …`. Les espaces sont liés aux **symboles de niveau 1** de la rangée AZERTY (`ampersand`, `eacute`…) et non à `code:NN`, qui échoue silencieusement dans la config Lua. Remplace `sway` sur le poste de référence ; `sway` est gardé pour le lab. |
| `uwsm` | `.config/uwsm/env` | **Environnement de la session graphique**, sourcé par `uwsm` (`man uwsm`). Il source `/etc/profile.d/flatpak.sh` pour `XDG_DATA_DIRS` — sans quoi aucune application Flatpak n'apparaît dans le lanceur. Raison de fond : `profile.d` ne s'exécute que dans un shell de **login**, et une session lancée par greetd → uwsm → Hyprland ne source jamais `/etc/profile`. **Exige `mkdir -p ~/.config/uwsm` AVANT le `stow`** (voir les limites). |
| `kitty` | `.config/kitty/kitty.conf` | **Terminal du poste**, depuis le 2026-09-04. Remplace le paquet `foot`, supprimé le 2026-09-09 avec le paquet RPM : foot était installé et inutilisé, son `foot.ini` ne configurait plus rien. Contenu : **un filtre de notifications**, qui écarte les « Claude is waiting for your input » (83 des 91 notifications de l'historique) et **garde** les 8 demandes de permission. Aucun réglage de police, et c'est délibéré : le défaut de kitty vaut déjà 11.0, la valeur que le `foot.ini` posait à la main — le raisonnement de foot est donc **clos par la mesure**, pas hérité. |

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

# 4. SIMULER d'abord — la simulation nomme le niveau exact de chaque lien
stow -n -v -t ~ bash git hypr kitty nas uwsm noctalia

# 5. Faire exister les dossiers que le tree folding remonterait trop haut
mkdir -p ~/.config/uwsm

# 6. Poser les liens
stow -v -t ~ bash git hypr kitty nas uwsm noctalia
```

> **L'étape 4 n'est pas facultative.** `stow` remonte le lien au niveau le plus haut
> possible (« tree folding ») : si `~/.config/uwsm` n'existe pas, il pose
> `~/.config/uwsm → <dépôt>/uwsm/.config/uwsm`, et tout ce qu'un programme écrira ensuite
> dans ce dossier finira **versionné**. Trois occurrences déjà sur ce dépôt :
> `~/.bashrc.d`, `~/.config/systemd`, `~/.config/uwsm`. La simulation `-n -v` dit à quel
> niveau le lien atterrirait — c'est le seul contrôle fiable.

> **Choisir les paquets selon la machine.** `hypr` (poste de référence) et `sway` (lab)
> sont **exclusifs** : ce sont deux compositeurs. `nas`, `kitty`, `noctalia` et `uwsm` n'ont de sens
> que sur une machine avec session graphique. Sur une machine sans bureau,
> `stow -v -t ~ bash git` suffit.

### État réel des liens sur le poste de référence — 2026-09-08

**Les six paquets de la cible sont posés.** Vérifié par `readlink` sur chaque cible, pas
par la commande qu'on a tapée :

| Paquet | Cible | Forme du lien |
|---|---|---|
| `bash` | `~/.bashrc`, `~/.bash_profile`, `~/.bashrc.d` | posé le 2026-09-08 |
| `git` | `~/.gitconfig`, `~/.config/git/ignore` | posé le 2026-09-08 |
| `hypr` | `~/.config/hypr/hyprland.lua` | **feuille** : `~/.config/hypr` reste un dossier réel, Hyprland y écrit ses propres fichiers |
| `kitty` | `~/.config/kitty/kitty.conf` | feuille — **créé le 2026-09-09, à poser** |
| `noctalia` | `~/.config/noctalia/idle.toml` | feuille — posé le 2026-09-09 |
| `nas` | `~/.config/systemd/user/nas-infoadmin.service` | feuille |
| `uwsm` | `~/.config/uwsm/env` | feuille |
| *hors cible* : `desktop`, `sway` | — | non posés : l'entrée de `desktop` n'a plus d'objet, `sway` ne sert qu'au lab |

**Ce qui bloquait pendant quatre jours, et ce que ça apprend.** `bash` et `git` étaient
refusés depuis le 2026-09-04 : `stow` ne remplace jamais un vrai fichier. Les quatre
fichiers en cause étaient le squelette de l'ISO (`.bashrc`, `.bash_profile`, datés du
16 janvier) ou des versions **antérieures** à celles du dépôt (`.gitconfig` et
`.config/git/ignore` du 2026-09-04, contre les versions enrichies du 2026-09-07). Écartés
dans `~/sauvegarde-dotfiles-2026-09-08/`, hors du dépôt.

> **Un lien posé à la main au bon endroit n'est pas un lien reconnu par Stow.**
> `~/.bashrc.d` avait été lié à la main vers le dépôt — en **absolu**. `stow -n -v` a
> répondu `existing target is not owned by stow: .bashrc.d` et **abandonné tout le
> paquet** : Stow ne reconnaît comme siens que les liens **relatifs** qu'il crée. Le
> remède est de retirer le lien manuel (pas sa cible) et de laisser Stow le refaire.
> Même famille que « une commande qui réussit n'est pas une commande qui fait ce qu'on
> croit » : le lien fonctionnait parfaitement, et empêchait pourtant le déploiement.

**Duplication née du déploiement, et refermée le même jour.**
`~/.bashrc.d/20-historique.sh` avait été écrit *parce que* le `.bashrc` du dépôt n'était
pas déployé — c'était dans son en-tête. Une fois le paquet posé, les deux fichiers posaient
les mêmes valeurs d'historique et seule la ligne `history -a` du fragment était unique :
elle a été **remontée dans le `.bashrc`** et le fragment supprimé. `~/.bashrc.d/` ne garde
que `10-aliases.sh`.

`history -a` est ajouté **devant** le `PROMPT_COMMAND` existant, jamais à sa place : sur
Fedora, `/etc/bashrc` y a déjà mis le titre de terminal, et le `.bashrc` du dépôt source
`/etc/bashrc` avant. Un garde-fou (`case … *'history -a'*`) rend l'ajout idempotent.
Vérifié dans un bash de login neuf : `PROMPT_COMMAND` = `history -a; printf "\033]0;…"`.

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
- **Ce qui n'est pas dans le home est hors d'atteinte, par construction.** Deux cas réels
  sur le poste de référence, trouvés le 2026-09-07 :
  - `/var/lib/noctalia-greeter/greeter.toml` — configuration du greeter, `greetd:greetd`,
    écrite à la main et livrée par aucun paquet. Recopiée intégralement dans
    `installation/procedure.md` §6.3 : c'est la seule des trois destinations qui puisse
    l'accueillir.
  - `/etc/tmpfiles.d/noctalia-greeter.conf` — même situation, même traitement.

  La leçon générale : **`stow` couvre le home, pas le poste.** Un geste posé dans `/etc`
  ou `/var` n'a qu'une destination possible, `installation/procedure.md` — et rien ne le
  rappelle au moment où on le pose.
- **Noctalia écrit dans `XDG_STATE_HOME`, pas dans `.config`.** Ses réglages sont dans
  `~/.local/state/noctalia/settings.toml`, à côté de son historique de notifications, de
  son presse-papiers chiffré, de ses compteurs d'usage et de son cache de palettes
  communautaires. **Décision du 2026-09-07 : pas de paquet `stow` pour ça.** Versionner ce
  dossier, ce serait versionner un flux d'écriture continu ; l'isoler proprement
  demanderait de trier fichier par fichier un dossier dont le contenu change à chaque
  version de Noctalia. **La perte est donc assumée : après une réinstallation, les
  réglages de Noctalia se refont à la main.** Écrit ici pour que ça reste un choix et pas
  une surprise.
  À distinguer du `greeter.toml`, qui est **déclaratif** et que le greeter ne réécrit
  jamais — c'est ce qui le rend recopiable, pas le fait qu'il soit plus important.
