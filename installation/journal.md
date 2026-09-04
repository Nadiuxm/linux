# Journal — poste de référence

Entrées datées, les plus récentes en haut.
Noter **le problème et ce qu'il apprend**, pas seulement la solution.

Ce journal est celui de la **construction du poste de travail**, distinct de
`journal/<itération>/journal.md` qui reste celui de l'évaluation des distributions.

---

## 2026-09-04 — Ouverture de l'axe : un poste de référence, et une décision reprise sur un démenti

Journée de cadrage, pas de construction : aucun paquet installé au-delà de `git`.
Ce qui a été fait tient en deux choses — établir ce qu'est cette machine, et défaire une
décision de partitionnement prise le matin même sur une prémisse fausse.

### La machine n'est plus celle que le dépôt décrivait

Fedora 44 **minimale** (53 paquets explicites, 419 au total, `multi-user.target`, aucun
bureau) installée à 11:59 sur le **NVMe interne**, avec **LUKS**. L'itération 01 est
intacte sur le SSD USB.

Les rôles se sont donc inversés : l'interne devient le poste de travail, l'externe devient
le lab. Le Windows interne de secours a disparu.

**Ce que ça change dépasse le matériel.** La contrainte fondatrice du dépôt — « chaque
réinstallation efface la machine, ce dépôt compris » — ne tient plus. C'était elle qui
justifiait la procédure de bascule, la règle « rien n'existe tant que ce n'est pas poussé »,
et une bonne part de la discipline du projet. Une itération sur le disque externe ne
menace plus rien.

Le risque est écrit dans `CLAUDE.md` pour ne pas être découvert trop tard : la méthode
tirait sa force de l'obligation de vivre dans la distro testée. Un poste confortable à
côté, et une distro de test devient une visite. **Il faut remplacer la contrainte perdue
par une discipline explicite**, sinon l'axe distro s'éteint sans que personne ne le décide.

### Le mot « finale » était faux, et le corriger a ajouté une exigence

`poste/README.md` parlait d'« installation finale ». Or une réinstallation dans trois à six
mois est envisagée. Ce n'est donc pas un aboutissement mais un **poste de référence** —
la pile retenue, épurée, mais **rejouable**.

La conséquence n'est pas cosmétique : **cette install doit être reproductible.** Un journal
explique pourquoi ; il ne rebâtit pas une machine. D'où la règle des trois destinations
(`procedure.md`, `dotfiles/`, `poste/`) et le fait que tout geste qui n'atterrit dans aucune
des trois sera perdu.

### `grub-btrfs` — une décision irrattrapable prise sur une déduction non vérifiée

**C'est l'enseignement de la journée.**

Le matin, l'entrée de l'itération 01 concluait : `grub-btrfs` cherche noyau et initramfs
*dans* l'instantané, or `/boot` est une partition ext4 séparée, donc le `boot/` d'un
instantané est vide, donc **`/boot` devra être placé dans le sous-volume Btrfs**. Le point
avait été relayé dans `poste/README.md` comme une contrainte d'installation irrattrapable.

Chaque étape du raisonnement était correcte. **La conclusion était fausse.** Le README de
`grub-btrfs` annonce :

> « Automatically detect if `/boot` is in a separate partition. »

Et fournit `GRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION` pour les cas où la détection
échoue. Avec un `/boot` séparé, il prend le noyau sur la partition vivante et lui ajoute
`rootflags=subvol=<instantané>` : c'est-à-dire **exactement la porte de sortie manuelle**
déjà notée dans la fiche, mais générée automatiquement en entrée de menu.

Le mécanisme déduit ne décrivait donc pas une impossibilité, seulement le cas d'un `/boot`
intégré. Rien dans la chaîne logique n'était faux — il manquait d'avoir lu ce que l'outil
dit de lui-même avant de laisser une déduction imposer une décision qu'on ne peut pas
reprendre.

**Coût évité de justesse : une réinstallation complète.** La disposition en place est
gardée.

### Et le `/boot` séparé n'est pas un pis-aller — c'est le bon choix

En instruisant la question, l'argument s'est même retourné. Si `/boot` était dans le Btrfs
chiffré, **GRUB devrait ouvrir LUKS lui-même** pour lire le noyau. Or son `cryptomount` ne
connaît que la phrase de passe et le fichier clé : **aucun support TPM2**. On saisirait donc
le mot de passe à chaque démarrage, et l'enrôlement TPM — matériel présent et vérifié,
`/dev/tpm0`, `has-tpm2` → `yes` — ne servirait plus à rien.

|  | `grub-btrfs` | Déverrouillage TPM |
|---|---|---|
| `/boot` ext4 séparé (retenu) | ✅ | ✅ |
| `/boot` dans le Btrfs chiffré | ✅ | ❌ |

Limitation acceptée : le noyau vient du `/boot` vivant, donc remonter un instantané
antérieur à une mise à jour de noyau décale `/lib/modules`. On choisit alors aussi
l'ancienne entrée de noyau — Fedora en garde trois.

**Reste à vérifier par l'expérience** que `grub-btrfs` génère bien des entrées ici. Ne pas
refaire l'erreur symétrique : la documentation dit que ça marche, elle ne prouve pas que
ça marche sur cette machine. Et il **n'est pas dans les dépôts Fedora** — `dnf` ne connaît
aucun paquet de ce nom.

### Sway → Hyprland, et la vraie facture

Décision prise pour une raison visuelle. Formulée « Sway est moche », elle n'aurait pas
tenu six mois : Sway ne peignait plus que des bordures de 2 px, tout le reste du visible
étant à Noctalia depuis le 2026-09-01, et la config portait déjà
`default_border pixel 2` sans barre de titre. Il n'y avait plus rien à déraidir.

Formulée correctement, elle tient : **animations, coins arrondis, flou — que wlroots ne
fournit pas par choix amont**. Ce n'est pas un réglage manqué, c'est une limite de la pile.

Ce que ça coûte, mesuré plutôt que supposé :

- **Noctalia suit sans problème** — c'était le vrai risque, puisqu'il fait tout le shell.
  Intégration Hyprland **native**, annoncée en amont aux côtés de Niri et Sway. Les ~15
  liaisons `noctalia msg …` se transposent presque telles quelles.
- **Hyprland n'est pas dans Fedora.** Seules ses *bibliothèques* y sont (`hyprutils`,
  `hyprlang` 0.6.4, `hyprgraphics` 0.1.5, `hyprcursor` 0.1.11, `hyprland-protocols` 0.4.0).
  Un COPR est obligatoire — et un décalage de versions entre le COPR et ces bibliothèques
  Fedora est un mode de panne à surveiller.
- **418 lignes de config à réécrire**, dont tout le travail AZERTY en `bindcode`. La leçon
  se transpose, le fichier non.
- **La plomberie systemd est la vraie facture.** Sous Fedora, `sway-systemd/session.sh`
  propageait l'environnement vers systemd et D-Bus, démarrait `sway-session.target`,
  l'agent SSH et les portails. **Hyprland n'a pas d'équivalent packagé, et `uwsm` non
  plus.** Or `nas-infoadmin.service` est en `PartOf=graphical-session.target`.
  C'est l'inversion exacte du piège maison « vérifier si la distro n'a pas déjà traité le
  problème » : cette fois, **elle ne l'a pas fait**.

### Le greeter Noctalia : la note « à vérifier » avait raison de se méfier

`poste/README.md` disait le 2026-09-03 : le greeter existe, mais pas dans le paquet Fedora,
« à vérifier avant de compter dessus ». Re-testé, et trois choses en sont sorties :

1. **Toujours aucun fichier de greeter** dans `noctalia` 5.0.0~beta.10. C'est un **projet
   séparé**, `noctalia-dev/noctalia-greeter`.
2. **`greetd` reste obligatoire** — « It is built for greetd: greetd starts the bundled
   wlroots compositor ». Le greeter Noctalia remplace `tuigreet`/`gtkgreet`, pas `greetd`.
   La décision « greeter Noctalia » n'évacue donc pas `greetd`, elle s'ajoute par-dessus.
3. **Il embarque son propre compositeur wlroots.** On quitte wlroots pour le bureau et on
   le garde pour l'écran de connexion.

Installation par compilation (`just`, `meson`, `sudo meson install` dans `/usr/local`, puis
un script système à exécuter en root). Toutes les dépendances sont dans Fedora 44 — y
compris `wlroots-devel` 0.20.2, ce qui a demandé de se reprendre : voir ci-dessous.

**Ça fait trois composants hors dépôt** — Hyprland, ce greeter, `grub-btrfs`. C'est là que
l'exigence de reproductibilité coûte quelque chose de réel : « compilé depuis `main` » n'est
pas une instruction rejouable, et `/usr/local` échappe à `dnf`. La procédure devra porter
des commits et des versions, pas des noms de branches.

### Une liste tronquée m'a fait annoncer un blocage qui n'existait pas

En vérifiant les dépendances du greeter, `dnf list --available 'wlroots*' | tail -8` n'a
montré que `wlroots0.18` et `wlroots0.19`. Conclusion annoncée : `wlroots 0.20` absent de
Fedora, greeter infaisable sans compiler wlroots aussi.

Faux. Le `tail` avait coupé les paquets **non versionnés** : `wlroots` 0.20.2 est dans
`updates`, et `dnf repoquery --whatprovides 'pkgconfig(wlroots-0.20)'` le donne
immédiatement. Les paquets `wlroots0.18`/`0.19` sont des paquets de **compatibilité**.

Deuxième fois dans la journée qu'une conclusion est tirée d'un fait étroit, et la leçon est
la même à un niveau plus bête : **un filtre d'affichage n'est pas un résultat de
recherche.** Poser la question exacte plutôt que lire un extrait de liste.

### `gnome-keyring` gardé — et c'est moins cher que le journal ne le craignait

KeePassXC en fournisseur Secret Service est **reporté**, pas abandonné : la faisabilité est
prouvée depuis ce matin, mais l'ordonnancement au login reste tout le chantier.

Il faut donc porter les trois lignes `pam_gnome_keyring.so` de GDM dans
`/etc/pam.d/greetd`, sans quoi le trousseau n'est pas déverrouillé au login et
`nas-infoadmin.service` échoue.

Et l'entrée de ce matin se corrige au passage : elle disait que retirer `gnome-keyring`
« emporte GDM (`gdm` → `gnome-keyring-pam` → `gnome-keyring`) ». **La chaîne ne se lit que
dans un sens.** `gnome-keyring-pam` 50.0 ne dépend que de `gnome-keyring`, `pam` et
`libselinux` — aucune trace de GDM. Retirer `gnome-keyring` emporterait GDM ; **garder
`gnome-keyring` sans GDM est gratuit.**

### Un fichier a failli être perdu, et la procédure de bascule ne l'aurait pas vu

`git status` sur le dépôt de l'ancien disque :

```
?? dotfiles/foot/
```

`dotfiles/foot/.config/foot/foot.ini` n'avait **jamais été commité ni poussé**. Pas ignoré :
oublié. Il existait depuis le 2026-09-01 et n'existait que là.

Ce n'était pas un fichier vide — vingt lignes, dont le raisonnement complet sur `dpi-aware`,
l'échelle Wayland et la densité du P2725DE. Le `font=monospace:size=11` se retrouve en dix
secondes ; l'analyse, non.

**Ce que ça apprend sur la procédure de bascule** : son étape 4 dit « vérifier que le push
est bien passé sur GitHub ». Elle ne dit pas de vérifier qu'il ne reste rien de **non
suivi**. `git log` et `git status` ne répondent pas à la même question, et c'est le second
qui protège. Fichier rapatrié et versionné.

### Deux frictions SSH sur une machine neuve

Le `git clone` a échoué deux fois de suite, pour deux raisons différentes :

1. **`Host key verification failed`** — `known_hosts` vide. Les empreintes ont été
   comparées à celles publiées par `api.github.com/meta` avant d'être ajoutées : les trois
   (ECDSA, RSA, ED25519) correspondaient. Un `ssh-keyscan >> known_hosts` sans comparaison
   aurait « marché » aussi, sans rien vérifier.
2. **`Permission denied (publickey)`** — la clé s'appelle `gitlinux`, or `ssh` ne propose
   spontanément que les noms par défaut (`id_ed25519`, `id_rsa`…). Il a fallu un
   `~/.ssh/config` avec `IdentityFile` et `IdentitiesOnly yes`.

`ssh -T git@github.com` a confirmé au passage que c'est une **deploy key** du dépôt et non
une clé de compte : la réponse est `Hi Nadiuxm/linux!`, pas un nom d'utilisateur.

### Bureau posé — et Hyprland ne se configure plus comme tous les tutoriels le disent

Paquets posés par `installation/scripts/01-bureau-hyprland.sh` : `mesa-dri-drivers`
(**absent d'une image minimale — sans lui Hyprland ne démarre pas du tout**), Hyprland
0.56.2 depuis le COPR, les deux portails, Noctalia, `foot`, `stow`, KeePassXC.

**Le décalage de versions annoncé a eu lieu immédiatement.** Le COPR a remplacé *toutes*
les bibliothèques `hypr*` de Fedora, avec des écarts majeurs : `hyprgraphics` 0.5.1 contre
0.1.5, `hyprutils` 0.14.1 contre 0.7.1 (et encore, la version Fedora est une `fc43`),
`hyprlang` 0.6.8 contre 0.6.4, plus `hyprwire` qui n'existe pas chez Fedora. Conséquence
durable : `dnf upgrade` devra **toujours** voir ce COPR activé, sinon Fedora tentera de
redescendre ces paquets. Relevé complet dans `scripts/versions-01.txt`.

#### Mon script est mort sur `rpm -q`

`rpm -q` **renvoie un code d'erreur pour tout paquet absent**. J'avais listé `quickshell`
dans le relevé final ; sous `set -euo pipefail`, ce code non nul a tué le script à cette
ligne — donc sans faire le `chown` ni afficher la suite. Résultat : un relevé à moitié
écrit et **appartenant à root** dans un dépôt git utilisateur, et des instructions jamais
affichées. Une commande d'inventaire ne doit jamais pouvoir interrompre un script.

Et `quickshell` n'avait rien à faire dans cette liste : **Noctalia 5 est livré en binaire
natif** (`/usr/bin/noctalia`), ce n'est plus une configuration Quickshell comme en
version 3. La note du 2026-09-01 a pris du retard sur l'amont.

#### Les messages d'erreur au premier lancement étaient tous bénins

Vérifiés un par un dans `$XDG_RUNTIME_DIR/hypr/<instance>/hyprland.log` :
`[libseat] Backend 'seatd' failed to open seat, skipping` (il cède la place à logind),
`Wayland backend cannot start: wl_display_connect failed` (il tente le Wayland imbriqué
avant de basculer sur DRM), du bruit `drm: Cannot commit when a page-flip is awaiting`, et
`failed to commit hdr metadata` (dalle sans HDR). **Aucun n'est un problème.**

Les mentions de `kitty` ne venaient pas d'une dépendance manquante mais du **fichier de
config autogénéré**, qui déclare `terminal = "kitty"`. Et Noctalia était absent parce que
ce fichier ne le lance pas. Le vrai sujet était ailleurs.

#### HYPRLANG EST DÉPRÉCIÉ — la config est en Lua

Hyprland avait généré `~/.config/hypr/hyprland.**lua**`, pas `hyprland.conf`. Depuis la
version 0.55, **hyprlang est déprécié au profit d'une API Lua**, et le paquet ne livre plus
qu'un exemple `.lua`. J'avais écrit 425 lignes de `.conf` de mémoire : format que Hyprland
ne lit plus. Réécrites en Lua.

La bonne référence est **sur le disque** : `/usr/share/hypr/stubs/hl.meta.lua`, 1777 lignes
d'API générée, plus l'exemple commenté. Les tutoriels en ligne sont presque tous encore en
hyprlang — c'est-à-dire faux pour cette version.

#### `code:NN` marche en hyprlang, PAS dans le Lua — et l'échec est SILENCIEUX

Le piège AZERTY de Sway se repose entier : la documentation confirme que
`input:resolve_binds_by_sym` vaut **`true`** par défaut, donc les liaisons se résolvent par
symbole. Changer de compositeur ne règle rien.

La doc donne `code:X` pour lier une touche physique. **Dans la config Lua, ça ne fonctionne
pas** — et rien ne le signale : aucune erreur, aucun avertissement dans le log. Quatre
variantes testées en direct (`"ALT + code:10"`, `"ALT+code:11"`, `"ALT, code:12"`,
`"ALT + 13"`) : deux enregistrent une liaison inerte, deux ne s'enregistrent pas du tout.

**Le diagnostic qui le révèle**, et c'est lui qu'il faut retenir : dans `hyprctl binds`,
une liaison correctement analysée montre une clé COURTE (`key: L`) avec le bon `modmask`.
Une liaison ratée conserve **la chaîne entière** (`key: SUPER + SHIFT + code:49`) et
`keycode: 0`. Comparer la forme de la sortie, pas seulement son existence.

#### La réponse : lier les symboles réels de la rangée AZERTY

Puisque la résolution se fait par symbole, autant nommer les symboles que les touches
produisent vraiment. La rangée du haut donne au **niveau 1** — sans Maj :

    &  é  "  '  (  -  è  _  ç  à
    ampersand eacute quotedbl apostrophe parenleft minus egrave underscore ccedilla agrave

Et au **niveau 2**, le chiffre lui-même. Donc « aller sur l'espace N » se lie sur le
symbole de niveau 1, et « y envoyer la fenêtre » sur `SHIFT + le chiffre` : **c'est la même
touche physique, lue à ses deux niveaux.** Aucun Maj superflu, aucune collision.

Vérifié après rechargement : **71 liaisons, 0 non analysée**, `ampersand` … `agrave` à
`modmask=64`, les chiffres à `modmask=65`. Même traitement pour `SHIFT + ISO_Left_Tab`
(Maj+Tab ne produit pas « Tab ») et pour le scratchpad sur `twosuperior` (le `²`).

#### Deux autres changements de la 0.56, trouvés en s'en servant

- **`hyprctl dispatch exec foo` ne marche plus.** Il faut passer du Lua :
  `hyprctl dispatch 'hl.dsp.exec_cmd("foo")'`. Le message d'erreur le dit, à condition de
  le lire — il parle de syntaxe Lua, pas de commande inconnue.
- **`hl.on("hyprland.start", …)` ne rejoue pas sur un `hyprctl reload`.** Après un
  rechargement, ce qui devait démarrer au lancement doit être lancé à la main. Ce n'est pas
  un bug, mais ça fait croire que l'autostart est cassé.

#### Résultat vérifié

`hyprctl monitors` : les trois écrans aux positions voulues — `HDMI-A-2` à `0x180`,
`DP-3` à `1920x0`, `DP-1` à `4480x180`. Les taux réels apparaissent enfin (60, 59.951 Hz),
ce que `preferred` avait évité d'inventer.

`hyprctl layers` : Noctalia peint barre, fond d'écran et OSD **sur les trois écrans**.

#### Le clavier « absent » — mesure refaite depuis la session active

`hyprctl devices` listait **zéro clavier et zéro souris**, ce qui avait été noté comme
inexpliqué plutôt que conclu. Mesure refaite une fois la session au premier plan : les
claviers sont bien là, tous en `l "fr", v "azerty"` avec
`active keymap: French (AZERTY)`. La disposition est donc confirmée active, et
l'hypothèse tenait — **le TTY n'était pas actif au moment de la première mesure**, et
logind libère les périphériques d'une session inactive.

Piège de méthode général, indépendant d'Hyprland : **certaines mesures n'ont de sens que
depuis la session active.** Une liste vide peut décrire l'état de la session
d'observation, pas celui de la machine. Même famille que « un agent automatisé tourne dans
un environnement filtré, ses échecs ne sont pas des symptômes système ».

#### Deux daemons Noctalia — et c'est le second qui peint

Après le rechargement, `pgrep` montrait **deux** processus `noctalia` : celui lancé à la
main pour compenser le fait que `hyprland.start` ne rejoue pas sur un `reload`, et celui
démarré par `hyprland.start` à la relance suivante.

`hyprctl layers` a tranché sans ambiguïté : **le plus récent possédait les trois surfaces
de chaque namespace** (barre, fond d'écran, OSD — une par écran), et l'ancien n'en peignait
aucune. Il n'y avait donc pas de peinture en double, juste un processus inerte. Tué.

C'est la même leçon que le `swaybg` résiduel de l'itération 01, vue par l'autre bout :
compter les processus ne dit rien, il faut regarder **qui possède la surface**. Et le
correctif durable est le même — ne pas lancer de concurrent plutôt que d'arbitrer entre
deux.

### Une clé de configuration peut mourir alors que la fonctionnalité survit

Au démarrage, Hyprland refusait la config : `unknown config key 'dwindle.pseudotile'`.
`hyprctl getoption dwindle:pseudotile` répond `no such option` — l'option **globale**
n'existe plus en 0.56.2, alors que tous les tutoriels la donnent. Le pseudo-tuilage, lui,
est intact : il ne reste que comme **action par fenêtre**, et l'exemple de config livré
par le paquet contient exactement le `hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())`
qui était déjà dans le fichier. Une ligne à supprimer, aucune fonctionnalité perdue.

**Ce que ça apprend, au-delà du correctif.** Une dépréciation ne frappe pas tout un
sous-système d'un coup : ici la *clé de configuration* est morte et le *dispatcher* a
survécu. Chercher « comment fait-on X » et trouver un exemple qui marche ne dit rien de la
façon dont X se **configure** aujourd'hui.

Deux pièges de lecture du message d'erreur, coûteux tous les deux :

- **Le numéro de ligne désigne l'appel, pas la clé.** Le message disait `:115` — c'est la
  ligne `hl.config({`. La clé fautive était à **154**. La table est validée au site
  d'appel ; il faut chercher à la main dans les cinquante lignes qui suivent.
- **Le chemin annoncé est tronqué.** Le message donnait
  `/home/jzielona/.config/hyprland.lua`, fichier qui **n'existe pas** : le vrai est
  `~/.config/hypr/hyprland.lua`. Cherché tel quel, on ne le trouve pas.

Vérification faite ensuite sur les **25 clés** des deux appels `hl.config`, en interrogeant
le compositeur (`hyprctl getoption`) : 24 valides, celle-là seule absente. Comme la
validation s'arrête à la première clé inconnue, corriger sans vérifier le reste, c'est
s'exposer au même arrêt au prochain démarrage.

### « uwsm n'est pas packagé » : une facture annoncée qui n'existait pas

Le `README.md` de cet axe désignait la plomberie systemd comme **le vrai coût** du passage
à Hyprland, en affirmant que ni Hyprland ni `uwsm` n'avaient d'équivalent packagé dans
Fedora. Les deux moitiés étaient fausses : `uwsm` 0.26.7 **est installé**, et
`/usr/share/wayland-sessions/hyprland-uwsm.desktop` appartient au paquet `hyprland`.

Ce qui l'a caché : `uwsm` est arrivé comme **dépendance faible** du COPR
`dtutila/hyprland` (`reason=Weak Dependency`, aucun paquet ne le `Requires`). Il n'est ni
dans ce qu'on a tapé, ni dans les dépendances dures — donc dans aucune des listes qu'on
consulte spontanément. Le seul indice visible était le nom d'un fichier dans
`/usr/share/wayland-sessions/`, exactement comme l'indice de la config Lua était le nom du
fichier généré par Hyprland lui-même.

Et `graphical-session.target` était bel et bien **inactive** — mais parce qu'Hyprland
était lancé **à la main** depuis un tty, pas parce que l'outil manquait. Un symptôme réel,
attribué à la mauvaise cause.

**Leçon :** le piège maison « vérifier si la distro n'a pas déjà traité le problème »
s'appliquait ; l'erreur a été de conclure qu'elle ne l'avait pas fait, sans chercher.

### Deux sessions Hyprland ouvertes en même temps — et une note d'hier à compléter

`loginctl` a révélé **quatre sessions**, dont deux Wayland : `Hyprland` sur tty2
(inactive, un résidu) et `hyprland` sur tty3 (active, celle où l'on travaille). Deux
sockets `wayland-*`, deux signatures dans `/run/user/1000/hypr/`.

La note écrite plus tôt dans la journée — « `hyprctl devices` listait zéro clavier, logind
libère les périphériques d'une session inactive » — est **juste mais incomplète** : elle
explique le mécanisme sans dire *pourquoi* une session inactive était visée. La cause
première, c'est qu'il y en avait deux, et qu'une mesure peut atterrir sur la dormante.

C'est un effet direct du lancement manuel depuis un tty, et donc un argument concret pour
le greeter : avec `greetd`, une seule session s'ouvre.

### greetd et le greeter Noctalia : tout est posé, rien n'est branché

Déroulé complet dans `procedure.md` §6, avec les quatre pièges du script d'installation.
Ce que la journée apprend, en propre :

- **Le README d'un projet peut ne pas s'appliquer à sa propre liste de distributions
  supportées.** Fedora y figure explicitement, et deux des paquets de la ligne `dnf`
  n'existent pas dans Fedora 44 (`libEGL-devel`, `mesa-libGLES-devel` → `libglvnd-devel`).
  Vérifier chaque nom **avant** de lancer la commande coûte une minute ; le `configure`
  a ensuite confirmé la substitution (`egl found: YES 1.5`, `glesv2 found: YES 3.2`).
- **Un projet sans release apparente peut en avoir.** La procédure prévoyait de noter le
  commit de `main` « parce que ce n'est pas reproductible autrement ». Le projet publie en
  fait des tags jusqu'à `v1.3.1`, et `main` n'en était qu'à deux commits, tous deux de CI.
  Compiler un tag, pas une branche.
- **Un outil bien écrit résout les variations de distribution lui-même.** Le script a
  trouvé le compte `greetd` (celui que Fedora crée) au lieu du `greeter` de son README, en
  interrogeant la config plutôt qu'en codant le nom en dur. Ce que j'avais annoncé comme
  un écart à corriger n'en était pas un.
- **Un fichier livré peut prescrire sa propre surcharge.** Son `tmpfiles.d` code en dur
  `greeter:greeter`, et son commentaire dit quoi faire : « override under
  `/etc/tmpfiles.d/` if your greetd user differs ». Lire le fichier, pas seulement
  l'appliquer.

### Suivre la procédure officielle plutôt que devancer un risque déduit

Le script d'installation ajoute `session required pam_systemd.so` à `/etc/pam.d/greetd`,
et sa garde ne regarde que ce fichier — or Fedora apporte déjà le module via
`session include system-auth`. J'ai voulu neutraliser ce geste d'avance : double appel,
`required` au lieu d'`optional`, donc un module dont l'échec refuse le login.

Julien a répondu : « si y a une doc c'est peut être pas pour rien non ? ». Il avait raison.
`man pam_systemd` ne documente **aucun** problème d'appel répété, et son point 1 est même
écrit pour être idempotent (« If it does not exist yet, the user runtime directory … is
either created or mounted »). Je n'avais rien de mesuré — seulement un mécanisme plausible.

**C'est la troisième fois dans la journée** que la même erreur se présente sous une forme
différente : `grub-btrfs`, la liste `wlroots` tronquée, et maintenant ce patch PAM. La
règle qui en sort : **un écart à la doc d'un outil ne se justifie que par un fait constaté
sur la machine** — un nom de paquet qui n'existe pas, un compte que la distro nomme
autrement — jamais par un raisonnement sur le mécanisme, aussi juste soit-il. Le geste du
script a donc été appliqué tel quel, avec sa sauvegarde, et l'effet sera **mesuré** au
premier login (`loginctl` : une seule session attendue).

### La bascule a eu lieu — et trois de mes prédictions se sont retournées

`systemctl enable greetd` + `set-default graphical.target`, reboot. Le greeter Noctalia
s'affiche, l'AZERTY fonctionne (mot de passe saisi correctement du premier coup, ce qui est
la seule preuve qui vaille), la session démarre. Cinq mesures, trois enseignements.

**1. Le double `pam_systemd` était inoffensif.** `loginctl` : **une seule** session
utilisateur (`Id=2`, `Service=greetd`, `VTNr=1`), contre quatre avant la bascule. Le
raisonnement qui m'avait fait vouloir annuler ce geste du script était juste sur le
mécanisme et sans conséquence dans les faits. La règle « appliquer le geste documenté puis
mesurer » a payé au premier essai.

**2. Le déni SELinux annoncé comme "plausible" s'est produit, et sa signature dit tout :**

```
AVC denied { write } comm="noctalia-greete" name="sync.toml"
  scontext=system_u:system_r:xdm_t          ← le greeter est confiné en xdm_t
  tcontext=unconfined_u:object_r:var_lib_t  ← le fichier est en var_lib_t
```

Le greeter le signale lui-même : `failed to save sync.toml (check permissions on …)`. Ce
n'est pas un problème de droits Unix — le propriétaire est bon — mais de **type**. Le
paquet `greetd` étiquette son propre `/var/lib/greetd` en `xdm_var_lib_t` ; un logiciel
installé hors `dnf` n'a personne pour le faire. Conséquence fonctionnelle : le greeter ne
mémorise pas le dernier choix de session. Réponse : `semanage fcontext` vers
`xdm_var_lib_t`. On ne desserre pas SELinux, on déclare la vraie nature du répertoire.

**Leçon transposable :** un binaire posé par `meson install` hérite des types du chemin
(`/usr/local/bin` → `bin_t`, donc exécutable sans problème), mais **un répertoire d'état
qu'il crée lui-même n'hérite de rien d'utile**. Sur toute distro avec du MAC, l'installation
hors gestionnaire de paquets laisse ce travail au lecteur.

**3. `uwsm` apporte exactement une chose, et elle compte.** Mesuré aux deux sessions :

| | `Hyprland` | `Hyprland (uwsm-managed)` |
|---|---|---|
| `WAYLAND_DISPLAY` dans `systemd --user` | oui (2 lignes maison) | oui |
| `noctalia --daemon` | oui | oui |
| `graphical-session.target` | **inactive** | **active** |

Tout ce que le dépôt attribuait à `uwsm` était **déjà couvert à la main** par
`hyprland.lua`, sauf la target — et elle porte `RefuseManualStart=yes`, donc elle n'est pas
obtenable par un `exec`. C'est ce qui tranche : `nas-infoadmin.service` s'y accroche par
`PartOf=`, la directive qui **démonte** le partage à la déconnexion. Sans elle, le NAS
resterait monté après le logout avec le secret qui l'a monté.

### Le trousseau réclamé au premier login — et une hypothèse fausse en trois minutes

Au démarrage de la session uwsm, un dialogue : « An application wants to create a new
keyring called *Trousseau de clés par défaut* ».

**Ma première explication était fausse.** J'ai annoncé que c'était l'autostart XDG,
désormais lancé par `uwsm`, qui réveillait `gnome-keyring`. Vérification : les trois unités
`app-gnome-keyring-*@autostart.service` sont bien **chargées** par `uwsm`, et
`ExecMainStartTimestamp` est **vide**, `pid=0` — elles ne se sont **jamais exécutées**,
filtrées parce que `XDG_CURRENT_DESKTOP=Hyprland`. Le cgroup du daemon le disait déjà :
`dbus-:1.2-org.freedesktop.secrets@0.service`, soit une activation **D-Bus** par un client.
Et `:1.2` s'est révélé être `dbus-broker-launch` lui-même — le nom porté par l'unité est
celui du **lanceur**, pas du demandeur. Le client reste non identifié, et il ne sera pas
inventé.

> **Piège à retenir : une unité *chargée* n'est pas une unité *exécutée*.** `list-units`
> l'affiche, son horodatage dit si elle a tourné. Même famille que « un paquet installé
> n'est pas un paquet utilisé » — et j'ai reproduit l'erreur le jour même où je l'écrivais.

**La cause réelle, elle, est simple et mesurable :** `~/.local/share/keyrings/` est **vide**
— aucun trousseau n'a jamais existé sur ce poste — et le service n'expose que la collection
`session`, celle qui vit en mémoire et meurt avec la session. Il n'y a pas de GDM pour
créer le trousseau `login`, et `pam_gnome_keyring.so` n'est pas installé : les deux lignes
que Fedora avait pourtant écrites dans `/etc/pam.d/greetd` sont inertes. Donc le premier
client qui réclame la collection par défaut réveille `gcr-prompter`, et ça se reproduira à
chaque session.

Décision de Julien, conforme au cadrage déjà écrit : **`gnome-keyring` pour l'instant**, le
passage à KeePassXC reste reporté et non abandonné. D'où `gnome-keyring-pam` et la seule
ligne `password` manquante — `/etc/pam.d/greetd` est `%config(noreplace)`, l'édition
survivra aux mises à jour du paquet.

### Le NAS et les instantanés — et une échéance qui est arrivée sans qu'on la voie

Montage NAS déployé (`stow nas`, unité `--user` active) et instantanés Btrfs en place.
Compte rendu dans `poste/README.md`. Deux résultats en propre.

**La piste laissée ouverte à l'itération 01 est tranchée.** Le journal notait :
« Nautilus n'est nécessaire que pour **une seule opération**, écrire le mot de passe du NAS
dans le trousseau. `secret-tool store` sait le faire ; reste à savoir si `gvfsd` retrouve le
secret sous le bon schéma. Si oui, la cible n'a plus aucune application GNOME. » Réponse :
**oui.** `secret-tool store` avec les cinq attributs, puis `gio mount` monte sans rien
demander, stdin fermé. Nautilus n'a plus d'usage sur ce poste.

**Un piège de Stow évité de justesse, cousin de celui de `~/.bashrc.d`.** `stow nas` allait
poser `LINK: .config/systemd => ../linux/dotfiles/nas/.config/systemd` — un tree folding
**deux niveaux au-dessus** du seul fichier du paquet. Tout `~/.config/systemd/` serait
devenu le dépôt, et `systemctl --user enable` y aurait écrit ses liens `.wants`, sans
parler des drop-ins futurs. Remède minimal : faire exister `~/.config/systemd/user` avant,
pour que Stow n'ait plus rien à folder. Vérifié après coup : le lien d'activation est bien
dans le home, et `git status` est resté propre.

> **Leçon : `stow -n -v` avant tout `stow`.** La simulation dit à quel niveau le folding
> va se produire — c'est la seule façon de le voir venir, et ça ne coûte rien.

**Et l'échéance de la fiche snapper est arrivée aujourd'hui, sans que personne ne la
déclenche.** Elle disait : « le disque interne porte un Windows opérationnel qui sert de
secours ; **le jour où ce Windows sera formaté**, la question de la sauvegarde hors machine
se reposera entièrement. » Ce Windows a disparu ce matin. Il n'y a donc plus aucun secours
hors du disque de travail : les instantanés vivent sur le disque qu'ils protègent, et
`grub-btrfs` n'étant pas installé, ils ne sont même pas amorçables. Consigné comme point
ouvert dans `poste/README.md`, non tranché.

> **Ce qui est intéressant, c'est que la note s'était condamnée elle-même à l'avance** et
> que personne ne l'a rouverte au moment où sa condition s'est réalisée. Une note qui
> dépend d'un état de la machine devrait être relue quand cet état change — c'est le
> corollaire de « une note de piège se re-teste ».

### Ce qui reste, et quand

- **VM Windows d'administration : prévu le lundi 7 septembre 2026.** Étapes 3 à 7 de la
  fiche `poste/` — `libvirt`, groupe `libvirt` (effectif à la session suivante), copie de
  l'image depuis `sda3` en `cp --sparse=always`, `restorecon`, pont `br0`, domaine. Le
  prérequis Btrfs est **déjà fait** : sous-volume créé, `+C` posé à vide, exclusion prouvée.
- `grub-btrfs`, hors dépôt Fedora — sans lui les instantanés ne sont pas amorçables.
- Retirer les deux lignes redondantes de `hyprland.lua`, après quelques jours d'usage réel
  d'`uwsm`.
- Enrôlement TPM2 pour LUKS.

### Temps passé

<!-- TODO : à compléter. C'est encore la donnée qui manque à chaque entrée. -->
