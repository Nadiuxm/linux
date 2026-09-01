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

**Install strictement vierge jusqu'à la capture de la baseline (28 août).** C'est
délibéré : une baseline ne vaut que si elle est reproductible à l'identique sur les
distros suivantes. Ce qui a été ajouté ensuite est daté ci-dessous et relève d'un
second axe — voir « Second axe » plus bas.

Chronologie réelle, lue dans `dnf history` :

| Date | Transaction | Contenu |
|---|---|---|
| 22 avr. 2026 | 1 – 2 (`kiwi`) | Construction de l'image ISO **chez Fedora**. Pas une action de ma part : c'est la date de fabrication de l'ISO. |
| 28 août 16:09 | 3 | Langpacks français (`langpacks-fr`, dictionnaires LibreOffice, `man-pages-fr`). Déclenché **automatiquement** par le choix de langue au premier démarrage. |
| 28 août 16:18 | 4 | `dnf update` — 1550 paquets |
| 28 août 16:29 | 5 | `dnf install keepassxc` — 16 paquets |
| 28 août 17:02 | 6 | `dnf install stow` — 3 paquets (outillage du lab) |
| 1er sept. 09:50 | 7 | `dnf update` — 111 paquets. Aucun problème constaté. |
| 1er sept. 10:01 | 8 | `dnf group install swaywm` — 38 paquets. **Hors protocole de baseline**, voir plus bas. |
| 1er sept. 14:45 | 9 | `dnf install ./rustdeskadmin-x86_64.rpm` — 5 paquets. Client **RustDesk** d'administration des postes utilisateurs, utilisé en résolution de ticket (équivalent libre de TeamViewer). Paquet généré par mes soins, donc disponible dans n'importe quel format (`.deb`, `.pkg.tar.zst`…) : **ce n'est pas une contrainte de distro**. Hors protocole de baseline. |
| 1er sept. 16:09 | 10 | `dnf install noctalia` — 9 paquets. Shell Wayland complet, remplace swaybar et wmenu. **Hors protocole de baseline**, même cadre que la transaction 8. |

Deux `dnf install` volontaires, et ils ne jouent pas le même rôle :

- **KeePassXC** — logiciel personnel, contrainte de travail (voir plus bas)
- **`stow`** — outillage du lab lui-même, sans lequel les dotfiles ne se
  réappliquent pas sur la distro suivante

`git` n'apparaît pas : il est déjà dans l'image Fedora Workstation.
Tout le reste vient de l'image de base ou de la mise à jour.

### Le protocole à reproduire

C'est la séquence exacte à rejouer sur chaque distro testée, sans y ajouter quoi
que ce soit — sinon je ne compare plus les distros mais mes propres bricolages :

> **install par défaut → mise à jour complète → KeePassXC → git + stow → rien d'autre**

Le temps passé sur chaque étape est lui-même une donnée : si obtenir KeePassXC
demande trois manipulations sur une distro et zéro sur une autre, c'est noté.

### Second axe : environnements de bureau (hors baseline)

Le 1er septembre, Sway (WM tuilant Wayland) a été installé — **transaction 8, 38 paquets**.
C'est une sortie assumée du protocole ci-dessus, et elle demande d'être cadrée pour ne
pas fausser le verdict de cette itération :

- **Elle ne pollue pas la baseline.** Celle-ci était capturée et poussée depuis le
  28 août ; `baseline/` décrit toujours la machine vierge. Tout ce qui a suivi est
  daté dans `dnf history` et défaisable (`sudo dnf history undo 8`).
- **Ce n'est pas le même axe d'évaluation.** Le protocole compare des *distributions* ;
  Sway relève du choix de l'*environnement de travail*, second objectif du projet.
  GNOME reste la session par défaut, Sway s'ajoute dans GDM sans rien remplacer.
- **Un WM tuilant a été choisi précisément pour ça** : il n'entre en concurrence avec
  rien. Un bureau complet type KDE aurait tiré SDDM face à GDM déjà actif, et là
  l'itération aurait été réellement contaminée.

Conséquence pour le verdict plus bas : les notes « distro » se jugent sur la baseline
du 28 août. Si l'axe bureaux prend de l'ampleur (KDE, Xfce), il aura son propre dossier.

### Les dépôts tiers ne sont pas des ajouts

Quatre dépôts non-Fedora sont activés (google-chrome, RPM Fusion nonfree NVIDIA,
RPM Fusion nonfree Steam, COPR `phracek/PyCharm`). Ce ne sont **pas** des ajouts
manuels : les fichiers `.repo` appartiennent au paquet `fedora-workstation-repositories`,
livré dans l'image de base et désactivé par défaut.

```console
$ rpm -qf /etc/yum.repos.d/google-chrome.repo
fedora-workstation-repositories-38-9.fc44.x86_64
```

La case « Activer les dépôts tiers » de l'écran de bienvenue les bascule sur
`enabled=1`. Rien n'en a été installé pour autant : `google-chrome-stable` n'est
pas présent sur le système, le dépôt est simplement ouvert et disponible.

À retenir pour la comparaison : cette facilité est **spécifique à Fedora**. Sur
Debian ou openSUSE, obtenir les codecs, le pilote propriétaire ou Chrome demandera
des manipulations à chronométrer — ce sera une donnée de comparaison à part entière.

### Caractéristiques héritées de l'installateur

- **Btrfs** sur `/` et `/home` (sous-volumes), `/boot` en ext4, `/boot/efi` en vfat
- Swap sur **zram** — 8 Go compressés en RAM, aucune partition swap sur disque
- **SELinux** en mode `Enforcing`, firewalld actif

Détail complet et reproductible dans [`baseline/`](baseline/).

## Contrainte non négociable : KeePassXC

KeePassXC n'est pas un confort, c'est mon accès à mes mots de passe personnels.

**Conséquence : c'est un critère éliminatoire, pas une ligne de note.** Une distro
qui ne le fournit pas facilement n'est pas évaluable, quelles que soient ses autres
qualités. À vérifier **avant** d'installer quoi que ce soit :

- présent dans les dépôts officiels ? à quelle version ?
- sinon, disponible en Flatpak — et l'intégration au trousseau/navigateur suit-elle ?

Ici : `keepassxc-2.7.12`, dépôt Fedora officiel, sans manipulation. C'est la
référence à battre.

> La base `.kdbx` est exclue du dépôt par le `.gitignore`, volontairement.
> Mais l'exclure de git signifie que **rien ne la sauvegarde automatiquement** :
> c'est le point le plus dangereux de la méthode bare-metal. Sauvegarde hors machine
> obligatoire avant chaque bascule (voir `journal/README.md`, étape 5).

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
| KeePassXC disponible | *éliminatoire* | ✅ dépôt officiel, 2.7.12, sans manipulation |
| Stabilité | | |
| Support matériel | | |
| Outillage SRC | | |
| Documentation / communauté | | |
| Confort quotidien | | |

**Conclusion :**
