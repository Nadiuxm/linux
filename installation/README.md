# Poste de référence — cadrage

> **Ce document est une note de décision, pas un mode opératoire.** Il dit *ce qui a
> été choisi et pourquoi*. Les gestes sont dans `procedure.md`, les mesures et versions
> dans `mesures.md`, le récit daté de la construction dans `journal.md`.
>
> Les mentions de Sway et de GDM qui subsistent ici sont le **récit d'une décision datée**
> (pourquoi Hyprland a remplacé Sway, pourquoi les lignes PAM de GDM ont été portées dans
> greetd), pas une description du poste. Convention posée le 2026-09-07.
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
| `installation/procedure.md` | **le geste** : la commande, dans l'ordre, avec ce qui casse si on l'inverse |
| `dotfiles/` | ce que `stow` restaure |
| `poste/` | l'inventaire vivant, une fiche par outil |

**Un geste qui n'entre dans aucun des trois sera perdu.** C'est le critère à appliquer au
fil de la construction, pas à la fin.

> **`mesures.md` n'est PAS une quatrième destination**, et la distinction compte. Un geste
> va dans `procedure.md` ; ce que sa mesure a appris va dans `mesures.md`. Le découpage du
> 2026-09-08 vient précisément de ce que les deux étaient mélangés : le fichier accumulait
> des constats très complets **sous lesquels des gestes manquaient**, et personne ne le
> voyait en le relisant — seulement en le rejouant.

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
| Terminal | ~~**foot** — provisoire~~ **périmé, voir plus bas** | `dnf` | ~~kitty envisagé à court terme~~ — kitty était installé le jour même |
| Navigateur | **Chromium** | `dnf` | habitude, pas contrainte technique |
| Plomberie freedesktop | `gvfs`, `gcr`, `xdg-desktop-portal-*` | `dnf` | ce n'est pas « GNOME le bureau » |
| Non retenu | GNOME Shell, Mutter, gnome-session, GDM, Évince, Logiciels | — | rien n'en dépend une fois Hyprland et Noctalia posés |

**Quatre lignes à ajouter, relevées par l'audit du 2026-09-07** — elles étaient sur la
machine sans être dans ce tableau, et deux d'entre elles sont des briques de travail, pas
des accessoires :

| Composant | Choix | Obtention | Raison |
|---|---|---|---|
| **Support à distance** | **RustDesk** 1.4.9 | **RPM généré par Julien**, hors dépôt | c'est l'outil de traitement des tickets ; le RPM porte l'adresse du serveur et la clé de relais, donc il se **régénère**, il ne se télécharge pas |
| **Virtualisation** | `qemu-kvm` 10.2.2 + `libvirt` 12.0.0 + `virt-manager` 5.1.0, `edk2-ovmf`, `swtpm-tools` | `dnf` | hôte de la VM Windows d'administration ; `edk2-ovmf` et `swtpm-tools` sont **obligatoires** pour Windows 11 (UEFI Secure Boot + TPM émulé) |
| **Terminal** | **kitty** 0.47.1 | `dnf` | **tranché le 2026-09-04**, et non écrit pendant trois jours : c'est kitty qui tourne, `foot` est installé mais inutilisé |
| Applications Flatpak | Mattermost 6.3.0, WinBox 4.3 | Flathub, portée **`system`** | seul canal identique d'une distro à l'autre — mais voir la nuance du 2026-09-07 dans `poste/README.md` |

La ligne « Terminal — **foot** — provisoire » du tableau ci-dessus est donc **périmée**.
Elle est laissée telle quelle plutôt que réécrite : c'est l'état au 2026-09-04, et le fait
que la décision ait mis trois jours à atterrir dans le dépôt est lui-même la donnée
intéressante.

### Deux propriétés du socle qui ne figuraient nulle part

**Secure Boot est actif** (`enabled (deployed)`, `shim-x64` 16.1-5, amorçage par
`shimx64.efi`). Ça ne gêne rien aujourd'hui et ça se saura le jour où un module noyau non
signé refusera de se charger — le symptôme sera « module introuvable », sans mention de
signature. À connaître avant d'y perdre une heure.

**La machine n'est PAS jointe au domaine**, et c'est mesuré, pas déduit : `authselect
current` → profil **`local`**, et `/etc/sssd/` ne contient **aucun `sssd.conf`**. Pourtant
`sssd.service` est `enabled` — c'est un préréglage de Fedora, pas une configuration.
D'où un piège de méthode qui vaut au-delà de ce cas : **un service activé n'est pas un
service configuré.** L'authentification est locale ; le NAS s'atteint par un secret dans le
trousseau, pas par un ticket de domaine.

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
- **La plomberie systemd : `uwsm` la fournit déjà. La facture annoncée ici n'existe pas.**
  Cette ligne disait le contraire jusqu'au 2026-09-04 — « à remonter à la main, c'est le
  vrai coût, Hyprland n'a pas d'équivalent packagé dans Fedora et `uwsm` non plus ».
  **C'était faux sur les deux moitiés.** `uwsm` 0.26.7 est sur la machine depuis
  l'installation d'Hyprland : c'est une *dépendance faible* du COPR `dtutila/hyprland`,
  donc tirée sans qu'on l'ait demandée ni vue passer. Il livre `wayland-wm@.service`,
  `wayland-session@.target`, `wayland-wm-env@.service`, les trois slices graphiques et
  `wayland-session-xdg-autostart@.target`. Et le paquet `hyprland` livre lui-même
  `/usr/share/wayland-sessions/hyprland-uwsm.desktop`, dont l'`Exec=uwsm start -e -D
  Hyprland hyprland.desktop` suit à la lettre la recommandation du README d'uwsm —
  référencer une autre entrée plutôt qu'un exécutable.
  Ce qui restait vrai : `sway-systemd` n'a pas d'équivalent **Hyprland** packagé, et
  `graphical-session.target` était bien **inactive**. Mais parce qu'Hyprland était lancé
  **à la main depuis un tty**, pas parce que l'outil manquait.
  **Deux leçons.** Le piège maison « vérifier si la distro n'a pas déjà traité le
  problème » s'appliquait bel et bien — l'erreur a été de conclure l'inverse sans
  chercher. Et un paquet arrivé par une dépendance *faible* n'apparaît dans aucune des
  listes qu'on lit spontanément : ni dans ce qu'on a tapé, ni dans les `Requires`.

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

| Composant | Origine | Relevé au 2026-09-07 |
|---|---|---|
| **Hyprland** | COPR | `dtutila/hyprland`, `hyprland` **0.56.2-3.fc44** + 12 autres paquets |
| **greeter Noctalia** | sources, `meson install` dans `/usr/local` | tag **`v1.3.1`** = commit **`6379fe287bb02b0bb538ad155fe18b1bf8615daf`** (2026-09-02). **11 fichiers**, aucun possédé par un RPM |
| **`grub-btrfs`** | COPR | `pego-copr/grub-btrfs`, **4.14-1.fc44**, script `master-2026-05-31T15:55:08+00:00` |
| **RustDesk** | **RPM local, `@commandline`** | `rustdeskadmin` **1.4.9-0**, non signé, construit le 2026-09-01. Le RPM se **régénère** depuis la console de l'entreprise, il ne se télécharge pas |

**Ils sont donc quatre, pas trois — et le quatrième est le plus fragile.** Les trois
premiers se retrouvent : un COPR reste interrogeable, un commit git reste clonable. Le RPM
RustDesk, lui, n'existe nulle part publiquement : il est produit à la demande et porte des
paramètres d'entreprise. **La seule trace réutilisable est le numéro de version**, et le
geste de reproduction n'est pas « retélécharger » mais « regénérer ».

**Comment repérer un composant hors dépôt dans un inventaire**, puisque c'est la difficulté
de fond — trois questions, trois commandes :

```bash
# 1. Quels paquets ne viennent pas de Fedora ?  (@commandline = RPM local)
dnf repoquery --installed --qf '%{name}|%{from_repo}\n' | grep -v '|fedora\|updates'

# 2. Qu'y a-t-il dans /usr/local que dnf ignore ?
for f in $(find /usr/local -type f); do rpm -qf "$f" >/dev/null 2>&1 || echo "$f"; done

# 3. Quelles unités systemd sont écrites en dehors de /usr/lib ?
find /etc/systemd/system -maxdepth 1 -type f
```

La troisième a servi : elle a sorti `rustdeskadmin.service` et `grub-btrfsd.service`, tous
deux posés dans `/etc/systemd/system/` par leur paquet — donc **survivants à une
désinstallation**.

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
- ~~**Terminal.**~~ **Tranché : kitty.** Il était installé le 2026-09-04 à 15:56 et c'est
  lui qui tourne depuis — ce point « reporté » ne l'était plus, il n'avait juste pas été
  écrit. Ce qui reste vrai, et qui est maintenant le vrai point ouvert : **le raisonnement
  du `foot.ini` ne s'applique aujourd'hui à rien.** `~/.config/kitty/` est vide, kitty
  tourne sur ses défauts, et les questions du `foot.ini` — `dpi-aware`, échelle Wayland,
  densité du P2725DE à 2560x1440 sur 600 mm — se reposent à l'identique sans avoir été
  reposées. C'est bien une **question** qui survit, pas un réglage : elle attend juste
  qu'on la traite pour kitty.
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
   USB qui joue ce rôle. **Ce troisième point redevient vrai bientôt** : le formatage du
   SSD USB est annoncé (2026-09-07), et la machine redeviendra unique. Une correction peut
   se périmer aussi vite que ce qu'elle corrigeait.
4. **`gnome-keyring` sans GDM n'emporte rien.** Voir plus haut.

**Cinq de plus, relevées par l'audit du 2026-09-07.** Elles ont un point commun qui vaut
d'être nommé : aucune ne vient d'une erreur de raisonnement, toutes viennent d'un **écrit
qui n'a pas suivi un geste posé**. C'est le mode de défaillance principal de ce dépôt, et
il n'est pas corrigé par plus de réflexion — seulement par la relecture périodique contre
la machine.

5. **« Greeter non activé » — FAUX depuis le 2026-09-04.** Le titre de §6 de la procédure
   le disait encore ; `greetd` est `enabled` **et** `active`, et c'est lui qui ouvre la
   session de travail. La bascule était cochée quinze lignes plus bas.
6. **« Terminal : foot, kitty envisagé » — FAUX depuis le 2026-09-04 à 15:56.** kitty était
   installé le jour même de la décision.
7. **« Mise à jour complète » comme étape d'installation — SANS OBJET sur une netinstall.**
   `dnf history` ne contient aucun `upgrade` : le système est né à jour. Le coût de cette
   étape est une propriété de **l'édition de l'image**, pas de la distribution.
8. **`input:resolve_binds_by_sym` vaut `false`, pas `true`.** La note de `CLAUDE.md`
   justifiait le bon geste par la mauvaise raison. Mesuré : `bool: false set: false` — et
   c'est précisément ce `false` qui fait que lier les symboles AZERTY fonctionne, Hyprland
   traduisant le keysym en code de touche via le keymap.
9. **`greeter.toml` n'était nulle part.** Un fichier de configuration écrit à la main,
   root, sous `/var/lib`, donc hors de portée de `stow` et hors de tout paquet : il
   n'appartenait à **aucune** des trois destinations et aurait disparu à la première
   réinstallation. Recopié intégralement dans la procédure. **La règle des trois
   destinations ne suffit pas si personne ne vérifie qu'un geste y a bien atterri** — et
   trois jours ont suffi pour que ce contrôle manque.

## Le poste est monté — état au 2026-09-07

> **Cette liste comptait douze cases vides. Neuf étaient faites.** L'audit complet du
> 2026-09-07 (voir `journal.md`) les a confrontées à la machine une par une. Ce n'est pas
> anodin : une liste de « reste à faire » qui décrit un poste déjà monté ne se contente pas
> d'être inexacte, elle **oriente le travail vers ce qui est déjà fait** et masque les deux
> ou trois choses qui manquent réellement. C'est le même piège que le `[ ]` de `nas` en
> §9 de la procédure, à l'échelle d'un document.

**Fait, et vérifié sur la machine :**

- [x] `grub-btrfs` — COPR `pego-copr/grub-btrfs`, 4.14-1.fc44, **11 entrées générées** et
      sourcées par `grub.cfg`. La décision de garder `/boot` séparé est validée **par la
      mesure**, pas par la documentation seule
- [x] Hyprland depuis le COPR `dtutila/hyprland`, 0.56.2-3.fc44, **13 paquets relevés**
- [x] Propagation d'environnement et `graphical-session.target` — **active**, fournie par
      `uwsm` 0.26.7. La « facture » annoncée n'existait pas
- [x] Config du compositeur réécrite — 61 liaisons, 0 inerte, 9 règles d'espaces, trois
      écrans. **Par symboles AZERTY, pas par codes physiques** : `code:NN` échoue
      silencieusement en Lua (la formulation de cette case était déjà fausse)
- [x] `greetd` + greeter Noctalia compilé — **tag `v1.3.1`, commit
      `6379fe287bb02b0bb538ad155fe18b1bf8615daf`**, scripts système lus avant exécution,
      **en service depuis le 2026-09-04**
- [x] `pam_gnome_keyring.so` — deux des trois lignes étaient déjà livrées par Fedora, la
      troisième a été ajoutée. Trousseau déverrouillé au login, vérifié `Locked = false`
- [x] `nas-infoadmin.service` — vérifié de bout en bout, chaîne complète mesurée
- [x] `stow` — **4 paquets sur 7** (`hypr`, `foot`, `nas`, `uwsm`). Voir ci-dessous
- [x] snapper — configs `root` et `home`, minuteries actives, rétention 7 jours
- [x] VM Windows et son NVRAM récupérés — **elle tourne**, 46 Go réels, agent invité à
      l'écoute
- [x] Version LUKS relevée : **LUKS2**, `aes-xts-plain64`, `argon2id`

**Ce qui manque réellement, par ordre d'importance :**

- [ ] **Enrôler le TPM2 sur LUKS** (`systemd-cryptenroll`). C'est la seule case du départ
      qui n'a pas bougé, et c'est la plus visible au quotidien : phrase de passe à chaque
      démarrage. `luksDump` confirme `Tokens:` vide et **un seul emplacement de clé** —
      donc aussi aucune seconde voie d'ouverture si la phrase est perdue
- [ ] **Poser `bash` et `git`** (`stow`). Sur un poste de lab dont la méthode repose sur
      « retrouver ce qu'on a tapé », tourner avec l'historique par défaut de Fedora
      (1000 lignes, sans horodatage) est la perte la plus concrète des trois paquets
      manquants. `desktop` peut attendre : son unique entrée n'a plus d'objet
- [ ] **Configurer kitty.** Le raisonnement du `foot.ini` ne s'applique à rien tant que
      `~/.config/kitty/` est vide
- [ ] **Nommer la machine.** `hostnamectl` → `(unset)` ; le `fedora` affiché est le nom
      transitoire par défaut
- [ ] Vérifier les portails **à l'usage** (capture d'écran, sélecteur de fichiers) : trois
      processus qui tournent ne prouvent pas qu'un portail répond
- [ ] Veille / reprise — jamais éprouvée, et c'est justement ce que le bare-metal doit dire
- [ ] Répéter **à froid** la porte de sortie GRUB vers un instantané (détail en §10 de la
      procédure). Une procédure de secours jamais exécutée est une intention
