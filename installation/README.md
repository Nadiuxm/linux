# Poste de référence — cadrage

> **Ce document est une note de décision, pas un mode opératoire.** Il dit *ce qui a
> été choisi et pourquoi*. La séquence rejouable est dans `procedure.md`, le récit
> daté de la construction dans `journal.md`.
>
> Ouvert le 2026-09-04, au lendemain de l'installation.

## Ce que c'est — et pourquoi ce n'est plus « l'installation finale »

`poste/README.md` parlait d'une « installation finale » : une seule pile, aucune brique
inutile, par opposition au lab où l'accumulation est volontaire. Cette machine est bien
cette pile-là.

Mais **« finale » est le mauvais mot**, et le corriger n'est pas cosmétique : une
réinstallation dans trois à six mois est explicitement envisagée. C'est donc un **poste
de référence** — la pile choisie, épurée, celle qui sert à travailler, mais **rejouable**.

Ça ajoute une exigence que la note du 2026-09-03 n'avait pas, parce qu'elle croyait
décrire un aboutissement : **cette install doit être reproductible.** Un journal explique
pourquoi ; il ne rebâtit pas une machine.

### La règle des trois destinations

Tout geste posé sur ce poste doit atterrir dans **exactement un** des trois :

| Destination | Contenu |
|---|---|
| `installation/procedure.md` | la séquence rejouable, dans l'ordre : paquets, COPR, commits, lignes PAM, enrôlement TPM |
| `dotfiles/` | ce que `stow` restaure |
| `poste/` | l'inventaire vivant, une fiche par outil |

**Un geste qui n'entre dans aucun des trois sera perdu.** C'est le critère à appliquer au
fil de la construction, pas à la fin.

## Les deux disques — les rôles se sont inversés

| | Rôle | Contenu |
|---|---|---|
| **NVMe interne** (KIOXIA BG6, 238 Go) | **le poste réel** — chiffré, vissé, qui doit durer | ce cadrage |
| **SSD USB** (« Generic PCIE », 233 Go) | **le lab** — formaté à volonté | itération 01 (Fedora 44 Workstation), intacte |

L'itération 01 vivait sur le disque **externe**, et le disque interne portait un Windows
de secours. C'est inversé : le Windows a disparu, le poste de travail est passé à
l'intérieur, et l'externe est libre.

**Ça dissout la contrainte fondatrice du dépôt.** Depuis le 2026-08-28, la méthode
reposait sur : « chaque réinstallation efface la machine, ce dépôt compris ». Ce n'est
plus vrai. Une itération sur le disque externe ne touche plus ni le poste, ni le dépôt.
Et ça reste du bare-metal sur la vraie machine, exactement comme l'itération 01 : le
ressenti matériel garde toute sa valeur.

**Le risque, à voir en face.** La méthode tirait sa force de « je suis obligé de vivre
dedans ». Avec un poste confortable sur le disque interne, une distro de test sur
l'externe risque d'être visitée une heure et jamais éprouvée. Ce qui donnait du poids aux
notes, c'était la contrainte ; en la levant, il faut la remplacer par une discipline
explicite — **une itération ne compte que si elle a porté du travail réel pendant
plusieurs jours** — sinon l'axe distro meurt en silence, sans que personne ne le décide.

## Ce qui s'est décidé à l'installation, et ne se rattrape pas

### Chiffrement — LUKS, fait

`nvme0n1p3` en `crypto_LUKS`, Btrfs à l'intérieur. Le point ouvert « disque non chiffré »
du `CLAUDE.md`, qui traînait depuis le 2026-09-01, est soldé.

**Reste à faire : l'enrôlement TPM2**, pour ne pas saisir la phrase de passe à chaque
démarrage. Le matériel est vérifié sur cette machine : `/dev/tpm0` présent,
`systemd-analyze has-tpm2` → `yes` (firmware, pilote, sous-système, bibliothèques),
`systemd-cryptenroll` installé.

### Partitionnement — `/boot` séparé, **conservé sciemment**

```
nvme0n1p1   600 Mo  vfat   /boot/efi
nvme0n1p2     2 Go  ext4   /boot        <- séparé
nvme0n1p3   236 Go  LUKS -> btrfs       /  et  /home  (sous-volumes root, home)
```

C'est la disposition Fedora par défaut, et **elle contredit la décision du 2026-09-04**,
qui exigeait `/boot` *dans* le sous-volume Btrfs pour `grub-btrfs`. Cette décision était
fondée sur une prémisse fausse — voir « Corrections » plus bas.

La disposition est **gardée**, pour une raison qui n'avait pas été vue :

| Disposition | `grub-btrfs` | Déverrouillage TPM |
|---|---|---|
| `/boot` ext4 séparé (**retenu**) | ✅ géré nativement | ✅ |
| `/boot` dans le Btrfs chiffré | ✅ | ❌ |

`grub-btrfs` gère un `/boot` séparé : il prend le noyau sur la partition `/boot` vivante
et y ajoute `rootflags=subvol=<instantané>`. À l'inverse, si `/boot` était chiffré, **GRUB
devrait ouvrir LUKS lui-même** — et son `cryptomount` ne connaît que la phrase de passe et
le fichier clé, **aucun support TPM2**. On taperait donc le mot de passe à chaque
démarrage, et l'enrôlement TPM ne servirait plus à rien.

**Limitation acceptée :** le noyau vient du `/boot` vivant, pas de l'instantané. Remonter
un instantané pris avant une mise à jour de noyau donne un décalage avec
`/lib/modules`. Contournement : choisir aussi l'ancienne entrée de noyau au menu GRUB —
Fedora en garde trois.

### Image — Everything/netinstall, minimale

`os-release` n'a **pas** de champ `VARIANT` (l'itération 01 avait
`VARIANT="Workstation Edition"`). **53 paquets explicites, 419 au total**, aucun bureau,
cible `multi-user.target`.

C'est la réponse à la question du 2026-09-03 : « peut-on aller directement à la cible sans
poser tout GNOME ? ». Oui — page blanche, on compose.

**Conséquence de méthode :** cette install **n'est pas une itération** et n'entre pas dans
la numérotation de `journal/`. Une baseline comparée à celle de l'itération 01 mesurerait
l'image ISO (53 paquets contre 357), pas la distribution — et c'est la même distribution,
Fedora 44 dans les deux cas. Le protocole de baseline ne s'applique pas ici, comme il ne
s'applique pas à `poste/`.

## La pile retenue

| Composant | Choix | Obtention | Raison |
|---|---|---|---|
| Compositeur | **Hyprland** | **COPR** — absent des dépôts Fedora | voir ci-dessous |
| Shell (barre, lanceur, notifications, fond, OSD, verrouillage) | **Noctalia** 5.0.0~beta.10 | `dnf` (`updates`) | intégration Hyprland **native** |
| Greeter | **greetd** + **greeter Noctalia** | `greetd` par `dnf` ; le greeter **depuis les sources** | cohérence visuelle avec le shell |
| Trousseau / Secret Service | **`gnome-keyring`** + `gnome-keyring-pam` | `dnf` | statu quo assumé ; KeePassXC reporté |
| Gestionnaire de fichiers | **Nautilus** | `dnf` | installable seul (89 exigences, zéro composant de bureau) |
| Terminal | **foot** — provisoire | `dnf` | kitty envisagé à court terme |
| Navigateur | **Chromium** | `dnf` | habitude, pas contrainte technique |
| Plomberie freedesktop | `gvfs`, `gcr`, `xdg-desktop-portal-*` | `dnf` | ce n'est pas « GNOME le bureau » |
| Non retenu | GNOME Shell, Mutter, gnome-session, GDM, Évince, Logiciels | — | rien n'en dépend une fois Hyprland et Noctalia posés |

### Hyprland — la raison, écrite pour tenir six mois

> **Hyprland pour les animations, les coins arrondis et le flou, que Sway ne peut
> structurellement pas fournir.** La chrome de Sway avait déjà été réduite au minimum
> (`default_border pixel 2`, aucune barre de titre) : le manque restant n'est pas un
> défaut de configuration.

Formulé « Sway est moche », le choix ne tiendrait pas : Sway ne peignait plus que des
bordures de 2 px, tout le reste du visible étant à Noctalia. Ce qui manque relève d'un
choix amont de wlroots, pas d'un réglage — d'où le changement de compositeur.

**Conséquence de méthode :** le point ouvert « ressenti Sway à froid » est **clos sans
verdict, sur un abandon avant mesure**. Il faut que ce soit écrit : sinon, dans six mois,
on ne saura plus si Sway avait été jugé ou seulement traversé.

### Ce que le changement de compositeur coûte

- **418 lignes de config Sway à réécrire.** Le travail AZERTY en `bindcode` (codes lus
  dans `/usr/share/X11/xkb/keycodes/evdev`), les trois écrans, l'affectation des espaces :
  la **leçon** se transpose, le fichier non. Les ~15 liaisons `noctalia msg …` se
  transposent presque telles quelles. `dotfiles/sway/` est **gardé** : il ne coûte rien et
  documente la solution AZERTY, valable pour tout WM tuilant.
- **La plomberie systemd est à remonter à la main.** C'est le vrai coût. Sous Fedora,
  `/etc/sway/config.d/10-systemd-session.conf` lançait `sway-systemd/session.sh`, qui
  propageait l'environnement vers systemd et D-Bus (`WAYLAND_DISPLAY`,
  `XDG_CURRENT_DESKTOP`), démarrait `sway-session.target`, l'agent SSH et les portails.
  **Hyprland n'a pas d'équivalent packagé dans Fedora, et `uwsm` non plus.**
  Or `nas-infoadmin.service` est en `After=`/`PartOf=`/`WantedBy=graphical-session.target`.
  C'est l'inversion exacte du piège maison « vérifier si la distro n'a pas déjà traité le
  problème » : ici, **elle ne l'a pas fait**.

### Le greeter — trois choses vérifiées le 2026-09-04

La note du 2026-09-03 disait « le greeter Noctalia existe, mais pas dans le paquet Fedora,
à vérifier avant de compter dessus ». Vérifié :

1. **Toujours aucun fichier de greeter** dans le paquet `noctalia` 5.0.0~beta.10. Le
   greeter est un **projet séparé** : `noctalia-dev/noctalia-greeter`.
2. **`greetd` reste obligatoire** — « It is built for greetd: greetd starts the bundled
   wlroots compositor ». Le greeter Noctalia remplace `tuigreet`/`gtkgreet`, **pas**
   `greetd`.
3. **Il embarque son propre compositeur wlroots** (`noctalia-greeter-compositor`), pas
   Hyprland. Donc wlroots reste sur la machine pour l'écran de connexion, alors que le
   bureau le quitte. Sans conséquence pratique, mais à savoir avant de s'en étonner.

Toutes les dépendances de compilation sont dans Fedora 44, y compris **`wlroots-devel`
0.20.2** (`updates`) qui fournit `pkgconfig(wlroots-0.20)`. Rien à chercher ailleurs.

L'installation est une **compilation** — `just`, `meson`, `sudo meson install` dans
`/usr/local`, donc **hors de la connaissance de `dnf`** — suivie de
`sudo ./scripts/setup_greeter_system.sh`. Ce script s'exécute en root et modifie l'état
système : **à lire en entier avant**, comme `/etc/sway/config` l'avait été.
Configuration dans `/var/lib/noctalia-greeter/greeter.toml`.

### Le trousseau — et les trois lignes PAM qui vont avec

`gnome-keyring` est **gardé pour l'instant**. Le passage à KeePassXC en fournisseur Secret
Service est **reporté**, pas abandonné.

Ce que ça impose : GDM n'existe plus, donc les trois lignes de sa pile PAM sont à porter
dans `/etc/pam.d/greetd` — sans elles, le trousseau n'est pas déverrouillé au login et
`nas-infoadmin.service` échoue.

```
auth      optional  pam_gnome_keyring.so
password  optional  pam_gnome_keyring.so use_authtok
session   optional  pam_gnome_keyring.so auto_start
```

**Moins coûteux que le journal ne le craignait :** `gnome-keyring-pam` 50.0 ne dépend que
de `gnome-keyring`, `pam` et `libselinux` — **aucune trace de GDM**. La chaîne
`gdm → gnome-keyring-pam → gnome-keyring` du 2026-09-04 ne se lit que dans un sens :
retirer `gnome-keyring` emporterait GDM, mais **garder `gnome-keyring` sans GDM est
gratuit**.

## Les composants hors dépôt — et ce que ça coûte à la reproductibilité

Trois, et c'est le point où l'exigence « rejouable » coûte quelque chose de réel :

| Composant | Origine | Ce que la procédure doit noter |
|---|---|---|
| **Hyprland** | COPR | le nom exact du COPR **et** la version installée |
| **greeter Noctalia** | sources | le **commit exact**, pas « depuis `main` » |
| **`grub-btrfs`** | hors dépôt Fedora — vérifié le 2026-09-04, `dnf` ne connaît rien de ce nom | l'origine retenue et la version |

« Compilé depuis `main` » n'est pas une instruction reproductible : dans six mois ce ne
sera pas le même logiciel. Et un `sudo meson install` dans `/usr/local` n'est suivi par
aucun gestionnaire de paquets — ce que `dnf` ne connaît pas, seule la procédure le sait.

Point de vigilance sur le COPR : Fedora livre déjà les *bibliothèques* Hyprland
(`hyprutils`, `hyprlang` 0.6.4, `hyprgraphics` 0.1.5, `hyprcursor` 0.1.11,
`hyprland-protocols` 0.4.0) sans le compositeur. Un Hyprland de COPR peut exiger des
versions divergentes de ces bibliothèques : **décalage de versions à surveiller** à chaque
mise à jour. Sway était dans les dépôts officiels avec un groupe dédié — c'est une donnée
de comparaison en soi, comme la note du 2026-09-03 l'annonçait.

## Décisions reportées

- **KeePassXC en fournisseur Secret Service.** Faisabilité prouvée le 2026-09-04
  (chaîne KeePassXC → FdoSecrets → `libsecret` → `gvfsd` → SMB, sans `gnome-keyring`),
  mais **l'ordonnancement au login n'est pas testé** — et c'est tout le chantier. Piste
  notée : `keepassxc.service` en `Type=dbus` + `BusName=org.freedesktop.secrets`, avec
  `nas-infoadmin.service` en `After=`. Ne couvre pas « la base est déverrouillée ».
- **Terminal.** `foot` est en place et sa config rapatriée, mais kitty est envisagé à court
  terme. Chaque terminal est un paquet `stow` indépendant : le changement est mécanique.
  Ce qui doit survivre, c'est le **raisonnement** du `foot.ini` — `dpi-aware`, échelle
  Wayland, densité du P2725DE — qui se posera à l'identique ailleurs, comme une
  **question**, pas comme un réglage.
- **Retrait de Firefox** — envisagé le 2026-09-03, jamais décidé. Sans objet ici : l'image
  minimale ne l'a pas installé.

## Corrections apportées aux notes antérieures

Quatre affirmations du dépôt sont devenues fausses, ou l'étaient déjà :

1. **`grub-btrfs` exige `/boot` dans le Btrfs — FAUX.** Le README amont annonce
   « Automatically detect if `/boot` is in a separate partition », et
   `GRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION` existe pour les cas où la détection
   échoue. La prémisse « le `boot/` d'un instantané est vide, donc aucune entrée n'est
   générée » n'avait jamais été confrontée à la documentation de l'outil. À corriger dans
   l'entrée de journal du 2026-09-04 et dans `poste/README.md`.
2. **« Installation finale » → poste de référence.** Voir plus haut : une réinstallation
   est envisagée, donc la reproductibilité devient une exigence.
3. **La section « Machine » de `CLAUDE.md` est périmée sur trois points** : le Windows
   interne de secours n'existe plus, le système ne vit plus sur un disque externe, et
   « il n'y a pas de second poste de secours » est faux — c'est l'itération 01 sur le SSD
   USB qui joue ce rôle.
4. **`gnome-keyring` sans GDM n'emporte rien.** Voir plus haut.

## Reste à faire avant de considérer le poste monté

- [ ] Enrôler le TPM2 sur LUKS (`systemd-cryptenroll`)
- [ ] Vérifier la version LUKS de `nvme0n1p3` (`cryptsetup luksDump`)
- [ ] Installer `grub-btrfs` (**hors dépôt Fedora** — origine à choisir) et **vérifier
      qu'il génère bien des entrées** avec ce `/boot`. C'est la case qui valide ou
      invalide la décision de partitionnement par l'expérience : à faire tôt.
- [ ] Hyprland depuis le COPR, version notée
- [ ] Remonter la propagation d'environnement et `graphical-session.target` sans
      `sway-systemd`
- [ ] Réécrire la config du compositeur : AZERTY en codes physiques, trois écrans, espaces
- [ ] `greetd` + greeter Noctalia compilé, commit noté, script système lu avant exécution
- [ ] Les trois lignes `pam_gnome_keyring.so` dans `/etc/pam.d/greetd`
- [ ] `nas-infoadmin.service` vérifié de bout en bout après le premier login réel
- [ ] `stow` et pose des liens depuis `dotfiles/`
- [ ] snapper, et `grub-btrfs` conditionné à la case ci-dessus
- [ ] Récupérer la VM Windows et son NVRAM depuis le disque externe (`sudo` requis)
