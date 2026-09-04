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

### Temps passé

<!-- TODO : à compléter. C'est encore la donnée qui manque à chaque entrée. -->
