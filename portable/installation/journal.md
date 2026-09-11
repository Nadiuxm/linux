# Journal — construction du second poste (portable)

> Même convention que `uc/installation/journal.md` : le récit daté, le problème et ce
> qu'il apprend — pas seulement la commande qui l'a réglé.

## 2026-09-11

**Identification de la machine.** `hostnamectl` : `Dell Pro 16 PC16250`, `Chassis: laptop`,
`Static hostname: PDC-7VL5-1165`. Contrairement à `uc`, le hostname n'est **pas** vide ici
— la case « nommer la machine » du reste-à-faire de `uc` ne se reproduit pas sur ce poste.
Détail dans `CLAUDE.md`, section Structure.

**État de base déjà en place**, mesuré avant toute intervention : `lsblk` montre EFI vfat +
`/boot` ext4 séparé + LUKS2 → Btrfs (`subvol=root`, `subvol=home`), Secure Boot
`enabled (deployed)` — exactement le schéma de `uc/installation/procedure.md` §1. Disque
Samsung 512 Go NVMe (contre KIOXIA BG6 238 Go sur `uc`). 487 paquets installés, cohérent
avec une image minimale. Locale/clavier/fuseau déjà réglés : `fr_FR.UTF-8`,
`Europe/Paris`, X11 `fr`/`oss` — **contrairement à `uc`, où cette case était restée
`✎ INVENTÉ`**. TPM2 présent (`/dev/tpm0`) mais **pas enrôlé sur LUKS**, comme sur `uc`.

**Dotfiles dupliqués, pas partagés — décision explicite de Julien.** `bash`, `git`,
`kitty`, `nas`, `noctalia`, `uwsm` copiés de `uc/dotfiles/` vers `portable/dotfiles/`
(commit `e1f021e`). Raison donnée : modifier l'un ne doit pas affecter l'autre en
silence. `hypr` **volontairement laissé de côté** : il dépend des écrans et du clavier de
la machine, à reconstruire une fois Hyprland installé et mesuré ici (`hyprctl monitors
all`), pas à copier depuis `uc`.

**Audit matériel complet, avant tout paquet de bureau.** Mesuré via `/sys`, `lsmod`,
`journalctl -k` (pas de `lspci`/`lsusb`, absents sur l'image minimale — installés
temporairement le temps de l'audit). Résultats :

| Composant | État initial | Cause | Correctif |
|---|---|---|---|
| GPU (`i915`), NPU (`intel_vpu`), Ethernet (`e1000e`), Bluetooth, webcam, pavé tactile | OK d'emblée | — | aucun |
| Audio (SOF, plateforme Arrow Lake) | KO | `sof-audio-pci-intel-mtl` réclamait `intel/sof-ipc4/arl/sof-arl.ri`, absent | `sudo dnf install alsa-sof-firmware` — **effectif seulement après reboot**, le pilote avait déjà échoué à ce démarrage-là |
| Régulation radio (`regulatory.db`) | KO | fichier absent | `sudo dnf install wireless-regdb` |
| Lecteur d'empreintes (Goodix `27c6:634c`) | non configuré | `fprintd` absent | `sudo dnf install fprintd` — puce reconnue officiellement en amont par libfprint |
| Wi-Fi (Intel, PCI `7740:4090`, en réalité famille « Bz » Wi-Fi 7, étiqueté « AX211 » par erreur cosmétique du pilote) | KO | `iwlwifi` réclamait `iwlwifi-bz-b0-gf-a0-100.ucode` | voir ci-dessous |

**Piège payé sur le Wi-Fi : une recherche web a d'abord donné une fausse piste.** Le
message noyau renvoie vers `git://git.kernel.org/.../linux-firmware.git`, et une recherche
web a fait conclure — à tort — que le fichier manquait des dépôts Fedora eux-mêmes (un bug
Ubuntu identique semblait le confirmer). **Faux** : `linux-firmware` installé ne contient
**aucun** micrologiciel `iwlwifi` — juste sa licence — parce que Fedora les a scindés en
sous-paquets (`iwlwifi-dvm-firmware`, `iwlwifi-mvm-firmware`, `iwlwifi-mld-firmware`),
absents de l'image minimale. `dnf repoquery -l iwlwifi-mld-firmware` a montré le fichier
exact avant même d'installer quoi que ce soit. Correctif : `sudo dnf install
iwlwifi-mld-firmware`, puis reboot.

**Second correctif Wi-Fi, après le micrologiciel : NetworkManager marquait l'interface
`non-géré`.** `nmcli device show wlp0s20f3` → `NM-PLUGIN-MISSING: oui`, log :
« 'wifi' plugin not available ; creating generic device ». Le paquet `NetworkManager-wifi`
n'était pas installé — encore une conséquence de l'image minimale, rien à voir avec le
pilote ou le micrologiciel. `sudo dnf install NetworkManager-wifi` a suffi, sans reboot.
→ `nmcli device wifi list` voit les réseaux de l'entreprise (`TE-ENTREPRISE`, `PROD`).

**Accès au dépôt cassé, trouvé en préparant la suite.** Le dépôt était déjà cloné
(`~/linux`, remote en SSH), mais **sans `~/.ssh/config`** : `git ls-remote origin` échoue
sur `Permission denied (publickey)`, exactement le symptôme documenté en
`uc/installation/procedure.md` §2. La clé `gitlinux` était bien là
(`~/.ssh/gitlinux`, `known_hosts` peuplé), juste jamais déclarée. Corrigé en écrivant le
même bloc que `uc` (voir `procedure.md` §2 ici).

**§4 Hyprland — COPR et transaction, identiques à `uc`.** `mesa-dri-drivers` puis
`dnf copr enable dtutila/hyprland` + la transaction (`hyprland`, `noctalia`, `stow`,
`keepassxc`…) : tout confirmé installé, `uwsm` arrivé en `Weak Dependency` comme sur `uc`.
Une différence notable : **Noctalia est ici en `5.0.1`, sortie de bêta** — `uc` tourne
encore en `5.0.0~beta.10`. Reste à faire : premier lancement d'Hyprland depuis un autre
tty pour mesurer les vrais écrans et le clavier, puis écrire `dotfiles/hypr` propre à ce
poste (pas de config existante à stower, contrairement à `uc`).

**§4.3 Premier lancement, mesuré depuis ce shell (pas depuis Hyprland) — un seul écran
interne.** `hyprctl monitors all` → `eDP-1`, LG Display, 1920x1200@60, 340x220mm.
`hyprctl devices`, une fois la bonne session active (voir plus bas), a montré **8
claviers** (dont beaucoup de pseudo-périphériques : `intel-hid-events`,
`dell-wmi-hotkeys`, `power-button`…) contre 14 sur `uc`, mais un seul **réel** :
`at-translated-set-2-keyboard`. Trois souris, dont un **vrai pavé tactile**
(`ven_0488:00-0488:108b-touchpad`) — absent de `uc`. Un commutateur de capot (`Lid
Switch`), à traiter plus tard (gestion d'énergie, axe neuf pour ce poste).

**Piège reproduit du premier coup : `ActiveSession` ≠ le tty où tourne Hyprland.**
`loginctl show-seat seat0 -p ActiveSession` donnait la session du tty1, pas celle du tty3
où Hyprland venait d'être lancé — `hyprctl devices` répondait donc vide. Un aller-retour
`Ctrl+Alt+F3` a suffi à corriger. Même mécanisme déjà payé sur `uc` le 2026-09-04.

**`dotfiles/hypr` écrit pour ce poste, pas copié.** Un seul moniteur (`eDP-1`) plus une
règle générique pour toute sortie future (dock), sans ancrage de workspace par écran —
décision reportée tant qu'un dock n'a pas été réellement testé (voir `README.md`). Section
3CX de `uc` retirée (Chromium pas installé, rien décidé ici). Disposition clavier
`fr`/`azerty` reprise à l'identique, et la même solution symbole-de-niveau-1 pour les
raccourcis d'espace sur AZERTY. `~/.config/hypr/hyprland.lua` généré par Hyprland écarté
dans `~/.dotfiles-backup/` avant le `stow` (`stow` ne remplace jamais un vrai fichier).
→ `hyprctl configerrors` vide, `hyprctl devices` → clavier interne en **French (AZERTY)**,
`hyprctl binds` → clé courte `ampersand` sur l'espace 1 (liaison bien analysée).

**Kitty installé et stowé hors de l'ordre normal**, pour donner un terminal utilisable
dans la session — sans lui `SUPER+Q` (lié dans le `hyprland.lua` ci-dessus) n'ouvrait rien.
`§8` n'est donc plus totalement en séquence : le reste (`nautilus`, `chromium`,
`gvfs-smb`…) suit plus tard.

**§6 Greeter compilé et configuré, même tag que `uc` (`v1.3.1`, commit `6379fe2` identique).**
Les trois scripts lus en entier avant exécution, comme l'exige la règle du dépôt. Deux
divergences avec le compte-rendu de `uc`, sur cette version plus récente (11 cibles de
build) : `resolve_greeter_user` a trouvé `greetd` tout seul (pas de repli sur `greeter` à
corriger comme sur `uc` — mécanisme non élucidé, mesuré et suffisant) ; et le
`greeter.toml` que le script "installe" est un squelette de commentaires, pas rempli — ce
qu'il gère réellement sous ce nom est `sync.toml` (synchro d'apparence), pas les sections
session/clavier/écran. Celles-ci ont été écrites à la main, comme sur `uc`.

**Fausse alerte sur l'ordre : `systemctl enable --now greetd` a semblé apparaître dans un
collage de terminal**, alors que la commande n'avait en réalité pas été exécutée
(`systemctl is-enabled/is-active greetd` → `disabled`/`inactive`, vérifié). Le trousseau
n'étant pas encore configuré, l'activer à ce stade aurait reproduit le symptôme documenté
sur `uc` (NAS qui ne monte pas, sans erreur claire).

**Tmpfiles.d : décision consciente de NE PAS reproduire la surcharge de `uc`.** Le fichier
livré code en dur `greeter:greeter` comme sur `uc`, mais `systemd-tmpfiles-setup.service`
est `static` — déjà exécuté à ce boot, avant même l'installation du paquet. La ligne
fautive ne sera relue qu'au prochain redémarrage, et le dossier aura déjà le bon
propriétaire (posé par le script lui-même) : coût réel de l'ignorer = un message d'erreur
inoffensif au boot suivant, rien de plus. Sur `uc`, le geste avait un effet réel parce que
`tmpfiles.d` était le mécanisme de création initiale ; ici `setup_greeter_system.sh` l'a
déjà fait correctement. Même mécanisme observé (fichier figé), effet différent — à
re-mesurer, pas à recopier par réflexe.

**§6 bouclé : premier login réel par le greeter, réussi.** `greetd` activé
(`enable` + `set-default graphical.target`), redémarrage, session ouverte sur tty1 via
`greetd`. Vérifié après coup : `graphical-session.target` **active**, Noctalia peint pour
de vrai (`hyprctl layers` → fond d'écran + barre sur `eDP-1`), clavier en `French
(AZERTY)` dans la vraie session, trousseau **déverrouillé** (`Locked → false`). La chaîne
greetd → PAM → uwsm → Hyprland → Noctalia fonctionne d'un bout à l'autre.

**Reliquat non résolu : `gnome-keyring` toujours en `Weak Dependency`.** La commande
`sudo dnf install gnome-keyring` (lancée en même temps que `gnome-keyring-pam`) n'a pas
changé la raison — `dnf5` ne semble pas la rendre explicite quand le paquet est déjà
présent et qu'une autre installation l'accompagne dans la même transaction. Correctif
identifié mais pas encore appliqué : `sudo dnf mark user gnome-keyring` (syntaxe `dnf5`,
vérifiée localement via `dnf mark --help` — `dnf mark install` de `uc`, en `dnf4`, ne
s'applique pas ici tel quel).

**§7 dotfiles restants stowés : `bash`, `git`, `uwsm`, `noctalia`, `nas`.** Deux fichiers à
écarter avant, comme sur `uc` : `.bashrc`/`.bash_profile` de l'ISO (16 janvier), **et un
troisième non prévu par `uc`** — `~/.config/git/ignore` existait déjà, créé par Claude Code
lui-même le jour même (`**/.claude/settings.local.json`, sans les commentaires du fichier
versionné) : écarté sans perte, la version du dépôt porte déjà cette ligne. Les deux pièges
de tree-folding déjà documentés sur `uc` (`~/.config/uwsm`, `~/.config/systemd/user`)
anticipés par un `mkdir -p` avant le `stow` — aucun des deux ne s'est reproduit.
`systemctl --user enable nas-infoadmin.service` fait à part (`stow` ne l'active jamais).

**§7/§8 bouclés : trousseau, NAS, applications.** `gnome-keyring` rendu explicite
(`dnf mark user`, syntaxe `dnf5`), ligne PAM manquante ajoutée, `greetd` activé et
redémarré — connexion réelle réussie (voir plus haut). `nautilus`, `chromium`, `gvfs-smb`
installés, dotfiles restants (`bash`, `git`, `uwsm`, `noctalia`, `nas`) stowés — un
troisième fichier à écarter en plus des deux de `uc` : `~/.config/git/ignore`, créé par
Claude Code lui-même le jour même, sans perte (contenu déjà dans la version versionnée).
NAS monté depuis Nautilus, mot de passe enregistré dans le trousseau, `~/nas` listable.

**WireGuard — reporté à lundi, à la demande de Julien (config perdue pour l'instant).**
Vérifié avant d'arrêter : module noyau `wireguard` déjà présent (intégré au noyau depuis
longtemps, aucun DKMS/akmod requis), paquet `wireguard-tools` disponible dans les dépôts
Fedora 44. Rien d'autre fait — ni installé, ni configuré.

**VM Windows — mise de côté, pas oubliée.** Décision de Julien : pas de VM Windows sur ce
poste pour l'instant, incertain que ça arrive un jour. §8quater, §8quinquies et §11 de la
procédure `uc` (virtualisation, pont `br0`, reprise de la VM) **ne figurent pas** dans
`procedure.md` ici — à réintroduire seulement si la décision change.
