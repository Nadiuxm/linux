# Procédure — rebâtir ce poste, dans l'ordre

> **Ce fichier ne contient que des GESTES.** Il se déroule de haut en bas sur une machine
> nue et n'explique rien : chaque étape renvoie à `mesures.md`, **même numéro de section
> principale (§1 à §12)**, pour le pourquoi, les versions exactes et ce qui a été appris.
> Les sous-sections (`8bis`, `8ter`…) ont divergé entre les deux fichiers : les renvois les
> nomment explicitement.
>
> **Le test de ce fichier :** *un lecteur qui ne lit que les blocs de code obtient-il la
> machine ?* Si la réponse est non, c'est un défaut de ce fichier, pas du lecteur.
>
> | Fichier | Contenu |
> |---|---|
> | **`procedure.md`** (ici) | les gestes, à l'impératif. **Seule source de ce qu'on tape.** |
> | `mesures.md` | les constats, versions, tableaux de mesure, et ce que chaque étape a appris |
> | `README.md` | les décisions et leurs raisons |
> | `journal.md` | le récit daté de la construction |
>
> **Règle de tenue :** un geste posé sur ce poste s'écrit **ici** le jour même, ou il sera
> perdu. Trois destinations possibles pour un geste — ce fichier, `dotfiles/`, ou `poste/`.
> Rien d'autre. Un geste posé dans `/etc` ou `/var` n'a qu'une destination possible : ici.
>
> Découpé de l'ancien `procedure.md` le 2026-09-08, qui mélangeait les deux et était devenu
> un registre de constats plutôt qu'un mode opératoire.

**Convention :** `→` = la vérification qui dit que l'étape a marché.
`⚠ ORDRE` = étape dont la position est contrainte, avec ce qui casse si on l'inverse.
`✎ INVENTÉ` = geste non attesté dans le dépôt, reconstitué. À confirmer au premier passage.

---

## Étape 0 — prérequis externes, à réunir AVANT de démarrer l'ISO

Rien de ce qui suit n'est dans le dépôt, et c'est volontaire pour les secrets
(`CLAUDE.md`, « Hors périmètre »). L'étape existe parce que le blocage se découvre sinon
à l'étape 2, machine déjà formatée.

| # | À réunir | Bloque à |
|---|---|---|
| 1 | ISO **Fedora 44 Everything netinstall** + clé USB | §1 |
| 2 | **Phrase de passe LUKS** (nouvelle, choisie) | §1 |
| 3 | Mot de passe du compte, **et le compte doit être administrateur** | §1 |
| 4 | **Clé SSH `gitlinux`** (deploy key du dépôt) — ou de quoi en créer une et l'ajouter sur GitHub | **§2 — sans elle, pas de dépôt, donc pas de procédure** |
| 5 | **RPM RustDesk régénéré** depuis la console de l'entreprise | §8ter |
| 6 | **Sauvegarde de la VM** : `win11.qcow2`, `win11_VARS.qcow2`, le XML | §11 |
| 7 | ISO **`virtio-win`** + ISO **Windows 11** + licence — seulement si 6 manque | §11 |
| 8 | **Mot de passe SMB** du partage NAS | §7 |
| 9 | Identifiants de domaine pour la VM, URL Mattermost, accès MikroTik | §11, §8 |
| 10 | **Renseignements réseau employeur** : la nouvelle carte a une **nouvelle MAC** — à déclarer ? 802.1X ? seconde machine sur le port ? | §8quater |
| 11 | Matériel branché **à l'identique** : P2425H → HDMI-A-2, P2725DE → DP-3, P2414H → DP-1 | §4, §6 |

> **Le point 11 n'est pas du confort.** L'ancrage des espaces et les positions d'écran se
> font **par nom de sortie**, donc par port. Un câble déplacé et deux fichiers sont faux.
> Détail : `mesures.md` §4, « Écrans ».

---

## 1. Installation de base

Dans l'installateur, à saisir tel quel :

| Paramètre | Valeur |
|---|---|
| Image | Fedora 44 **Everything netinstall** |
| Cible | **NVMe interne**, `nvme0n1` |
| Chiffrement | **LUKS** sur `nvme0n1p3` |
| Système de fichiers | **Btrfs**, sous-volumes `root` et `home`, `compress=zstd:1` |
| Cible systemd | `multi-user.target` |
| Compte | `jzielona`, **administrateur** |
| Langue / clavier / fuseau | ✎ INVENTÉ — `fr_FR.UTF-8`, AZERTY, `Europe/Paris` |

Partitionnement à obtenir — **le `/boot` séparé est voulu**, raison dans `README.md` :

```
nvme0n1p1   600 Mo  vfat   /boot/efi
nvme0n1p2     2 Go  ext4   /boot          <- séparé, et c'est voulu
nvme0n1p3   236 Go  LUKS -> btrfs         /  (subvol=root)  et  /home  (subvol=home)
```

→ `lsblk -f` reproduit le tableau ci-dessus
→ `bootctl status` → `Secure Boot: enabled (deployed)`

> ✎ **Le fuseau et la disposition console ne sont écrits nulle part dans le dépôt.**
> Un fuseau faux casse Kerberos dans la VM (< 5 min d'écart exigé). Et
> `/etc/X11/xorg.conf.d/00-keyboard.conf` porte `XkbVariant "oss"` sur ce poste, donc la
> variante réellement choisie au premier écran n'est pas connue. À trancher une fois, puis
> à écrire ici.

- [ ] **Enrôler le TPM2 sur LUKS** — `systemd-cryptenroll`. **Jamais fait.** Sans ça,
      phrase de passe à chaque démarrage, et **aucune seconde voie d'ouverture du disque**
      (un seul emplacement de clé). Matériel vérifié : `mesures.md` §1.

## 2. Accès au dépôt

```bash
sudo dnf install git
```

**La clé du dépôt est une deploy key nommée `gitlinux`**, donc `ssh` ne la propose pas
spontanément. Sans ce bloc, le clone échoue sur `Permission denied (publickey)` :

```
# ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/gitlinux
    IdentitiesOnly yes
```

Clé d'hôte GitHub, **après comparaison** avec les empreintes publiées sur
`https://api.github.com/meta` — un `ssh-keyscan` seul ne vérifie rien :

```bash
ssh-keyscan -t rsa,ecdsa,ed25519 github.com > /tmp/gh
ssh-keygen -lf /tmp/gh          # comparer aux 3 empreintes de api.github.com/meta
cat /tmp/gh >> ~/.ssh/known_hosts

git clone git@github.com:Nadiuxm/linux.git ~/linux
```

→ `git ls-remote` aboutit **dans un vrai terminal** (pas dans celui d'un agent)

> ⚠ **ORDRE — ne PAS taper `git config --global` ici.** C'est ce qui crée un `~/.gitconfig`
> réel, et donc le conflit qui fait **refuser `stow git`** en §9. L'identité vient du
> paquet `git` de `dotfiles/`. L'ancienne procédure faisait les deux et fabriquait
> elle-même le conflit qu'elle documentait quinze sections plus bas.

## 3. Mise à jour complète — SANS OBJET

Une netinstall naît à jour : les paquets viennent de `fedora` + `updates` au moment de
l'installation. Aucun geste. Détail et leçon transposable : `mesures.md` §3.

## 4. Compositeur — Hyprland

### 4.0 Pilotes graphiques — EN PREMIER

```bash
sudo dnf install mesa-dri-drivers
```

⚠ **ORDRE — avant tout lancement du compositeur.** Une image minimale n'installe **aucun**
pilote graphique : sans ça **Hyprland ne démarre pas du tout**, et le symptôme ne le
désigne pas.

### 4.1 Le COPR et la transaction

```bash
sudo dnf copr enable dtutila/hyprland
sudo dnf install -y hyprland hyprland-guiutils xdg-desktop-portal-hyprland \
                    xdg-desktop-portal-gtk noctalia stow keepassxc
```

317 paquets. `keepassxc` et `stow` viennent du protocole de baseline du lab, pas
d'Hyprland. `uwsm` arrive avec, en **dépendance faible** — c'est lui qui fournit toute la
plomberie de session.

→ `dnf repoquery --installed --qf '%{name} reason=%{reason} from=%{from_repo}\n' uwsm`
   → `reason=Weak Dependency`
→ les 13 paquets du COPR : liste et versions dans `mesures.md` §4

⚠ **ORDRE, permanent celui-là — tout `dnf upgrade` ultérieur doit voir ce COPR activé**,
sinon Fedora tente de redescendre les bibliothèques `hypr*` que le COPR a remplacées.

### 4.2 La configuration

```bash
cd ~/linux/dotfiles
stow -n -v -t ~ hypr        # simulation d'abord, toujours
stow    -v -t ~ hypr
```

Si `stow` refuse : Hyprland a généré son propre `hyprland.lua`. **L'écarter dans
`~/.dotfiles-backup/`, ne pas forcer** — `stow` ne remplace jamais un vrai fichier, c'est
une sécurité.

→ `~/.config/hypr/hyprland.lua` est un lien vers le dépôt

### 4.3 Premier lancement

⚠ **ORDRE — depuis un AUTRE tty** (`Ctrl+Alt+F3`), pas celui où l'on travaille : lancer
Hyprland depuis le tty courant emporte la session en cours.

```bash
Hyprland
```

Puis, **depuis la session active uniquement** — logind libère les périphériques d'une
session inactive, et une mesure faite ailleurs décrit la mauvaise session :

```bash
loginctl list-sessions                  # UNE seule session attendue
hyprctl monitors                        # trois écrans, positions de mesures.md §4
hyprctl devices                         # claviers en l "fr", v "azerty"
hyprctl binds                           # 61 liaisons, aucune clé contenant " + "
hyprctl configerrors                    # vide
```

→ une liaison ratée garde la chaîne entière (`key: SUPER + SHIFT + code:49`) et
  `keycode: 0`. **Compter les liaisons ne dit rien — c'est leur forme qui parle.**

Ce qui ne marche pas encore, et c'est normal : le trousseau ne se déverrouille pas (pas de
greeter, donc pas de PAM), `~/nas` ne monte pas (`graphical-session.target` n'existe pas
tant que la session n'est pas lancée par `uwsm`).

## 5. Shell — Noctalia

**Aucun geste** : `noctalia` est arrivé avec la transaction §4.1. Il est livré en binaire
natif, `quickshell` n'est ni installé ni requis.

→ `hyprctl layers` → barre, fond d'écran et OSD sur les **trois** écrans, 3 surfaces par
  namespace. C'est cette mesure qui prouve qu'un seul daemon peint, pas `pgrep` : un
  daemon surnuméraire peut être totalement inerte.

## 6. Greeter — greetd + greeter Noctalia

### 6.1 Dépendances de compilation

```bash
sudo dnf install meson gcc-c++ just \
  greetd greetd-selinux dbus \
  wayland-devel wayland-protocols-devel wlroots-devel \
  libglvnd-devel \
  freetype-devel fontconfig-devel \
  cairo-devel pango-devel harfbuzz-devel \
  libxkbcommon-devel glib2-devel \
  tomlplusplus-devel json-devel stb_image_resize2-devel \
  libwebp-devel librsvg2-devel
```

100 paquets, 443 Mo. **Deux substitutions par rapport au README amont**, qui liste des
paquets inexistants dans Fedora 44 : `libglvnd-devel` remplace `libEGL-devel` +
`mesa-libGLES-devel`, et `greetd-selinux` s'ajoute (SELinux en `Enforcing`).

→ le scriptlet `sysusers` de `greetd` crée le compte **`greetd`**, pas `greeter`

### 6.2 Compiler — un TAG, pas `main`

```bash
git clone https://github.com/noctalia-dev/noctalia-greeter ~/src/noctalia-greeter
cd ~/src/noctalia-greeter
git checkout v1.3.1        # = commit 6379fe287bb02b0bb538ad155fe18b1bf8615daf

just configure-release && just build-release
sudo meson install -C build-release
```

Cloné dans `~/src/`, **hors du dépôt**. Préfixe `/usr/local`, donc **hors de `dnf`** : ce
que `dnf` ne connaît pas, seule cette procédure le sait.

⚠ **Lire `scripts/setup_greeter_system.sh` EN ENTIER avant de l'exécuter**, ainsi que ses
deux dépendances `greetd_setup_lib.sh` et `setup_greetd_pam.sh`, où se trouve le vrai
travail. Il s'exécute en root et modifie l'état système.

```bash
sudo ./scripts/setup_greeter_system.sh
```

→ 11 fichiers dans `/usr/local`, aucun possédé par un RPM

**Le bloc `config.toml` que le script imprime finit par `systemctl enable --now greetd`.
Reprendre le bloc SANS le `--now`** : il basculerait l'écran de connexion séance tenante.

- [ ] **TROU CONNU : le contenu de `/etc/greetd/config.toml` n'est pas dans ce dépôt.**
      Seul fichier de la chaîne du greeter dans ce cas. Le relever et le recopier ici :
      `sudo cat /etc/greetd/config.toml`. Une minute, et sans lui greetd démarre sur son
      greeter par défaut (écran texte) — le `greeter.toml` du §6.3 ne servirait alors à rien.

### 6.3 Les deux fichiers hors du home — aucun `stow` ne les atteindra

`/var/lib/noctalia-greeter/greeter.toml`, à écrire tel quel :

```toml
# ── Réglages du poste de référence ───────────────────────────────────────────
# Volontairement minimal : l'apparence (palette, fond d'écran) vient de la
# synchro Noctalia, qui écrit dans sync.toml. Ce que l'on fixe ici l'emporte.

[session]
# Le libellé EXACT rendu par « noctalia-greeter sessions », pas l'id du .desktop.
# Le sélecteur F3 permet de retomber sur « Hyprland » si la session uwsm échoue.
default = "Hyprland (uwsm-managed)"

[keyboard]
# Le compositeur du greeter est wlroots : il ne lit ni gsettings ni
# /etc/X11/xorg.conf.d/00-keyboard.conf, il retomberait sur US QWERTY.
# Taper son mot de passe en QWERTY sur un clavier AZERTY : à régler ici.
layout = "fr"
variant = "azerty"

[output]
# Positions relevées sur la session Hyprland (hyprctl monitors).
layout = "HDMI-A-2:0,180; DP-3:1920,0; DP-1:4480,180"

[idle]
timeout = 300
```

`/etc/tmpfiles.d/noctalia-greeter.conf`, qui surcharge celui du greeter — lequel code en
dur `greeter:greeter`, compte inexistant ici, et **prescrit lui-même sa surcharge** dans
son propre commentaire :

```
# Surcharge de /usr/local/lib/tmpfiles.d/noctalia-greeter.conf, qui code en dur
# « greeter:greeter ». Sur Fedora le paquet greetd crée le compte « greetd ».
d /var/lib/noctalia-greeter 0750 greetd greetd -
```

→ `/var/lib/noctalia-greeter` en `greetd:greetd 0750`

> **Les positions d'écran sont une duplication assumée** : le greeter tourne sur son propre
> compositeur wlroots, qui ne lit pas `hyprland.lua`. Si les écrans bougent, **deux**
> fichiers sont à corriger — celui-ci et `dotfiles/hypr/`.

### 6.4 SELinux — le répertoire d'état du greeter

```bash
sudo semanage fcontext -a -t xdm_var_lib_t '/var/lib/noctalia-greeter(/.*)?'
sudo restorecon -Rv /var/lib/noctalia-greeter
```

**Les deux commandes sont nécessaires** : `restorecon` corrige l'état présent,
`semanage fcontext` enregistre la règle pour qu'un relabel complet ne la défasse pas. Un
logiciel installé hors gestionnaire de paquets n'a personne pour l'étiqueter.

→ `sudo semanage fcontext -l | grep noctalia`
→ plus aucun `denied { write }` sur `sync.toml` (sinon : le greeter ne mémorise pas le
  dernier choix de session, et il le signale lui-même dans le journal)

## 7. Trousseau et NAS

```bash
sudo dnf install gnome-keyring gnome-keyring-pam
```

`gnome-keyring-pam` ne dépend que de `gnome-keyring`, `pam` et `libselinux` : **il ne tire
pas GDM.**

Ajouter dans `/etc/pam.d/greetd` **la seule ligne manquante** — Fedora livre déjà les deux
autres, et elles sont inertes tant que le paquet n'est pas là (préfixe `-` = ignorer un
module absent, en silence) :

```
-password   optional    pam_gnome_keyring.so use_authtok
```

après `password include system-auth`. Garder le préfixe `-` comme les autres lignes : si le
paquet est retiré un jour, PAM ignore le module au lieu de casser le login.

⚠ **ORDRE, le plus serré de la procédure.** Après `greetd` (§6 livre
`/etc/pam.d/greetd`) et **avant le premier login par le greeter**, sinon le trousseau n'est
pas déverrouillé et `nas-infoadmin.service` échoue — avec un symptôme qui accuse le NAS.

### 7.1 Bascule vers le greeter

```bash
sudo systemctl enable greetd
sudo systemctl set-default graphical.target
```

Deux commandes suffisent, sans rien écrire : `greetd.service` déclare
`Alias=display-manager.service` et `graphical.target` porte
`Wants=display-manager.service`.

⚠ **Vérifier le tty de secours AVANT de redémarrer.** `greetd` ne prend que le **VT 1** ;
les VT 2 à 6 restent servis à la demande. Repli depuis un tty :
`systemctl disable --now greetd` puis `systemctl set-default multi-user.target`.

Au login, choisir **« Hyprland (uwsm-managed) »**, pas « Hyprland » : c'est la seule des
deux qui active `graphical-session.target`, dont dépend le montage NAS.

→ `greetd.service` `enabled` **et** `active (running)`
→ `loginctl` → **une seule** session utilisateur, `Service=greetd`, `TTY=tty1`
→ `systemctl --user show-environment` contient `WAYLAND_DISPLAY`, `XDG_CURRENT_DESKTOP`,
  `HYPRLAND_INSTANCE_SIGNATURE`
→ `systemctl --user is-active graphical-session.target` → `active`

### 7.2 Réenregistrer le mot de passe SMB — une fois, à la main

⚠ **ORDRE — après Nautilus (§8), et il n'y a pas d'autre voie.**

Monter le partage **depuis Nautilus** et cocher « se souvenir pour toujours ».
**`gio mount` en ligne de commande ne sait pas écrire dans le trousseau** — seul le
dialogue GTK le fait ; `gvfsd` sait ensuite y *lire*. C'est l'unique raison pour laquelle
Nautilus est gardé sur ce poste.

Le trousseau est chiffré par le mot de passe de session et **n'est pas transposable** d'une
installation à l'autre : `stow` remet l'unité en place, le secret ne revient pas avec.

→ `~/nas` listable, et cherché avec `findmnt -t fuse.gvfsd-fuse` — **pas** avec `df` ni
  `findmnt -t cifs` : c'est un lien vers un montage gvfs de session, pas un montage CIFS
→ collection déverrouillée, **sans lire le secret** :
```bash
busctl --user get-property org.freedesktop.secrets \
  /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked
```

> **Ne JAMAIS vérifier ce secret avec `secret-tool search`** : la commande affiche le mot
> de passe **en clair** sur la sortie standard. Erreur commise le 2026-09-07.

## 8. Applications

```bash
sudo dnf install nautilus chromium kitty gvfs-smb
```

`nautilus` est installable seul (89 exigences, aucun composant de bureau) et **nécessaire
au moins pour le §7.2**. `kitty` est le terminal retenu, et le seul : `foot` arrivait
autrefois par le §4.1, il a été **retiré du §4.1 et de la machine le 2026-09-09** parce
qu'il était installé sans être utilisé. Versions relevées : `mesures.md` §8.

→ `pgrep -f xdg-desktop-portal` → les **trois** portails tournent

- [x] **Configurer kitty — FAIT le 2026-09-09**, paquet `dotfiles/kitty`. Le contenu n'est
      pas celui qu'annonçait cette case : la question de la **taille de police** est close
      par la mesure, `font_size` valant déjà 11.0 par défaut chez kitty, soit la valeur que
      le `foot.ini` posait à la main. Ce que le fichier porte à la place est un **filtre de
      notifications** (`filter_notification`), qui écarte le bruit de Claude Code et garde
      ses demandes de permission. Reste hors sujet terminal : la densité du P2725DE, qui
      est une question d'échelle de compositeur.

### 8bis. Flatpak

```bash
sudo dnf install -y flatpak
# le paquet fournit les dépôts « fedora » et « fedora-testing », PAS Flathub
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub com.mattermost.Desktop com.mikrotik.WinBox
```

Les deux en portée **`system`**, choix assumé : un seul dépôt, une seule portée.

⚠ **ORDRE — se déconnecter/reconnecter après**, sinon les applications sont installées mais
**invisibles au lanceur**. La cause est réglée par le paquet `uwsm` du §9 :
`/etc/profile.d/flatpak.sh` ne s'exécute que dans un shell de **login**, et la session
greetd → uwsm → Hyprland ne source jamais `/etc/profile`.

→ `flatpak list --app --columns=application,version,installation` → les deux en `system`
→ sur le processus **en session**, jamais dans un shell quelconque :
```bash
tr '\0' '\n' < /proc/$(pgrep -x Hyprland)/environ | grep XDG_DATA_DIRS
```

### 8ter. RustDesk — une seule commande

```bash
sudo dnf install ~/rustdeskadmin-x86_64.rpm
```

Le RPM est **généré** depuis la console RustDesk de l'entreprise : il embarque l'adresse du
serveur et la clé de relais. Il n'existe à aucune URL publique — il se **régénère**, il ne
se télécharge pas.

⚠ **Ne PAS taper `systemctl enable --now` ensuite : le `%post` l'a déjà fait.** Il copie
aussi l'unité dans `/etc/systemd/system/`, deux `.desktop` dans `/usr/share/applications/`
et crée `/usr/bin/rustdeskadmin` — **quatre fichiers que `rpm -qf` ne reconnaîtra jamais.**

> **Sur tout RPM hors distribution : `rpm -qp --scripts` AVANT `dnf install`.** C'est la
> seule façon de savoir ce qui va se passer. Deuxième fois que ça sert sur cette machine.

→ `rustdeskadmin.service` `enabled`, trois processus (`--service` root, `--server`, `--tray`)
→ `hyprctl devices` → un périphérique `rustdesk-uinput-keyboard` apparaît
→ **rien à ouvrir dans `firewalld`** : RustDesk sort vers son relais, il n'écoute pas

### 8quater. Virtualisation — hôte de la VM Windows

```bash
sudo dnf install -y qemu-kvm libvirt virt-manager edk2-ovmf swtpm-tools
sudo usermod -aG libvirt "$USER"
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket
```

228 paquets — la plus grosse transaction après l'installation. `edk2-ovmf` et
`swtpm-tools` **ne sont pas optionnels pour Windows 11** (UEFI Secure Boot + TPM émulé), et
sans eux le message ne dit pas lequel manque.

⚠ Le groupe `libvirt` n'est **effectif qu'après une nouvelle session** : ouvrir un autre
terminal ne suffit pas.

Puis le sous-volume des images, ⚠ **AVANT la première image et AVANT tout instantané** :

```bash
sudo btrfs subvolume create /var/lib/libvirt/images
sudo chattr +C /var/lib/libvirt/images
sudo restorecon -Rv /var/lib/libvirt/images
```

- **`+C` ne s'applique qu'aux fichiers créés ENSUITE.** Posé sur un dossier déjà peuplé il
  **ne fait rien** — pas d'erreur, pas d'effet.
- **Un sous-volume Btrfs neuf est `unlabeled_t`**, pas `var_lib_t` : sans `restorecon`,
  `qemu` confiné ne peut pas lire l'image, avec un « impossible d'ouvrir le disque » opaque.

→ `lsattr -d /var/lib/libvirt/images` → `C`
→ `ls -Zd /var/lib/libvirt/images` → `virt_image_t`

### 8quinquies. Le pont réseau `br0` — trois profils

```bash
sudo nmcli connection add type bridge con-name br0 ifname br0 \
    ipv4.method auto ipv6.method auto \
    bridge.stp no \
    bridge.mac-address <MAC DE LA CARTE PHYSIQUE DE CETTE MACHINE> \
    connection.autoconnect yes

sudo nmcli connection add type ethernet con-name br0-port ifname enp0s31f6 \
    controller br0 connection.autoconnect yes

sudo nmcli connection modify "Connexion filaire 2" connection.autoconnect no
```

**La troisième commande est la moitié du travail, et c'est celle qu'on oublie.** Laissé
actif, le profil Ethernet d'origine se dispute la carte avec `br0-port` au démarrage, de
façon non déterministe.

- **`bridge.stp no`** : un pont avec STP actif **émet des BPDU**, ce qui met un port protégé
  par BPDU guard en `err-disable` — et la remise en service se fait **côté switch**.
- **`bridge.mac-address`** : sans lui le pont prend la MAC la plus basse de ses ports, donc
  peut changer quand une VM démarre — et l'hôte change alors d'adresse IP tout seul.

> ✎ **La MAC et le nom d'interface sont propres au MATÉRIEL, pas à la configuration.**
> `mesures.md` §8quater enregistre `E8:CF:83:89:18:D4` et `enp0s31f6` : ce sont ceux de
> la carte du poste précédent. Sur une machine neuve, **relever les vrais** :
> `ip -br link` et `cat /sys/class/net/<iface>/address`. Recopier la valeur enregistrée
> serait usurper la MAC d'une carte morte.

→ ce que le **noyau applique**, pas ce que `nmcli` déclare :
```bash
cat /sys/class/net/br0/address              # = la MAC de la carte
cat /sys/class/net/br0/bridge/stp_state     # 0
cat /sys/class/net/br0/bridge/vlan_filtering # 0
bridge link show                            # carte en « master br0 », état « forwarding »
```
`forwarding` immédiat prouve que STP est coupé : avec STP actif, le port passerait par
`listening` puis `learning`.

### 8sexies. Outils d'administration réseau

```bash
sudo dnf install bind-utils nmap tcpdump
```

Outils d'alternance SRC, pas des dépendances du bureau.

## 9. Dotfiles

```bash
# 1. Écarter les fichiers par défaut de la distro — sinon stow REFUSE
mkdir -p ~/.dotfiles-backup
for f in .bashrc .bash_profile .gitconfig; do
    [ -f ~/"$f" ] && [ ! -L ~/"$f" ] && mv ~/"$f" ~/.dotfiles-backup/
done

# 2. Faire exister les dossiers que le tree folding remonterait trop haut
mkdir -p ~/.config/uwsm

# 3. SIMULER — la simulation nomme le niveau exact de chaque lien
cd ~/linux/dotfiles
stow -n -v -t ~ bash git hypr kitty nas uwsm noctalia

# 4. Poser
stow -v -t ~ bash git hypr kitty nas uwsm noctalia
```

⚠ **L'étape 1 n'est pas facultative** : c'est elle qui débloque `bash` et `git`. Elle n'a
jamais été exécutée sur le poste précédent, d'où 4 paquets posés sur 6.

⚠ **L'étape 2 non plus.** Sans elle, `stow` pose `~/.config/uwsm → <dépôt>` et le
`default-id` qu'y écrit `uwsm select` finirait **versionné**. Troisième occurrence du même
piège après `~/.bashrc.d` et `~/.config/systemd`.

⚠ **L'étape 3 non plus** : `stow -n -v` est le seul contrôle fiable du niveau où le lien
atterrit.

`-t ~` est obligatoire : sans lui, `stow` vise le **parent** du dossier courant, donc
`~/linux/`. Le paquet `desktop` n'est pas posé (son unique entrée n'a plus d'objet) et
`sway` ne sert qu'au lab.

→ `ls -l` sur les cibles des six paquets — **un `[ ]` peut vouloir dire « pas fait » ou
  « fait, pas noté », et seule la machine tranche** :
  `~/.bashrc`, `~/.bash_profile`, `~/.bashrc.d`, `~/.gitconfig`, `~/.config/git/ignore`,
  `~/.config/hypr/hyprland.lua`, `~/.config/kitty/kitty.conf`,
  `~/.config/noctalia/idle.toml`,
  `~/.config/systemd/user/nas-infoadmin.service`, `~/.config/uwsm/env`
  (`~/.bashrc.d` est un lien de **dossier** — tree folding : il pointe sur le dépôt en
  entier, donc **jamais de secret dedans**. Les autres sont des liens de fichier.)

Puis **déconnexion / reconnexion** : l'environnement de session ne se recharge pas.

## 10. Instantanés

```bash
sudo dnf install snapper
sudo snapper -c root create-config /          # ✎ INVENTÉ — commande non attestée
sudo snapper -c home create-config /home      # ✎ INVENTÉ
```

Puis reporter les réglages dans `/etc/snapper/configs/root` **et** `/etc/snapper/configs/home`
(identiques) :

```
TIMELINE_CREATE=yes      TIMELINE_CLEANUP=yes     TIMELINE_MIN_AGE=1800
TIMELINE_LIMIT_HOURLY=0  TIMELINE_LIMIT_DAILY=7   (weekly/monthly/yearly = 0)
NUMBER_CLEANUP=yes       NUMBER_LIMIT=10          NUMBER_LIMIT_IMPORTANT=5
SPACE_LIMIT=0.5          FREE_LIMIT=0.2
ALLOW_USERS="jzielona"   SYNC_ACL="yes"
```

```bash
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

⚠ `snapper-timeline.timer` a `UnitFilePreset=disabled` : **installer `snapper` ne suffit
pas** à avoir des instantanés automatiques.

→ `systemctl is-enabled snapper-timeline.timer snapper-cleanup.timer` — **pas** la sortie
  de `enable`, qui n'a annoncé qu'un lien sur deux le 2026-09-04
→ exclusion de la VM, et c'est cette mesure qui la prouve, pas l'existence du sous-volume :
  `ls -a /.snapshots/1/snapshot/var/lib/libvirt/images/` → `.` et `..` seulement
→ `snapper -c root list` répond **sans `sudo`** (effet de `ALLOW_USERS` + `SYNC_ACL`)

### 10bis. `grub-btrfs` — sauvegarde AVANT

```bash
# ⚠ ORDRE : le %post du RPM lance grub2-mkconfig tout seul et réécrit grub.cfg
sudo snapper -c root create -d "avant grub-btrfs"
sudo cp -a /boot/grub2/grub.cfg /root/grub.cfg.avant-grub-btrfs

sudo dnf copr enable pego-copr/grub-btrfs
sudo dnf install grub-btrfs          # tire inotify-tools
sudo systemctl enable --now grub-btrfsd
```

**COPR `pego-copr/grub-btrfs`**, paquet `grub-btrfs-4.14-1.fc44.noarch`.
⚠ **Ne pas prendre `kylegospo/grub-btrfs`** : ses chroots incluent `fedora-44` mais le
paquet est un instantané git de 2022 en release `.fc38`. Le nom d'un chroot ne dit rien de
l'âge du paquet.

**Aucune configuration à écrire** : le `config` livré détecte Fedora tout seul et l'unité
surveille déjà `/.snapshots`.

→ **deux mesures, et la seconde est la plus importante** :
```bash
sudo sh -c 'grep -c menuentry /boot/grub2/grub-btrfs.cfg'   # attendu : > 0
sudo sh -c 'grep -n "41_snapshots" /boot/grub2/grub.cfg'    # attendu : un configfile
```
Sans la seconde, des entrées peuvent exister dans un fichier qu'aucun `configfile` ne lit —
indiscernable de l'extérieur d'une installation qui marche.

Le `sh -c` n'est pas décoratif : `/boot/grub2/` est en `root`, le glob serait développé par
le shell **appelant** et `grep` recevrait la chaîne littérale.

- [ ] **Répéter à froid la porte de sortie manuelle**, pas le jour où ça casse. Au menu
      GRUB, touche `e`, remplacer `subvol=root` par **`subvol=root/.snapshots/<N>/snapshot`**
      (le préfixe `root/` compte : `/` est monté en `subvol=/root`). **Le démarrage sera
      dégradé** — `/var` et `/var/log` sont dans l'instantané, donc en lecture seule.
      Objectif : obtenir un shell suffisant pour `snapper rollback`. **Pas** une session
      graphique. Raisonnement complet dans `poste/README.md`.

## 11. Reprise de la VM Windows

```bash
sudo cp --sparse=always /chemin/sauvegarde/win11.qcow2 /var/lib/libvirt/images/
sudo cp -a /chemin/sauvegarde/win11_VARS.qcow2 /var/lib/libvirt/qemu/nvram/
sudo restorecon -Rv /var/lib/libvirt/images/
sudo virsh -c qemu:///system define /chemin/sauvegarde/win11.xml
```

⚠ **`cp --sparse=always` n'est pas une option de confort.** L'image est un fichier
**creux** : sans ça la copie occupe sa taille **apparente** (101 Go au lieu de 46 réels),
sans erreur et sans avertissement.

⚠ **`mv` conserverait l'étiquette SELinux d'origine** et `qemu`, confiné, ne pourrait pas
lire le fichier — symptôme opaque. D'où `cp` + `restorecon`.

→ la preuve que la copie creuse a marché, et c'est la seule après coup :
  `du -sh` (≈46 Go) **différent** de `du -sbh` (≈101 Go)
→ `ls -Z` → `svirt_image_t` avec des catégories MCS
→ `sudo virsh -c qemu:///system list` — **jamais `virsh` sans `-c`**, qui vise
  `qemu:///session` et répond vide alors que la VM tourne
→ `sudo virsh -c qemu:///system qemu-agent-command win11 '{"execute":"guest-ping"}'`
  → `{"return":{}}`

Si la sauvegarde manque, la VM se reconstruit de zéro : fiche complète dans
`poste/README.md` (chipset Q35 obligatoire, firmware `secboot` irréversible, TPM émulé,
pilote `viostor`, jointure au domaine).

## 12. Vérifications de fin

```bash
sudo reboot
```

Après le redémarrage :

- [ ] greeter affiché, **mot de passe saisi correctement du premier coup** — c'est la seule
      preuve qui vaille que l'AZERTY du greeter fonctionne
- [ ] trousseau déverrouillé (`Locked = false`, §7.2) et `~/nas` monté
- [ ] les trois portails tournent — **et à éprouver à l'usage** : capture d'écran et
      sélecteur de fichiers. Trois processus qui tournent ne prouvent pas qu'un portail répond
- [ ] `git ls-remote` aboutit dans un vrai terminal
- [ ] veille / reprise — jamais éprouvée sur ce matériel
- [ ] première capture d'état : `./bin/snapshot.sh --poste` → `installation/etats/<date>/`.
      **Jamais `--baseline`** : une baseline mesurerait l'image ISO, pas la distribution

## Ce qui reste ouvert après la procédure

Les cases ci-dessous ne sont **pas** des étapes ratées : ce sont les points que le poste
précédent n'avait pas tranchés, reportés tels quels pour ne pas les perdre.

- [ ] **Enrôler le TPM2 sur LUKS** (§1) — la plus visible au quotidien
- [ ] **Relever et recopier `/etc/greetd/config.toml`** (§6.2)
- [ ] **Configurer kitty** (§8)
- [ ] **Nommer la machine** — `hostnamectl` → `(unset)` ; le `fedora` affiché est le nom
      transitoire par défaut. Deux effets réels : le nom apparaît dans les journaux et sur
      le réseau, et un poste d'entreprise identifié « fedora » n'est pas identifié
- [ ] **Répéter à froid la porte de sortie GRUB** (§10bis)
- [ ] **Trancher le sort des 100 paquets de compilation du greeter** (65 `-devel`) : les
      garder pour recompiler hors ligne, ou les retirer pour que l'inventaire reste lisible
- [ ] **Écrire le fuseau et la disposition console réellement choisis** (§1)
