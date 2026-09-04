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

- [x] COPR retenu : **`dtutila/hyprland`**, `hyprland` 0.56.2-3.fc44 (2026-09-04).
      `solopasha/hyprland`, le COPR de référence, n'a **aucun chroot fedora-44**.
- [x] Relevé des versions : `scripts/versions-01.txt`
- [ ] **Décalage de versions : il a déjà eu lieu.** Le COPR a remplacé toutes les
      bibliothèques `hypr*` de Fedora (`hyprgraphics` 0.5.1 vs 0.1.5, `hyprutils` 0.14.1
      vs 0.7.1, `hyprlang` 0.6.8 vs 0.6.4, plus `hyprwire` inexistant chez Fedora).
      **`dnf upgrade` doit toujours voir ce COPR activé**, sinon Fedora tentera de
      redescendre ces paquets. À surveiller à chaque mise à jour.

### La plomberie de session : `uwsm` la fournit — MESURÉ le 2026-09-04

Sous Sway, `/etc/sway/config.d/10-systemd-session.conf` lançait
`/usr/libexec/sway-systemd/session.sh` : propagation de l'environnement vers systemd et
D-Bus, démarrage de `sway-session.target`, agent SSH, portails.

Ce paragraphe affirmait qu'aucun équivalent n'existait pour Hyprland dans Fedora, `uwsm`
compris. **C'était faux** : `uwsm` 0.26.7 arrive comme *dépendance faible* du COPR
`dtutila/hyprland`, et le paquet `hyprland` livre `hyprland-uwsm.desktop`. Voir le piège
« un paquet peut arriver par une dépendance FAIBLE » dans `CLAUDE.md`.

**Se connecter par la session « Hyprland (uwsm-managed) », pas « Hyprland ».** Les deux
apparaissent dans le sélecteur du greeter et la différence n'est pas cosmétique :

| | `Hyprland` | `Hyprland (uwsm-managed)` |
|---|---|---|
| Environnement propagé vers systemd/D-Bus | oui, par les 2 lignes de `hyprland.lua` | oui, par `wayland-wm-env@.service` |
| `noctalia --daemon` lancé | oui, par `hl.on("hyprland.start")` | oui, idem |
| **`graphical-session.target`** | **inactive** | **active** |

- [x] Session lancée via `uwsm` → `graphical-session.target` **active**, avec
      `wayland-wm@hyprland.desktop.service`, `wayland-session@…target`,
      `wayland-session-xdg-autostart@…target` et les slices graphiques
- [x] Propagation vérifiée : `systemctl --user show-environment` contient
      `WAYLAND_DISPLAY`, `XDG_CURRENT_DESKTOP`, `HYPRLAND_INSTANCE_SIGNATURE`
- [ ] Retirer les deux lignes devenues redondantes de `hyprland.lua`
      (`dbus-update-activation-environment`, `systemctl --user import-environment`) —
      **seulement après** avoir confirmé qu'`uwsm` est la session retenue au quotidien
- [ ] Montage NAS de bout en bout — `nas-infoadmin.service` n'est pas encore déployé ici

> **Pourquoi `graphical-session.target` n'est pas un luxe.** Elle porte
> `RefuseManualStart=yes` : impossible de la démarrer avec un `exec` dans `hyprland.lua`.
> Sans `uwsm`, il faudrait écrire une unité maison qui la tire, ou rebrancher
> `nas-infoadmin.service` sur `default.target` — et alors son `PartOf=` ne démonterait
> plus le partage à la déconnexion : le NAS resterait monté après le logout, avec le
> secret qui a servi à le monter. Ce n'est pas de la robustesse théorique, c'est un
> comportement différent et moins bon.

**Un effet de bord d'`uwsm` à connaître :** il charge les unités d'autostart XDG
(`app-*@autostart.service`). Celles de `gnome-keyring` apparaissent dans
`systemctl --user list-units 'app-*'` mais **ne s'exécutent jamais**
(`ExecMainStartTimestamp` vide, `pid=0`) — elles sont filtrées, `XDG_CURRENT_DESKTOP`
valant `Hyprland`. Une unité **chargée** n'est pas une unité **exécutée** : ne pas lui
imputer un symptôme sans regarder son horodatage. Même famille que « un paquet installé
n'est pas un paquet utilisé ».

### Configuration

- [x] **La config est en LUA, pas en `.conf`** : hyprlang est déprécié depuis Hyprland
      0.55. Référence à lire : `/usr/share/hypr/stubs/hl.meta.lua` (API générée) et
      l'exemple `/usr/share/hypr/hyprland.lua`. Les tutoriels en ligne sont encore en
      hyprlang, donc faux pour cette version.
- [x] Paquet `dotfiles/hypr/.config/hypr/hyprland.lua` créé, posé par `stow`.
      Le fichier autogénéré par Hyprland a été écarté dans `~/.dotfiles-backup/` —
      `stow` refuse de remplacer un vrai fichier, et c'est une sécurité.
- [x] **AZERTY : par SYMBOLES de niveau 1, pas par `code:NN`.** `code:NN` est la syntaxe
      hyprlang et **échoue silencieusement** dans la config Lua. Voir le journal du
      2026-09-04. Diagnostic : dans `hyprctl binds`, une liaison analysée montre une clé
      courte (`key: L`) ; une liaison ratée garde la chaîne entière et `keycode: 0`.
- [x] Vérifié : **71 liaisons, 0 non analysée**. Trois écrans aux bonnes positions.

## 5. Shell — Noctalia

- [x] `noctalia` 5.0.0~beta.10 installé. **Livré en binaire natif** — ce n'est plus une
      configuration Quickshell comme en version 3, `quickshell` n'est ni installé ni requis.
- [x] Vérifié par `hyprctl layers` : barre, fond d'écran et OSD sur les **trois** écrans.
- [ ] Vérifier l'intégration des espaces et des actions de session à l'usage
- [x] `hyprctl devices` depuis la session **active** : claviers présents, tous en
      `l "fr", v "azerty"`, `active keymap: French (AZERTY)`. La liste vide observée
      auparavant décrivait une session inactive, pas la machine — logind libère les
      périphériques d'une session en arrière-plan. **Certaines mesures n'ont de sens que
      depuis la session active.**
- [x] Un seul daemon Noctalia doit tourner. Vérifier avec `hyprctl layers` **qui possède
      les surfaces** (3 par namespace = une par écran), pas avec `pgrep` : un daemon
      surnuméraire peut être totalement inerte. Même leçon que le `swaybg` résiduel.

**Deux pièges de la 0.56 à connaître :**
- `hyprctl dispatch exec foo` ne marche plus — il faut
  `hyprctl dispatch 'hl.dsp.exec_cmd("foo")'`.
- `hl.on("hyprland.start", …)` **ne rejoue pas** sur un `hyprctl reload` : après un
  rechargement, l'autostart est à relancer à la main. Ça fait croire qu'il est cassé.

## 6. Greeter — greetd + greeter Noctalia — FAIT le 2026-09-04, **non activé**

`greetd` 0.10.3 est packagé. Le greeter Noctalia est un **projet séparé à compiler**, et
`greetd` reste obligatoire : c'est lui qui démarre le compositeur wlroots embarqué du
greeter.

**La ligne du README upstream ne s'applique pas telle quelle à Fedora 44.** Deux de ses
paquets n'y existent pas — `libEGL-devel` et `mesa-libGLES-devel` : c'est `libglvnd-devel`
qui fournit `pkgconfig(egl)`, `pkgconfig(glesv2)` et `pkgconfig(gl)`. Et `greetd-selinux`
est à ajouter, SELinux étant en `Enforcing`.

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

100 paquets, 443 Mo. `wlroots-devel` 0.20.2 (`updates`) fournit bien
`pkgconfig(wlroots-0.20)`. Le scriptlet `sysusers` de `greetd` crée le compte **`greetd`**
(UID 986) — **pas** `greeter`, comme l'écrit le README upstream.

- [x] Cloner `noctalia-dev/noctalia-greeter` — **compiler un tag, pas `main`** :
      `v1.3.1` = commit `6379fe287bb02b0bb538ad155fe18b1bf8615daf`. Le projet publie des
      tags (v1.0.0 → v1.3.1) et `main` n'en était qu'à 2 commits, tous deux de CI : rien
      n'obligeait à suivre une branche mouvante. Cloné dans `~/src/`, **hors de ce dépôt**.
- [x] `scripts/setup_greeter_system.sh` lu en entier avant exécution — ainsi que ses deux
      dépendances, `greetd_setup_lib.sh` et `setup_greetd_pam.sh`, où se trouve le vrai
      travail
- [x] `just configure-release && just build-release && sudo meson install -C build-release`
      → trois binaires en `/usr/local/bin` : `noctalia-greeter`, `-apply-appearance`,
      `-compositor`, plus une politique polkit et un `tmpfiles.d`
- [x] `sudo ./scripts/setup_greeter_system.sh`
- [x] `/var/lib/noctalia-greeter/greeter.toml` configuré : session par défaut,
      **`fr`/`azerty`**, les trois écrans, veille 300 s
- [x] Préfixe d'installation : **`/usr/local`** (défaut), donc **hors de `dnf`**
- [x] `systemctl enable greetd` + `systemctl set-default graphical.target` — **fait le
      2026-09-04**, tty de secours vérifié avant

**Quatre choses apprises, à ne pas redécouvrir.**

1. **Le script résout le compte tout seul.** `resolve_greeter_user` interroge
   `apply-appearance --print-greeter-user`, qui lit `/etc/greetd/config.toml` ; il a
   annoncé `greetd`. Le `user = "greeter"` du README n'est qu'un exemple, le projet gère
   la variation entre distributions.
2. **Il patche `/etc/pam.d/greetd`** en y ajoutant `session required pam_systemd.so`
   (sauvegarde `.bak.noctalia.<horodatage>`). Sa garde `grep -F pam_systemd.so` ne lit que
   *ce fichier*, alors que Fedora apporte déjà le module via `session include system-auth`.
   Il y a donc deux appels, dont un en `required`. **`man pam_systemd` ne documente aucun
   problème d'appel répété** : à **mesurer** au premier login (`loginctl`, une seule
   session attendue), pas à préjuger — et le `.bak` est là si besoin.
3. **Le bloc `config.toml` qu'il imprime finit par `systemctl enable --now greetd`.** Le
   `--now` basculerait l'écran de connexion séance tenante. Reprendre le bloc sans lui.
4. **Son `tmpfiles.d` code en dur `greeter:greeter`**, un compte inexistant ici — et son
   propre commentaire prescrit la réponse : « override under `/etc/tmpfiles.d/` if your
   greetd user differs ». D'où `/etc/tmpfiles.d/noctalia-greeter.conf` en `greetd greetd`.

**Le clavier n'est pas un détail de confort.** Le compositeur du greeter est wlroots : il
ne lit ni `gsettings`, ni `/etc/X11/xorg.conf.d/00-keyboard.conf`, et retomberait sur
**US QWERTY** — pour saisir un mot de passe. `[keyboard] layout = "fr"` /
`variant = "azerty"` est obligatoire, et `azerty` est bien une variante XKB de `fr`
(`fr: French (AZERTY)`). Même piège que Sway à l'itération 01, sur un autre compositeur.

**La bascule tient en deux commandes, sans rien écrire.** `greetd.service` déclare
`Alias=display-manager.service` et `graphical.target` porte `Wants=display-manager.service` :
`enable greetd` + `set-default graphical.target` suffisent.

**Le filet est structurel.** `greetd` ne prend que le **VT 1** (`Conflicts=getty@tty1.service`,
`vt = 1`), et `autovt@.service → getty@.service` avec `NAutoVTs = 6` : les VT 2 à 6 restent
servis à la demande. Repli depuis un tty : `systemctl disable --now greetd` puis
`systemctl set-default multi-user.target`.

**SELinux, à mesurer après la bascule — pas à traiter d'avance.** `/usr/local/bin/*`
s'étiquette `bin_t`, exactement comme `/usr/bin` : aucun problème d'exécution. Mais
`/var/lib/noctalia-greeter` est en `var_lib_t` alors que `/var/lib/greetd` est en
`xdm_var_lib_t`. **Le déni s'est produit** — `denied { write }` sur `sync.toml`,
`scontext=xdm_t`, `tcontext=var_lib_t` — et le greeter le signalait lui-même dans le
journal (`failed to save sync.toml`). Effet : il ne mémorise pas le dernier choix de
session. Correctif appliqué :

```bash
sudo semanage fcontext -a -t xdm_var_lib_t '/var/lib/noctalia-greeter(/.*)?'
sudo restorecon -Rv /var/lib/noctalia-greeter
```

Résultat vérifié : `xdm_var_lib_t`, plus aucun déni. **Les deux commandes sont
nécessaires** — `restorecon` seul corrige l'état présent, `semanage fcontext` enregistre
la règle pour qu'un relabel complet ultérieur ne la défasse pas. Règle persistante
confirmée le 2026-09-04 :

```
/var/lib/noctalia-greeter(/.*)?   all files   system_u:object_r:xdm_var_lib_t:s0
```

Contrôle après une réinstallation : `sudo semanage fcontext -l | grep noctalia`.

## 7. Trousseau — gnome-keyring

```bash
sudo dnf install gnome-keyring gnome-keyring-pam
```

`gnome-keyring-pam` ne dépend que de `gnome-keyring`, `pam` et `libselinux` : **il ne tire
pas GDM**.

**Fedora en a déjà écrit deux sur trois — et elles sont inertes.** Vérifié le 2026-09-04 :
le `/etc/pam.d/greetd` livré par le paquet `greetd` contient déjà

```
-auth       optional    pam_gnome_keyring.so
-session    optional    pam_gnome_keyring.so auto_start
```

Il ne manque que la ligne `password … use_authtok`, absente aussi de `system-auth`. Mais
`gnome-keyring-pam` n'est pas installé, donc `/usr/lib64/security/pam_gnome_keyring.so`
**n'existe pas** — et le préfixe `-` dit précisément à PAM d'ignorer un module manquant
**en silence**. Les lignes sont là et ne font rien.

> **Piège de méthode :** vérifier la présence du **module**, pas celle de la ligne. Même
> famille que « un dépôt activé n'est pas un paquet installé ». C'est le paquet qui
> manque, pas la configuration.

État constaté sur ce poste : `org.freedesktop.secrets` est bien détenu par
`gnome-keyring-daemon`, mais **activé par D-Bus** à la demande sous `user@1000.service` —
il n'y a pas de DM, donc aucun déverrouillage PAM. Le trousseau tourne sans être
déverrouillé.

**Ne pas traiter avant d'avoir tranché le point ouvert KeePassXC** (faisabilité prouvée le
2026-09-04) : installer `gnome-keyring-pam` ici, c'est choisir `gnome-keyring` comme
fournisseur Secret Service du poste de référence. Sans conséquence immédiate tant que
`nas-infoadmin.service` n'est pas déployé — cette unité n'existe pas encore sur ce poste,
donc le symptôme « le montage NAS échoue » n'est pas encore mesurable.

- [x] **Décision du 2026-09-04 : `gnome-keyring`**, KeePassXC reste reporté
- [x] `sudo dnf install gnome-keyring-pam`, puis ajout de la seule ligne manquante
      (`-password optional pam_gnome_keyring.so use_authtok`, après
      `password include system-auth`). Préfixe `-` comme les autres lignes du fichier :
      si le paquet est retiré un jour, PAM ignore le module au lieu de casser le login.
- [x] **Vérifié après un vrai login** — et une simple déconnexion/reconnexion suffit,
      PAM s'exécutant au *login* et non au boot :

  | Mesure | Résultat |
  |---|---|
  | `~/.local/share/keyrings/` | `login.keyring` + `user.keystore` créés |
  | Collections exposées | **deux** : `session` *et* `login` (contre `session` seule avant) |
  | **`login` déverrouillé** | **`Locked = false`** |
  | `gcr-prompter` après le correctif | **aucun** |

  > **La mesure qui compte est `Locked`, pas l'existence du fichier.** Un
  > `login.keyring` présent mais verrouillé redemanderait le mot de passe à chaque
  > client. Vérifier :
  > `busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked`

  **Deux processus `gnome-keyring-daemon` coexistent**, comme à l'itération 01 :
  `--daemonize --login` (lancé par PAM, c'est lui qui détient le nom) et
  `--start --components=secrets`. Ce n'est pas un doublon anormal.

- [ ] Montage NAS de bout en bout — `nas-infoadmin.service` n'est pas encore déployé ici

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
stow -v -t ~ hypr foot          # fait le 2026-09-04
stow -v -t ~ bash git nas desktop
```

- [x] `hypr` et `foot` posés
- [ ] `bash`, `git`, `nas`, `desktop` — à poser

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
