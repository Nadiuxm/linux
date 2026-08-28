# Itération 01 — Fedora 44 Workstation

| | |
|---|---|
| **Distribution** | Fedora Linux 44 (Workstation Edition) |
| **Environnement** | GNOME Shell 50.4, session Wayland |
| **Noyau** | 6.19.10-300.fc44.x86_64 |
| **Installation** | ISO Workstation officielle, options par défaut |
| **Début** | 2026-08-28 |
| **Fin** | — |
| **Statut** | 🟢 en cours |

## Pourquoi celle-ci en premier

Point de départ volontairement banal. Fedora Workstation est la référence de fait
du desktop Linux « moderne » : GNOME récent, Wayland par défaut, noyau très à jour,
SELinux actif. C'est la **baseline** — la distro contre laquelle je comparerai les
suivantes, pas nécessairement celle que je garderai.

Cycle court (~6 mois par version, ~13 mois de support) : bon pour voir vite ce que
donne un système à jour, à surveiller de près pour un poste d'alternance où je ne
veux pas passer mes journées à réparer des mises à jour.

## Configuration installée

Installation par défaut, **mais déjà écartée du strict vanilla** — à garder en tête
en comparant avec les itérations suivantes, qui devront partir du même périmètre :

- Dépôts additionnels : RPM Fusion nonfree (pilote NVIDIA, Steam), google-chrome,
  COPR `phracek/PyCharm`
- Logiciels ajoutés : KeePassXC, Podman, GNOME Boxes, Firefox + Chrome, LibreOffice
- Système de fichiers : **Btrfs** sur `/` et `/home` (sous-volumes), `/boot` en ext4,
  swap sur **zram** (8 Go compressés en RAM, pas de partition swap disque)
- Sécurité : SELinux en mode `Enforcing`, firewalld actif

Détail complet et reproductible dans [`baseline/`](baseline/).

## Ce que je veux évaluer sur cette itération

- **Stabilité au quotidien** : est-ce que les mises à jour cassent quelque chose ?
- **Matériel Dell** : veille/reprise, gestion écrans, audio, périphériques USB.
- **Outillage SRC** : Podman, conteneurs, virtualisation (Boxes/libvirt), Ansible,
  clients réseau. Est-ce que les paquets sont présents et à jour dans les dépôts ?
- **SELinux** : combien de fois est-ce qu'il me gêne, et est-ce que je sais le diagnostiquer ?
- **Frictions Wayland** : partage d'écran, outils X11 anciens, accès distant.

## Verdict

*À remplir en fin d'itération, avant la bascule.*

| Critère | Note /5 | Commentaire |
|---|---|---|
| Stabilité | | |
| Support matériel | | |
| Outillage SRC | | |
| Documentation / communauté | | |
| Confort quotidien | | |

**Conclusion :**
