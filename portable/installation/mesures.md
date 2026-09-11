# Mesures — second poste (portable)

Constats et valeurs exactes, par numéro de section (correspond à `procedure.md`).
L'audit matériel complet (Wi-Fi, audio, empreinte, etc.) et ses correctifs sont dans
`journal.md`, entrée du 2026-09-11 — pas dupliqués ici.

## 1. Installation de base

```
nvme0n1p1   vfat    /boot/efi
nvme0n1p2   ext4    /boot          (séparé)
nvme0n1p3   LUKS2 -> btrfs   subvol=root (/)  subvol=home (/home)
```

- Disque : Samsung 512 Go NVMe (`BM9C1 Samsung 512GB`).
- `bootctl status` → `Secure Boot: enabled`.
- TPM2 : `/dev/tpm0` présent, non enrôlé sur LUKS (`luksDump` : un seul emplacement de clé).
- `localectl status` → `LANG=fr_FR.UTF-8`, `X11 Layout: fr`, `X11 Variant: oss`.
- `timedatectl` → `Europe/Paris`, NTP actif.
- `rpm -qa | wc -l` → 487 paquets, cohérent avec une image minimale.

## 2. Accès au dépôt

`~/.ssh/gitlinux` et `~/.ssh/known_hosts` déjà présents (clonage antérieur à cette
session) mais **aucun `~/.ssh/config`** : `git ls-remote origin` →
`git@github.com: Permission denied (publickey)`. La clé n'était jamais déclarée à `ssh`,
qui ne la propose pas spontanément (nom `gitlinux`, pas `id_rsa`/`id_ed25519`).

## 4. Compositeur — Hyprland

Transaction identique à `uc`, versions à date (2026-09-11, plus récentes que celles
notées dans `uc/installation/mesures.md`) :

```
hyprland-0.56.2-3.fc44          hyprland-guiutils-0.2.2-2.fc44
xdg-desktop-portal-hyprland-1.4.1-1.fc44
xdg-desktop-portal-gtk-1.15.3-3.fc44
noctalia-5.0.1-1.fc44            (uc était en 5.0.0~beta.10 : celle-ci n'est plus bêta)
stow-2.4.1-4.fc44                keepassxc-2.7.12-1.fc44
uwsm-0.26.7-1.fc44               reason=Weak Dependency, from=copr:...:dtutila:hyprland
```

`dnf copr list` → `copr.fedorainfracloud.org/dtutila/hyprland`, seul dépôt tiers activé.

Matériel mesuré au premier lancement (`hyprctl monitors all` / `devices`) :
- Écran : `eDP-1`, LG Display `0x07A8`, 1920x1200@60/48Hz, 340x220mm.
- Clavier réel : `at-translated-set-2-keyboard` (`main: yes`) ; 7 autres entrées sont des
  pseudo-claviers (touches spéciales Dell/Intel, capot, alimentation), pas des claviers.
- Pavé tactile : `ven_0488:00-0488:108b-touchpad` (+ une entrée `-mouse` du même id).
- `kitty-0.47.1-1.fc44`, installé hors ordre (voir `procedure.md` §4.4).
