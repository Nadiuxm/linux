# Journal — Fedora 44 Workstation

Entrées datées, les plus récentes en haut.
Noter **le problème et le temps perdu**, pas seulement la solution.

---

## 2026-09-01 — Sway : un second bureau, le clavier qui saute, et l'accès au NAS

Première sortie du protocole de baseline, assumée. La baseline Fedora était déjà
capturée et poussée, donc ce qui suit est daté et traçable sans la polluer.

### Mise à jour du matin

`dnf update` (transaction 7, 09:50) — **111 paquets, aucun problème constaté**.
C'est une donnée, pas un non-événement : le critère « stabilité » de cette itération
se construit exactement comme ça, une mise à jour à la fois. La deuxième depuis
l'install, la deuxième sans casse.

### Pourquoi un gestionnaire de fenêtres

Le projet vise à choisir une distro **et** un environnement de travail. GNOME est le
défaut de Fedora, pas un choix — il fallait bien un comparatif. Un WM tuilant est le
bon premier pas : il ne remplace rien, il ajoute une session dans GDM, et il se retire
sans traces. Un bureau complet type KDE aurait tiré SDDM en concurrence de GDM.

**Sway plutôt que Hyprland, et le dépôt a tranché tout seul :**

```console
$ dnf info sway        →  sway 1.11-3.fc44, dépôt « fedora »
$ dnf list hyprland    →  Aucun paquet correspondant à lister
```

Hyprland aurait demandé un COPR tiers. Ajouter un dépôt non maintenu par Fedora sur
la machine de baseline pour découvrir le tuilant : mauvais rapport risque/bénéfice.
À reconsidérer plus tard si Sway convainc.

### Ce que « minimal » veut dire — transaction 8

`dnf group install swaywm` (10:01) — **38 paquets**. Le détail de `dnf history info 8`
vaut le détour, grâce à la colonne `Reason` :

- **14 en `Group`** : ce que j'ai demandé (`sway`, `swaybg`, `swayidle`, `swaylock`,
  `foot`, `waybar`, `dunst`, `grim`, `slurp`, `xdg-desktop-portal-wlr`…)
- **le reste en `Dependency` / `Weak Dependency`** : `wlroots` (le moteur de
  compositeur sous Sway), les dépendances de `waybar`, les polices FontAwesome

**Le WM « léger » coûte donc 2,7× ce qu'on croit demander.** Retenir la colonne
`Reason` : elle distingue une intention d'une conséquence, ce que la simple liste
des paquets installés ne dit pas.

Le groupe `swaywm` valait mieux que `dnf install sway` seul : ce dernier aurait donné
un WM sans terminal, sans lanceur, sans barre et sans outil de capture — c'est-à-dire
un écran noir dont on ne sait pas sortir.

### Le vrai enseignement : trois piles clavier qui ne se parlent pas

En arrivant sur Sway, le clavier serait passé en **US QWERTY**. Repéré avant de me
connecter, en croisant trois vérifications :

```console
$ cat /etc/X11/xorg.conf.d/00-keyboard.conf
# Written by systemd-localed(8), read by systemd-localed and Xorg.
        Option "XkbLayout" "fr"
        Option "XkbVariant" "azerty"

$ grep -rl XKB_DEFAULT_LAYOUT /etc/environment /etc/environment.d/ ...
(rien)

$ grep -iE "xkb|input" /etc/sway/config
(rien)
```

Le système *sait* que je suis en AZERTY — mais chaque environnement l'apprend par un
canal différent, et aucun n'est partagé :

| Pile | Source lue |
|---|---|
| Xorg | `/etc/X11/xorg.conf.d/00-keyboard.conf` |
| GNOME | `gsettings` → `[('xkb', 'fr+azerty')]` |
| Sway / wlroots | `XKB_DEFAULT_LAYOUT`, ou sa propre section `input` — sinon **`us`** |

L'en-tête du fichier Xorg le dit lui-même : *« read by systemd-localed and Xorg »*.
Sway est Wayland, il ne le lit jamais.

**Leçon, et c'est la même que celle des dépôts tiers, vue sous un autre angle :
un fichier de configuration présent dans `/etc` n'est pas un fichier lu par tout
le monde.** Avant de conclure qu'un réglage est « fait au niveau système », vérifier
*qui* le lit. Le corollaire pratique : ce sera à refaire sur chaque distro où je
testerai un compositeur Wayland — ce n'est pas un défaut de Fedora.

Temps perdu : zéro, parce que le problème a été vu avant. Il aurait coûté un bon
quart d'heure de tâtonnement à taper des commandes en QWERTY sans le savoir.

### Config Sway versionnée — et le piège du `include`

Config posée en paquet Stow : `dotfiles/sway/.config/sway/config`, deux réglages
seulement (`include` + section `input`).

Le `include /etc/sway/config` n'est pas cosmétique : **dès que `~/.config/sway/config`
existe, Sway ignore `/etc/sway/config` entièrement, il ne fusionne pas.** Sans cette
ligne, tous les raccourcis par défaut disparaissaient d'un coup. À ne pas confondre
avec `/etc/sway/config.d/`, qui lui est bien fusionné — mais qui appartient à root et
ne peut donc pas vivre dans le dépôt.

### Tree folding, vu dans l'autre sens

```
LINK: .config/sway => ../linux/dotfiles/sway/.config/sway
```

Stow pose toujours le lien **le plus haut possible**. Pour `bash` il avait pu prendre
`~/.bashrc.d` en entier ; ici il s'arrête à `~/.config/sway` parce que `~/.config`
existait déjà avec 15 entrées à GNOME — impossible de monter plus haut sans les
écraser. Même mécanisme, résultat différent selon l'état de la cible.

Conséquence identique en revanche : `~/.config/sway/` **est** le dépôt. Tout fichier
déposé dedans sera versionné — jamais de secret là-dedans.

### Vérification finale

```console
$ swaymsg -t get_inputs | grep xkb_active_layout_name
    "xkb_active_layout_name": "French (AZERTY)"     (sur chaque périphérique)
```

`input type:keyboard` s'applique à toute la **classe**, pas à un modèle nommé : un
clavier USB branché demain sera en AZERTY sans rien toucher. Effet de bord amusant,
les faux claviers (`Power Button`, `Video Bus`, `Dell WMI hotkeys`) sont listés aussi.

### Trois écrans : Sway ne sait pas ce qu'est un « écran principal »

Disposition à remettre d'aplomb — le grand 27" devait être au centre, il était à
gauche dans le plan virtuel. Deux notions manquantes côté Wayland, et c'est le
vrai apprentissage du sujet :

- **Pas de numérotation d'écrans.** Sway ne connaît que des *sorties* nommées
  (`DP-3`, `HDMI-A-2`, `DP-1`) placées par **coordonnées en pixels** dans un plan
  virtuel commun. « Écran 1 » n'existe nulle part : c'est la position X qui décide
  du bord par lequel la souris passe, et rien d'autre.
- **Pas d'écran principal.** `--primary` est une notion **X11/RandR** qui n'a pas
  d'équivalent Wayland. Ce qui s'en rapproche, c'est de décider où atterrissent les
  espaces de travail (`workspace 1 output DP-3`) : la session s'ouvre sur l'espace 1,
  donc sur cet écran-là.

Identification physique des dalles avec `swaynag -o <sortie> -m "<sortie>"` : un
bandeau nommé s'affiche sur chaque écran. Indispensable — les noms de sortie ne
disent rien de la place sur le bureau, et inverser deux écrans se paie en souris
qui part du mauvais côté.

**Le détail qui compte, l'alignement vertical.** Le central fait 1440 de haut, les
deux latéraux 1080. Collés à `y=0`, leurs bords hauts sont alignés et les petits
« pendent » de 360 px : la souris décroche en traversant. `(1440-1080)/2 = 180`
les centre verticalement. Testé, adopté — le passage est fluide.

```
   HDMI-A-2            DP-3              DP-1
   1920x1080         2560x1440         1920x1080
   ┌────────┐      ┌──────────────┐      ┌────────┐
   │ y=180  │      │     y=0      │      │ y=180  │
   └────────┘      └──────────────┘      └────────┘
   x=0             x=1920                x=4480
```

**Méthode de travail à réutiliser :** `swaymsg output ... position ...` applique
**immédiatement et ne persiste pas**. On essaie à chaud, on compare, et seulement
une fois convaincu on écrit dans la config. Un `Super+Maj+C` annule tout.
Et avant de recharger une config modifiée :

```console
$ sway --validate --config ~/.config/sway/config
```

Elle vérifie la syntaxe **sans appliquer** — de quoi ne pas se retrouver avec une
session cassée pour une accolade oubliée.

**Nommage par port, choix assumé.** La config utilise `DP-3`/`HDMI-A-2`/`DP-1`,
c'est-à-dire les **prises**. Un câble déplacé d'un port à l'autre rend le bloc faux.
L'alternative durable est l'identifiant `marque modèle série`
(`"Dell Inc. DELL P2725DE FVTKM84"`), qui suit la dalle et pas le connecteur — noté
en commentaire dans la config. Le branchement ne bougeant pas, le plus lisible a été
préféré, en connaissance de cause.

### Deux pièges de raccourcis, dont un vrai bug AZERTY

Première vraie session d'usage. Deux frictions, et les deux sont des mécanismes à
comprendre plutôt que des réglages à ajuster.

#### `bindsym` lie un symbole, pas une touche

Constaté à l'usage : `Super+Maj+&` **changeait d'espace de travail** au lieu d'y
envoyer la fenêtre. Autrement dit, « déplacer une fenêtre vers l'espace N » était
purement **inatteignable au clavier**.

La cause est dans le manuel, noir sur blanc :

> *Bindings to keysyms are layout-dependent. This can be changed with the
> `--to-code` flag.* — `man 5 sway`

`/etc/sway/config` écrit `bindsym $mod+1`, ce qui lie le **symbole** `1`. Sur AZERTY,
ce symbole n'existe qu'avec `Maj` (la touche donne `&` sans). Donc `Super+Maj+&`
produit bien le symbole `1`, et déclenche la liaison **sans**-Maj — celle qui change
d'espace. Pour atteindre `$mod+Shift+1` il faudrait un *second* `Maj`. Il n'y en a pas.

Correctif : `bindsym --to-code`, qui traduit le symbole en **code de touche physique**
dans la première disposition configurée. C'est alors la touche qui compte, plus le
caractère qu'elle produit.

Détail qui a son importance : les anciennes liaisons ont été retirées à l'`unbindsym`
plutôt que simplement redéfinies. Une liaison par symbole et une liaison par code sont
**deux objets distincts** pour Sway ; les deux auraient coexisté et se seraient marché
dessus.

**Portée du problème :** ce n'est ni un défaut de Fedora ni de Sway, c'est la rencontre
entre une config écrite pour QWERTY et un clavier AZERTY. Le même piège attend sur i3,
Hyprland, et toute config de WM tuilant récupérée sur Internet. À vérifier
systématiquement : *ce raccourci lie-t-il un caractère ou une touche ?*

#### Une affectation d'espace ne vaut qu'à la création

Après avoir écrit `workspace 2 output DP-3` et rechargé, l'espace 2 restait obstinément
sur l'écran de gauche. Réflexe d'abord : « j'ai dû me tromper de manip ». Non.

`workspace <n> output <sortie>` s'applique **au moment où l'espace est créé**. Les
espaces 1 et 2 avaient été créés automatiquement au démarrage de la session — Sway en
ouvre un par écran — donc *avant* que la règle n'existe. `swaymsg reload` prend bien la
règle pour la suite, mais ne **déplace pas** ce qui est déjà là.

Deux sorties : relancer la session, ou déplacer à la main.

```console
$ swaymsg 'workspace number 2; move workspace to output DP-3'
```

**Leçon générale, et c'est la troisième fois de la journée que je la croise :**
recharger une configuration n'est pas la même chose que repartir d'un état neuf.
Certaines directives décrivent un *état* (`output ... position`, appliqué
immédiatement), d'autres une *règle appliquée à un événement futur*
(`workspace ... output`, appliqué à la création). Confondre les deux fait douter de
sa propre manipulation.

#### Réglages retenus

- **Flèches = déplacer la fenêtre**, `h/j/k/l` = déplacer le focus. Les flèches
  faisaient doublon avec `hjkl` sur le focus ; déplacer une fenêtre est le geste le
  plus fréquent, il méritait les touches les plus évidentes.
- **Une colonne d'écran par position dans la rangée de chiffres** : `1 4 7 10` à
  gauche, `2 5 8` au centre, `3 6 9` à droite. La rangée du clavier reproduit la
  disposition du bureau — `Super+&` part à gauche, `Super+é` au centre, `Super+"` à
  droite. Plus rien à mémoriser.
- **Pas besoin de `move container to output`.** Avec des espaces épinglés à des
  sorties, envoyer une fenêtre sur l'espace 4 l'envoie *de fait* sur l'écran de
  gauche. Le raccourci « déplacer vers l'écran voisin » devient superflu — une
  bonne répartition remplace une famille entière de raccourcis.
- `exec swaymsg workspace number 2` pour démarrer au centre, l'espace 1 étant
  désormais à gauche. C'est ce qui tient lieu d'« écran principal ».

### Accès au NAS de l'alternance — trois façons de garder un mot de passe

Le NAS `pdc-nas-info` contient mon travail d'alternance : sans accès, je ne travaille
pas. Il fallait donc un montage automatique. Contrainte que je me suis fixée : **pas de
mot de passe en clair sur le disque**, d'autant que ce disque n'est pas chiffré.

Ces deux exigences se sont révélées **incompatibles telles quelles**, et c'est le vrai
enseignement de la journée.

#### Un montage système ne peut pas interroger un trousseau

`mount.cifs` ne sait lire qu'un fichier ou une variable d'environnement. Aucun hook,
aucun rappel vers un gestionnaire de secrets. Ce n'est pas une lacune de configuration :
un montage déclaré dans `/etc/fstab` s'exécute **en root, avant mon login**, à un moment
où ni le bus de session ni le trousseau déverrouillé n'existent. Il n'y a rien à
appeler.

Donc : « monté par le système » et « secret dans un trousseau de session » ne peuvent
pas aller ensemble. Il faut lâcher l'un des deux. J'ai lâché « système » — le montage se
fait maintenant dans ma session, au login.

À retenir plus largement : **avant de chercher comment brancher deux composants,
vérifier qu'ils sont éveillés au même moment.** C'est la même erreur de raisonnement que
pour le clavier — croire qu'un réglage est disponible partout parce qu'il existe.

#### Le trousseau fonctionne sous Sway, l'agent SSH non — et ce n'est pas contradictoire

J'aurais parié le contraire, vu le point ouvert sur `SSH_AUTH_SOCK`. Vérifié :

```
org.freedesktop.secrets   3714  gnome-keyring-d  jzielona  session-2.scope
```

Le trousseau répond, déverrouillé, en session Sway. Écriture et lecture testées.

Alors que les trois `/etc/xdg/autostart/gnome-keyring-*.desktop` portent bien
`OnlyShowIn=GNOME;Unity;MATE;` — Sway ne les lance pas. La contradiction n'est
qu'apparente : **deux composants du même paquet démarrent par deux mécanismes
différents.**

| Composant | Démarrage | Sous Sway |
|---|---|---|
| `ssh` | autostart XDG, filtré `OnlyShowIn` | absent → d'où `SSH_AUTH_SOCK` vide |
| `secrets` | activation **D-Bus** à la demande | présent |
| déverrouillage | **PAM** (`pam_gnome_keyring` dans `/etc/pam.d/gdm-password`) | fait au login GDM, quel que soit le bureau lancé ensuite |

Correction de ma règle précédente : « vérifier *qui* lit un réglage » ne suffit pas, il
faut aussi vérifier **par quel mécanisme un service démarre**. Un même paquet peut être
à moitié disponible.

#### `gio mount` ne sait pas écrire dans le trousseau — une heure perdue

Le montage en ligne de commande fonctionnait, mais le mot de passe n'était jamais
enregistré. J'ai d'abord cru rater l'invite `[0] Never, [1] Session, [2] Permanently` :
en réalité **elle ne m'a jamais été proposée**, et `gio mount --help` ne montre aucune
option de sauvegarde.

Le composant qui écrit dans `gnome-keyring`, c'est le **dialogue GTK**
(`GtkMountOperation`), celui de Nautilus — pas l'outil en ligne de commande. Un montage
depuis Nautilus, « se souvenir pour toujours », et l'entrée apparaît :

```
label = jzielona@pdc-nas-info.te-mgmt.io
schema = org.gnome.keyring.NetworkPassword
attribute.server = pdc-nas-info.te-mgmt.io
attribute.domain = /
```

Ensuite seulement, `gio mount` monte sans rien demander : il ne sait pas écrire dans le
trousseau, mais `gvfsd` sait y lire.

**Ce n'est pas un problème de Sway** — `gio mount` se comporterait pareil sous GNOME.
Piège de méthode : quand on teste deux choses nouvelles en même temps (un bureau et un
protocole), la tentation est d'imputer chaque friction à la nouveauté la plus visible.
Ici ça aurait pollué l'axe « bureaux » avec une limite d'outil qui n'a rien à y voir.

#### Nautilus sous Sway : dégradé mais utilisable

Lancé depuis Sway, Nautilus crache une série d'erreurs — `org.gnome.Mutter.ServiceChannel`
sans propriétaire, portail `Inhibit` absent, `Tracker3.Miner.Files` en échec — puis
s'ouvre et fonctionne. L'indexation et la recherche sont mortes, le reste marche.

Donnée pour l'axe « bureaux » : les applications GNOME ne sont pas binaires sous un
compositeur tiers. Elles perdent des morceaux sans le dire clairement. Pour un usage
ponctuel c'est acceptable ; en usage quotidien il faudra voir ce qui manque vraiment.

#### Ce qui a été retenu

Montage GVFS déclenché par une unité `systemd --user` accrochée à
`graphical-session.target` (paquet Stow `nas`). Le mot de passe reste dans le trousseau,
l'unité ne contient aucun secret.

**Découverte au passage, qui vaut au-delà du NAS :** `sway-session.target` *et*
`graphical-session.target` sont toutes les deux actives — Fedora fournit une vraie
intégration systemd pour Sway. Une unité utilisateur accrochée à `graphical-session.target`
se déclenche donc **sous GNOME comme sous Sway**, avec un seul fichier. C'est
probablement la bonne piste pour régler `SSH_AUTH_SOCK`, plutôt que
`~/.config/environment.d/`.

Détail attrapé au test : `ExecStop` échouait quand le partage était déjà démonté à la
main, laissant l'unité en `failed` sans raison. Corrigé par un `-` préfixé
(`ExecStop=-/usr/bin/gio ...`), qui dit à systemd d'ignorer l'échec de cette commande.
Une commande d'arrêt doit tolérer que le travail soit déjà fait.

#### Ce que ça change pour la procédure de bascule

Le trousseau (`~/.local/share/keyrings/`) est chiffré par le mot de passe de session :
**il ne se transporte pas** d'une installation à l'autre, et n'a rien à faire dans le
dépôt. Donc après chaque réinstallation, `stow nas` remet l'unité en place, mais il
faudra **réenregistrer le mot de passe une fois via Nautilus**.

Trente secondes — à condition de savoir que l'étape existe. Sinon c'est un quart d'heure
à se demander pourquoi le partage ne monte pas. Noté dans `dotfiles/README.md`.

#### Constat non résolu : le disque n'est pas chiffré

`lsblk` : pas de LUKS, `/etc/crypttab` absent. Le trousseau protège le mot de passe
contre les autres comptes de la machine, mais quelqu'un qui démarre sur une clé USB ou
repart avec le SSD accède à tout — y compris à `login.keyring`, dont le chiffrement ne
tient qu'à mon mot de passe de session.

Pour un poste qui porte des accès à l'infrastructure d'un employeur, c'est le vrai trou,
et ni GVFS ni le trousseau n'y changent quoi que ce soit. **Le chiffrement se décide au
moment de l'installation** : c'est donc une case à cocher à la prochaine bascule de
distro, pas quelque chose à rattraper aujourd'hui. À trancher avant l'itération 02.

### Détail à ne pas oublier en relisant ce journal

`dnf history` affiche les heures en **UTC**, alors que les dates de ce journal et du
`README.md` sont en heure locale (UTC+2). La transaction 8 y apparaît à 08:01, elle a
été lancée à 10:01. Deux heures d'écart, de quoi se tromper en recoupant plus tard.

---

## 2026-08-28 — Mise en place du lab

Fedora 44 Workstation installé avec les options par défaut. Premier vrai geste :
créer ce dépôt pour ne plus perdre le fil d'une réinstall à l'autre.

Choix de méthode : **bare-metal successif** plutôt que des VMs. Plus lent et plus
risqué, mais je veux le ressenti réel sur la machine — veille, autonomie, matériel
Dell, stabilité sur la durée. Une VM ne dit rien de tout ça.

Dotfiles gérés avec **GNU Stow** (suggestion d'un collègue). Adapté au problème :
sur une machine nue, `git clone` puis `stow` remet tout en place, et les fichiers
réels vivent dans le dépôt — pas de script de synchronisation à maintenir.
`.bashrc` rendu portable au passage : le chemin du bashrc système diffère entre
Fedora (`/etc/bashrc`) et Debian (`/etc/bash.bashrc`), autant régler ça maintenant
plutôt qu'à l'itération suivante.

Baseline capturée : 357 paquets installés explicitement, 2024 au total.

### Le protocole de baseline

L'install est **strictement vierge**, et c'est volontaire. `dnf history` le confirme :
en dehors de la construction de l'ISO (avril, chez Fedora) et des langpacks français
posés automatiquement au choix de la langue, il n'y a que deux transactions à moi —
un `dnf update`, puis `dnf install keepassxc`.

**Un seul `dnf install` volontaire sur toute la machine.** C'est le protocole que je
dois reproduire à l'identique sur chaque distro suivante :

> install par défaut → mise à jour complète → KeePassXC → git + stow → rien d'autre

Toute la valeur de la comparaison tient à ça. Si j'ajoute des outils sur une distro
et pas sur une autre, je ne compare plus les distros mais mes propres bricolages.

`git` et `stow` ne sont pas des ajouts de confort : c'est l'outillage du lab, sans
lequel la méthode ne fonctionne pas sur la distro suivante. Ils font donc partie du
protocole, au même titre que KeePassXC — mais pour une raison différente, et cette
distinction compte quand je relirai ce journal dans six mois.

### Piège évité : les dépôts tiers ne sont pas des ajouts

En relisant la baseline j'ai d'abord cru que quatre dépôts non-Fedora avaient été
ajoutés à la main (google-chrome, RPM Fusion NVIDIA, RPM Fusion Steam, COPR PyCharm).
Faux — et `rpm -qf` le tranche en une commande :

```console
$ rpm -qf /etc/yum.repos.d/google-chrome.repo
fedora-workstation-repositories-38-9.fc44.x86_64
```

Les fichiers `.repo` sont **livrés par Fedora**, désactivés ; la case « Activer les
dépôts tiers » du premier démarrage les passe à `enabled=1`. Et rien n'en a été
installé : `google-chrome-stable` est absent du système, le dépôt est juste ouvert.

**Leçon de méthode :** un dépôt activé ≠ un paquet installé, et un fichier présent
dans `/etc` ≠ un fichier que j'ai mis là. Vérifier à qui appartient un fichier
(`rpm -qf`, ou `dpkg -S` côté Debian) avant d'en tirer une conclusion.

À noter pour la comparaison : cette facilité est propre à Fedora. Sur Debian ou
openSUSE, les codecs et pilotes propriétaires demanderont des manipulations —
**à chronométrer**, ce sera une donnée de comparaison.

### KeePassXC : critère éliminatoire

Seul logiciel installé volontairement, et pas par confort : c'est mon accès à mes
mots de passe personnels. Une distro qui ne le fournit pas facilement est
**éliminée d'office**, quelles que soient ses autres qualités. À vérifier avant
même de lancer une install : présent dans les dépôts officiels ? à quelle version ?

Ici : version 2.7.12, dépôt Fedora officiel, aucune manipulation. Référence à battre.

Point de vigilance associé : la base `.kdbx` est exclue du dépôt par le `.gitignore`.
C'est le bon choix — mais ça veut dire que **rien ne la sauvegarde automatiquement**.
En bare-metal, oublier cette sauvegarde avant une réinstall = perdre ses mots de
passe. C'est le risque n°1 de la méthode.

### Stow posé — ce que le conflit m'a appris

`stow -n -v -t ~ bash git` (simulation) a refusé de continuer :

```
WARNING! stowing bash would cause conflicts:
  * cannot stow .../bash/.bashrc over existing target .bashrc since neither
    a link nor a directory and --adopt not specified
All operations aborted.
```

Ce n'est pas un bug : Stow ne remplace **jamais** un fichier qu'il n'a pas créé.
Il ne gère que ses propres liens symboliques. Les `.bashrc` et `.bash_profile`
livrés par Fedora étaient de vrais fichiers, il fallait donc les écarter d'abord
(`mv` vers `~/.dotfiles-backup/`, pas `rm` — on ne détruit pas ce qu'on n'a pas relu).

Bien vu aussi : « All operations aborted ». Stow est **atomique**, il ne pose rien
tant qu'un seul conflit subsiste. Pas de demi-installation à rattraper.

Après nettoyage, les quatre liens se posent. Deux détails qui comptent :

- Ils sont **relatifs** (`.bashrc -> linux/dotfiles/bash/.bashrc`), pas absolus.
  Le dossier utilisateur peut être renommé ou remonté ailleurs, ça tient.
- `~/.bashrc.d` est un lien vers le **dossier** entier, pas un dossier réel contenant
  des liens : c'est le *tree folding* de Stow, qui pose le lien le plus haut possible.
  Conséquence pratique — tout fichier déposé dans `~/.bashrc.d/` atterrit dans le
  dépôt et sera versionné. Pratique, mais **jamais de secret ni de token là-dedans**.

### Dépôt distant — deploy key et identité

Poussé sur `github.com/Nadiuxm/linux` (privé).

Deux choses relevées au passage, à retenir pour la suite :

**La clé SSH est une deploy key, pas une clé de compte.** `ssh -T git@github.com`
répond `Hi Nadiuxm/linux!` — avec le nom du dépôt. Une clé de compte répondrait
`Hi Nadiuxm!` tout court. Une deploy key n'ouvre **qu'un seul dépôt**, et elle est
en lecture seule sauf si « Allow write access » a été coché. Ici l'écriture passe
(vérifié par `git push --dry-run`, qui teste les permissions sans rien envoyer).
Au prochain dépôt il faudra soit refaire une clé, soit l'enregistrer dans
*Settings → SSH and GPG keys* du compte pour qu'elle vaille partout.

**Identité git corrigée avant le premier push.** Les commits partaient avec mon
adresse pro alors que ce lab est personnel. Réécrit avec :

```bash
git rebase --root --exec "git commit --amend --no-edit --reset-author"
```

Trivial parce que rien n'était encore poussé. La même correction après un push
aurait demandé de réécrire l'historique côté GitHub — beaucoup plus pénible.
**Leçon : vérifier `git config user.email` avant le premier commit, pas après.**

---
