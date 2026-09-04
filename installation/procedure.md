# Procédure — poste de référence, rejouable

> **But : rebâtir ce poste sans rien réinventer.** Ce fichier n'explique pas les choix
> (c'est `README.md`) et ne raconte pas la construction (c'est `journal.md`). Il est la
> **séquence**, dans l'ordre, avec les versions exactes.
>
> **Règle de tenue :** un geste posé sur la machine s'écrit ici le jour même, ou il sera
> perdu. Trois destinations possibles pour un geste — ce fichier, `dotfiles/`, ou `poste/`.
> Rien d'autre.

**État : en cours de construction.** Les étapes non cochées ne sont pas encore faites, et
tant qu'elles ne le sont pas, ce fichier n'est pas rejouable.

---

## 1. Installation de base — FAIT le 2026-09-04

| Paramètre | Valeur retenue |
|---|---|
| Image | Fedora 44, **Everything netinstall** — minimale, aucun bureau |
| Cible | **NVMe interne** (KIOXIA BG6 256 Go), `nvme0n1` |
| Chiffrement | **LUKS** sur `nvme0n1p3` |
| Système de fichiers | **Btrfs**, sous-volumes `root` et `home`, `compress=zstd:1` |
| Cible systemd | `multi-user.target` |

Partitionnement obtenu, **conservé sciemment** (raison dans `README.md`) :

```
nvme0n1p1   600 Mo  vfat   /boot/efi
nvme0n1p2     2 Go  ext4   /boot          <- séparé, et c'est voulu
nvme0n1p3   236 Go  LUKS -> btrfs         /  (subvol=root)  et  /home  (subvol=home)
```

Résultat : **53 paquets explicites, 419 au total.**

- [x] Installation
- [ ] **Enrôler le TPM2 sur LUKS** — `systemd-cryptenroll`. Matériel vérifié :
      `/dev/tpm0`, `systemd-analyze has-tpm2` → `yes`. Sans ça, phrase de passe à chaque
      démarrage.
- [ ] Relever la version LUKS de `nvme0n1p3` (`sudo cryptsetup luksDump`) et la noter ici.

## 2. Accès au dépôt — FAIT le 2026-09-04

```bash
sudo dnf install git

git config --global user.name  "jzielona"
git config --global user.email "zielonajulien@gmail.com"
```

**La clé du dépôt est une deploy key nommée `gitlinux`**, donc `ssh` ne la propose pas
spontanément (il n'essaie que `id_ed25519`, `id_rsa`…). Sans le bloc ci-dessous, le clone
échoue sur `Permission denied (publickey)` :

```
# ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/gitlinux
    IdentitiesOnly yes
```

Clé d'hôte GitHub à ajouter **après comparaison** avec les empreintes publiées sur
`https://api.github.com/meta` — un `ssh-keyscan` seul ne vérifie rien :

```bash
ssh-keyscan -t rsa,ecdsa,ed25519 github.com > /tmp/gh
ssh-keygen -lf /tmp/gh          # comparer aux 3 empreintes de api.github.com/meta
cat /tmp/gh >> ~/.ssh/known_hosts
```

Puis :

```bash
git clone git@github.com:Nadiuxm/linux.git ~/linux
```

- [x] `git`, identité, `~/.ssh/config`, clone

## 3. Mise à jour complète

- [ ] `sudo dnf upgrade`
- [ ] Noter la version du noyau obtenue

## 4. Compositeur — Hyprland

Absent des dépôts Fedora ; **un COPR est nécessaire**. Fedora fournit les bibliothèques
(`hyprutils`, `hyprlang` 0.6.4, `hyprgraphics` 0.1.5, `hyprcursor` 0.1.11,
`hyprland-protocols` 0.4.0) mais pas le compositeur.

- [ ] Choisir le COPR et **le noter ici avec la version installée**
- [ ] Surveiller le décalage de versions avec les bibliothèques Fedora à chaque mise à jour

### La plomberie que Sway fournissait et qu'Hyprland ne fournit pas

Sous Sway, `/etc/sway/config.d/10-systemd-session.conf` lançait
`/usr/libexec/sway-systemd/session.sh` : propagation de l'environnement vers systemd et
D-Bus, démarrage de `sway-session.target`, agent SSH, portails. **Aucun équivalent packagé
pour Hyprland dans Fedora, et `uwsm` n'y est pas non plus.**

`nas-infoadmin.service` en dépend (`After=`/`PartOf=`/`WantedBy=graphical-session.target`).

- [ ] Assurer la propagation d'environnement et l'existence de `graphical-session.target`
- [ ] **Vérifier l'effet, pas la commande** : `systemctl --user status graphical-session.target`,
      `env | grep WAYLAND`, et le montage NAS de bout en bout

### Configuration

- [ ] Réécrire la config : **AZERTY en codes physiques** (pas en symboles — voir le piège
      `bindsym`/`bindcode` dans `CLAUDE.md`), disposition des trois écrans, espaces de
      travail, liaisons `noctalia msg …` reprises de `dotfiles/sway/`
- [ ] Créer le paquet `dotfiles/hypr/`

## 5. Shell — Noctalia

- [ ] `sudo dnf install noctalia` (5.0.0~beta.10 dans `updates`)
- [ ] Vérifier l'intégration Hyprland native (espaces, fenêtres, sorties, actions de session)

## 6. Greeter — greetd + greeter Noctalia

`greetd` 0.10.3 est packagé. Le greeter Noctalia est un **projet séparé à compiler**, et
`greetd` reste obligatoire : c'est lui qui démarre le compositeur wlroots embarqué du
greeter.

```bash
sudo dnf install meson gcc-c++ just greetd dbus \
  wayland-devel wayland-protocols-devel wlroots-devel \
  libEGL-devel mesa-libGLES-devel freetype-devel fontconfig-devel \
  cairo-devel pango-devel harfbuzz-devel libxkbcommon-devel glib2-devel \
  tomlplusplus-devel json-devel stb_image_resize2-devel libwebp-devel librsvg2-devel
```

`wlroots-devel` 0.20.2 (dépôt `updates`) fournit bien `pkgconfig(wlroots-0.20)`.

- [ ] Cloner `noctalia-dev/noctalia-greeter` et **noter le commit exact** — « depuis
      `main` » n'est pas reproductible
- [ ] **Lire `scripts/setup_greeter_system.sh` en entier avant de l'exécuter** : il tourne
      en root et modifie l'état système
- [ ] `just configure-release && just build-release && sudo meson install -C build-release`
- [ ] `sudo ./scripts/setup_greeter_system.sh`
- [ ] Configurer `/var/lib/noctalia-greeter/greeter.toml` (curseur, **disposition clavier**,
      échelle des sorties, extinction par inactivité)
- [ ] Noter le préfixe d'installation retenu — `/usr/local` par défaut, **hors de `dnf`**

## 7. Trousseau — gnome-keyring

```bash
sudo dnf install gnome-keyring gnome-keyring-pam
```

`gnome-keyring-pam` ne dépend que de `gnome-keyring`, `pam` et `libselinux` : **il ne tire
pas GDM**.

GDM n'existant plus, ses trois lignes PAM sont à porter dans `/etc/pam.d/greetd` — sans
elles, le trousseau n'est pas déverrouillé au login et le montage NAS échoue :

```
auth      optional  pam_gnome_keyring.so
password  optional  pam_gnome_keyring.so use_authtok
session   optional  pam_gnome_keyring.so auto_start
```

- [ ] Paquets installés
- [ ] Trois lignes ajoutées à `/etc/pam.d/greetd`
- [ ] **Vérifié après un vrai login** : `org.freedesktop.secrets` détenu, montage NAS actif

## 8. Plomberie freedesktop et applications

- [ ] `gvfs`, `gcr`, `xdg-desktop-portal-*`
- [ ] `nautilus` — installable seul, vérifié (89 exigences, aucun composant de bureau).
      Nécessaire au moins pour **écrire le mot de passe NAS dans le trousseau**, ce que
      `gio mount` ne sait pas faire
- [ ] `chromium`
- [ ] `foot` — provisoire, kitty envisagé
- [ ] `keepassxc`

## 9. Dotfiles

```bash
sudo dnf install stow
cd ~/linux/dotfiles
# écarter d'abord les fichiers par défaut de la distro : stow ne remplace jamais
# un vrai fichier — c'est une sécurité, pas un bug
stow -v -t ~ bash git nas desktop foot        # + hypr quand il existera
```

- [ ] Liens posés et vérifiés

## 10. Instantanés

- [ ] `snapper`, configurations `root` et `home`
- [ ] **Convertir `/var/lib/libvirt/images` en sous-volume AVANT tout instantané**
- [ ] `snapper-timeline.timer` et `snapper-cleanup.timer`
- [ ] `grub-btrfs` — **hors dépôt Fedora**, origine et version à noter ici. Puis
      `grub2-mkconfig` et **vérifier que des entrées d'instantané apparaissent vraiment**
      au menu : la documentation dit que le `/boot` séparé est géré, elle ne prouve pas
      que ça marche sur cette machine
- [ ] Répéter **à froid** la porte de sortie manuelle (`e` au menu GRUB, puis
      `rootflags=subvol=.snapshots/<N>/snapshot`), pas le jour où ça casse

## 11. Reprise depuis l'ancien disque

- [ ] VM Windows : image `*.qcow2`, **le NVRAM `*_VARS.qcow2`** (celui qu'on oublie, il
      porte les variables UEFI), et `virsh dumpxml`. Copier avec `cp --sparse=always`,
      puis `restorecon` — `mv` conserverait l'étiquette SELinux d'origine et `qemu`,
      confiné, ne pourrait pas lire les fichiers
- [ ] Base KeePassXC, profils de navigateur, documents
- [ ] Ces fichiers sont sur `sda3`, sous-volume `root`, et demandent `sudo`

## 12. Vérifications de fin

- [ ] Redémarrage complet : LUKS déverrouillé par TPM, greeter affiché, session ouverte
- [ ] Trousseau déverrouillé, `~/nas` monté
- [ ] Agent SSH fonctionnel, `git ls-remote` aboutit **dans un vrai terminal**
- [ ] Portails : capture d'écran et sélecteur de fichiers
- [ ] Veille / reprise
- [ ] `bin/snapshot.sh` — première capture d'état de ce poste
