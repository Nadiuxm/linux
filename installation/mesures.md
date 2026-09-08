# Mesures du poste de référence — ce qui a été constaté, et ce que ça apprend

> **CE FICHIER N'EST PAS UNE PROCÉDURE. Ne rien taper depuis ici.**
>
> Les gestes sont dans **`procedure.md`**, et nulle part ailleurs. Ce fichier-ci porte les
> **mesures** : versions exactes, sorties de commandes, tableaux relevés sur la machine, et
> ce que chaque étape a appris. Il sert à **vérifier** et à **comprendre**, pas à installer.
>
> **Les blocs de commandes qui subsistent ci-dessous sont le RELEVÉ de ce qui a été tapé
> les 2026-09-04 et 2026-09-07** — une trace utile, puisque `dnf history` ne survit pas à
> une réinstallation. Ils ne sont pas à jour et ne le seront pas : `procedure.md` fait foi.
>
> | Fichier | Contenu |
> |---|---|
> | `procedure.md` | les gestes, à l'impératif. **Seule source de ce qu'on tape.** |
> | **`mesures.md`** (ici) | les constats, versions, mesures, et ce qu'elles apprennent |
> | `README.md` | les décisions et leurs raisons |
> | `journal.md` | le récit daté de la construction |
>
> **Les numéros de section PRINCIPAUX (§1 à §12) se correspondent** : §7 ici documente §7
> là-bas. Les sous-sections (`8bis`, `8ter`…) ont divergé et ne sont pas alignées — les
> renvois entre les deux fichiers les nomment explicitement.
> C'est la seule chose à maintenir entre les deux fichiers.

**Découpé de l'ancien `procedure.md` le 2026-09-08.** Ce fichier s'annonçait « la séquence,
dans l'ordre, avec les versions exactes » et était devenu un **registre de constats** : on
pouvait y vérifier le poste bien mieux qu'on ne pouvait le construire. L'émulation d'une
réinstallation sur papier a montré le prix — `mesa-dri-drivers`, le mot de passe SMB, le
bloc `nmcli`, `create-config` : des gestes absents sous des mesures très complètes.

> **Toutes les cases ont été confrontées à la machine le 2026-09-07** (audit complet :

> **Toutes les cases ont été confrontées à la machine le 2026-09-07** (audit complet :
> `dnf history`, `rpm -q --qf '%{installtime:date}'`, `systemctl`, `cryptsetup luksDump`,
> `hyprctl`, `virsh`, `loginctl`, `semanage fcontext -l -C`). Neuf cases se sont révélées
> **faites sans avoir été notées** — c'est précisément le piège signalé en §9. Une case
> vide ne prouve rien ; seule la machine tranche.

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

Résultat : **53 paquets explicites, 419 au total.** (Pour comparaison, au 2026-09-07 :
**101 explicites, 1235 au total** — l'écart est mesuré dans `etats/2026-09-07/`.)

**Secure Boot est actif, et ce n'est pas neutre.** `bootctl status` →
`Secure Boot: enabled (deployed)`, `shim-x64` 16.1-5 installé, amorçage par
`\EFI\fedora\shimx64.efi`. Conséquence à connaître avant d'en avoir besoin : **un module
noyau non signé ne se chargera pas** (pilote propriétaire, DKMS maison). Rien sur ce poste
n'en dépend aujourd'hui ; le jour où ça arrivera, le symptôme sera un module « introuvable »
sans autre explication.

- [x] Installation
- [ ] **Enrôler le TPM2 sur LUKS** — `systemd-cryptenroll`. Matériel vérifié :
      `/dev/tpm0`, `/dev/tpmrm0`, `systemd-analyze has-tpm2` → `yes` (+firmware, +driver,
      +system, +subsystem, +libraries). **Toujours pas fait au 2026-09-07** : le `luksDump`
      montre `Tokens:` **vide** et un seul emplacement de clé. Sans ça, phrase de passe à
      chaque démarrage.
- [x] **Version LUKS relevée le 2026-09-07** — `sudo cryptsetup luksDump /dev/nvme0n1p3` :

      | | |
      |---|---|
      | Version | **LUKS2** |
      | UUID | `680cb146-2018-49f5-b166-c4ecec3dfe26` |
      | Chiffrement | `aes-xts-plain64`, clé de **512 bits**, secteur 512 o |
      | Dérivation | `argon2id`, coût 8, mémoire 1 Go, 4 fils |
      | Emplacements de clé | **1 seul** (0), priorité normale |
      | Jetons | **aucun** → pas de TPM2, pas de FIDO2, pas de clé de secours |
      | Drapeaux | `allow-discards` |

      `/etc/crypttab` :
      `luks-680cb146-… UUID=680cb146-… none discard,x-initrd.attach`.
      Pas de `crypttab.initramfs`.

      **Le seul emplacement de clé est un point de fragilité à connaître.** Perdre la
      phrase de passe, c'est perdre le disque : il n'y a aucune seconde voie d'ouverture.
      Enrôler le TPM2 en ajoutera une — mais liée à la machine, donc pas une sauvegarde.

## 2. Accès au dépôt — FAIT le 2026-09-04

**Gestes : `procedure.md` §2.** Ce qui a été appris ici :

- **La clé du dépôt est une deploy key nommée `gitlinux`**, donc `ssh` ne la propose pas
  spontanément — il n'essaie que `id_ed25519`, `id_rsa`… Sans un bloc `Host github.com`
  avec `IdentityFile` et `IdentitiesOnly yes` dans `~/.ssh/config`, le clone échoue sur
  `Permission denied (publickey)`, et le message n'indique pas que la clé existe pourtant.
- **Un `ssh-keyscan` seul ne vérifie rien** : il enregistre ce que le serveur répond, quel
  qu'il soit. Les empreintes se comparent à celles publiées sur
  `https://api.github.com/meta` avant d'écrire dans `known_hosts`.
- **L'identité git a été posée en `git config --global` le 2026-09-04, et c'était une
  erreur de séquence** : ça crée un `~/.gitconfig` réel, donc le conflit qui fait refuser
  `stow git`. Trois jours plus tard le paquet `git` n'était toujours pas posé pour cette
  seule raison. `procedure.md` §2 dit maintenant de ne pas le faire — l'identité vient du
  paquet `dotfiles/git/`.

- [x] `git`, identité, `~/.ssh/config`, clone

## 3. Mise à jour complète — SANS OBJET sur une netinstall, vérifié le 2026-09-07

Cette étape venait du protocole de baseline du lab, où l'on part d'une image ISO figée.
**Elle n'a jamais été exécutée ici, et c'est normal :** `dnf history` ne contient aucun
`upgrade`, la transaction 1 (l'installation elle-même) a posé un noyau
`7.1.13-200.fc44.x86_64` **construit le 2026-09-02**, soit deux jours avant l'installation.
Une image *netinstall* télécharge les paquets depuis `fedora` + `updates` au moment de
l'installation : le système naît à jour.

**La leçon est transposable :** le coût de la mise à jour initiale n'est pas une propriété
de la distribution, c'est une propriété de **l'édition de l'image**. Une comparaison entre
distros qui chronomètre ce temps compare des images, pas des distros — même piège que le
« coût d'obtention de Flatpak » relevé en §8.

- [x] Noyau obtenu : `7.1.13-200.fc44.x86_64` (2026-09-02), inchangé au 2026-09-07
- [ ] `sudo dnf upgrade` — à faire *périodiquement*, pas comme étape d'installation.
      **Toujours avec le COPR `dtutila/hyprland` activé**, sinon Fedora tentera de
      redescendre les bibliothèques `hypr*` (voir §4)

## 4. Compositeur — Hyprland

### 4.0 Pilotes graphiques — À FAIRE EN PREMIER, sinon rien ne démarre

```bash
sudo dnf install mesa-dri-drivers        # 26.1.8-1.fc44 au 2026-09-04
```

**Une image minimale n'installe AUCUN pilote graphique : sans `mesa-dri-drivers`, Hyprland
ne démarre pas du tout.** C'est la dépendance qu'on oublie parce qu'elle va de soi sur une
image Workstation, et le symptôme ne la désigne pas.

> **Cette étape a manqué à ce fichier du 2026-09-04 au 2026-09-07.** Elle ne vivait que
> dans `scripts/01-bureau-hyprland.sh`, un script que la procédure ne référençait nulle
> part — donc invisible à qui déroulait ce document. Le script a été supprimé le
> 2026-09-07 : il installait `foot` au lieu de `kitty`, omettait `hyprland-guiutils`, et
> ses instructions finales faisaient lancer Hyprland **à la main depuis un tty**, ce qui
> est précisément ce qui a produit les deux sessions Hyprland simultanées du 2026-09-04.
> **Deux sources pour la même séquence, dont une fausse : c'est la situation à ne pas
> garder.** `procedure.md` est désormais la seule source de ce qu'on tape.

### 4.1 Le COPR

Absent des dépôts Fedora ; **un COPR est nécessaire**. Fedora fournit les bibliothèques
(`hyprutils`, `hyprlang` 0.6.4, `hyprgraphics` 0.1.5, `hyprcursor` 0.1.11,
`hyprland-protocols` 0.4.0) mais pas le compositeur.

- [x] COPR retenu : **`dtutila/hyprland`**, `hyprland` 0.56.2-3.fc44 (2026-09-04).
      `solopasha/hyprland`, le COPR de référence, n'a **aucun chroot fedora-44**.
- [x] Relevé des versions : `scripts/versions-01.txt`
- [x] **La commande exacte, relevée dans `dnf history` le 2026-09-07** — elle fait plus
      que le compositeur, et c'est par elle que `stow`, `keepassxc`, `foot`, `noctalia`
      et (par dépendance faible) `uwsm` sont arrivés :

      ```bash
      sudo dnf copr enable dtutila/hyprland
      sudo dnf install -y hyprland hyprland-guiutils xdg-desktop-portal-hyprland \
                          xdg-desktop-portal-gtk noctalia foot stow keepassxc
      ```

      **317 paquets.** `keepassxc` et `stow` sont là parce qu'ils sont le protocole de
      baseline du lab, pas parce qu'Hyprland en a besoin.

      > **`hyprland-guiutils` a été ajouté à cette commande le 2026-09-07.** Il est
      > `reason=User` dans le tableau ci-dessous et explicite dans
      > `etats/2026-09-07/packages-explicit.txt`, mais il ne figurait pas dans la commande :
      > **la séquence enregistrée ne reproduisait donc pas l'état enregistré.** Écart trouvé
      > en rejouant la procédure sur papier, pas en la relisant.

      > **Ce COPR est un dépôt tiers tenu par une personne** — sa description est
      > littéralement « my personal hyprland packages ». Risque assumé et documenté :
      > `solopasha/hyprland`, le COPR de référence, n'a **aucun chroot fedora-44**. Il n'y a
      > donc **aucun repli** si celui-ci disparaît : ce serait à instruire ce jour-là.

- [x] **Les 13 paquets réellement fournis par le COPR au 2026-09-07** — la liste compte,
      c'est elle qu'un `dnf upgrade` sans le COPR essaierait de redescendre :

      | Paquet | Version | Raison |
      |---|---|---|
      | `hyprland` | 0.56.2-3.fc44 | User |
      | `hyprland-guiutils` | 0.2.2-2.fc44 | User |
      | `xdg-desktop-portal-hyprland` | 1.4.1-1.fc44 | User |
      | `aquamarine` | 0.15.0-2.fc44 | dépendance |
      | `hyprcursor` | 0.1.13-2.fc44 | dépendance |
      | `hyprgraphics` | 0.5.1-2.fc44 | dépendance |
      | `hyprlang` | 0.6.8-1.fc44 | dépendance |
      | `hyprtoolkit` | 0.5.4-3.fc44 | dépendance |
      | `hyprutils` | 0.14.1-2.fc44 | dépendance |
      | `hyprwire` | 0.3.1-2.fc44 | dépendance |
      | `lua55` | 5.5.0-1.fc44 | dépendance |
      | `uwsm` | 0.26.7-1.fc44 | **dépendance FAIBLE** |

      `lua55` est arrivé avec : c'est le moteur de la configuration Lua. `uwsm` n'est
      exigé par aucun `Requires` — d'où le fait qu'il n'apparaisse dans aucune liste
      qu'on lit spontanément.
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
- [x] Montage NAS de bout en bout — **fait**, détail et mesures en §7
- [x] **`uwsm` EST la session retenue au quotidien**, mesuré le 2026-09-07 :
      `graphical-session.target` **active**, `wayland-session@hyprland.desktop.target`
      active, `wayland-wm@hyprland.desktop.service` porte le compositeur, et le
      `greeter.toml` fixe `default = "Hyprland (uwsm-managed)"`. La condition de la ligne
      précédente est donc remplie — le nettoyage de `hyprland.lua` peut se faire.
      À noter : `~/.config/uwsm/` ne contient **que** le lien `env` posé par `stow`, pas
      de `default-id` — le greeter passe la session explicitement, `uwsm select` n'a jamais
      servi. Le piège du tree folding a donc été évité pour rien, mais il reste juste.

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
- [x] Vérifié le 2026-09-04 : **71 liaisons, 0 non analysée**. Trois écrans aux bonnes
      positions. **Re-mesuré le 2026-09-07 après la réécriture de la config :
      61 liaisons, 0 non analysée** (aucune clé ne contient de ` + `, seul signe fiable
      d'une liaison inerte). `hyprctl configerrors` : vide.
- [x] **Espaces ancrés par règle**, mesuré le 2026-09-07 : 9 `workspace_rule` actives,
      1/4/7 → `HDMI-A-2`, 2/5/8 → `DP-3`, 3/6/9 → `DP-1`, avec `default = true` sur la
      première de chaque écran. Sans ces règles, Hyprland distribue 1..N dans l'ordre des
      `monitorID`, qui change d'un démarrage à l'autre.
- [x] **`input:resolve_binds_by_sym` vaut `false`, et c'est POUR ÇA que les symboles
      marchent** — mesuré le 2026-09-07 : `hyprctl getoption input:resolve_binds_by_sym`
      → `bool: false set: false`. La note de `CLAUDE.md` affirmait le contraire (`true`
      par défaut) : le raisonnement était à l'envers, le geste retenu était bon. Avec
      `false`, Hyprland traduit le keysym écrit dans la config en **code de touche** via
      le keymap courant, donc `eacute` désigne la touche physique `AE02` quel que soit son
      niveau — d'où le fait que `$mod+eacute` et `$mod+SHIFT+2` cohabitent.
      **Une note de piège se re-teste : celle-là était fausse depuis le début.**

### Écrans — relevé du 2026-09-07

Les positions ne sont pas dans la config par hasard : elles sont recopiées dans le
`greeter.toml` (§6), qui tourne sur un **autre** compositeur et n'a aucun moyen de les
deviner.

| Sortie | Modèle | Série | Mode | Position |
|---|---|---|---|---|
| `HDMI-A-2` | Dell P2425H | `BH19JF4` | 1920x1080@60 | `0,180` |
| `DP-3` | Dell P2725DE | `FVTKM84` | 2560x1440@59,95 | `1920,0` |
| `DP-1` | Dell P2414H | `36WJX4BI4L0L` | 1920x1080@60 | `4480,180` |

**L'ancrage se fait par nom de sortie, donc il suit le PORT, pas l'écran.** Si les câbles
bougent, les espaces suivent le port. Pour ancrer à l'écran physique, utiliser
`description` (qui porte le numéro de série, colonne ci-dessus).

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

## 6. Greeter — greetd + greeter Noctalia — FAIT et **EN SERVICE** depuis le 2026-09-04

> **Ce titre disait « non activé » jusqu'au 2026-09-07.** C'était faux : mesuré le
> 2026-09-07, `greetd.service` est `enabled` **et** `active (running)` depuis le boot,
> `/etc/systemd/system/display-manager.service` pointe sur lui, et la session ouverte
> porte `Service: greetd`, `Leader: 2176 (greetd)`, `TTY: tty1`. **C'est le greeter
> Noctalia qui ouvre la session de travail depuis trois jours.** La bascule était notée
> plus bas dans la même section, cochée — seul le titre avait pris du retard, et c'est
> exactement ce qui rend un titre dangereux : on le lit sans lire la suite.

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
- [x] Préfixe d'installation : **`/usr/local`** (défaut), donc **hors de `dnf`**.
      Vérifié le 2026-09-07 : **11 fichiers** dans `/usr/local`, aucun possédé par un RPM
      (`rpm -qf` échoue sur chacun) — 5 binaires dans `bin/`, 4 scripts dans
      `share/noctalia-greeter/`, le `tmpfiles.d`, et un `mimeinfo.cache`.

### `greeter.toml` — pourquoi il est recopié, et ce qu'il faut en savoir

`/var/lib/noctalia-greeter/greeter.toml` appartient à `greetd:greetd` sous `/var/lib` :
il est **hors du home**, donc hors de portée de `stow`, et il n'est pas livré par un
paquet. Il n'a que deux destinations possibles — la procédure, ou l'oubli.

> **Le contenu du fichier est dans `procedure.md` §6.3, et là seulement.** Il y était en
> double jusqu'au 2026-09-08 : deux copies d'un fichier de configuration dans deux
> documents, c'est-à-dire deux vérités possibles le jour où l'une est modifiée. C'est le
> geste « écrire ce fichier » qui appartient à la procédure ; ce qui reste ici, c'est ce
> qu'il faut **savoir** à son sujet.

**Trois choses à savoir sur ce fichier.**

1. **Il est déclaratif et le greeter ne l'écrit jamais.** Ce que l'interface et la synchro
   Noctalia modifient va dans `sync.toml`, à côté ; ce qui est fixé ici l'emporte. C'est
   pour ça qu'il est recopiable tel quel, contrairement aux réglages Noctalia de la session
   (voir §8bis).
2. **Les positions d'écran sont une duplication assumée.** Le greeter tourne sur son propre
   compositeur wlroots, qui ne lit pas `hyprland.lua`. Si les écrans bougent, **deux**
   fichiers sont à corriger — celui-ci et le paquet `hypr` de `dotfiles/`.
3. **Le `[keyboard]` n'est pas du confort.** Sans lui, l'écran où l'on saisit son mot de
   passe est en US QWERTY. Même piège que Sway à l'itération 01, sur un troisième
   compositeur.

Le dossier livré à côté au 2026-09-07 : `greeter.toml`, `greeter.toml.bak` (laissé par le
script d'installation) et `sync.toml`, tous en `greetd:greetd` et `xdm_var_lib_t`.
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
   **MESURÉ le 2026-09-07, sans effet : `loginctl list-sessions` ne montre qu'UNE session
   utilisateur** (`2`, `seat0`, `tty1`, `active`) ; les autres lignes sont un `manager`
   (`user@1000.service`) et un `background`, qui existent sur toute machine systemd. Le
   double appel n'a créé aucune session en trop. **Sujet clos : le geste documenté par
   l'outil était le bon, et l'écart déduit n'aurait rien corrigé.** Le `.bak` du script
   (`greetd.bak.noctalia.<horodatage>`) peut rester où il est.
3. **Le bloc `config.toml` qu'il imprime finit par `systemctl enable --now greetd`.** Le
   `--now` basculerait l'écran de connexion séance tenante. Reprendre le bloc sans lui.

   > **TROU CONNU : le contenu de `/etc/greetd/config.toml` n'est nulle part dans ce
   > dépôt.** Seul fichier de la chaîne du greeter dans ce cas — le `greeter.toml` et le
   > `tmpfiles.d` ont été rapatriés le 2026-09-07, celui-là a été raté par le même audit.
   > Il dépend donc entièrement du bloc imprimé par `setup_greeter_system.sh` au tag
   > `v1.3.1` : si l'amont change, greetd démarre sur son greeter par défaut (écran texte)
   > et le `greeter.toml` ne sert à rien. **Case à cocher dans `procedure.md` §6.2.**
4. **Son `tmpfiles.d` code en dur `greeter:greeter`**, un compte inexistant ici — et son
   propre commentaire prescrit la réponse : « override under `/etc/tmpfiles.d/` if your
   greetd user differs ». **Le geste correct était écrit dans le fichier livré.** D'où la
   surcharge `/etc/tmpfiles.d/noctalia-greeter.conf`, dont le contenu est dans
   `procedure.md` §6.3 — même raison que le `greeter.toml` : un fichier de `/etc` qu'aucun
   paquet ne livre, donc hors de portée de `stow`.

   Vérifié le 2026-09-07 : le dossier est bien en `greetd:greetd 0750`.

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

> **Les deux paragraphes qui suivaient ici décrivaient l'état d'AVANT la bascule et sont
> périmés** — ils disaient « il n'y a pas de DM, donc aucun déverrouillage PAM » et
> « `nas-infoadmin.service` n'existe pas encore sur ce poste ». Les deux sont faux depuis
> le 2026-09-04 : greetd est le DM, PAM déverrouille, l'unité NAS tourne. Gardés
> supprimés plutôt que corrigés, la suite de la section portant déjà l'état vérifié.

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
  **Re-mesuré le 2026-09-07, avec une précision qui change la lecture :** le processus
  PAM vit dans `session-2.scope` (cgroup de la session greetd), l'autre dans
  `app-dbus-:1.2-org.freedesktop.secrets@0.service` — deux **cgroups différents**, donc
  deux mécanismes de démarrage distincts pour un même paquet. C'est le cas déjà noté dans
  `CLAUDE.md` (« un paquet peut être à moitié disponible »), vu ici sous sa forme complète.

- [x] **Montage NAS de bout en bout — VÉRIFIÉ le 2026-09-07, et c'était fait depuis le
      2026-09-04 sans avoir été noté.** La chaîne complète mesurée :

      | Maillon | Mesure |
      |---|---|
      | Unité | `nas-infoadmin.service` `enabled` + `active (exited)`, depuis le boot |
      | `ExecStart` | `gio mount smb://pdc-nas-info.te-mgmt.io/infoadmin` → `status=0` |
      | `ExecStartPost` | lien `~/nas` posé vers `/run/user/1000/gvfs/smb-share:…` |
      | Secret | entrée `org.gnome.keyring.NetworkPassword` dans `login.keyring`, créée le 2026-09-04 |
      | Montage | `gvfsd-fuse` sur `/run/user/1000/gvfs`, `gvfsd-smb` en cours |
      | Contenu | `~/nas` listable, dossiers du partage présents |

      **`~/nas` n'est pas un montage CIFS, c'est un lien vers un montage gvfs de session.**
      Il n'apparaît donc **pas** dans `df` ni dans `findmnt -t cifs` — seulement dans
      `findmnt -t fuse.gvfsd-fuse`. Chercher le partage avec les mauvais outils fait
      conclure à une panne qui n'existe pas.

      > **Ne jamais relever ce secret avec `secret-tool search`** : la commande **affiche
      > le mot de passe en clair** sur la sortie standard. Erreur commise le 2026-09-07
      > pendant l'audit, le mot de passe SMB s'est retrouvé dans une transcription. Pour
      > vérifier qu'une entrée existe sans la lire, interroger la collection :
      > `busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked`

- [ ] **APRÈS UNE RÉINSTALLATION : réenregistrer le mot de passe SMB, une fois.** Le
      trousseau est chiffré par le mot de passe de session et **n'est pas transposable**
      d'une installation à l'autre (`dotfiles/README.md`, section « Limites ») : `stow`
      remet l'unité en place, le secret ne revient pas avec.

      Le geste : monter le partage **depuis Nautilus** et cocher « se souvenir pour
      toujours ». **`gio mount` en ligne de commande ne sait pas écrire dans le
      trousseau** — seul le dialogue GTK le fait ; `gvfsd` sait ensuite y *lire*. C'est
      l'unique raison pour laquelle Nautilus est gardé sur ce poste (§8).

      > **Cette étape ne figurait nulle part dans cette procédure jusqu'au 2026-09-07** :
      > elle n'existait que dans `dotfiles/README.md`, au titre des limites de `stow`.
      > Or sans elle `nas-infoadmin.service` échoue au premier login d'une machine neuve,
      > et le symptôme désigne le NAS ou l'unité — pas le trousseau. C'est le second trou
      > bloquant trouvé en rejouant la procédure sur papier.

## 8. Plomberie freedesktop et applications

**Les cinq cases ci-dessous étaient vides au 2026-09-07 et tout était installé depuis le
2026-09-04.** Versions et dates relevées par
`rpm -q --qf '%{installtime:date}  %{version}-%{release}'`, transactions recoupées dans
`dnf history` (dont l'heure est en **UTC**, deux heures de moins que le journal) :

- [x] `gvfs`, `gcr`, `xdg-desktop-portal-*` — `gvfs-smb` 1.60.2 (2026-09-04 16:52),
      `xdg-desktop-portal` 1.22.1, `-gtk` 1.15.3, `-hyprland` 1.4.1.
      **Les trois portails tournent**, vérifié le 2026-09-07 (`pgrep -f xdg-desktop-portal`)
- [x] `nautilus` 50.3 (2026-09-04 16:03) — installable seul, vérifié (89 exigences, aucun
      composant de bureau). Nécessaire au moins pour **écrire le mot de passe NAS dans le
      trousseau**, ce que `gio mount` ne sait pas faire
- [x] `chromium` 151.0.7922.173 (2026-09-04 15:50) — 21 paquets. Tourne en
      `--ozone-platform=wayland`, natif
- [x] `foot` 1.27.0 (2026-09-04 15:24, arrivé avec la transaction Hyprland) — **installé
      et versionné, mais ce n'est plus le terminal utilisé**, voir §8bis
- [x] `keepassxc` 2.7.12 (2026-09-04 15:24) — protocole de baseline du lab.
      **Installé, jamais lancé sur ce poste** : `~/.config/keepassxc/keepassxc.ini` ne
      contient que `ConfigVersion=2` et deux clés vides de générateur de mots de passe, et
      aucun processus `keepassxc` ne tourne. Cohérent avec le report de la décision
      « KeePassXC en fournisseur Secret Service » : le sujet n'est pas entamé

### 8bis. Terminal — kitty, et c'est tranché

**`kitty` 0.47.1, installé le 2026-09-04 à 15:56** (transaction 6, `dnf install kitty -y`,
6 paquets). Mesuré le 2026-09-07 : ce sont **deux instances de `kitty`** qui tournent dans
la session, aucune de `foot`.

Le dépôt annonçait « `foot` provisoire, kitty envisagé à court terme » depuis le
2026-09-04. **Le choix a été fait le jour même et n'a jamais été écrit** — trois jours
pendant lesquels la procédure décrivait un terminal qui n'était plus utilisé.

- [x] `kitty` installé et en service
- [ ] **`~/.config/kitty/` est VIDE** — aucun réglage n'a été posé. Le raisonnement du
      `foot.ini` (`dpi-aware`, échelle Wayland, densité du P2725DE à 2560x1440 sur 600 mm)
      **ne s'applique donc à rien aujourd'hui** : kitty tourne sur ses défauts. C'est la
      question du `foot.ini` qui se repose à l'identique, pas son réglage — à trancher à
      l'usage, puis à versionner en paquet `dotfiles/kitty`
- [ ] Décider du sort de `foot` : le garder comme terminal de secours (il ne coûte rien et
      sa config est déjà au dépôt) ou le retirer pour que la liste des paquets reste
      lisible. Ne pas retirer le paquet `dotfiles/foot` dans tous les cas — il documente
      un raisonnement, comme `dotfiles/sway`

### 8ter. RustDesk — outil de support, RPM hors dépôt

**C'est l'outil de travail du poste**, pas un accessoire : c'est par lui que se traitent
les tickets. Fiche complète dans `poste/README.md`, geste dans `procedure.md` §8ter ; ici,
ce que l'installation a appris.

```bash
# Le RPM est GÉNÉRÉ par Julien depuis la console RustDesk de l'entreprise :
# il embarque l'adresse du serveur et la clé publique de relais dans
# /usr/share/rustdeskadmin/custom.txt (base64). Il n'est donc pas téléchargeable
# depuis une URL publique — il se régénère.
#
# UNE SEULE COMMANDE : son %post active ET démarre le service lui-même.
sudo dnf install ~/rustdeskadmin-x86_64.rpm
```

> **Ce `%post` fait cinq choses hors du contrôle de `rpm`, lues avec
> `rpm -q --scripts rustdeskadmin` :** il copie l'unité dans
> `/etc/systemd/system/rustdeskadmin.service`, copie **deux** `.desktop` dans
> `/usr/share/applications/`, crée le lien `/usr/bin/rustdeskadmin` →
> `/usr/share/rustdeskadmin/rustdeskadmin`, puis enchaîne `systemctl daemon-reload`,
> `enable` et `start`.
>
> **Conséquence à connaître : `rpm -qf` ne reconnaît AUCUN de ces quatre fichiers.**
> `rpm -qf /usr/bin/rustdeskadmin` → « n'appartient à aucun paquet ». Un inventaire fondé
> sur `rpm -ql` passe donc à côté du lanceur, du binaire dans `$PATH` et de l'unité
> systemd. Le `%preun` les retire, donc ça reste cohérent — mais tant que le paquet est
> là, ces fichiers sont invisibles à toute question posée à `rpm`.
>
> C'est la deuxième fois qu'un RPM hors distribution surprend par son `%post` sur cette
> machine (le premier était `grub-btrfs`, qui réécrit `grub.cfg`). **Sur un RPM qui ne
> vient pas de la distro, `rpm -qp --scripts` avant `dnf install` n'est pas une
> précaution de puriste : c'est la seule façon de savoir ce qui va se passer.**

- [x] `rustdeskadmin` **1.4.9-0**, installé le 2026-09-07 à 08:57 (7 paquets).
      Dépôt d'origine `@commandline` — **c'est ainsi qu'un RPM local se signale**, et le
      seul moyen de le repérer dans un inventaire de paquets
- [x] `rustdeskadmin.service` `enabled` (`ExecStart=/usr/bin/rustdeskadmin --service`),
      **activé par le `%post`, pas à la main**. L'unité est **copiée** dans
      `/etc/systemd/system/` — pas livrée par le paquet, pas dans
      `/usr/lib/systemd/system/`. Trois processus tournent : `--service` (root, PID 1769),
      `--server` et `--tray` (session)
- [x] Effet visible dans la session : un périphérique **`rustdesk-uinput-keyboard`**
      apparaît dans `hyprctl devices`. C'est normal (injection d'événements pour le
      contrôle à distance), et c'est aussi la preuve que le service tourne

> **Le RPM n'est pas signé** — `rpm -qi` → `Signature : (none)`, `Vendor : rustdeskadmin
> <info@rustdeskadmin.com>`, `Build Host : build-linx`, construit le 2026-09-01. Ça se
> constate, ça ne se corrige pas : c'est le mode de distribution de l'outil. Conséquence
> concrète pour la reproductibilité : **la version exacte ne se retrouve pas dans un
> dépôt**, elle se régénère depuis la console. Noter la version installée est donc la
> seule trace utile.

> **Aucun port entrant n'a été ouvert dans `firewalld` pour lui**, et il fonctionne :
> `public` (la zone de `br0`) n'autorise que `dhcpv6-client`, `mdns` et `ssh`. RustDesk
> sort vers son relais, il n'écoute pas. Vérifier avant de « corriger » un pare-feu qui
> n'a rien cassé.

### 8quater. Virtualisation — la pile hôte de la VM Windows

La VM elle-même a sa fiche dans `poste/README.md`. Ce qui suit est ce qu'il faut
**réinstaller sur l'hôte** pour qu'elle démarre.

```bash
sudo dnf install -y qemu-kvm libvirt virt-manager edk2-ovmf swtpm-tools
sudo usermod -aG libvirt "$USER"        # puis re-login
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket
```

- [x] Posé le 2026-09-07 à 09:29 — **228 paquets**, de loin la plus grosse transaction
      après l'installation elle-même. Versions : `qemu-kvm` 10.2.2, `libvirt` 12.0.0,
      `virt-manager` 5.1.0, `edk2-ovmf` 20260812, `swtpm-tools` 0.10.2
- [x] `jzielona` est dans le groupe **`libvirt`** (981) — sans ça, `virsh -c qemu:///system`
      passe par polkit à chaque appel
- [x] **`edk2-ovmf` et `swtpm-tools` ne sont pas optionnels pour Windows 11** : l'un fournit
      `OVMF_CODE_4M.secboot.qcow2` (UEFI + Secure Boot dans l'invité), l'autre le TPM
      émulé. Sans eux, Windows 11 refuse de démarrer et le message ne dit pas lequel manque
- [x] **Le sous-volume `/var/lib/libvirt/images` doit exister AVANT la première image** —
      voir §10 : il est en `+C` (NOCOW) et hors des instantanés. Sous-volume ID 259

**Le pont `br0` — trois profils NetworkManager, et le troisième est le plus important.**
Refait le 2026-09-07 à 09:36. La VM est sur le réseau de l'employeur en direct, pas
derrière du NAT :

| Profil | Type | Rôle |
|---|---|---|
| `br0` | bridge | porte l'adresse, `stp=false`, `mac-address=E8:CF:83:89:18:D4` (celle de la carte physique) |
| `br0-port` | ethernet | `enp0s31f6` rattachée au pont (`controller=br0`, `port-type=bridge`) |
| `Connexion filaire 2` | ethernet | **`autoconnect=false`** — le profil DHCP d'origine sur `enp0s31f6` |

**La troisième ligne est celle qu'on oublie et qui casse tout.** Si le profil Ethernet
d'origine garde `autoconnect=true`, il se dispute la carte avec `br0-port` au démarrage,
de façon non déterministe. Le désactiver n'est pas du ménage, c'est la moitié du travail.

- [x] Reprise de la MAC physique sur le pont : sans ça, le réseau de l'employeur voit
      une nouvelle adresse matérielle apparaître
- [x] `virbr0` (réseau `default`, NAT 192.168.122.0/24) est **actif et `autostart`, mais
      `linkdown`** — aucune VM ne l'utilise. Laissé tel quel : il ne gêne pas, et le
      retirer casserait la création d'une VM de test au NAT

### 8quinquies. Outils d'administration réseau

Ajoutés le 2026-09-07, en fin de journée, au fil d'un besoin réel :

- [x] `bind-utils` 9.18.50 (11:26) — `dig`, `host` : 5 paquets
- [x] `nmap` 7.92 (11:40) — 2 paquets
- [x] `tcpdump` 4.99.6 (11:40) — 1 paquet

**Ce sont des outils d'alternance SRC, pas des dépendances du bureau** : ils appartiennent
à la même famille que `nvme-cli`, `efibootmgr` ou `cryptsetup`, sauf que ceux-là étaient
déjà dans l'image (installés à 14:00:2x le 2026-09-04, avec la transaction 1). La
distinction se lit dans la date d'installation, pas dans la raison `dnf`.

### Flatpak — FAIT le 2026-09-07

**Absent de l'image minimale**, contrairement à Workstation où il était livré et où la
case « dépôts tiers » du premier démarrage ajoutait Flathub. Ici les trois gestes sont à
poser à la main :

```bash
sudo dnf install -y flatpak
# le paquet fournit les dépôts « fedora » et « fedora-testing », PAS Flathub
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub com.mattermost.Desktop com.mikrotik.WinBox
flatpak list --app --columns=application,version,installation
```

- [x] `flatpak` 1.18.2, dépôt `flathub` ajouté en portée **system**
- [x] `com.mattermost.Desktop` 6.3.0 et `com.mikrotik.WinBox` 4.3, **les deux en `system`**

> **Changement assumé par rapport à l'itération 01 :** WinBox y était installé en portée
> `user`, ce que `poste/README.md` qualifiait d'« incohérence à connaître » (un second
> dépôt `flathub` au niveau utilisateur, et une application capturée par les instantanés
> `/home` au lieu de `/`). Les deux sont désormais en `system` : un seul dépôt, une seule
> portée, et `flatpak list --columns=…,installation` redevient lisible d'un coup d'œil.

- [ ] **Après un `dnf install flatpak`, se déconnecter/reconnecter** — voir la section
      suivante : sans ça les applications sont installées mais **invisibles au lanceur**

### `XDG_DATA_DIRS` : les Flatpaks n'apparaissent pas dans le lanceur — FAIT le 2026-09-07

Symptôme : `flatpak list` montre les applications, `Super+R` ne les propose pas.

**Cause, mesurée sur le processus en session** (`tr '\0' '\n' < /proc/$(pgrep -x Hyprland)/environ`) :
`XDG_DATA_DIRS=/usr/local/share:/usr/share` — les chemins Flatpak manquent, alors que les
`.desktop` sont bien dans `/var/lib/flatpak/exports/share/applications/`.

Fedora livre pourtant `/etc/profile.d/flatpak.sh`, qui fait exactement le travail. **Mais
`profile.d` ne s'exécute que dans un shell de LOGIN**, et la session est lancée par
greetd → uwsm → Hyprland, qui ne source jamais `/etc/profile`. Le script est là et ne
tourne pas.

Réponse retenue — le fichier que `man uwsm` prévoit pour ça (section CONFIGURATION,
« Environment (shell) to be sourced for the graphical session ») :

```bash
mkdir -p ~/.config/uwsm          # AVANT le stow, sinon tree folding (voir ci-dessous)
cd ~/linux && stow -n -v -t ~ -d dotfiles uwsm
stow -v -t ~ -d dotfiles uwsm
# puis déconnexion / reconnexion — l'environnement de session ne se recharge pas
```

Le paquet `dotfiles/uwsm/` contient un `env` d'une seule ligne utile, qui **source le
script de Fedora** plutôt que de coder les chemins en dur — il interroge
`flatpak --installations` et couvre donc les portées `system` et `user`, même si elles
changent plus tard.

**Piège Stow, le troisième de la même famille** (après `~/.bashrc.d` et
`~/.config/systemd`) : `stow -n -v` annonçait
`LINK: .config/uwsm => ../linux/dotfiles/uwsm/.config/uwsm`, donc tout `~/.config/uwsm/`
devenait le dépôt — et `uwsm select` y écrit un `default-id`, qui se serait retrouvé
versionné. Faire exister le dossier avant suffit : la simulation passe alors à
`LINK: .config/uwsm/env`.

Vérification, sur le processus en session et pas dans un shell quelconque :

```bash
tr '\0' '\n' < /proc/$(pgrep -x Hyprland)/environ | grep XDG_DATA_DIRS
```

Obtenu le 2026-09-07 :
`/home/jzielona/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share`

## 8sexies. Reliquats — état des lieux du 2026-09-07

Question posée : le poste porte-t-il la pollution du modèle de test (Sway, GNOME, tout ce
qui a été empilé sur l'itération 01) ? **Non, et c'est l'image minimale qui l'a évité, pas
un nettoyage.** Rien de tout ça n'a jamais été installé ici. Vérifié :

| Cherché | Résultat |
|---|---|
| `sway`, `swaybg`, `swaylock`, `waybar` | **absents** |
| `gnome-shell`, `mutter`, `gnome-session`, `gdm` | **absents** |
| `firefox` | **absent** |
| `/etc/sway/`, `/etc/gdm/`, `/etc/gnome*` | **inexistants** |
| Paquets orphelins (`dnf repoquery --unneeded`) | **0** |

Les paquets `gnome-*` restants sont **tous des dépendances de Nautilus**, assumées :
`gnome-desktop3`, `gnome-desktop4`, `gnome-autoar`, `gsettings-desktop-schemas`,
`nautilus-extensions`. Plus `gnome-keyring` (dépendance faible) et `gnome-keyring-pam`
(voulu). `wlroots` reste, et c'est **normal** : c'est le compositeur embarqué du greeter
Noctalia qui en a besoin — aucun paquet ne l'exige, seul le binaire compilé s'y lie.

### Ce qui reste vraiment, par ordre d'importance

**1. La chaîne de compilation du greeter : 100 paquets, 443 Mo, dont 65 `-devel`.**
C'est le seul reliquat de taille, et c'est un **choix**, pas un oubli. La transaction 8 a
installé `meson`, `gcc-c++`, `just` et 65 paquets de développement pour compiler le
greeter — qui est compilé depuis le 2026-09-04. Deux options, à trancher :

- **Les garder** : recompiler le greeter (mise à jour, changement d'écran, nouvelle
  version de Noctalia) reste possible hors ligne et sans réfléchir.
- **Les retirer** : `sudo dnf remove` sur la liste de la transaction 8. On regagne 443 Mo
  et la liste de paquets redevient lisible — mais **la prochaine recompilation redemande
  les 100 paquets**, donc du réseau et cinq minutes.

443 Mo sur un disque de 236 Go dont 180 sont libres n'est pas un argument. **La vraie
question est la lisibilité de l'inventaire** : 65 `-devel` sur 101 paquets explicites
noient les 36 autres. Aucune urgence, mais à décider une fois pour de bon plutôt qu'à
chaque relecture.

**2. Trois clés `dconf` orphelines, et le piège qu'elles illustrent.**
`dconf dump /org/gnome/` rend encore :

```
[login-screen]
enable-fingerprint-authentication=false
enable-smartcard-authentication=false
enable-switchable-authentication=false
```

Ce sont des clés du schéma **`org.gnome.login-screen`, livré par GDM** — qui n'est pas
installé. Vérifié : aucun fichier de `/usr/share/glib-2.0/schemas/` ne définit ce schéma,
et `gsettings get org.gnome.login-screen …` répond « Le schéma n'existe pas ».

> **Une clé `dconf` peut exister sans son schéma, et personne ne s'en plaint.** `dconf`
> est une base clé/valeur ; les schémas GSettings ne sont qu'une **description** posée
> par-dessus. Retirer le paquet qui livre un schéma laisse donc les valeurs en place,
> illisibles par `gsettings` mais toujours présentes dans la base. Conséquence pour un
> inventaire : `dconf dump` montre des réglages **qui ne sont plus lus par rien**, et rien
> ne le signale. Même famille que « un paquet installé n'est pas un paquet utilisé », au
> niveau des données de configuration.

Purge sans conséquence : `dconf reset -f /org/gnome/login-screen/`. Le reste de
`/org/gnome/` est **utile et à garder** : `desktop/interface` porte `color-scheme='prefer-dark'`
et le thème de curseur, lus par les applications GTK ; `nautilus/*` est écrit par Nautilus.

**3. Un fichier inerte, déjà connu sous une autre forme.**
`/etc/X11/xorg.conf.d/00-keyboard.conf` existe (posé par `systemd-localed`, paquet
`systemd`) et **n'est lu par personne** : son propre en-tête dit « read by systemd-localed
and Xorg », et `xorg-x11-server-Xorg` n'est pas installé — seul `Xwayland` est là, et il
ne lit pas ce fichier.

**Détail qui compte davantage que son inertie : il dit `XkbVariant "oss"`, pas `azerty`.**
La note de `CLAUDE.md` sur ce piège affirme qu'il dit `fr/azerty` ; c'était vrai sur
l'itération 01, ce ne l'est pas ici. Donc même le jour où un composant le lirait, il
donnerait une **autre** disposition que celle configurée dans `hyprland.lua` et le
`greeter.toml`. À laisser tel quel — `localectl` le régénère — mais à ne pas prendre pour
une source de vérité du clavier.

**4. Deux dormants, qui ne sont pas des reliquats mais y ressemblent.**

- **`localsearch`** (l'ex-`tracker-miners`, dépendance faible de Nautilus) est installé et
  **ne tourne pas** : son autostart XDG porte `OnlyShowIn=GNOME;KDE;XFCE;X-IVI;Unity;`,
  qui exclut Hyprland. Vérifié : service `inactive`, aucun processus, **aucun cache
  d'index**. Il n'indexe donc pas le home. Même mécanisme que les trois composants
  `gnome-keyring` filtrés par `OnlyShowIn` — un paquet peut être là et n'être **jamais**
  démarré.
- **`~/.dotfiles-backup/hyprland.lua.autogenere`** : le fichier qu'Hyprland avait généré
  pour lui-même, écarté par `stow`. Gardé volontairement — c'est la référence du format
  Lua livré par le paquet.

### Ce qui n'a pas été vérifié, et pourquoi

Le SSD USB (itération 01) porte, lui, toute l'accumulation du modèle de test. **Il n'a pas
été audité** : il va probablement être formaté (décision de Julien, 2026-09-07), donc son
état n'a pas d'avenir. Ce qui doit en sortir avant le formatage est traité dans
`journal/01-fedora-44-workstation/README.md`.

## 9. Dotfiles

```bash
sudo dnf install stow
cd ~/linux/dotfiles
# écarter d'abord les fichiers par défaut de la distro : stow ne remplace jamais
# un vrai fichier — c'est une sécurité, pas un bug
stow -v -t ~ hypr foot          # fait le 2026-09-04
mkdir -p ~/.config/uwsm         # AVANT, contre le tree folding
stow -v -t ~ uwsm               # fait le 2026-09-07
stow -v -t ~ bash git nas desktop
```

- [x] `hypr` et `foot` posés (2026-09-04)
- [x] `uwsm` posé (2026-09-07) — `XDG_DATA_DIRS` pour les Flatpaks
- [x] `nas` — **posé, mais ça n'avait pas été noté** ; l'unité tourne depuis le 2026-09-04
- [ ] `bash`, `git`, `desktop` — **toujours pas posés au 2026-09-07** : `~/.bashrc`,
      `~/.bash_profile` et `~/.gitconfig` sont encore les fichiers par défaut de Fedora et
      `~/.bashrc.d` n'existe pas. Rien du paquet `bash` du dépôt n'est en service.
      Re-vérifié par `stow -n -v` le 2026-09-07 : `bash` et `git` **refusent** (conflit sur
      des vrais fichiers), `desktop` poserait le lien sans conflit

**L'état exact des liens, mesuré le 2026-09-07** — 4 paquets sur 7 :

| Paquet | Posé ? | Preuve |
|---|---|---|
| `hypr` | oui | `~/.config/hypr/hyprland.lua` → dépôt, contenu identique |
| `foot` | oui | `~/.config/foot` → dépôt (lien de **dossier**, tree folding) |
| `nas` | oui | `~/.config/systemd/user/nas-infoadmin.service` → dépôt |
| `uwsm` | oui | `~/.config/uwsm/env` → dépôt |
| `bash` | **non** | `~/.bashrc` et `~/.bash_profile` datés du **16 janv. 2026** = l'ISO |
| `git` | **non** | `~/.gitconfig` écrit à la main : `[user]` seul, 3 lignes |
| `desktop` | **non** | `~/.local/share/applications/` ne contient qu'un fichier de Claude Code |

**Ce que le paquet `bash` non posé coûte concrètement**, pour que ce ne soit pas une ligne
abstraite : pas d'historique élargi ni horodaté (`HISTSIZE=1000` au lieu de 50000, aucun
`HISTTIMEFORMAT`), pas de `~/.bashrc.d`, pas d'alias. Sur un poste de lab dont toute la
méthode repose sur « retrouver ce qu'on a tapé », c'est la perte la plus gênante des trois.

**Et `desktop` n'a rien à poser d'utile aujourd'hui** : son unique entrée
`vm-win11.desktop` lançait la VM via `virt-manager` — or la VM tourne et se retrouve par
le lanceur Noctalia. À reprendre quand on saura ce qu'on veut y mettre, plutôt qu'à poser
pour cocher une case.

### Deux fichiers de configuration hors paquet, trouvés le 2026-09-07

- `~/.config/git/ignore` contient `**/.claude/settings.local.json`. C'est un vrai geste,
  utile et non versionné : à **intégrer au paquet `git`** (`dotfiles/git/.config/git/ignore`),
  pas à laisser dans un coin du home.
- `~/.config/autostart/mattermost-desktop.desktop` a été créé **par Mattermost lui-même**
  au premier lancement (`Exec=/app/main/mattermost-desktop`). Rien à versionner : il se
  recréera. À savoir pour ne pas le prendre pour une configuration maison.

> **Un `[ ]` peut vouloir dire « pas fait » ou « fait, pas noté ».** Constaté le
> 2026-09-07 : `nas` était déployé et l'unité active, mais la case était vide. La seule
> façon de trancher est de regarder la machine — `ls -l` sur les cibles, pas la procédure.

## 10. Instantanés — FAIT le 2026-09-04, complété le 2026-09-07

- [x] `snapper`, configurations `root` et `home` — 0.13.0, dépôt Fedora (2026-09-04 17:06).
      Réglages relevés le 2026-09-07, identiques pour les deux configs :
      `TIMELINE_LIMIT_DAILY=7`, tous les autres paliers à `0`, `NUMBER_LIMIT=10`,
      `SPACE_LIMIT=0.5`, `FREE_LIMIT=0.2`, `ALLOW_USERS="jzielona"`, `SYNC_ACL="yes"`.
      **Seule la rétention quotidienne est active** : pas d'horaire, pas d'hebdomadaire.
      Sur un poste allumé en journée, ça donne un instantané par jour ouvré et une
      profondeur d'une semaine — état constaté : `root` 1, 7, 8, 9, 10, 11 ; `home` 1, 7,
      8, 9. `ALLOW_USERS` explique pourquoi `/.snapshots` est listable sans `sudo`.
- [x] **Convertir `/var/lib/libvirt/images` en sous-volume AVANT tout instantané** —
      sous-volume ID 259, `+C` posé à vide, `restorecon` → `virt_image_t` (2026-09-04)
- [x] `snapper-timeline.timer` et `snapper-cleanup.timer` — les deux `enabled` + `active`.
      Attention, `timeline` a `UnitFilePreset=disabled` : installer `snapper` ne suffit pas
- [x] **`grub-btrfs` — hors dépôt Fedora, posé le 2026-09-07 depuis un COPR.**

      ```bash
      # sauvegarde AVANT : le %post du RPM lance grub2-mkconfig tout seul
      sudo snapper -c root create -d "avant grub-btrfs"
      sudo cp -a /boot/grub2/grub.cfg /root/grub.cfg.avant-grub-btrfs

      sudo dnf copr enable pego-copr/grub-btrfs
      sudo dnf install grub-btrfs          # tire inotify-tools
      sudo systemctl enable --now grub-btrfsd
      ```

      **Origine et version :** COPR `pego-copr/grub-btrfs`, paquet
      `grub-btrfs-4.14-1.fc44.noarch`, script en version `master-2026-05-31T15:55:08+00:00`.
      Clé OpenPGP `3EEC594E5659BB518F800A200E5CA0BCBECCC126`.
      **Ne pas prendre `kylegospo/grub-btrfs`** : ses chroots incluent `fedora-44` mais le
      paquet est un instantané git de 2022 en release `.fc38`.

      **Aucune configuration à écrire** — le `config` livré détecte Fedora, l'unité
      surveille déjà `/.snapshots`. Vérifié avant installation avec `rpm -qlp`, `rpm -qRp`
      et `rpm -qp --scripts` sur le RPM téléchargé.

- [x] **Vérifier que ça marche vraiment, en DEUX mesures** (2026-09-07) — la documentation
      dit que le `/boot` séparé est géré, elle ne prouve pas que ça marche sur cette machine :

      ```bash
      sudo sh -c 'grep -c menuentry /boot/grub2/grub-btrfs.cfg'          # attendu : > 0
      sudo sh -c 'grep -n "41_snapshots" /boot/grub2/grub.cfg'           # attendu : un configfile
      ```

      La seconde est la moins évidente et la plus importante : sans elle, des entrées
      peuvent exister dans un fichier qu'aucun `configfile` ne lit. Résultat obtenu :
      11 entrées, et `grub.cfg:266-274` les source bien.

      **Forme exacte d'une entrée générée, relevée le 2026-09-07** — c'est elle qui prouve
      que le `/boot` séparé est géré :

      ```
      search --no-floppy --fs-uuid --set=root 4a4ba7f7-…     <- l'ext4 /boot VIVANTE
      linux "/vmlinuz-7.1.13-200.fc44.x86_64" root=UUID=39959ad8-… \
            rd.luks.uuid=luks-680cb146-… rhgb quiet \
            rootflags=compress=zstd:1,x-systemd.device-timeout=0,subvol="root/.snapshots/10/snapshot"
      ```

      Le noyau vient de la partition `/boot` en service (chemin relatif à elle), la racine
      du sous-volume de l'instantané. **Deux formes coexistent et il faut le savoir :**
      l'entrée BLS vivante porte `rootflags=subvol=root` tout court, le `grub-btrfs.cfg`
      généré reconstruit la ligne depuis `GRUB_CMDLINE_LINUX` + les options de `fstab`.
      Chercher le même motif dans les deux fichiers ne donne rien.

- [x] **`grub-btrfsd` ne surveille QUE `/.snapshots`** — vérifié le 2026-09-07 dans
      l'unité : `ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots`, et le processus
      `inotifywait` associé ne regarde que ce dossier. **Les instantanés de `/home`
      n'apparaîtront jamais au menu GRUB**, ce qui est cohérent : on ne démarre pas sur un
      `/home`. À ne pas prendre pour un oubli de configuration.
      L'unité est installée dans **`/etc/systemd/system/`** par le RPM du COPR, pas dans
      `/usr/lib/systemd/system/` — donc modifiable sans surcharge, mais aussi survivante à
      une désinstallation.

- [ ] **Aucune sauvegarde de `grub.cfg` n'existe sur `/boot`** — vérifié le 2026-09-07 :
      `/boot/grub2/` ne contient que `grub.cfg` (réécrit par le `%post` du RPM le
      2026-09-07 à 08:59) et `grub-btrfs.cfg`. La copie de sécurité prise avant
      l'installation était mise dans `/root/grub.cfg.avant-grub-btrfs` — à confirmer
      qu'elle y est encore, sinon la précaution documentée plus haut n'a plus d'objet

- [ ] Répéter **à froid** la porte de sortie manuelle, pas le jour où ça casse. Mesuré sur
      l'entrée vivante le 2026-09-07 (`sudo grubby --info=ALL`) :

      ```
      args="ro rootflags=subvol=root rd.luks.uuid=luks-680cb146-… rhgb quiet"
      ```

      Au menu GRUB, touche `e`, puis remplacer `subvol=root` par
      **`subvol=root/.snapshots/<N>/snapshot`**.
      *Le chemin a été corrigé le 2026-09-07* — il portait `.snapshots/<N>/snapshot`, sans
      le préfixe `root/`, et n'aurait pas démarré. Démenti dans la fiche « Instantanés
      Btrfs » de `poste/README.md`.

      **À quoi s'attendre, documenté le 2026-09-07 — ne pas chercher une panne qui n'en
      est pas une.** Le démarrage sera **dégradé** : `/var` et `/var/log` sont dans le
      sous-volume `root`, donc dans l'instantané, donc en lecture seule. Le projet exige
      `/var` en sous-volume séparé pour un démarrage propre (avertissement en tête de
      `41_snapshots-btrfs`), sa parade overlayfs demande **dracut ≥ 109** alors que la
      machine est en **108**, et l'issue #324 décrit ce cas exact toujours **non résolu**.
      **Objectif du test : obtenir un shell suffisant pour lancer `snapper rollback`.** Pas
      une session graphique

## 11. Reprise depuis l'ancien disque — FAITE le 2026-09-07, et volontairement partielle

- [x] **VM Windows reprise et en service.** Mesuré le 2026-09-07 : le domaine `win11`
      tourne, l'agent invité répond (`guest-info` → version **110.2.3**), le disque est
      `/var/lib/libvirt/images/win11.qcow2` et le NVRAM
      `/var/lib/libvirt/qemu/nvram/win11_VARS.qcow2` (561 ko) est bien là.

      | Mesure | Valeur |
      |---|---|
      | Occupation **réelle** (`du -sh`) | **46 Go** |
      | Taille **apparente** (`du -sbh`) | **101 Go** |
      | Attribut | `+C` (NOCOW) sur le fichier **et** sur le sous-volume |
      | Étiquette SELinux | `svirt_image_t:s0:c159,c991` |

      **L'écart 46/101 est la preuve que la copie creuse a marché.** Sans
      `cp --sparse=always`, le fichier occuperait ses 101 Go apparents — sans erreur, sans
      avertissement. C'est la seule façon de vérifier après coup : comparer `du -sh` et
      `du -sbh`. Le fichier a grossi depuis l'ancien disque (31 Go réels en septembre), ce
      qui est normal, Windows ayant tourné.

      L'étiquette SELinux avec les catégories MCS (`c159,c991`) confirme que
      `restorecon` — ou libvirt lui-même au démarrage du domaine — a fait son travail :
      un `mv` aurait laissé l'étiquette d'origine et `qemu`, confiné, n'aurait pas pu lire
      le fichier.

- [x] **Rien d'autre n'est repris, intentionnellement.** Décision de Julien le 2026-09-07 :
      la VM était le seul élément dont il avait réellement besoin, le reste de l'ancien
      disque étant du parasite. Écrit ici pour que ça ne soit pas relu plus tard comme une
      étape oubliée : **l'étape est close, pas en attente.**
      (La base KeePassXC et les clés relèvent de la gestion des secrets, hors périmètre du
      dépôt — voir `CLAUDE.md`.)

- [x] Ces fichiers étaient sur `sda3`, sous-volume `root`, et demandaient `sudo`

> **L'ancien disque est encore monté, en lecture seule et hors `fstab`.** Vérifié le
> 2026-09-07 : `/mnt/ancien` (`sda3[/root]`) et `/mnt/ancien-home` (`sda3[/home]`), tous
> deux en `ro`. Ces montages ne sont dans aucun fichier de configuration — ils ont été
> posés à la main pour la reprise et **ne survivront pas au prochain redémarrage**. Le
> `ro` est une bonne précaution : le disque porte l'itération 01, qui doit rester intacte.
> Reste à décider s'ils doivent être démontés maintenant que la reprise est finie.

## 12. Vérifications de fin — passées le 2026-09-07, sauf trois

- [x] **Redémarrage complet** : dernier boot le 2026-09-07 à 10:27, greeter affiché,
      session ouverte via greetd sur tty1. **LUKS déverrouillé à la phrase de passe, pas
      par le TPM** — l'enrôlement reste la seule case importante de §1
- [x] **Trousseau déverrouillé, `~/nas` monté** — mesures en §7
- [x] Portails : les **trois** tournent (`xdg-desktop-portal`, `-gtk`, `-hyprland`)
- [ ] Portails : vérifier à l'**usage** la capture d'écran et le sélecteur de fichiers.
      Trois processus qui tournent ne prouvent pas qu'un portail répond — même famille que
      « un paquet installé n'est pas un paquet utilisé »
- [ ] Agent SSH fonctionnel, `git ls-remote` aboutit **dans un vrai terminal**
- [ ] Veille / reprise
- [x] **`bin/snapshot.sh --poste` — première capture faite le 2026-09-07**, dans
      `installation/etats/2026-09-07/`.

      > **Le script ne savait pas capturer ce poste.** Il n'écrivait que dans
      > `journal/<itération>/`, et le poste de référence **n'est pas une itération** : la
      > case ci-dessus était donc infaisable telle quelle. Corrigé le 2026-09-07 par
      > l'option `--poste`, qui écrit dans `installation/etats/<date>/` et **n'écrit jamais
      > de baseline** — une baseline ici mesurerait l'image ISO, pas la distribution.
      > L'écart affiché est celui avec la **capture précédente**, la question utile sur ce
      > poste n'étant pas « qu'ai-je ajouté à la distro » mais « qu'ai-je changé depuis la
      > dernière fois ». Trois mesures ont aussi été ajoutées à `system.md`, absentes et
      > structurantes ici : version du compositeur, nombre de volumes LUKS, état de Secure
      > Boot et du TPM2.

- [ ] Définir un **nom de machine**. `hostnamectl` → `Static hostname: (unset)`,
      `/etc/hostname` absent, le `fedora` affiché partout est le nom **transitoire** par
      défaut. Sans conséquence technique connue ici, mais deux effets réels : le nom
      apparaît dans les journaux et sur le réseau, et un poste d'entreprise identifié
      « fedora » n'est pas identifié
