# Procédure — construire ce poste, dans l'ordre

> Même convention que `uc/installation/procedure.md` : ce fichier ne contient que des
> GESTES, dans l'ordre où ils ont été (ou seront) tapés. Renvoi à `mesures.md` par numéro
> de section pour le pourquoi et les valeurs exactes. **Pas de section virtualisation /
> pont réseau / reprise VM** : VM Windows mise de côté (voir `README.md`).

**Convention :** `→` = vérification que l'étape a marché. `⚠ ORDRE` = position contrainte.

---

## 1. Installation de base — déjà faite, mesurée le 2026-09-11

Rien à taper : l'installateur avait déjà été déroulé avant cette session. Constat, pas
geste — détail dans `mesures.md` §1.

- [ ] **Enrôler le TPM2 sur LUKS** (`systemd-cryptenroll`) — même tâche que sur `uc`,
      jamais faite ici non plus.

## 2. Accès au dépôt

Le dépôt était déjà cloné, mais **`~/.ssh/config` manquait** — `git ls-remote` échouait
sur `Permission denied (publickey)`. Corrigé le 2026-09-11 :

```bash
# ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/gitlinux
    IdentitiesOnly yes
```
```bash
chmod 600 ~/.ssh/config
```

→ `git ls-remote origin` aboutit

## 3. Mise à jour complète — sans objet

Comme sur `uc` : une netinstall naît à jour.

## 4. Compositeur — Hyprland

### 4.0 Pilotes graphiques — EN PREMIER

```bash
sudo dnf install mesa-dri-drivers
```

### 4.1 Le COPR et la transaction

```bash
sudo dnf copr enable dtutila/hyprland
sudo dnf install -y hyprland hyprland-guiutils xdg-desktop-portal-hyprland \
                    xdg-desktop-portal-gtk noctalia stow keepassxc
```

→ `dnf repoquery --installed --qf '%{name} reason=%{reason} from=%{from_repo}\n' uwsm`
  → `reason=Weak Dependency` — confirmé, comme sur `uc`.
→ versions : `mesures.md` §4.

### 4.2 Premier lancement AVANT la config — ordre inversé par rapport à `uc`

Sur `uc`, `dotfiles/hypr` existait déjà et se stowait avant le premier lancement. Ici il
n'existait pas : Hyprland a d'abord tourné sans configuration à nous, depuis un autre tty
(`Ctrl+Alt+F3`), pour mesurer les vrais noms de sortie et le clavier réel.

→ `hyprctl monitors all` → `eDP-1`, 1920x1200, LG Display
→ `hyprctl devices`, depuis la session active (`loginctl show-seat seat0 -p
  ActiveSession` doit désigner le tty où tourne Hyprland, sinon liste vide — même piège
  que sur `uc`) → clavier réel `at-translated-set-2-keyboard`, pavé tactile
  `ven_0488:00-0488:108b-touchpad`

### 4.3 La configuration

```bash
mkdir -p ~/.dotfiles-backup
mv ~/.config/hypr/hyprland.lua ~/.dotfiles-backup/hyprland.lua.genere-2026-09-11

cd ~/linux/portable/dotfiles
stow -n -v -t ~ hypr
stow    -v -t ~ hypr

hyprctl reload
```

→ `hyprctl configerrors` vide
→ `hyprctl devices` → clavier interne en `French (AZERTY)`
→ `hyprctl binds` → clé courte `ampersand` sur l'espace 1, pas la chaîne entière

Contenu de `dotfiles/hypr` : écran unique `eDP-1` + règle générique pour toute sortie
future (dock), sans ancrage de workspace par écran — reporté tant qu'un dock n'a pas été
testé. Pas de section 3CX (reprise de `uc`) : Chromium n'est pas installé ici.

### 4.4 Kitty, sorti de l'ordre normal

Sans terminal, `SUPER+Q` (lié dans `hyprland.lua`) n'ouvrait rien. Avancé depuis §8 :

```bash
sudo dnf install kitty
cd ~/linux/portable/dotfiles
stow -n -v -t ~ kitty
stow    -v -t ~ kitty
```

→ `readlink -f ~/.config/kitty/kitty.conf` pointe dans le dépôt

## 5. Shell — Noctalia

Aucun geste, comme sur `uc` : arrivé avec la transaction §4.1. Pas encore vérifié en
fonctionnement réel — `hyprctl layers` était vide au moment testé, mais c'est attendu tant
que la session n'est pas lancée par `uwsm` via le greeter (voir §4.3) : `noctalia --daemon`
ne se lance qu'au hook `hyprland.start`, jamais rejoué par un simple `reload`.

## 6. Greeter — greetd + greeter Noctalia

### 6.1 Dependances de compilation

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

Identique a uc, memes substitutions (libglvnd-devel, greetd-selinux). Compte greetd cree
par le scriptlet sysusers du paquet.

### 6.2 Compiler, meme tag que uc

```bash
git clone https://github.com/noctalia-dev/noctalia-greeter ~/src/noctalia-greeter
cd ~/src/noctalia-greeter
git checkout v1.3.1
git rev-parse HEAD
```

Commit 6379fe287bb02b0bb538ad155fe18b1bf8615daf, identique a uc.

```bash
just configure-release && just build-release
sudo meson install -C build-release
```

Les trois scripts (setup_greeter_system.sh, greetd_setup_lib.sh, setup_greetd_pam.sh) ont
ete lus en entier avant execution. Deux differences avec uc, sur cette version (11 cibles
de compilation) :

- resolve_greeter_user a trouve greetd tout seul, via
  noctalia-greeter-apply-appearance --print-greeter-user, pas de repli sur "greeter" a
  corriger a la main comme sur uc. Mecanisme non elucide, mesure et suffisant.
- greeter.toml genere par le script est un squelette de commentaires, pas rempli : les
  sections session/keyboard/output restent a ecrire a la main, comme sur uc. Ce que le
  script gere sous ce nom est la synchro d'apparence (sync.toml), un fichier different.

```bash
sudo ./scripts/setup_greeter_system.sh
```

Verifie : PAM patche (session required pam_systemd.so ajoute a /etc/pam.d/greetd),
/var/lib/noctalia-greeter cree avec proprietaire greetd:greetd, bloc de config imprime
avec user = "greetd" deja correct.

TROU CONNU, comme sur uc : /etc/greetd/config.toml n'est pas dans ce depot -
`sudo cat /etc/greetd/config.toml` pour le relever si besoin.

### 6.3 Configuration greetd et greeter.toml

```bash
sudo useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter greetd 2>/dev/null || true

sudo cp -a /etc/greetd/config.toml /etc/greetd/config.toml.bak 2>/dev/null || true
sudo tee /etc/greetd/config.toml >/dev/null <<'GREETD_CONFIG'
[terminal]
vt = 1

[default_session]
command = "/usr/local/bin/noctalia-greeter-session"
user = "greetd"
GREETD_CONFIG
```

ATTENTION : pas de "sudo systemctl enable --now greetd" ici, trop tot avant le
trousseau (paragraphe 7).

```bash
sudo tee /var/lib/noctalia-greeter/greeter.toml >/dev/null <<'EOF'
# Reglages du portable - minimal, l'apparence vient de la synchro Noctalia (sync.toml).

[session]
default = "Hyprland (uwsm-managed)"

[keyboard]
layout = "fr"
variant = "azerty"

[idle]
timeout = 300
EOF
```

Pas de section [output] : un seul ecran, rien d'ambigu, a ajouter si un dock est un jour
mesure. "Hyprland (uwsm-managed)" confirme present dans
/usr/share/wayland-sessions/hyprland-uwsm.desktop.

### 6.4 SELinux

```bash
sudo semanage fcontext -a -t xdm_var_lib_t '/var/lib/noctalia-greeter(/.*)?'
sudo restorecon -Rv /var/lib/noctalia-greeter
```

Verifie : `ls -Zd /var/lib/noctalia-greeter` -> xdm_var_lib_t

### 6.5 Tmpfiles.d, decision : pas de surcharge, contrairement a uc

Le fichier livre (/usr/local/lib/tmpfiles.d/noctalia-greeter.conf) code en dur
greeter:greeter, absent ici, meme constat que uc. Mais l'effet differe :
systemd-tmpfiles-setup.service est static, execute une seule fois par demarrage, deja
passe a ce boot avant meme l'installation du paquet. La ligne fautive ne sera relue qu'au
prochain redemarrage, et a ce moment le dossier existera deja avec le bon proprietaire
(pose par setup_greeter_system.sh lui-meme) : elle echouera juste a resoudre "greeter",
sans rien modifier. Cout de ne rien faire : un message d'erreur inoffensif au prochain
boot, un dossier en 0755 au lieu de 0750 sans secret dedans. Decision : pas de fichier
/etc/tmpfiles.d/ ici, la mecanique reelle differe de uc, ce n'est pas un oubli.

## 7. Trousseau et NAS

```bash
sudo dnf mark user gnome-keyring   # dnf5 : reason=Weak Dependency sinon, deja constate
sudo dnf install gnome-keyring-pam
```

Ajouter la ligne manquante apres `password include system-auth` dans `/etc/pam.d/greetd`
(les deux autres, `-auth`/`-session`, sont deja livrees par Fedora et inertes tant que le
paquet manque) :

```bash
sudo sed -i '/^password   include     system-auth$/a -password   optional    pam_gnome_keyring.so use_authtok' /etc/pam.d/greetd
```

```bash
sudo systemctl enable greetd
sudo systemctl set-default graphical.target
sudo reboot
```

Verifie apres redemarrage : `graphical-session.target` actif, `hyprctl layers` montre
Noctalia, clavier en `French (AZERTY)`, trousseau deverrouille :

```bash
busctl --user get-property org.freedesktop.secrets \
  /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked
```

## 8. Applications

```bash
sudo dnf install nautilus chromium gvfs-smb
```

Deja installe hors ordre (§4.4) : `kitty`. Dotfiles restants stowes ici :

```bash
mkdir -p ~/.dotfiles-backup
mv ~/.bashrc ~/.bash_profile ~/.dotfiles-backup/          # skeleton ISO
mv ~/.config/git/ignore ~/.dotfiles-backup/                # cree par Claude Code lui-meme

mkdir -p ~/.config/uwsm ~/.config/systemd/user

cd ~/linux/portable/dotfiles
stow -n -v -t ~ bash git uwsm noctalia nas
stow    -v -t ~ bash git uwsm noctalia nas

systemctl --user enable nas-infoadmin.service
```

### 8.1 Reenregistrer le mot de passe SMB - a la main, une fois

Meme geste que uc, meme raison : `gio mount` en ligne de commande ne sait pas ecrire dans
le trousseau, seul le dialogue GTK de Nautilus le fait. Monter depuis Nautilus
(`smb://pdc-nas-info.te-mgmt.io/infoadmin`), cocher "se souvenir pour toujours".

```bash
systemctl --user start nas-infoadmin.service
ls ~/nas
```

Verifie : le partage etait deja monte par Nautilus au moment du test, donc le service a
echoue une fois avec "L'emplacement est deja monte" (`gio mount -l` le confirme) - pas un
vrai probleme, ca ne se reproduit pas a un login normal ou rien n'est monte avant. Le lien
`~/nas` a ete recree a la main pour la verification :
`ln -sfn /run/user/1000/gvfs/smb-share:server=...,share=infoadmin ~/nas`.

## 9 a 12, reste a faire

RustDesk (§8ter - a partir d'un RPM regenere par Julien depuis la console entreprise, pas
recuperable autrement), enrolement TPM2 sur LUKS (§1, jamais fait), instantanes/grub-btrfs
(§10), verifications finales (§12) - en sautant les sections virtualisation/pont br0/VM.
