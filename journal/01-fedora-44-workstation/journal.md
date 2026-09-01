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

> **CORRECTION, fin de journée — ce correctif était faux.** `--to-code` traduit bien le
> symbole en code, mais **sans retirer le `Maj` que ce symbole exige** : `$mod+1` et
> `$mod+Shift+1` se retrouvaient tous deux sur `$mod+Shift+AE01`, et la première liaison
> inscrite gagnait. Le bug n'était pas résolu, il était **déplacé**. La bonne réponse est
> `bindcode` (codes `10`–`19`) — voir « Le point ouvert des chiffres, soldé » plus bas.

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

### L'agent SSH sous Sway : un problème qui n'en était plus un

Point ouvert depuis quelques jours : `SSH_AUTH_SOCK` réputé non persistant sous Sway,
après un `git push` bloqué. En voulant le régler, j'ai découvert qu'il **était déjà
réglé** — et la façon dont je m'en suis rendu compte vaut plus que le correctif.

Le fichier qui fait le travail, `/usr/lib/systemd/user/gcr-ssh-agent.socket` :

```ini
ListenStream=%t/gcr/ssh
ExecStartPost=-/usr/bin/systemctl --user set-environment SSH_AUTH_SOCK=%t/gcr/ssh
[Install]
WantedBy=sockets.target
```

Il vient du paquet `gcr`, il est `WantedBy=sockets.target`, donc **relancé à chaque
session, quel que soit le bureau**. La variable n'est pas un résidu volatil : elle est
reposée à chaque login. Mon point ouvert décrivait l'état d'*avant* l'activation du
socket, et je ne l'avais pas relu depuis.

Vérification dans le terminal :

```
SSH_AUTH_SOCK = /run/user/1000/gcr/ssh
256 SHA256:VVStpM… jzielona@fedora (ED25519)
56fdced…  refs/heads/main
```

Tout répond. Rien à corriger.

#### Deux fausses pistes, et ce qu'elles apprennent

**J'ai d'abord soupçonné un conflit GNOME/Sway** — Sway installé par-dessus GNOME,
d'où un environnement bâtard qu'une install propre n'aurait pas. Faux : le socket `gcr`
ne dépend d'aucun bureau. Le vrai clivage est ailleurs, et il est plus intéressant :
**qui lance le compositeur.** GNOME est démarré par `systemd --user` et hérite donc de
`set-environment` ; Sway est lancé par GDM dans `session-2.scope` et n'en hérite pas.
Fedora comble l'écart avec `/etc/sway/config.d/10-systemd-session.conf`, qui lance
`sway-systemd/session.sh` pour propager l'environnement dans les deux sens.

Leçon : **avant d'écrire un contournement, vérifier si la distro n'a pas déjà traité le
problème.** J'allais versionner un correctif pour quelque chose que Fedora gère.

**Ensuite j'ai cru reproduire la panne en direct** : un `git fetch` échouait
(`Permission denied (publickey)`) avec `SSH_AUTH_SOCK` vide, pendant que le mien passait
dans le terminal. Mais c'était l'assistant qui échouait, pas la machine — il tourne dans
un bac à sable qui retire l'accès à l'agent SSH et interdit même la lecture de
`/proc/<pid>/environ`. Un outil automatisé n'est pas un témoin fiable de l'état du
système : **refaire la mesure dans un vrai terminal avant de conclure.**

C'est la deuxième fois de la journée que je manque d'attribuer une friction à la mauvaise
cause — après `gio mount` qu'il aurait été facile d'imputer à Sway. Le point commun :
tester deux choses nouvelles en même temps rend la nouveauté la plus visible
suspecte par défaut.

#### Ce que ça change pour l'axe « bureaux »

L'agent SSH, le trousseau et le dialogue de montage viennent **tous** de la pile GNOME
installée par la baseline. Sway s'appuie dessus sans le dire. Une install Sway seule
n'aurait pas ce problème — elle en aurait un autre : monter un agent SSH et un
gestionnaire de secrets à la main.

Ce n'est pas une réserve sur la validité du test : ce que je reproche à GNOME est son
**interface**, pas sa plomberie. `gnome-keyring`, `gvfs`, Nautilus me vont très bien et
resteront. « Sway par-dessus les utilitaires GNOME » est donc la configuration que je
vise, pas un artefact.

Ce que ça change quand même, pour les itérations suivantes : sur une distro qui ne livre
pas ces utilitaires aussi facilement que Fedora Workstation, le temps passé à les gréer
sera à chronométrer comme n'importe quelle autre friction. C'est une donnée de
comparaison entre distros, pas un doute sur l'axe bureaux.

### Noctalia remplace swaybar et wmenu — et une collision AZERTY de plus

Point de départ trivial : le menu de `Super+D` est illisible et minuscule. En cherchant
à le remplacer, j'ai découvert deux choses que je croyais savoir et qui étaient fausses.

**Ma barre n'était pas `waybar`.** Le paquet est installé — tiré par le groupe
`swaywm` — mais rien ne le lance. Ce que j'avais en haut de l'écran, c'était `swaybar`,
démarré par le bloc `bar { }` de `/etc/sway/config`, avec pour toute barre d'état :

```
status_command while date +'%Y-%m-%d %X'; do sleep 1; done
```

Une boucle shell qui affiche la date. Mon point ouvert « waybar laissée par défaut »
était faux depuis le début : **un paquet installé n'est pas un paquet utilisé**, variante
directe du piège « un dépôt activé n'est pas un paquet installé » du 28 août.

**Noctalia n'est pas un lanceur.** C'est un shell Wayland complet — barre, lanceur,
notifications, verrouillage, fond d'écran, réglages, 112 commandes IPC. Le confondre
avec un remplaçant de `wmenu` aurait mené à un chantier trois fois plus gros que prévu
sans que je l'aie décidé. Ici c'est ce que je voulais, mais il fallait le savoir avant.

Bonne surprise : **packagé dans Fedora officiel** (dépôt `updates`), pas un COPR.
`noctalia 5.0.0~beta.10`, 9 paquets, 45 Mo. C'est une **beta**, ce qui sur une machine
unique mérite d'être pesé — mais le risque est plus faible qu'il n'y paraît : Noctalia
n'est pas le compositeur. S'il tombe, Sway continue et je perds la barre, pas la session.
Une beta de shell et une beta de noyau ne se jugent pas pareil.

#### La méthode qui a payé : tout tester à chaud avant d'écrire

Démon lancé à la main, `swaymsg bar bar-0 mode invisible`, lanceur testé en IPC —
**rien d'écrit tant que ce n'était pas validé de visu**. Un redémarrage de session
suffisait à tout effacer en cas d'échec. Ça n'a rien coûté et ça évite de versionner
une configuration qu'on n'a jamais vue tourner.

Détail de config qui vaut d'être noté : la barre de `/etc/sway/config` **ne peut pas être
supprimée**, puisque le `include` ne se retire pas. Il faut la neutraliser par son
identifiant — que Sway génère seul et que `swaymsg -t get_bar_config` révèle (`bar-0`) :

```sway
bar bar-0 mode invisible
```

Sans ça, deux barres se superposent. Même logique que les `unbindsym` : le fichier
personnel n'efface pas la config système, il la surcharge.

#### `Super+Maj+-` muet : le piège symbole/code, vu par l'autre bout

Un seul raccourci ne répondait plus. Un seul — et c'est ce détail qui a donné la cause.

En fr-azerty : `key <AE06> { [ minus, 6, bar, fiveeighths ] }`. La touche « 6 » produit
`minus` **sans** Maj. Or `/etc/sway/config` lie le scratchpad à ce symbole :

```sway
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+minus scratchpad show
```

Mes `unbindsym $mod+6` / `$mod+Shift+6` n'y touchaient pas : **un symbole et un code sont
deux objets distincts**, et je n'avais retiré que le mauvais des deux. Deux liaisons se
disputaient la même touche physique.

Et c'est la **seule** collision possible : la rangée AZERTY produit `& é " ' ( - è _ ç à`,
et `minus` est le seul de ces symboles que Sway lie par défaut. Le symptôme « une seule
touche est muette » n'était donc pas une anomalie à côté du problème — c'était la
signature exacte de la cause. Une panne qui ne touche qu'un seul cas mérite qu'on cherche
ce que ce cas a d'unique avant de suspecter le hasard.

Correctif : `unbindsym $mod+minus` et `unbindsym $mod+Shift+minus`. Conséquence assumée,
le scratchpad n'a plus de raccourci — noté dans les points ouverts plutôt que réattribué
à la va-vite.

#### Ce que ça met au jour, et qui reste à traiter

En vérifiant, j'ai constaté que `Super+chiffre` ne fait **rien** et que
`Super+Maj+chiffre` va sur l'espace au lieu d'y envoyer la fenêtre. Les deux rôles sont
décalés d'un cran.

Hypothèse : `--to-code` traduit le keysym `1` en keycode, mais `1` est au **niveau 2** de
`AE01` en AZERTY — il exige déjà Maj — et Sway a pu conserver ce Maj dans la liaison.
`$mod+1` serait devenu `$mod+Shift+AE01`, et `$mod+Shift+1` demanderait deux Maj, donc
serait inatteignable. Ce serait exactement le bug d'origine, déplacé d'un rang.

Si ça se confirme, **mon correctif du 1er septembre n'a pas résolu le problème, il l'a
déplacé** — et l'entrée correspondante de ce journal est à corriger. À vérifier avec
`bindcode` et les codes physiques (`10` à `19`) plutôt qu'avec `--to-code`. Non bloquant,
mais c'est le genre de chose qu'on ne retrouve jamais si on ne l'écrit pas le jour même.

### Le cadre bleu « Claude Code » — chercher le pixel du bon côté

Un cadre bleu portant « Claude Code » sur chaque fenêtre, entre la barre Noctalia et
l'invite. J'ai d'abord cherché du côté de Claude Code. Mauvaise piste.

C'est la **barre de titre de Sway**. `swaymsg -t get_tree` le dit sans ambiguïté :

```
'foot'                border='normal'  bw=2  name='◐ Cadre bleu Claude Code…'
'org.mozilla.firefox' border='normal'  bw=2  name='Fedora Start | …'
```

`border=normal`, c'est le défaut de Sway : un liseré **plus** une barre de titre. Le
texte est écrit par l'application (Claude Code renomme le titre du terminal, Firefox y
met le nom de l'onglet), le bleu vient de `client.focused` (`#285577`) — jamais redéfini,
`/etc/sway/config` ne contient aucune directive `border`, `client.*` ni `font`.

Réglé en `default_border pixel 2` : le liseré reste (il indique le focus, indispensable
en tuilage sur trois écrans), la barre de titre disparaît.

**Ce que ça apprend :** le programme dont le nom s'affiche n'est pas celui qui dessine.
Même famille que « un paquet installé n'est pas un paquet utilisé » — avant de chercher
un réglage dans une application, vérifier qui peint réellement le pixel.

Deux détails de méthode au passage. `default_border` est une règle appliquée à la
**création** d'une fenêtre : un `reload` ne retouche pas les fenêtres ouvertes, il faut
un sélecteur (`swaymsg '[title=".*"] border pixel 2'`) pour voir l'effet tout de suite.
Et en disposition onglets ou piles, les titres reviennent forcément — c'est le principe
de ces dispositions, pas la bordure.

### Le fond d'écran : deux surfaces sur la même couche

Voulu supprimer le papier peint de Sway pour laisser Noctalia gérer le fond. Le premier
réflexe — recouvrir avec `output * bg #000000 solid_color` — a produit un bug bien plus
instructif que le réglage lui-même : **à la connexion c'était le fond Noctalia, mais au
moindre `swaymsg reload` Sway reprenait la main.**

La cause n'est pas une histoire de priorité. La directive `bg` ne fait pas dessiner Sway :
elle lui fait **lancer un processus `swaybg`** (`pgrep -a swaybg` le montre). Or swaybg et
Noctalia peignent tous deux sur la même couche layer-shell `background`, où c'est la
surface **la plus récemment créée** qui passe devant. À la connexion, Noctalia démarre
après swaybg et gagne. Au rechargement, Sway tue et relance swaybg : le nouveau devient
le plus récent et recouvre Noctalia.

Deux corrections écartées, vérifiées et pas supposées :

- swaybg transparent (`#00000000`) pour voir Noctalia au travers : Sway refuse l'alpha,
  `Colors should be of the form #RRGGBB`. `swaybg -c` non plus.
- retirer la directive : impossible, le `include` se surcharge et `bg none` n'existe pas.

J'ai donc essayé de tuer le processus : `exec_always pkill -x swaybg`. **Ça n'a pas
marché, et l'échec était trompeur** — la commande tuait bien quelque chose, mais
`exec_always` s'exécute *avant* que Sway ait fini d'appliquer la config des sorties.
Elle tuait l'ancien swaybg, et le nouveau — celui qui gêne — survivait. Il a fallu
`exec_always sh -c 'sleep 1; pkill -x swaybg'` pour que ça tienne.

**Ce que ça apprend :** une commande qui réussit n'est pas une commande qui fait ce qu'on
croit. `pkill` renvoyait un succès en frappant la mauvaise cible. Et une temporisation qui
marche reste un aveu : on ne sait pas *quand* l'autre composant agit, on parie.

### Sortir de l'`include` — Sway ne fait plus que du tuilage

Le `sleep 1` m'a décidé. Ce n'est pas propre d'attendre qu'un processus se lance pour le
tuer aussitôt, et surtout ce n'était pas un cas isolé. Le fichier accumulait des
contournements qui disaient tous la même chose :

| Contournement | Ce qu'il compensait |
|---|---|
| 22 × `unbindsym` | les liaisons chiffres par symbole |
| `bar bar-0 mode invisible` | le bloc `bar { }` |
| `output * bg` + `sleep 1; pkill` | la ligne 24 du fichier système |

**Cause commune : `include /etc/sway/config`.** Sway ne sait pas *désactiver* une
directive — il n'existe aucun « défaire », seulement « en poser une autre par-dessus ».
Tant qu'on hérite d'un environnement de bureau complet dont on ne veut pas, on ne peut
que le recouvrir pièce par pièce.

D'où la bascule : reprendre le fichier au lieu de l'hériter. Les 91 directives actives du
fichier système découpées en deux, selon ce que je veux vraiment — **Sway ne fait que du
tuilage, Noctalia fait le shell.** Passent à Noctalia : le fond d'écran, le lanceur
(`wmenu-run`), le menu de session (`swaynag`), le son et la luminosité (`pactl`,
`brightnessctl`), la capture (`grim`), la barre. Reste à Sway : variables, focus et
déplacement, espaces de travail, dispositions, scratchpad, mode resize.

Résultat : **plus aucune directive `bg`, donc Sway ne lance plus swaybg du tout.** Rien à
tuer, pas de temporisation, pas de course entre deux surfaces. Les 22 `unbindsym` et le
`bar bar-0 mode invisible` disparaissent dans le même mouvement. 100 directives actives,
un seul fichier.

**Le piège de l'opération, à ne jamais oublier.** La *dernière* ligne de
`/etc/sway/config` est `include /etc/sway/config.d/*`. Abandonner l'include principal
sans reprendre celle-là aurait cassé la session : c'est elle qui charge
`10-systemd-session.conf`, donc `sway-systemd/session.sh`, donc la propagation de
l'environnement vers systemd et D-Bus (`WAYLAND_DISPLAY`, `SWAYSOCK`,
`XDG_CURRENT_DESKTOP`), le démarrage de `sway-session.target`, et par ricochet l'agent
SSH et les portails. Un fichier qu'on remplace, ça se lit **en entier** d'abord — la
ligne vitale était la dernière.

Ce que la bascule coûte, assumé : une mise à jour du paquet `sway` ne se propage plus
dans ma config. Pour le lab ça déplace aussi légèrement l'axe — l'`include` montrait *ce
que Fedora fournit*, un fichier possédé donne le même environnement partout. Compte tenu
de l'objectif « Sway ne fait que du tuilage », c'est le bon compromis.

Une précision qui a orienté tout le découpage : **les raccourcis restent dans Sway.**
Noctalia n'a aucun système de raccourcis — son `settings.toml` ne contient que `[theme]`
et `[wallpaper.*]` — et ne peut pas en avoir, puisque sous Wayland seul le compositeur
voit le clavier. Le partage réel est : Sway capte la frappe, Noctalia fournit le
comportement et l'affichage. Les lignes `bindsym … exec noctalia msg …` sont des appels
IPC, pas des implémentations. « Déléguer à Noctalia » ne veut donc pas dire « vider la
config Sway ».

### Le point ouvert des chiffres, soldé — `--to-code` était bien coupable

Hypothèse notée hier, confirmée aujourd'hui. `bindsym --to-code` traduit bien le symbole
en code de touche, **mais sans retirer le Maj que ce symbole exige**. Sur AZERTY, `1` est
au niveau 2 de `AE01` :

- `bindsym --to-code $mod+1` devenait `$mod+Shift+AE01`
- `bindsym --to-code $mod+Shift+1` devenait… la même chose

Les deux liaisons atterrissaient sur la même combinaison physique et la première inscrite
gagnait. D'où le symptôme exact : `Super+touche` ne faisait rien, `Super+Maj+touche`
changeait d'espace au lieu d'y envoyer la fenêtre.

**Mon correctif du matin n'avait donc pas résolu le bug, il l'avait déplacé d'un rang.**
C'est la vraie leçon de la journée, plus que la syntaxe : un symptôme qui change de forme
n'est pas un symptôme qui disparaît.

Corrigé en `bindcode`, qui prend le code de la touche **physique** sans passer par un
symbole ni par un niveau. Codes lus dans `/usr/share/X11/xkb/keycodes/evdev`, pas devinés :
rangée du haut `AE01`=10 … `AE10`=19, et `TLDE`=49. Testé : `Super+&` va sur l'espace 1,
`Super+Maj+&` y envoie la fenêtre. Les deux fonctionnent enfin.

Trois objets distincts, à ne plus confondre : un **symbole**, un **code de touche**, un
**niveau**. Toute config de WM tuilant écrite pour QWERTY est à relire avec ça en tête.

Le scratchpad, orphelin depuis que j'ai retiré les liaisons `minus` qui entraient en
collision avec l'espace 6, est réattribué à `²` (`bindcode 49`) — touche libre, isolée en
haut à gauche, hors de la rangée des chiffres.

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
