# Contexte du projet — à lire avant toute intervention

Ce fichier est la mémoire durable du lab. Il est versionné : il survit aux
réinstallations, contrairement à `~/.claude/`. Le tenir à jour fait partie du travail.

## Ce qu'est ce dépôt

Un **lab d'évaluation de distributions Linux**, pas un projet logiciel. Objectif :
choisir la distribution et l'environnement de travail pour une alternance en
**mastère SRC** (Systèmes, Réseaux et Cloud computing), sur des notes prises au fil
de l'usage réel plutôt que sur une impression.

Utilisateur : Julien Zielona (`Nadiuxm` sur GitHub), **début d'alternance**.
Il administre des postes utilisateurs et traite des tickets — d'où RustDesk
(client généré par ses soins, donc portable sur toute distro) et l'accès NAS.
Ce n'est pas un poste de développement : les outils qui comptent sont ceux de
l'administration et du support.
Dépôt privé : `git@github.com:Nadiuxm/linux.git`

## Méthode : bare-metal successif

Chaque distro est installée **réellement sur la machine**, jamais en VM — le but est
le ressenti réel (matériel, veille, stabilité dans la durée). Une VM ne dit rien de ça.

> **Conséquence structurante :** chaque réinstallation efface la machine, ce dépôt
> local compris. Rien n'existe tant que ce n'est pas poussé. La procédure de bascule
> est dans `journal/README.md` et doit être déroulée **intégralement** avant tout wipe.

## Protocole de baseline — ne pas y déroger

Sur chaque distro testée, exactement :

> install par défaut → mise à jour complète → KeePassXC → git + stow → **rien d'autre**

Ajouter un outil sur une distro et pas sur une autre casse la comparaison. Le temps
passé sur chaque étape est lui-même une donnée à noter.

**KeePassXC est un critère éliminatoire**, pas une ligne de note : c'est l'accès aux
mots de passe personnels. Une distro qui ne le fournit pas facilement n'est pas
évaluable. À vérifier avant même de lancer l'installateur.

## Machine

Dell Pro Slim QCS1250 — Intel Core i5-14500 (20 threads) — 16 Go RAM.

**Deux disques, et leurs rôles se sont inversés le 2026-09-04.** Ce paragraphe affirmait
jusque-là que le système vivait sur un SSD externe et que le disque interne portait un
Windows de secours. **Les deux moitiés sont fausses depuis le 2026-09-04.**

| Disque | Rôle | Contenu |
|---|---|---|
| **NVMe interne** — KIOXIA BG6, 238 Go | **le poste de travail réel** | Fedora 44 minimale, **LUKS**, Btrfs. Cadrage dans `installation/` |
| **SSD USB** — boîtier générique « Generic PCIE », 233 Go (`TRAN=usb`) | **le lab** — formaté à volonté | itération 01 (Fedora 44 Workstation), intacte — **mais formatage annoncé le 2026-09-07** |

Le Windows interne n'existe plus : le NVMe est entièrement Fedora.

**Le reste du matériel, relevé le 2026-09-07** — il manquait, et il conditionne des
décisions (positions d'écran dans deux fichiers, injection clavier de RustDesk) :

- **Trois écrans Dell**, et l'ancrage se fait par **nom de sortie**, donc il suit le port :
  `HDMI-A-2` = P2425H (1920x1080, position `0,180`), `DP-3` = P2725DE (2560x1440,
  `1920,0`), `DP-1` = P2414H (1920x1080, `4480,180`). Les positions sont écrites **deux
  fois** — dans `dotfiles/hypr/` et dans le `greeter.toml`, qui tourne sur un autre
  compositeur et ne peut pas les deviner.
- **Clavier et souris Logitech** par récepteur unifying, **casque Yealink WH64** (qui se
  présente aussi comme un clavier). 14 périphériques clavier vus par Hyprland, **tous en
  `fr/azerty`**.
- **Secure Boot activé** (`enabled (deployed)`, `shim-x64`) : un module noyau non signé ne
  se chargera pas, et le message ne le dira pas.
- **TPM 2.0 présent** (`/dev/tpm0`, `has-tpm2` → yes) mais **PAS enrôlé sur LUKS** :
  `luksDump` montre `Tokens:` vide et **un seul emplacement de clé**. Phrase de passe à
  chaque démarrage, et aucune seconde voie d'ouverture du disque.
- **Machine sans nom** : `hostnamectl` → `Static hostname: (unset)`. Le `fedora` affiché
  partout est le nom transitoire par défaut.
- **Réseau : pont `br0`** (la VM Windows est sur le réseau de l'employeur en direct, pas
  derrière du NAT), `enp0s31f6` rattachée, et le profil Ethernet d'origine mis en
  `autoconnect=false` — cette dernière moitié est celle qu'on oublie.

**Conséquence sur la méthode, structurante.** La contrainte fondatrice — « chaque
réinstallation efface la machine, ce dépôt compris » — **ne tient plus**. Une itération se
mène sur le disque externe et ne touche ni le poste, ni le dépôt. Ça reste du bare-metal
sur la vraie machine, donc le ressenti matériel garde sa valeur.

**Le risque qui vient avec, à ne pas laisser filer.** La méthode tirait sa force de
l'obligation de vivre dans la distro testée. Avec un poste confortable sur le disque
interne, une distro sur l'externe risque d'être visitée une heure et jamais éprouvée.
La contrainte disparue doit être remplacée par une discipline explicite : **une itération
ne compte que si elle a porté du travail réel plusieurs jours**. Sinon l'axe distro meurt
en silence, sans que personne ne le décide.

Contrepartie inchangée du boîtier USB : modes de panne qu'un disque vissé n'a pas
(débranchement, câble, puce du pont). Ça ne concerne plus que le lab.

## Structure

> **Réorganisation par machine, le 2026-09-11.** Le dépôt décrivait **une seule** machine ;
> il en couvre deux. Tout l'historique est descendu d'un cran dans **`uc/`** (le poste fixe,
> Dell Pro Slim), et **`portable/`** a été créé **vide** pour le second poste.
>
> **Convention de lecture, qui vaut pour TOUT ce fichier et pour tout le contenu de `uc/` :**
> les chemins cités s'entendent **relatifs à `uc/`**. `installation/procedure.md` désigne
> `uc/installation/procedure.md`. Les fichiers n'ont pas été préfixés — c'eût été des
> centaines de retouches sans valeur, et un texte illisible. Le préfixe s'ajoute une fois,
> ici. **Seuls les GESTES ont été réécrits** (`cd ~/linux/uc/dotfiles`,
> `./uc/bin/snapshot.sh`) : une commande fausse ne se rattrape pas à la lecture.
> `installation/mesures.md` a été laissé intact **exprès** — ce sont des constats datés,
> et réécrire ce qui a réellement été tapé ce jour-là serait une falsification.
>
> **Ce que `portable/` doit contenir n'est PAS décidé** — second poste de travail, ou banc
> d'essai de `installation/procedure.md` ? Les deux ne donnent pas la même arborescence, et
> le second est le test de reproductibilité que ce dépôt exige sans l'avoir jamais passé
> autrement que sur papier (2026-09-08). Ne rien y écrire avant d'avoir tranché.

| Chemin | Rôle |
|---|---|
| `journal/` | Une itération = une distro. Fiche + entrées datées + `baseline/` capturée. |
| `poste/` | Inventaire **vivant** des outils de travail, indépendant de la distro. |
| `installation/` | **Le poste de référence.** Quatre fichiers aux rôles disjoints, découpés le 2026-09-08 : `procedure.md` = **les gestes** (seule source de ce qu'on tape) · `mesures.md` = les constats, versions et ce qu'ils apprennent · `README.md` = les décisions · `journal.md` = le récit daté. Les numéros de section de `procedure.md` et `mesures.md` se correspondent. |
| `dotfiles/` | Paquets **GNU Stow**. Poste de référence, *cible* : `stow -v -t ~ bash git hypr kitty nas uwsm noctalia` (**sept** paquets — `desktop` en est sorti le 2026-09-07, son unique entrée n'a plus d'objet ; `noctalia` et `kitty` sont entrés le 2026-09-09, tandis que `code` et **`foot`** ont été supprimés le même jour, avec leurs paquets RPM). **État réel au 2026-09-09 : 6 sur 7** — `noctalia` est posé, `kitty` reste à poser ; `bash` et `git` avaient été débloqués le 2026-09-08 en écartant les fichiers de l'ISO dans `~/sauvegarde-dotfiles-2026-09-08/` (ils étaient refusés depuis le 2026-09-04). Ne pas lire cette ligne comme un état : elle se re-mesure par `readlink` sur les cibles, pas par la commande qu'on a tapée. Le paquet `sway` ne sert plus qu'au lab. **`uwsm` exige `mkdir -p ~/.config/uwsm` avant le stow** (tree folding, voir les pièges). **Et le déplacement du 2026-09-11 a cassé les dix liens d’un coup** : ils sont relatifs et visaient `linux/dotfiles/…` — restow obligatoire, voir `dotfiles/README.md`. |
| `bin/snapshot.sh` | Capture l'état système. Agnostique du gestionnaire de paquets. Son `REPO` se déduit de sa propre position (`dirname/..`), il résout donc vers `uc/` sans modification — les captures continuent d'atterrir au bon endroit. |
| **`../portable/`** | **Le second poste**, vide au 2026-09-11. Rien n'y est mesuré : ni modèle, ni écrans, ni chiffrement, ni Secure Boot, ni TPM. Joignable en SSH sur `10.11.65.4`. |

Itération 01 : `journal/01-fedora-44-workstation/` (Fedora 44, GNOME 50.4, Wayland) —
sur le SSD USB, plus le poste de travail.

**Quatrième axe, ouvert le 2026-09-04 : le poste de référence** (`installation/`). Ce
n'est **pas une itération** et il n'entre pas dans la numérotation de `journal/` : c'est
la pile retenue pour travailler, épurée, montée sur le NVMe interne depuis une image
Fedora **minimale**. Le protocole de baseline ne s'y applique pas, comme il ne s'applique
pas à `poste/`. Une baseline comparée à celle de l'itération 01 mesurerait l'image ISO
(53 paquets explicites contre 357), pas la distribution — et c'est la même distribution.

**Exigence propre à cet axe : la reproductibilité.** Une réinstallation dans trois à six
mois est envisagée, donc « installation finale » est le mauvais mot. Tout geste posé doit
atterrir dans **exactement un** de ces trois endroits — `installation/procedure.md`,
`dotfiles/`, ou `poste/` — sinon il sera perdu. Détail et raisons dans
`installation/README.md`.

> **Corollaire appris le 2026-09-08, en rejouant la réinstallation sur papier : écrire un
> CONSTAT n'est pas écrire un GESTE.** L'ancien `procedure.md` portait des mesures très
> complètes — versions, sorties de commandes, tableaux — et il manquait dessous des gestes
> sans lesquels la machine ne démarre pas (`mesa-dri-drivers`) ou le NAS ne monte pas
> (réenregistrer le mot de passe SMB). **Aucune relecture ne le montrait ; seul le fait de
> dérouler le fichier comme un mode opératoire l'a montré.** D'où le découpage, et d'où le
> test à appliquer à `procedure.md` : *un lecteur qui ne lit que les blocs de code
> obtient-il la machine ?*

**Compositeur : Hyprland remplace Sway sur le poste de référence** (décision du
2026-09-04), pour les animations, coins arrondis et flou que wlroots ne fournit pas. La
chrome de Sway était déjà réduite au minimum, donc le manque n'était pas un défaut de
configuration. Le point ouvert « ressenti Sway à froid » est **clos sans verdict, sur un
abandon avant mesure** — l'écrire évite de croire plus tard que Sway avait été jugé.
`dotfiles/sway/` est gardé : il documente la solution AZERTY, valable pour tout WM tuilant.

**Troisième axe ouvert le 2026-09-03 : les outils du poste de travail** (`poste/`).
Ni `baseline/` (photo figée, sert à comparer les distros) ni `journal/` (daté, propre à
une itération) ne répondaient à « que dois-je réinstaller et reconfigurer pour
**retravailler** après une bascule ». `poste/` est cet inventaire, **explicitement hors
protocole de baseline** : rien de ce qu'il liste ne doit être installé avant la capture
de la baseline d'une nouvelle itération. Il se déroule de haut en bas après une
réinstallation, et alimente la procédure de bascule.
Une fiche par outil, toujours la même structure : rôle, obtention, portabilité, ce
qu'aucun `stow` ne restaurera, ce qu'il faut sauvegarder, ce qui est versionné.
Six fiches au 2026-09-09 : **VM Windows d'administration**, **RustDesk**, **Mattermost**,
**instantanés Btrfs (snapper)**, **WinBox** et **3CX**. Les deux outils **bloquants** — sans
lesquels le travail ne se fait pas depuis ce poste — restent la VM Windows et RustDesk ;
le 3CX est **secondaire** (un repli existe : mobile, poste physique). Le 3CX est aussi le
seul outil du fichier **sans installation de paquet** : 3CX n'a jamais publié de client
Linux et son app desktop est morte en janvier 2026, la voie supportée est le client web en
**PWA**, installé depuis Chromium. Rien à versionner, rien à sauvegarder.

**Second axe ouvert le 2026-09-01 : environnements de bureau.** Sway + Noctalia par-dessus
GNOME, sur l'itération 01. **Cet axe ne concerne QUE le lab, sur le SSD USB** — il n'y a ni
`sway`, ni `gnome-shell`, ni `gdm` sur le poste de référence, et il n'y en a jamais eu
(image minimale, vérifié le 2026-09-07). Cadrage détaillé dans le `README.md` de
l'itération 01, qui reste sa source. Si l'axe grossit (KDE, Xfce), lui donner son dossier.

**Noctalia — le seul composant de cet axe qui ait survécu à la bascule**, et il est passé
du lab au poste : shell Wayland complet (barre, lanceur, notifications, fond d'écran, OSD,
verrouillage, menu de session, IPC `noctalia msg --help`), aujourd'hui en **5.0.0~beta.10**
sur le poste, livré en binaire natif. Version **beta**, risque accepté : ce n'est pas le
compositeur, s'il tombe Hyprland continue de tuiler. Le grief contre GNOME étant esthétique
et non technique, c'est bien l'interface qui était évaluée.

**Le partage compositeur / shell est la vraie leçon de cet axe, et il s'est transposé
tel quel :** le compositeur ne fait que du **tuilage**, Noctalia fait **tout le shell**.
Corollaire à ne pas mal lire : **les raccourcis restent dans le compositeur** et appellent
`noctalia msg …`. Noctalia n'a aucun système de raccourcis et ne peut pas en avoir — sous
Wayland, seul le compositeur voit le clavier.

> **Ce qui était écrit ici jusqu'au 2026-09-07 décrivait Sway au présent** (« GNOME reste
> la session par défaut », « la config Sway n'inclut plus `/etc/sway/config` », « s'il tombe
> Sway continue de tuiler »), dans le fichier de contexte lu au début de chaque session.
> Trois paragraphes de l'itération 01 présentés comme l'état de la machine. La leçon a été
> gardée, l'état a été corrigé. Le détail Sway — config *possédée* et non héritée, et ce
> que ça coûtait en `unbindsym` — reste dans les pièges plus bas et dans `dotfiles/sway/`.

## Comment travailler avec Julien

- **Avancer par étapes.** Proposer, faire valider, puis construire. Ne pas dérouler
  une arborescence entière d'un coup : le but du projet est qu'il apprenne
  l'environnement Linux, et une structure toute faite qu'il n'a pas vue naître va
  contre cet objectif.
- **Lui laisser les commandes qui ont une valeur d'apprentissage** (`stow`, `git remote`,
  `ssh-keygen`, `snapshot.sh`) plutôt que de les exécuter à sa place. Fournir la
  séquence commentée et expliquer ce qui va se passer.
- **Ne rien pousser ni configurer de distant sans son accord explicite.**
- Écrire en français.

### OBLIGATOIRE — consulter la documentation AVANT de donner une commande

**Règle, sans exception : aucune commande n'est donnée à Julien depuis la mémoire seule.**
La documentation se consulte **avant** de l'écrire, pas après qu'elle a échoué. Ça vaut
d'abord pour toute commande qui **modifie un état** — `stow -D`, `systemctl disable`,
`rm`, `--delete`, `dnf remove`, `git reset` — où l'erreur ne se rattrape pas à la lecture.

**Ordre de consultation, du moins cher au plus cher. S'arrêter dès qu'on a la réponse.**

1. **La page de manuel locale** — `man <outil>`, `<outil> --help`, `info <outil>`.
   Elle décrit la **version installée ici**, ce qu'aucune page web ne garantit.
2. **Ce que le paquet livre** — `rpm -ql <paquet>`, les stubs (`/usr/share/hypr/stubs/`),
   les fichiers de conf d'exemple, le `README` dans `/usr/share/doc/`, les scriptlets
   (`rpm -qp --scripts`). Un fichier peut prescrire sa propre surcharge.
3. **Le code du composant** — un `grep` dans un script vaut mieux qu'un raisonnement sur
   son comportement, y compris quand le raisonnement annonce une mauvaise nouvelle.
4. **Le web** — et là il est **obligatoire**, pas optionnel, pour : un logiciel en
   développement rapide (Hyprland, Noctalia, greeter), un paquet de COPR, un comportement
   qui a changé récemment, ou tout ce dont la page de manuel locale ne parle pas.
   Chercher la doc **amont de la version installée**, jamais un tutoriel : ce dépôt a déjà
   payé 425 lignes de config écrites d'après des tutoriels périmés.

**Dire d'où vient la réponse.** Citer la source dans la réponse — `man systemctl`,
section `disable` — pour que Julien puisse vérifier. **Et si la doc n'a pas pu être
consultée, l'écrire explicitement** au lieu de livrer une commande avec l'aplomb d'une
qui l'a été. Une incertitude annoncée coûte une minute ; une commande fausse donnée
comme sûre coûte la confiance dans toutes les autres.

> **Pourquoi cette règle est en IMPÉRATIF ici et pas seulement dans les pièges.** Les
> pièges disaient déjà « un mécanisme plausible n'est pas une contrainte — la documentation
> de l'outil, si », « lire le code coûte moins cher que le raisonnement », « un avertissement
> peut être en tête du fichier qu'on a déjà sur son disque ». **Et le 2026-09-11, trois
> commandes fausses ont été données coup sur coup dans la même demi-heure** : `stow -D` sur
> des liens dont la cible avait bougé, `systemctl reenable` sur une unité fournie par Stow,
> puis « reposer le lien suffit » alors qu'Hyprland gardait son erreur.
>
> **Les trois étaient réfutées par des pages de manuel présentes sur le disque.** `man stow`,
> section DELETING PACKAGES : « Any symlink it finds that **points into the package being
> deleted** is removed » — la propriété se juge sur la **cible**. `man systemctl`, entrée
> `disable` : « this removes **all symlinks** to matching unit files, **including manually
> created symlinks** […] disable may remove **more symlinks** than a prior enable created ».
> Le web n'était même pas nécessaire.
>
> Un catalogue de pièges se lit **après** l'erreur, comme un récit. Une règle en impératif
> se lit **avant**, comme un protocole. C'est la seule différence entre les deux, et elle
> vaut trois commandes fausses.

## Convention du journal

Noter **le problème et ce qu'il apprend**, pas seulement la solution.
« J'ai perdu 40 min sur le pilote NVIDIA » est une donnée de décision ;
« j'ai installé akmod-nvidia » n'en est pas une. Une entrée est datée et écrite le
jour même, tant que le détail est frais.

## Pièges déjà rencontrés — ne pas refaire l'erreur

> **Convention de lecture, posée le 2026-09-07.** Beaucoup de ces pièges citent **Sway,
> GNOME ou GDM** : c'est là qu'ils ont été payés, sur l'itération 01. **Ce sont des
> exemples, pas l'état de la machine** — le poste de référence n'a ni Sway, ni GNOME Shell,
> ni GDM. Ce qui compte dans chaque entrée est le **mécanisme**, qui se transpose ;
> l'outil cité ne fait que dater l'apprentissage. Corollaire pour l'écriture : un piège peut
> nommer Sway ; une description d'état, jamais.

- **Un dépôt activé ≠ un paquet installé.** Les 4 dépôts tiers de Fedora appartiennent
  au paquet `fedora-workstation-repositories` livré dans l'image ; la case « dépôts
  tiers » du premier démarrage les active. Vérifier avec `rpm -qf` (ou `dpkg -S`) à
  qui appartient un fichier avant d'en conclure quoi que ce soit.
- **`dnf history` fait foi** pour savoir ce qui a été installé et quand — pas la date
  de `rpm -q`, qui change à chaque mise à jour. **Mais il ne voit que les paquets de la
  distro.** Un Flatpak n'y laisse aucune trace : son historique est ailleurs
  (`flatpak history`, `flatpak list --app`). Constaté le 2026-09-03 avec Mattermost.
  Depuis qu'il y a des Flatpaks sur la machine, **aucune source unique ne dit ce qui est
  installé** : il faut interroger les deux. Vaut pour toute distro — et c'est justement
  ce qui rend Flatpak intéressant pour la comparaison, puisqu'il est le seul canal
  identique partout.
- **Vérifier `git config user.email` avant le premier commit.** Corriger après un push
  demande de réécrire l'historique côté distant.
- **`~/.bashrc.d` est un lien vers le dépôt** (tree folding de Stow). Tout fichier
  déposé dedans sera versionné : jamais de token ni de secret là-dedans.
- **Un fichier de conf dans `/etc` n'est pas lu par tout le monde.**
  `/etc/X11/xorg.conf.d/00-keyboard.conf` n'est lu que par **Xorg** (son propre en-tête le
  dit) ; GNOME lit `gsettings` ; les compositeurs Wayland — wlroots, Hyprland — ne lisent ni
  l'un ni l'autre et retombent sur **US QWERTY**. D'où une disposition à déclarer dans
  *chaque* compositeur : `hyprland.lua`, le `greeter.toml`, et la config Sway au lab.
  Avant de conclure qu'un réglage est « fait au niveau système », vérifier *qui* le lit.
  À refaire sur chaque distro où un compositeur Wayland est testé.
  **Et cette note affirmait que le fichier dit `fr/azerty` : FAUX sur le poste, corrigé le
  2026-09-07.** Il y dit `XkbVariant "oss"`. C'était vrai sur l'itération 01, ça ne l'est
  pas ici — donc même le jour où un composant le lirait, il donnerait une **autre**
  disposition que celle configurée partout ailleurs. Le fichier est en outre **inerte** :
  `xorg-x11-server-Xorg` n'est pas installé, seul `Xwayland` est là et ne le lit pas. À
  laisser tel quel (`localectl` le régénère), mais **jamais comme source de vérité du
  clavier** — et ça reste la preuve qu'une note de piège se re-teste.
- **Sway ne sait pas *désactiver* une directive, seulement en poser une autre par-dessus.**
  Tant que le fichier versionné incluait `/etc/sway/config`, il héritait d'un bureau
  complet dont on ne voulait pas et se remplissait de contournements : 22 `unbindsym`,
  `bar bar-0 mode invisible`, `output * bg` doublé d'un `pkill`. Chacun compensait une
  ligne héritée. Quand les contournements s'accumulent, la question n'est plus « comment
  mieux recouvrir » mais « faut-il encore hériter ».
- **La ligne vitale d'un fichier peut être la dernière.** En abandonnant
  `include /etc/sway/config`, il fallait impérativement reprendre sa dernière ligne,
  `include /etc/sway/config.d/*` : c'est elle qui charge `sway-systemd/session.sh`, donc
  la propagation d'environnement vers systemd et D-Bus, `sway-session.target`, l'agent SSH
  et les portails. Un fichier qu'on remplace se lit **en entier** d'abord.
- **`dnf history` affiche l'heure en UTC**, le journal est en heure locale (UTC+2).
  Deux heures d'écart au moment de recouper une transaction avec une entrée datée.
  **Et `flatpak history` affiche l'heure LOCALE** — les deux historiques de la même
  machine ne sont donc pas dans le même fuseau. Vérifié le 2026-09-03 : `dnf` disait
  `07:57:12` pour une transaction de `09:57` locales, `flatpak` disait `12:12:47` pour
  12:12 locales. Convertir avant de comparer deux lignes d'historique entre elles.
- **`bindsym` lie un *symbole*, pas une touche — et `--to-code` ne suffit PAS.** Sur
  AZERTY le symbole `1` est au niveau 2 de `AE01` (il exige `Maj`), donc `bindsym $mod+1`
  rend `$mod+Shift+1` inatteignable. `bindsym --to-code` traduit bien en code de touche
  **mais sans retirer le `Maj` qu'exige le symbole** : `$mod+1` et `$mod+Shift+1`
  atterrissent tous deux sur `$mod+Shift+AE01`, la première liaison inscrite gagne — le
  bug est *déplacé*, pas résolu. Seule réponse correcte : **`bindcode`** avec les codes
  physiques, lus dans `/usr/share/X11/xkb/keycodes/evdev` (`AE01`=10 … `AE10`=19,
  `TLDE`=49). Un symbole, un code et un niveau sont trois objets distincts. Vaut pour
  toute config de WM tuilant écrite pour QWERTY, sur toute distro.
- **Un symptôme qui change de forme n'est pas un symptôme qui disparaît.** Le correctif
  `--to-code` ci-dessus avait l'air de marcher : le bug s'était juste décalé d'un rang.
  Avant de clore, vérifier que le comportement attendu est là — pas seulement que
  l'ancien symptôme a bougé.
- **Recharger une config ≠ repartir d'un état neuf.** Certaines directives décrivent
  un état appliqué tout de suite (`output ... position`), d'autres une règle qui ne
  vaut qu'à un événement futur (`workspace ... output`, appliquée à la *création* de
  l'espace). Un `reload` ne déplace pas un espace déjà ouvert — ça fait douter de sa
  propre manipulation alors que la config est juste.
- **Un paquet installé n'est pas un paquet utilisé.** `waybar` était installé (tiré par
  le groupe `swaywm`) et supposé actif ; en réalité c'était `swaybar` qui tournait, lancé
  par le bloc `bar { }` de `/etc/sway/config`. Vérifier ce qui **tourne** (`pgrep`,
  `swaymsg -t get_bar_config`), pas ce qui est installé. Même famille que « un dépôt
  activé n'est pas un paquet installé ».
- **Le programme dont le nom s'affiche n'est pas celui qui dessine.** Le cadre bleu
  « Claude Code » sur chaque fenêtre venait de la **barre de titre de Sway**
  (`border normal` + `client.focused #285577`), pas de l'application : le titre est écrit
  par le programme, le cadre est peint par le compositeur. Vérifier *qui peint le pixel*
  (`swaymsg -t get_tree`) avant de chercher un réglage dans l'application.
- **Deux composants qui peignent la même couche : c'est l'ordre de CRÉATION qui décide,
  pas une priorité.** `swaybg` (lancé par la directive `bg` de Sway) et le fond d'écran de
  Noctalia occupent tous deux la couche layer-shell `background` ; la surface la plus
  récente passe devant. D'où un fond correct à la connexion et repris par Sway à chaque
  `reload`, qui relance swaybg. La vraie réponse n'était pas de gagner la course mais de
  supprimer le concurrent (plus de directive `bg` → plus de swaybg du tout).
- **Une commande qui réussit n'est pas une commande qui fait ce qu'on croit.**
  `exec_always pkill -x swaybg` tuait bien un processus — l'ancien : `exec_always`
  s'exécute *avant* que Sway ait fini d'appliquer la config des sorties, donc avant que le
  nouveau swaybg n'existe. Vérifier l'**effet** (`pgrep` après coup), pas le code retour.
  Corollaire : un correctif qui a besoin d'un `sleep` est un pari sur un ordonnancement
  qu'on ne maîtrise pas — signal qu'il faut traiter la cause.
- **Un montage système ne peut pas interroger un trousseau de session.** `mount.cifs`
  ne lit qu'un fichier ou une variable d'environnement ; une ligne de `fstab` s'exécute
  en root **avant le login**, sans bus de session ni trousseau déverrouillé. Avant de
  chercher comment brancher deux composants, vérifier qu'ils sont **éveillés au même
  moment**. Corollaire : « monté par le système » et « secret dans un trousseau de
  session » sont incompatibles — il faut lâcher l'un des deux.
- **Deux composants d'un même paquet peuvent démarrer par des mécanismes différents.**
  `gnome-keyring` : le composant `ssh` vient d'un autostart XDG filtré `OnlyShowIn`
  (donc absent sous Sway), le composant `secrets` est activé par **D-Bus** à la demande
  et déverrouillé par **PAM** au login GDM (donc présent sous Sway). Un paquet peut être
  **à moitié** disponible. Vérifier *par quel mécanisme* un service démarre, pas
  seulement s'il est installé.
- **`gio mount` ne sait pas écrire dans `gnome-keyring`** — seul le dialogue GTK
  (Nautilus) le fait ; `gvfsd` sait ensuite y *lire*. Rien à voir avec Sway, identique
  sous GNOME. Piège de méthode général : quand deux nouveautés sont testées en même
  temps, ne pas imputer chaque friction à la plus visible — ça pollue l'axe d'évaluation.
- **`systemctl --user set-environment` n'alimente que les processus lancés par
  `systemd --user`.** Sway est lancé par GDM dans `session-2.scope`, pas par le
  gestionnaire systemd utilisateur — il n'en hérite donc pas directement. Ce qui sauve
  la mise sous Fedora : `/etc/sway/config.d/10-systemd-session.conf` lance
  `/usr/libexec/sway-systemd/session.sh`, qui propage l'environnement dans les deux sens
  et démarre `sway-session.target`. **Avant d'écrire un contournement, vérifier si la
  distro n'a pas déjà traité le problème** — ici c'était le cas, et le point ouvert
  `SSH_AUTH_SOCK` était obsolète depuis l'activation de `gcr-ssh-agent.socket`.
- **Un agent automatisé tourne dans un environnement filtré — ses échecs ne sont pas des
  symptômes système.** Un `git fetch` qui échoue de son côté pendant qu'il marche dans le
  terminal ne prouve **rien** sur la machine : les deux environnements ne se ressemblent
  pas (bac à sable, variables et accès aux fichiers). Toujours refaire la mesure dans un
  vrai terminal avant de conclure.
  **Vérifié le 2026-09-03, et la note d'origine était devenue fausse :** elle affirmait
  que Claude Code n'avait pas `SSH_AUTH_SOCK`. Il l'a — `/run/user/1000/gcr/ssh`, l'agent
  lui sert la clé, `git ls-remote` aboutit. Le correctif est celui de la transaction
  `gcr-ssh-agent.socket` + `sway-systemd/session.sh` : la note avait pris du retard sur
  lui. La leçon tient, la prémisse ne tenait plus — **une note de piège se re-teste**,
  sinon elle devient un piège à elle seule.

- **Un paquet listé n'est pas un paquet ajouté.** `dnf repoquery --userinstalled`, sur
  lequel repose `packages-explicit.txt`, **n'est pas une liste stable** : un paquet peut y
  entrer sans avoir été installé, si sa *raison* passe de `Dependency` à `Group`. C'est ce
  qu'un `dnf group install` fait sur des paquets **déjà présents**. Cas vérifié le
  2026-09-03 : `tuned-ppd` est sur la machine depuis la fabrication de l'ISO (22 avril),
  il est paquet *par défaut* du groupe `swaywm`, et il apparaît donc comme un « ajout »
  entre la baseline et aujourd'hui alors qu'il n'a jamais été installé dans cet intervalle.
  Un `diff` de listes explicites dit ce qui a été **voulu**, pas ce qui est **arrivé** —
  et il faut la liste complète des paquets installés pour la seconde question. Même
  famille que « un dépôt activé n'est pas un paquet installé ».
  Vérifier la raison : `dnf repoquery --installed --qf '%{name} %{reason}\n' <paquet>`.

- **La taille d'un fichier n'est pas son occupation disque.** `ls -l` et `du -b` donnent la
  taille *apparente* ; sur un fichier **creux** — image de VM, base de données — l'écart
  atteint un facteur 4. Le 2026-09-03, un garde-fou écrit avec `du -sb` a refusé une copie
  de 31 Go en croyant devoir en écrire 109. `du` **sans** `-b` donne l'occupation réelle.
  Corollaire moins évident et plus dangereux : un outil qui copie un tel fichier doit être
  **explicitement** chargé de reproduire les trous (`cp --sparse=always`), sinon la copie
  occupe sa taille apparente pleine — sans erreur, sans avertissement.

- **Une commande locale rapporte un RÉGLAGE, jamais un RÔLE d'infrastructure.** Deux
  adresses dans `IP4.DNS` disent « voici les résolveurs configurés » — pas « voici les
  contrôleurs de domaine ». Le 2026-09-03, cette déduction a été faite et corrigée : ce
  sont des serveurs de cache DNS. De même, un `/27` observé ne dit ni s'il y a du DHCP,
  ni si une adresse est libre, ni comment le parc est découpé. L'architecture réseau de
  l'employeur ne se déduit pas du poste : **elle se demande**. Vaut aussi pour un agent
  automatisé, à qui il faut interdire d'inventer ce genre de conclusion. Même famille que
  « un dépôt activé n'est pas un paquet installé » et « un paquet installé n'est pas un
  paquet utilisé » : l'outil rapporte un fait étroit, l'interprétation est ajoutée par le
  lecteur.

- **Un glob est développé par le shell APPELANT, avant que `sudo` n'élève quoi que ce soit.**
  Le 2026-09-04, `sudo grep … /boot/loader/entries/*.conf` a répondu « Aucun fichier ou
  dossier de ce nom » alors que les fichiers existaient : le dossier est en `drwx------ root`,
  le shell utilisateur n'a donc pas pu développer `*.conf`, et `grep` a reçu la chaîne
  littérale. **Le message décrivait ce que `grep` avait reçu, pas l'état du disque.** Réponse
  correcte : `sudo sh -c "… /chemin/*.conf …"`, pour que l'expansion se fasse côté root.
  Vaut pour toute redirection aussi (`sudo … > /fichier/root` échoue pour la même raison).
  Même famille que « une commande qui réussit n'est pas une commande qui fait ce qu'on croit » :
  lire *qui* exécute quoi, et à quel moment.

- **Un mécanisme plausible n'est pas une contrainte — la documentation de l'outil, si.**
  Le 2026-09-04 a produit une décision de partitionnement irrattrapable (« `/boot` doit
  aller dans le sous-volume Btrfs ») à partir d'un raisonnement juste sur le mécanisme :
  `grub-btrfs` cherche le noyau dans l'instantané, un `/boot` séparé y laisse un dossier
  vide, donc aucune entrée. Chaque étape était correcte, **et la conclusion était fausse** :
  le README de `grub-btrfs` annonce « Automatically detect if `/boot` is in a separate
  partition », et fournit même `GRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION` pour les cas
  où la détection échoue. Le mécanisme déduit ignorait simplement que l'outil traite le cas.
  **Avant de laisser une déduction imposer une décision qu'on ne peut pas reprendre, lire
  ce que l'outil dit de lui-même.** Coût évité de justesse : une réinstallation complète.
  Même famille que « un dépôt activé n'est pas un paquet installé » — l'outil rapporte un
  fait étroit, la contrainte est ajoutée par le lecteur.

- **Une liste tronquée n'est pas l'état du dépôt.** Corollaire du précédent, rencontré le
  même jour : `dnf list --available 'wlroots*' | tail -8` a fait conclure que Fedora 44
  n'avait que `wlroots0.18` et `0.19`, donc que le greeter Noctalia (qui exige
  `wlroots-0.20`) était infaisable. Le `tail` avait coupé les paquets **non versionnés** —
  `wlroots` 0.20.2 est dans `updates`, et c'est lui qui fournit `pkgconfig(wlroots-0.20)`.
  Un filtre d'affichage n'est pas un résultat de recherche : interroger la question exacte
  (`dnf repoquery --whatprovides 'pkgconfig(...)'`) plutôt que lire un extrait de liste.

- **Un format de configuration se vérifie sur la machine, pas dans sa mémoire ni dans les
  tutoriels.** Le 2026-09-04, 425 lignes de configuration Hyprland ont été écrites en
  **hyprlang** (`key = value`, la syntaxe de tous les tutoriels en ligne) alors
  qu'Hyprland l'a **déprécié depuis la version 0.55** au profit d'une API **Lua**. Le
  paquet ne livre plus qu'un `hyprland.lua`, et le compositeur avait lui-même généré un
  `~/.config/hypr/hyprland.lua` — l'indice était sous les yeux, dans le nom du fichier.
  La référence était sur le disque : `/usr/share/hypr/stubs/hl.meta.lua`, 1777 lignes
  d'API générée. **Avant d'écrire une configuration, regarder le fichier que le programme
  génère pour lui-même** et chercher ses stubs dans `/usr/share`. Vaut pour tout logiciel
  qui a changé de format récemment — et un logiciel en développement rapide, tiré d'un
  COPR, est précisément ce cas.

- **Un échec de configuration peut être totalement silencieux — vérifier la FORME de la
  sortie, pas seulement son existence.** La documentation d'Hyprland donne `code:X` pour
  lier une touche physique. Dans la config **Lua**, ça ne fonctionne pas : aucune erreur,
  aucun avertissement dans le log, la liaison est simplement inerte. Ce qui l'a révélé est
  la forme de `hyprctl binds` : une liaison correctement analysée montre une clé **courte**
  (`key: L`) avec le bon `modmask`, une liaison ratée conserve **la chaîne entière**
  (`key: SUPER + SHIFT + code:49`) avec `keycode: 0`. Compter 71 liaisons enregistrées
  n'aurait rien dit — c'est leur forme qui parlait. Même famille que « une commande qui
  réussit n'est pas une commande qui fait ce qu'on croit ».
  **Réponse retenue : lier les SYMBOLES RÉELS que produisent les touches, pas `code:NN`.**
  Sur AZERTY, la rangée du haut donne au niveau 1 `& é " ' ( - è _ ç à` (`ampersand`,
  `eacute`, `quotedbl`, `apostrophe`, `parenleft`, `minus`, `egrave`, `underscore`,
  `ccedilla`, `agrave`) et au niveau 2 le chiffre. « Aller à l'espace N » se lie donc sur le
  symbole, « y envoyer la fenêtre » sur `SHIFT + chiffre` : **la même touche physique, lue à
  ses deux niveaux.**

  *Pourquoi ça marche — et cette explication a été écrite à l'envers pendant trois jours.*
  Mesuré le 2026-09-07 : `hyprctl getoption input:resolve_binds_by_sym` → **`bool: false
  set: false`**. C'est parce que l'option vaut **`false`** qu'on peut lier les symboles :
  Hyprland traduit alors le keysym de la config en **code de touche** via le keymap courant,
  donc `eacute` désigne la touche physique `AE02` quel que soit le niveau où le symbole se
  trouve — d'où la cohabitation de `$mod+eacute` et `$mod+SHIFT+2`. Cette note affirmait
  l'inverse (`true` par défaut). **Le geste était bon, la raison était fausse depuis le jour
  où elle a été écrite, et elle a « marché » trois jours** : un geste qui fonctionne ne
  valide pas l'explication qu'on en donne, et une explication fausse se paie le jour où on
  veut transposer le raisonnement ailleurs. Une note de piège se re-teste, y compris quand
  elle n'a jamais échoué.

- **Une commande d'inventaire ne doit jamais pouvoir interrompre un script.** `rpm -q`
  renvoie un code d'erreur pour tout paquet **absent**. Sous `set -euo pipefail`, un
  `rpm -q` de contrôle listant un paquet non installé a tué un script d'installation à sa
  dernière étape — donc avant son `chown`, laissant un fichier **root** dans un dépôt git
  utilisateur, et avant l'affichage des instructions de la suite. Les commandes de
  vérification se terminent par `|| true`.

- **Certaines mesures n'ont de sens que depuis la session ACTIVE.** Le 2026-09-04,
  `hyprctl devices` listait zéro clavier et zéro souris, ce qui laissait croire à un
  problème d'entrées. Mesure refaite avec la session au premier plan : tous les claviers
  étaient là, en `fr/azerty`. **logind libère les périphériques d'une session inactive**,
  donc la liste vide décrivait la session d'observation, pas la machine. Vaut pour tout ce
  qui touche au seat : entrées, sorties, DRM. Même famille que « un agent automatisé
  tourne dans un environnement filtré ».
  **Cause première, trouvée plus tard le même jour :** il y avait **deux** sessions
  Wayland ouvertes (deux Hyprland, tty2 et tty3, deux sockets, deux signatures dans
  `/run/user/1000/hypr/`) — effet du lancement manuel depuis un tty. Tant qu'il y a
  plusieurs sessions, une mesure peut atterrir sur la dormante : commencer par
  `loginctl list-sessions` avant de conclure quoi que ce soit sur le matériel.

- **Une dépréciation ne frappe pas tout un sous-système d'un coup.** Le 2026-09-04,
  Hyprland 0.56.2 refusait `dwindle.pseudotile` (`hyprctl getoption` → `no such option`)
  alors que le pseudo-tuilage fonctionne toujours : la **clé de configuration** est morte,
  le **dispatcher** a survécu, et l'exemple livré par le paquet le montre
  (`hl.dsp.window.pseudo()`). Trouver en ligne un exemple qui marche ne dit donc rien de
  la façon dont la chose se **configure** aujourd'hui. Deux pièges de lecture qui vont
  avec, vérifiés le même jour : le **numéro de ligne** d'une erreur `hl.config` désigne le
  **site d'appel** (`hl.config({`), pas la clé fautive — 39 lignes d'écart ici ; et le
  **chemin** annoncé était tronqué (`~/.config/hyprland.lua` au lieu de
  `~/.config/hypr/hyprland.lua`), donc introuvable si on le cherche tel quel. Comme la
  validation s'arrête à la **première** clé inconnue, passer toutes les clés au
  `hyprctl getoption` avant de redémarrer évite de recommencer.

- **Un paquet peut arriver par une dépendance FAIBLE, et n'apparaître dans aucune liste
  qu'on lit.** Le 2026-09-04, ce dépôt affirmait qu'`uwsm` n'était pas packagé dans Fedora
  et désignait « remonter la plomberie systemd à la main » comme le vrai coût du passage à
  Hyprland. `uwsm` était **déjà installé** : `reason=Weak Dependency` du COPR
  `dtutila/hyprland`, aucun paquet ne le `Requires`. Ni dans ce qu'on a tapé, ni dans les
  dépendances dures. Vérifier avec
  `dnf repoquery --installed --qf '%{name} reason=%{reason} from=%{from_repo}\n' <paquet>`.
  Corollaire : `graphical-session.target` était bien inactive, mais parce que le
  compositeur était lancé **à la main depuis un tty** — un symptôme réel imputé à la
  mauvaise cause. Même famille que « un dépôt activé n'est pas un paquet installé ».

- **Vérifier la présence du MODULE, pas celle de la ligne.** `/etc/pam.d/greetd` livré par
  Fedora contient déjà `-auth optional pam_gnome_keyring.so` et son pendant `session`.
  Le préfixe `-` dit à PAM d'ignorer **en silence** un module absent — et
  `gnome-keyring-pam` n'étant pas installé, le fichier `.so` n'existe pas. Les lignes sont
  là et ne font rien. C'est le paquet qui manque, pas la configuration. Même famille que
  « un paquet installé n'est pas un paquet utilisé ».

- **La garde d'un script peut lire un fichier là où il faudrait lire une PILE.**
  `setup_greetd_pam.sh` du greeter Noctalia n'ajoute `pam_systemd.so` que si
  `grep -F pam_systemd.so /etc/pam.d/greetd` échoue — or sous Fedora le module arrive par
  `session include system-auth`, invisible à ce `grep`. Le module finit donc appelé deux
  fois. **Mais la conclusion à en tirer n'est pas « corriger le script » :** `man
  pam_systemd` ne documente aucun problème d'appel répété, donc rien n'était mesuré. Règle
  générale sortie de là : **un écart à la procédure officielle d'un outil ne se justifie
  que par un fait constaté sur la machine** — un nom de paquet qui n'existe pas, un compte
  que la distro nomme autrement — jamais par un raisonnement sur le mécanisme, aussi juste
  soit-il. Appliquer le geste documenté, puis **mesurer son effet**. Même famille que
  « un mécanisme plausible n'est pas une contrainte ».

- **Un fichier livré peut prescrire sa propre surcharge — le lire avant de l'appliquer.**
  Le `tmpfiles.d` du greeter Noctalia code en dur `greeter:greeter`, compte inexistant
  sous Fedora (le paquet `greetd` crée `greetd`), et son propre commentaire donne la
  réponse : « override under `/etc/tmpfiles.d/` if your greetd user differs ». Le geste
  correct était écrit dans le fichier.

- **Une unité systemd CHARGÉE n'est pas une unité EXÉCUTÉE.** Le 2026-09-04, un dialogue
  de création de trousseau au login a été imputé aux unités d'autostart XDG qu'`uwsm`
  charge — `systemctl --user list-units 'app-*'` les affiche bien. Vérification :
  `ExecMainStartTimestamp` **vide** et `pid=0` sur les trois
  `app-gnome-keyring-*@autostart.service` — elles n'ont jamais tourné, filtrées parce que
  `XDG_CURRENT_DESKTOP=Hyprland`. Le vrai déclencheur était une **activation D-Bus**, que
  le cgroup du processus donnait (`/proc/<pid>/cgroup` →
  `dbus-…-org.freedesktop.secrets@0.service`). Piège dans le piège : le nom de bus inscrit
  dans une telle unité (`:1.2`) est celui du **lanceur** `dbus-broker-launch`, pas du
  client demandeur — il ne permet pas d'identifier qui a demandé. Même famille que « un
  paquet installé n'est pas un paquet utilisé », transposée à systemd.

- **Un logiciel installé hors gestionnaire de paquets n'a personne pour l'étiqueter
  SELinux.** Le 2026-09-04, le greeter Noctalia (compilé, `meson install` dans
  `/usr/local`) ne pouvait pas écrire son propre `sync.toml` : il tourne confiné en
  `xdm_t` et son répertoire d'état était en `var_lib_t`, alors que le paquet `greetd`
  étiquette le sien en `xdm_var_lib_t`. Les **binaires** vont bien — `/usr/local/bin`
  s'étiquette `bin_t` comme `/usr/bin` — mais un **répertoire d'état créé par un `mkdir`**
  n'hérite de rien d'utile. Réponse correcte : `semanage fcontext -a -t <type> '<chemin>(/.*)?'`
  puis `restorecon -R`, ce qui déclare la nature du répertoire au lieu de desserrer
  SELinux. Vaut sur toute distro avec du MAC, pour tout `make install`.

- **Un chroot COPR listé n'est pas un paquet à jour.** Le 2026-09-07, deux COPR annonçaient
  `fedora-44-x86_64` pour `grub-btrfs`. L'un livrait `4.14-1.fc44` construit en mars 2026,
  l'autre un instantané git de **2022** en release **`.fc38`**, simplement recopié dans le
  chroot récent. La page COPR affiche « fedora-44 » dans les deux cas. La question se pose
  au paquet, pas à la liste des chroots :
  `dnf repoquery --repofrompath="c,<url du chroot>" --repo=c --nogpgcheck --qf '%{name}-%{version}-%{release} (%{buildtime})\n'`
  — ça répond sans rien installer. Même famille que « un dépôt activé n'est pas un paquet
  installé ».

- **Une sortie vide ne distingue pas un mauvais MOTIF d'une mauvaise CIBLE.** Le
  2026-09-07, `grep -o 'rootflags=subvol=[^ ]*'` n'a rien renvoyé sur `grub-btrfs.cfg`, et
  la conclusion tirée — « la note du dépôt se trompe sur la forme de l'option » — était
  **fausse**. Il y a deux fichiers et deux formes : l'entrée BLS **vivante** porte
  `rootflags=subvol=root` (`grubby --info=ALL`), tandis que le `grub-btrfs.cfg` **généré**
  porte `rootflags=<flags de fstab>,subvol="…"`, grub-btrfs reconstruisant la ligne depuis
  `GRUB_CMDLINE_LINUX`. Le motif était bon, la cible ne l'était pas. **Quand une mesure
  revient vide : lire le contenu brut (`sed -n '1,60p'`), et vérifier qu'on interroge le
  fichier dont parle la note.** Même famille que « une liste tronquée n'est pas l'état du
  dépôt ».

- **Un avertissement peut être en tête du fichier qu'on a déjà sur son disque.** Le
  2026-09-07, la question « démarrer sur un instantané en lecture seule, ça marche ? » a été
  laissée « non mesurée » après deux déductions sur le montage `rw`/`ro`. La réponse était
  aux **lignes 11-12** de `/etc/grub.d/41_snapshots-btrfs`, déjà extrait en local :
  « Warning : booting on read-only snapshots can be tricky », avec le lien vers la section
  du README qui donne la condition — « `/var/log` or even `/var` must be on a separate
  subvolume ». Le problème n'était pas le montage de la racine mais l'espace utilisateur.
  **Avant de qualifier une question de « non mesurée », `grep -n -i 'warning\|caveat\|note'`
  sur le fichier concerné.** Un fichier qu'on remplace se lit en entier — un fichier qu'on
  *installe* aussi.

- **Un RPM hors distribution se lit avant de s'installer — surtout ses SCRIPTLETS.** Le
  `%post` du `grub-btrfs` du COPR lance `grub2-mkconfig -o /boot/grub2/grub.cfg` de
  lui-même : `dnf install` réécrit donc le `grub.cfg` d'une machine UEFI + BLS sans le
  demander. Le sachant, la copie de sauvegarde se prend **avant** l'installation ; sans le
  savoir, elle ne se prend jamais. Séquence qui a servi, sans rien installer :
  `dnf repoquery --location`, `curl -o`, puis `rpm -qlp` (contenu), `rpm -qRp`
  (dépendances), `rpm -qp --scripts` (scriptlets), `rpm2cpio | cpio -idm` (lire les
  fichiers de conf livrés). Bénéfice symétrique le même jour : ça a aussi montré qu'il n'y
  avait **aucune** configuration à écrire, le paquet détectant Fedora tout seul.

- **Une supposition gratuite peut être PESSIMISTE — ça reste une supposition.** Le
  2026-09-07, `grub-btrfsd` était soupçonné de relancer un `grub2-mkconfig` complet (donc
  `os-prober`) à chaque instantané. Trois lignes de `grep` dans `/usr/bin/grub-btrfsd`
  disent l'inverse : il n'appelle que `/etc/grub.d/41_snapshots-btrfs` quand `grub.cfg`
  contient déjà `snapshots-btrfs`. Se méfier de la déduction ne suffit pas si on ne se
  méfie que dans un sens : **lire le code du composant coûte moins cher que le raisonnement
  sur son comportement**, y compris quand le raisonnement annonce une mauvaise nouvelle.

- **Une procédure de secours jamais exécutée n'est pas une procédure, c'est une intention.**
  La porte de sortie manuelle du dépôt — éditer l'entrée GRUB pour démarrer sur un
  instantané — portait un chemin **faux** : `.snapshots/<N>/snapshot` au lieu de
  `root/.snapshots/<N>/snapshot`, `/` étant monté en `subvol=/root`. Elle n'aurait pas
  démarré, et ça ne se serait su que le jour où elle sert. La case « répéter à froid »
  existait et n'avait jamais été cochée. **Une procédure de secours se répète à froid, ou
  elle ne compte pas** — corollaire de « une note de piège se re-teste », appliqué aux
  gestes plutôt qu'aux faits.

- **`/etc/profile.d/` n'est PAS lu par une session graphique.** Le 2026-09-07, les deux
  applications Flatpak étaient installées et n'apparaissaient pas dans le lanceur : le
  compositeur avait `XDG_DATA_DIRS=/usr/local/share:/usr/share`, sans les chemins Flatpak.
  Fedora livre pourtant `/etc/profile.d/flatpak.sh` qui fait le travail — mais `profile.d`
  ne s'exécute que dans un shell de **login**, et la session est lancée par
  greetd → uwsm → Hyprland, qui ne source jamais `/etc/profile`. **Le script est là et ne
  tourne pas.** Tout ce que la distro pose dans `profile.d` est donc absent d'une session
  Wayland lancée par un greeter, et ça ne se voit qu'à l'usage. Réponse : le fichier prévu
  par l'outil — `~/.config/uwsm/env`, documenté dans `man uwsm` — qui **source le script de
  la distro** plutôt que de recopier ses chemins. Même famille que « un fichier de conf dans
  `/etc` n'est pas lu par tout le monde » : vérifier *qui* lit un fichier, et *quand*.
  Corollaire de mesure : lire la variable sur le **processus en session**
  (`tr '\0' '\n' < /proc/$(pgrep -x Hyprland)/environ`), jamais dans le shell d'un agent —
  les deux environnements ne se ressemblent pas.

- **Un lien posé à la main au bon endroit n'est pas un lien reconnu par Stow — et il bloque
  tout le paquet.** Le 2026-09-08, `~/.bashrc.d` pointait vers le dépôt, en **absolu**.
  `stow -n -v bash git` a répondu `existing target is not owned by stow: .bashrc.d` puis
  `All operations aborted`. Le lien fonctionnait parfaitement et empêchait pourtant le
  déploiement — retirer le lien (pas sa cible) et laisser Stow le refaire. Même famille que
  « une commande qui réussit n'est pas une commande qui fait ce qu'on croit ».
  **L'explication donnée ici était fausse, corrigée le 2026-09-11** : elle disait « Stow ne
  reconnaît comme siens que les liens **relatifs** qu'il crée ». C'est un raccourci qui
  décrit bien ce cas-ci et se trompe de cause — voir l'entrée suivante, qui donne la vraie
  règle et l'a payée.

- **Ce qui décide de la propriété d'un lien, pour Stow, c'est sa CIBLE RÉSOLUE — pas sa
  forme.** Le 2026-09-11, le dépôt a été réorganisé par machine (`dotfiles/` → `uc/dotfiles/`),
  ce qui casse d'un coup les dix liens posés dans le home : ils sont relatifs et visaient
  `linux/dotfiles/…`. La réparation annoncée était `stow -D` puis `stow`, au motif — écrit
  dans le README la minute d'avant — que « Stow reconnaît un lien relatif qu'il a créé, pas
  la validité de sa cible ». **Déroulé sur la machine : `stow -D` n'a rien fait, sortie
  vide**, puis le `stow` suivant a déclaré les dix liens `not owned by stow` et
  `All operations aborted`. Stow **résout** la cible et vérifie qu'elle tombe dans le
  répertoire stow courant ; une cible hors de `~/linux/uc/dotfiles` — et ici pointant dans
  le vide — n'est pas à lui. Réponse correcte : supprimer les liens morts avant de stower,
  `find ~ -maxdepth 5 -xtype l -lname '*linux/dotfiles*' -delete` (`-xtype l` ne peut
  matcher qu'un lien **cassé**, jamais un vrai fichier).
  **C'était dans `man stow`, section DELETING PACKAGES** : « Any symlink it finds that
  **points into the package being deleted** is removed » — la cible, pas la forme. Une page
  de manuel locale, jamais ouverte. Deux corollaires :
  **`All operations aborted` n'est pas un échec** mais le refus de toucher à quoi que ce
  soit tant qu'un conflit subsiste — relancer à l'identique ne pouvait rien donner de plus ;
  et **tout déplacement du dossier `dotfiles/` dans le dépôt casse silencieusement le home**,
  un shell neuf perdant simplement son `.bashrc`. Même famille que « un mécanisme plausible
  n'est pas une contrainte » : la note avait été écrite depuis un raisonnement, pas depuis
  une mesure, et elle a tenu moins d'une heure.

- **Un lien d'activation systemd ne se répare pas avec `stow`.** Corollaire du précédent,
  même jour : `~/.config/systemd/user/graphical-session.target.wants/nas-infoadmin.service`
  a été posé par `systemctl --user enable`, pas par Stow, et il est **absolu**. Après un
  restow le fichier de l'unité est de nouveau en place, mais ce lien-là pointe toujours dans
  le vide — **le NAS ne se monte plus au login, sans aucune erreur**. Il faut
  `systemctl --user enable nas-infoadmin.service`. Deux liens vers le même fichier, posés
  par deux outils, dont un seul revient avec `stow` : recenser par `find`, pas par paquet.

- **`systemctl reenable` DÉTRUIT une unité fournie par Stow — `enable` seul est la commande
  juste.** Suite immédiate du point précédent, le 2026-09-11 : le `reenable` recommandé a
  répondu `Unit nas-infoadmin.service does not exist` **alors que `stow` venait de reposer
  le lien à la ligne d'avant**, et il a fallu un second `stow`. `list-unit-files` donne
  l'état **`linked`** : une unité atteinte par un **symlink** dans `~/.config/systemd/user/`
  est classée *liée*, pas *installée*. Or `reenable` = `disable` + `enable`, et **`disable`
  sur une unité `linked` supprime le symlink de l'unité elle-même**, pas seulement ses liens
  d'activation — le `enable` qui suit ne trouve donc plus rien. **Le message décrivait un
  état que la commande venait de créer.** Vaut pour *tout* paquet Stow livrant une unité
  systemd, puisque Stow ne pose que des symlinks : `enable` n'écrit que dans les `.wants` et
  est sans danger ; `disable` et `reenable` emportent le lien du dépôt. Même famille que
  « une commande qui réussit n'est pas une commande qui fait ce qu'on croit », prise par
  l'autre bout — la commande annonce une absence qu'elle a elle-même provoquée.
  **Et `man systemctl` le dit mot pour mot**, entrée `disable` : « this removes **all
  symlinks** to matching unit files, **including manually created symlinks**, and not just
  those actually created by enable or link […] disable may remove **more symlinks** than a
  prior enable invocation of the same unit created ». Deuxième page de manuel locale non
  ouverte le même jour — d'où la règle impérative en tête de fichier.

- **Le tree folding de Stow frappe partout où le dossier cible n'existe pas encore.**
  Troisième occurrence le 2026-09-07, après `~/.bashrc.d` et `~/.config/systemd` :
  `stow uwsm` allait poser `LINK: .config/uwsm => <dépôt>`, or `uwsm select` écrit un
  `default-id` dans ce dossier — il aurait fini versionné. Remède minimal et systématique :
  **`stow -n -v` d'abord** (la simulation nomme le niveau exact du lien), et faire exister
  le dossier parent avant si le lien remonte trop haut.

- **Une dépréciation de format touche aussi la LIGNE DE COMMANDE, pas seulement les
  fichiers.** Le 2026-09-07, `hyprctl dispatch moveworkspacetomonitor 1 HDMI-A-2` — la
  forme donnée par tous les tutoriels — a échoué : depuis la mort d'hyprlang, `hyprctl
  dispatch` **évalue son argument comme du Lua** (`return hl.dispatch(<argument>)`), donc
  un nom de dispatcher suivi d'arguments nus est une erreur de syntaxe. Forme correcte :
  `hyprctl dispatch 'hl.dsp.workspace.move({ workspace = "1", monitor = "HDMI-A-2" })'`,
  les noms venant de `/usr/share/hypr/stubs/hl.meta.lua` (`hl.dsp.*`). Le message d'erreur
  le disait lui-même. Corollaire de méthode : **une commande donnée à Julien se teste
  avant d'être donnée** — celle-ci avait été écrite de mémoire dans une réponse, sur un
  logiciel dont on savait déjà qu'il avait changé de format.

- **Les espaces de travail ne sont pas attachés aux écrans par défaut, et l'ordre des
  `monitorID` est celui de la DÉTECTION.** Le 2026-09-07, après un reboot, les espaces
  étaient « décalés d'un cran » : 2 à gauche, 3 au centre, 1 à droite. Il n'y avait aucune
  règle de workspace dans la configuration — Hyprland distribue alors 1..N dans l'ordre
  des `monitorID`, qui varie d'un démarrage à l'autre (DP-1, l'écran de droite, avait pris
  l'ID 0). Le réglage n'était pas faux, **il n'existait pas** et retombait juste par
  hasard. Réponse : `hl.workspace_rule({ workspace = …, monitor = "<nom>", default = … })`
  pour chaque espace. Deux conséquences à connaître : une règle de workspace ne vaut qu'à
  la **création** de l'espace, donc `hyprctl reload` ne déplace pas ceux qui sont déjà
  ouverts (même famille que « recharger une config ≠ repartir d'un état neuf ») ; et
  l'ancrage se fait par **nom de sortie**, donc il suit le port et non l'écran — ancrable
  par `description` (numéro de série) si les branchements bougent.

- **Un service ACTIVÉ n'est pas un service CONFIGURÉ.** Le 2026-09-07, `sssd.service`
  apparaissait `enabled` sur le poste — de quoi conclure que la machine est jointe au
  domaine. Elle ne l'est pas : `authselect current` donne le profil **`local`** et
  `/etc/sssd/` ne contient **aucun `sssd.conf`**. C'est un préréglage de Fedora, rien de
  plus. Un service sans fichier de configuration démarre, ne fait rien, et n'échoue pas.
  Avant de déduire un rôle d'infrastructure d'une liste d'unités, chercher **le fichier de
  configuration** correspondant. Même famille que « un dépôt activé n'est pas un paquet
  installé » et « une unité chargée n'est pas une unité exécutée » — troisième variante du
  même piège, cette fois entre l'activation et la configuration.

- **Le `%post` d'un RPM hors distribution peut poser des fichiers que `rpm -qf` ne
  reconnaîtra JAMAIS.** Le 2026-09-07, le RPM RustDesk a copié son unité dans
  `/etc/systemd/system/`, deux `.desktop` dans `/usr/share/applications/`, créé le lien
  `/usr/bin/rustdeskadmin`, puis lancé `systemctl enable` **et** `start` de lui-même.
  `rpm -qf /usr/bin/rustdeskadmin` répond « n'appartient à aucun paquet », alors que le
  paquet est installé et que c'est lui qui a créé le lien. Deux conséquences : un
  inventaire fondé sur `rpm -ql` rate le binaire, le lanceur et le service ; et une
  commande `systemctl enable --now` tapée après coup est inutile. **Complément au piège
  précédent sur les scriptlets : ils ne modifient pas seulement l'état du système, ils
  créent des fichiers hors de la base rpm.** Trois questions pour retrouver ce genre de
  chose : `dnf repoquery --installed --qf '%{name}|%{from_repo}\n' | grep -v 'fedora\|updates'`
  (un RPM local se signale par `@commandline`), un `rpm -qf` en boucle sur `/usr/local`, et
  `find /etc/systemd/system -maxdepth 1 -type f`.

- **`secret-tool search` AFFICHE les secrets en clair.** Erreur commise le 2026-09-07 en
  vérifiant que l'entrée SMB du NAS existait : le mot de passe s'est retrouvé dans une
  transcription. Pour vérifier l'existence et l'état d'une collection sans la lire :
  `busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked`.
  Vaut a fortiori pour un agent automatisé, dont la sortie est conservée.

- **Un titre de section peut mentir alors que la case en dessous est cochée — et c'est le
  titre qu'on lit.** Le 2026-09-07, `procedure.md` §6 s'intitulait encore « FAIT le
  2026-09-04, **non activé** » alors que la bascule vers greetd était cochée quinze lignes
  plus bas et que le greeter ouvrait la session depuis trois jours. Sur les douze cases de
  « Reste à faire » du cadrage, **neuf étaient faites**. Une liste de restes qui décrit un
  travail déjà accompli ne se contente pas d'être inexacte : elle **oriente vers ce qui est
  déjà fait** et masque ce qui manque vraiment. Corollaire de tenue : quand on coche une
  case, relire le **titre** de sa section.

- **La règle des trois destinations ne s'applique pas d'elle-même.** Le `greeter.toml` du
  poste — session par défaut, disposition `fr/azerty`, positions des trois écrans — a vécu
  trois jours dans `/var/lib/noctalia-greeter/`, root, hors du home, livré par aucun
  paquet : il n'appartenait à **aucune** des trois destinations et aurait disparu à la
  première réinstallation. `stow` couvre le home, pas le poste. **Un geste posé dans `/etc`
  ou `/var` n'a qu'une destination possible — la procédure — et rien ne le rappelle au
  moment où on le pose.** Le contrôle ne peut donc pas être « y ai-je pensé », il doit être
  périodique : confronter le dépôt à la machine.

- **Une fonction absente n'est pas un paquet manquant.** Le 2026-09-08, l'absence de `grim`,
  `slurp`, `swappy` et `flameshot` a fait conclure qu'il n'y avait pas de capture d'écran sur
  ce poste. Noctalia la fait **lui-même** (`zwlr_screencopy_manager_v1`), les raccourcis
  existaient depuis quatre jours et trois captures dormaient dans `~/Pictures`. Quand le
  shell intègre une fonction, la liste des paquets ne la montre pas. Même famille que « un
  paquet installé n'est pas un paquet utilisé », pris par l'autre bout.

- **Pour un raccourci qui ne marche pas, mesurer EN AMONT du compositeur.** Le 2026-09-08, la
  touche Impr écran du K650 était soupçonnée d'être un problème AZERTY. `libinput
  debug-events --show-keycodes` **sans `--device`** (donc sur les 15 périphériques) : aucun
  événement — le noyau ne reçoit rien, le bind était juste et inatteignable. Cause : le
  récepteur Bolt `046d:c548` tourne sous `hid-generic`, `c548` n'étant pas dans les alias de
  `hid_logitech_dj` ; les touches HID++ ne sont traduites par personne. Deux corollaires :
  `Print` est au **niveau 1** sur AZERTY (`symbols/pc`, non surchargé par `symbols/fr`), donc
  le piège de la rangée des chiffres ne s'y applique pas ; et le **bitmap `KEY` d'un
  récepteur est générique**, il ne dit rien du clavier apparié — l'avoir pris pour une preuve
  était une erreur, corrigée le jour même.

- **Un binaire posé hors gestionnaire de paquets n'a personne pour tirer ses dépendances, et
  l'échec est MUET.** Le 2026-09-08, coller une capture dans Claude Code ne faisait rien : la
  copie était bonne (entrée de 115 087 o dans l'historique Noctalia, PNG de 115 033 o, même
  seconde), mais **un terminal ne transporte jamais une image** — Claude Code lit la sélection
  lui-même en appelant `xclip` ou `wl-paste`, aucun des deux installé. Ni erreur, ni
  avertissement. `wl-clipboard` est donc une dépendance **du poste**, qu'aucun RPM ne réclame.
  Même famille que le piège SELinux sur `/usr/local` : ce qui est installé à la main n'a
  personne derrière lui.

- **Un portail absent n'est pas un repli en clair — et c'est le compositeur qui décide
  quel portail est servi.** Le 2026-09-09, l'`argv.json` de VS Code (paquet Stow `code`,
  depuis supprimé) justifiait `"password-store": "gnome-libsecret"` ainsi : Chromium devine
  son magasin d'après `XDG_CURRENT_DESKTOP`, la détection échoue sous Hyprland, il retombe
  sur `basic` — clé codée en dur, donc du clair. **La prémisse est à moitié vraie et la
  conclusion est fausse.** Ce qui échoue sous Hyprland est le **portail** :
  `~/.config/chromium/Local State` porte
  `os_crypt = {portal: {prev_desktop: "Hyprland", prev_init_success: false}}`, et
  `org.freedesktop.portal.Secret` est absent des 22 interfaces servies par
  `xdg-desktop-portal`. Cause :
  `/usr/share/xdg-desktop-portal/hyprland-portals.conf` impose `default=hyprland;gtk`, et
  aucun des deux n'implémente `Secret` — alors que l'implémentation est **présente et
  activable** (`gnome-keyring.portal` +
  `/usr/share/dbus-1/services/org.freedesktop.impl.portal.Secret.service`). **Un `.portal`
  installé n'est pas un portail servi**, c'est le `portals.conf` qui tranche — même famille
  que « un paquet installé n'est pas un paquet utilisé ». **Et le repli n'était pas
  `basic` :** pas d'`encrypted_key` dans `Local State` (sa signature), et le trousseau
  `login` contient `Chromium Safe Storage`. Chromium 151 a échoué sur le portail **puis
  réussi sur `gnome-libsecret`**. La note lisait la trace d'un échec et en déduisait l'état
  final : **un composant peut échouer sur un chemin et réussir sur le suivant.** Le
  `password-store` explicite ne servait qu'à VS Code, dont l'Electron embarque un Chromium
  plus ancien qui, lui, devine encore. Mesure sans exposer de secret : `os_crypt` dans
  `Local State`, puis les **libellés** via `busctl --user get-property … Items` et
  `… Item Label` — **jamais `secret-tool search`**.

- **Un avertissement de dépréciation n'est pas un échec.** Le 2026-09-09,
  `sudo rpm -e gpg-pubkey-<empreinte>` a répondu `attention : erasing gpg-pubkey packages
  is deprecated; use rpmkeys --delete <empreinte>` — **et avait supprimé la clé**. Le
  `rpmkeys --delete` lancé ensuite a répondu `key not found`, ce qui se lit spontanément
  comme « l'outil recommandé ne trouve pas la clé » alors que ça veut dire « il ne reste
  rien à supprimer ». Seule la mesure de l'**effet** tranche, par les deux outils :
  `rpm -qa gpg-pubkey --qf '%{summary}\n'` et `rpmkeys --list`. Même famille que « une
  commande qui réussit n'est pas une commande qui fait ce qu'on croit », prise par l'autre
  bout : ici la commande annonçait un problème et avait réussi.

- **Un magasin de confiance n'est relu qu'au DÉMARRAGE du processus.** Le 2026-09-11, le
  certificat racine de la PKI a été posé dans `/etc/pki/ca-trust/source/anchors/` :
  `trust list` montrait l'ancre, les **trois** bundles extraits la contenaient — et Chromium
  refusait toujours. Il n'y avait aucune erreur : `ps -o lstart` donnait un navigateur lancé
  **deux jours plus tôt**, qui avait chargé ses racines à son démarrage. Relancer a suffi.
  **La vérification système et la vérification applicative mesurent deux choses
  différentes**, et la première peut être verte pendant des heures pendant que la seconde
  est rouge, sans qu'aucune ne mente. Ce qui a failli être fait à la place : imputer l'échec
  au **Chrome Root Store** de Chromium 151 — mécanisme réel, récent, plausible — et ajouter
  `nss-tools` plus une base `~/.pki/nssdb` dont ce poste n'a aucun besoin. Un horodatage a
  tranché ce qu'un raisonnement rendait compliqué. Même famille que « recharger une config ≠
  repartir d'un état neuf » et « un mécanisme plausible n'est pas une contrainte ».
  *Corollaire pour les certificats :* une CRL déposée à la main n'est lue par **personne**
  côté poste (ni OpenSSL, ni GnuTLS, ni NSS) — c'est un objet de serveur, et l'absence de
  geste se documente, sinon le fichier posé à côté du certificat en appellera un.

## Hors périmètre — ne pas relancer le sujet

**La gestion et la sauvegarde des secrets** (clé SSH du dépôt, base KeePassXC) est
prise en charge par Julien, en dehors de ce dépôt et par ses propres moyens.
Ne pas auditer la clé, ne pas proposer de passphrase, de rotation ni de stratégie
de sauvegarde : le sujet a été explicitement clos le 2026-08-28.

La sauvegarde des secrets reste listée à l'étape 5 de la procédure de bascule
(`journal/README.md`) comme point de contrôle avant un wipe — c'est une case à
cocher, pas une invitation à rouvrir le débat.

## Points ouverts

> **Les trois points Sway de cette liste sont CLOS SANS VERDICT depuis le 2026-09-07.**
> Ils ne concernaient que le lab — `sway`, `swaybg`, `waybar`, `gnome-shell`, `gdm` et
> `firefox` sont **tous absents** du poste et n'y ont jamais été installés. Ils n'étaient
> mesurables que sur le SSD USB, dont le **formatage est annoncé** : le jour où il part,
> ils deviennent immesurables pour toujours. Les porter encore, c'est garder des cases que
> personne ne pourra jamais cocher. Détail de la clôture juste en dessous.

- **CLOS sans verdict le 2026-09-07 — les trois points Sway du lab.** Écrit pour qu'on ne
  croie pas plus tard qu'ils avaient été tranchés :
  - *`swaybg` résiduel* — après `swaymsg reload`, un `swaybg` restait lancé par Sway sans
    aucun argument, alors que la config n'avait plus de directive `bg`. **Jamais regardé.**
    Il suffisait d'un coup d'œil au bureau (fond Noctalia visible = processus inerte). La
    leçon, elle, est acquise et vaut ailleurs : deux composants sur la même couche
    layer-shell, c'est l'ordre de **création** qui décide — voir les pièges.
  - *Ressenti Sway à froid* — **abandon avant mesure**, déjà consigné dans
    `installation/README.md`. Sway a été remplacé par Hyprland le 2026-09-04 pour les
    animations, les coins arrondis et le flou, que wlroots ne fournit pas. On ne saura donc
    jamais si Sway au quotidien était plus rapide que GNOME : la question n'a pas été
    perdue, elle n'a pas été posée assez longtemps.
  - *`waybar` inutilisée* — installée par le groupe `swaywm`, sans rôle depuis que Noctalia
    fournit la barre. Rien à décider : le paquet part avec le disque.
- **L'axe « bureaux » portait sur l'interface, pas sur la pile logicielle** — et ça reste
  vrai pour la suite. Ce que Julien reproche à GNOME est esthétique et ergonomique ; les
  utilitaires GNOME (`gnome-keyring`, `gvfs`, Nautilus) ne posent aucun problème et sont
  assumés. « Un WM tuilant par-dessus les utilitaires freedesktop » est la **configuration
  retenue**, pas un artefact de test — ne pas présenter cette dépendance comme un biais.
  Ce qui reste utile à en tirer pour les prochaines distros : sur une distro qui ne fournit
  pas ces utilitaires aussi facilement, le coût d'installation sera à noter comme n'importe
  quelle autre friction.
- **`bin/snapshot.sh` écrasait la baseline — corrigé le 2026-09-03.** Il écrivait sans
  condition dans `baseline/`, alors que ce dossier est la photo figée qui sert de
  référence. Le point ouvert « snapshot à relancer » invitait donc à détruire la
  référence. Désormais : `baseline/` est écrite **une seule fois** et le script refuse de
  l'écraser ; les captures suivantes vont dans `etats/<AAAA-MM-JJ>/`, et le script affiche
  l'écart de paquets avec la baseline. Première capture datée : `etats/2026-09-03/`,
  19 paquets au-delà du protocole.
  **Étendu au poste de référence le 2026-09-07.** Le script ne savait écrire que dans
  `journal/<itération>/`, et le poste **n'est pas une itération** : la case « première
  capture d'état de ce poste » de la procédure était donc infaisable. L'option `--poste`
  écrit dans `installation/etats/<date>/` et **n'écrit jamais de baseline** — une baseline
  y mesurerait l'image ISO, pas la distribution. L'écart affiché est celui avec la
  **capture précédente** : sur ce poste la question n'est pas « qu'ai-je ajouté à la
  distro » mais « qu'ai-je changé depuis la dernière fois ». Trois mesures ajoutées à
  `system.md` au passage, absentes et structurantes ici : version du compositeur, nombre de
  volumes LUKS, état de Secure Boot et du TPM2. Première capture : `installation/etats/2026-09-07/`.

- **Le dépôt a pris trois jours de retard sur la machine, et c'est le mode de défaillance
  principal à surveiller.** L'audit complet du 2026-09-07 a trouvé **neuf** cases faites
  non notées, **cinq** affirmations devenues fausses et **trois** configurations réelles
  n'appartenant à aucune des trois destinations. Aucune ne vient d'une erreur de
  raisonnement : toutes viennent d'un écrit qui n'a pas suivi un geste. La parade n'est pas
  plus de rigueur au moment du geste — ça a été tenté et ça n'a pas tenu trois jours —
  c'est une **confrontation périodique du dépôt à la machine**, du type de celle du
  2026-09-07. Compte rendu dans `installation/journal.md`.
- **ARRÊTÉ PAR DÉCISION, jusqu'à nouvel ordre — KeePassXC à la place de `gnome-keyring`
  comme fournisseur Secret Service.** Demandé par Julien le 2026-09-03, **instruit et testé
  le 2026-09-04**, **arrêté par Julien** : `gnome-keyring` est le fournisseur **retenu** du
  poste. Ce n'est ni un oubli, ni une tâche en retard — **ne pas relancer le sujet** sans
  qu'il le rouvre. Tout ce qui suit est conservé comme cadrage, au cas où il le rouvre ;
  rien là-dedans n'est une action à mener.

  > **FAISABILITÉ PROUVÉE le 2026-09-04** — la chaîne entrée KeePassXC → FdoSecrets →
  > `libsecret` → `gvfsd` → montage SMB fonctionne, `gnome-keyring` alors écarté de la
  > machine. **Compte rendu détaillé, attributs exacts et pièges : entrée de journal du
  > 2026-09-04.** La discussion ci-dessous garde sa valeur de cadrage, mais elle n'est plus
  > l'état de l'art — le journal l'est.
  >
  > **ÉTAT RÉEL MESURÉ LE 2026-09-09.** Cette note affirmait « `gnome-keyring` absent de la
  > machine » — **c'était vrai le 2026-09-04 et c'est faux depuis.** `gnome-keyring-50.0`
  > est installé, deux processus tournent : celui de PAM (`--daemonize --login`) **détient**
  > `org.freedesktop.secrets`, collection `login` **déverrouillée** (`Locked → false`) ;
  > l'autre est l'implémentation du portail Secret, activée par D-Bus. Côté KeePassXC :
  > aucun `~/.config/keepassxc/keepassxc.ini`, `FdoSecrets` jamais activé, processus
  > absent. **Ce n'est pas un retard, c'est l'état voulu** — voir le titre.
  >
  > **La mesure du 2026-09-09 avait d'abord été écrite comme une dérive** (« la bascule
  > n'a jamais été faite »), avant que Julien ne rappelle que c'est une décision. Le dépôt
  > portait toute la trace du *travail* KeePassXC et **aucune trace de son arrêt** : la
  > seule lecture possible était « en cours et en retard ». **Un état non écrit se lit
  > comme un oubli, jamais comme un choix**, et aucune mesure ne peut faire la différence
  > — la machine ne porte pas l'intention. Même famille que les trois points Sway « clos
  > sans verdict ». Compte rendu : entrée de journal du 2026-09-09.
  >
  > **Un point technique subsiste, et lui n'est pas une décision :** `gnome-keyring` est
  > arrivé en **`reason=Weak Dependency`** (même piège que `uwsm` — dans aucune liste qu'on
  > lit). Un fournisseur **retenu** qui ne tient qu'à une dépendance faible peut disparaître
  > à un `dnf autoremove` ou à un changement amont. À rendre explicite
  > (`sudo dnf install gnome-keyring`) et à inscrire dans `installation/procedure.md`,
  > sinon une réinstallation ne le remettra pas.
  >
  > Noter aussi que le trousseau contient une entrée `Noctalia encrypted storage key` :
  > **Noctalia dépend lui aussi du Secret Service.** Sans effet ici, à ressortir seulement
  > si le sujet est rouvert.

  **Ce dont il s'agit, et ce dont il ne s'agit PAS.** Il s'agit de savoir *quel composant
  implémente l'API D-Bus `org.freedesktop.secrets`* pour le bureau. Ce n'est **pas** une
  réouverture du sujet « gestion et sauvegarde des secrets », qui reste hors périmètre
  (voir plus haut) : on ne parle ni d'audit de la clé SSH, ni de passphrase, ni de
  stratégie de sauvegarde de la base `.kdbx`.

  **L'état actuel, vérifié le 2026-09-03 :**
  - `org.freedesktop.secrets` est détenu par `gnome-keyring-daemon` (composant `secrets`).
    **Correction du 2026-09-04 : les deux mécanismes de démarrage coexistent**, il y a deux
    processus. Le fichier `/usr/share/dbus-1/services/org.freedesktop.secrets.service` le
    rend activable à la demande, mais c'est **PAM** qui lance `--daemonize --login` avant
    l'ouverture de session, et **c'est ce processus-là qui détient le nom**. Dire
    « activable par D-Bus à la demande » tout court est faux en pratique : il n'y a pas de
    course à gagner, le nom est pris d'avance. Conséquence : le tuer ne suffit pas non plus
    à le faire rester mort, D-Bus le relance au premier client.
  - Ses clients connus ici : `gvfsd` pour le montage NAS, et le trousseau en général.
  - **KeePassXC sait le faire** : la construction Fedora de `keepassxc-2.7.12` contient
    bien l'implémentation `FdoSecrets` (symboles `FdoSecrets::Service`, `::Collection`,
    `::Session` dans le binaire). L'option n'est pas activée aujourd'hui.
  - **Mais KeePassXC ne livre aucun fichier de service D-Bus.** Il ne peut donc pas être
    activé à la demande : il doit **déjà tourner et être déverrouillé** pour répondre.

  **Les questions à instruire, sans y répondre d'avance :**
  - Deux fournisseurs ne peuvent pas détenir `org.freedesktop.secrets` en même temps.
    Comment se fait la bascule, et que devient `gnome-keyring` ?
  - **Le problème d'ordonnancement** : `gvfsd` monte le NAS au login, KeePassXC doit être
    lancé et déverrouillé avant. Même famille que « un montage système ne peut pas
    interroger un trousseau de session » — vérifier que les deux sont **éveillés au même
    moment** avant de chercher à les brancher.
  - Que devient le déverrouillage PAM, qui n'existe pas côté KeePassXC ?
  - Qu'est-ce qu'on y gagne réellement ? Un seul magasin au lieu de deux, et un secret qui
    suit la base `.kdbx` déjà sauvegardée — à confronter au coût ci-dessus.
  - Effet sur la note « Cible pour l'installation finale » de `poste/`, qui liste
    aujourd'hui `gnome-keyring` comme **gardé**.

  **Recherche du 2026-09-03 — à lire avant d'en rediscuter.**

  *Comment ça marcherait.* Le greffon **FdoSecrets** enregistre KeePassXC sur D-Bus comme
  serveur Secret Service (spécification Secret Storage 0.2). On choisit **quelle base et
  quel groupe** sont exposés, avec notification et confirmation possibles à chaque lecture
  — plus fin que `gnome-keyring`, qui sert tout, en silence.

  *Trois contraintes dures, confirmées par plusieurs sources.*
  1. **KeePassXC doit tourner** — pas d'activation D-Bus, contrairement à `gnome-keyring`.
  2. **La base doit être déverrouillée** : base verrouillée = collection vide.
  3. **Si KeePassXC n'est pas déjà lancé quand une application demande un secret,
     `gnome-keyring` démarre et prend la main.** Ce n'est pas théorique, c'est le mode
     d'échec le plus rapporté.

  *Frictions rapportées.* Masquer `gnome-keyring`
  (`systemctl --user mask gnome-keyring-daemon.service`) « ne fonctionne pas complètement
  dans tous les cas ». KeePassXC exige de déverrouiller **toutes** les bases ouvertes avant
  de servir celle qui est exposée. Chromium stocke une clé « Safe Storage » propre à chaque
  machine, problématique si la base est synchronisée — **ça nous concerne depuis le passage
  à Chromium**. Et une demande upstream reste **ouverte** pour que KeePassXC soit utilisable
  comme fournisseur par défaut d'une distribution : ce n'est pas une configuration supportée.

  **Le déverrouillage automatique — c'est faisable, et la machine a le matériel.**

  Trois voies, très inégales :
  - **Fichier clé lisible par le système** : marche (`--keyfile`), mais c'est un secret en
    clair sur disque. **Contraire à une position déjà tenue par Julien** (refus du fichier
    0600, préférence trousseau ou TPM), et particulièrement mal placé sur un SSD externe
    non chiffré qui se débranche.
  - **[`keepassxc-unlock`](https://github.com/sumwale/keepassxc-unlock)** : chiffre le mot
    de passe avec le schéma d'identifiants de systemd (AES256-GCM + SHA256), **scellé par
    une clé système locale et une clé TPM2**. Un service systemd **appartenant à root**
    déverrouille en surveillant les événements de session sur le bus système, **au login et
    au déverrouillage d'écran**, après avoir vérifié l'**empreinte SHA512 du binaire
    `keepassxc`**. Binaires statiques, annoncé pour toutes les distributions.
  - Script + `secret-tool` + `dbus-send` : **circulaire** si KeePassXC est lui-même le
    fournisseur Secret Service.

  *Matériel vérifié le 2026-09-03 :* **TPM 2.0 présent** (`/dev/tpm0`, version majeure 2),
  `systemd-analyze has-tpm2` → `yes` avec firmware, pilote, sous-système et bibliothèques ;
  `tpm2-tools` et `clevis` **déjà installés**. Rien à acheter.

  *Avertissement à ne pas manquer :* avec TPM2 les clés sont **liées à la machine**. Une
  sauvegarde système complète **ne permettra pas** de retrouver le mot de passe stocké si
  l'appareil meurt. La base `.kdbx` reste intacte — c'est le secret de déverrouillage qui
  est scellé au matériel. Sur un boîtier USB, à peser.

  **LE POINT QUI DEVRAIT STRUCTURER LA DISCUSSION.** Dès lors que la base se déverrouille
  automatiquement à l'ouverture de session, **le modèle de sécurité de KeePassXC devient
  celui de `gnome-keyring`** : les secrets sont disponibles dès que la session est ouverte,
  sans rien taper. Le gain n'est alors plus la sécurité, c'est **l'unification** (un seul
  magasin, qui suit la base déjà sauvegardée) et **la portabilité** (même outil partout, là
  où `gnome-keyring` suppose la plomberie GNOME). Ce sont de bons arguments — mais ce ne
  sont pas ceux qu'on croit avancer en parlant de KeePassXC.

  *Reste à tester, pas à déduire :* l'ordonnancement au login. Le service root déverrouille
  après authentification, l'unité `nas-infoadmin.service` monte le NAS au même moment. Qui
  gagne ? Même famille que « vérifier que deux composants sont éveillés au même moment ».

  *Lien avec un autre point ouvert :* ce TPM pourrait aussi déverrouiller **LUKS** au
  démarrage (`clevis` est installé, `systemd-cryptenroll` est disponible). Les deux points
  ouverts convergent sur le même matériel, et tous deux **se décident à l'installation**.

- **Disque non chiffré — SOLDÉ le 2026-09-04.** Le poste de référence est installé avec
  **LUKS** sur `nvme0n1p3`. Ce qui reste n'est plus une décision mais une tâche :
  enrôler le **TPM2** (`systemd-cryptenroll`) pour ne pas saisir la phrase de passe à
  chaque démarrage — matériel vérifié, `/dev/tpm0` présent et `has-tpm2` → `yes`.
  Le lab sur SSD USB reste non chiffré ; ça se décide itération par itération.

- **`/boot` séparé : décision inversée le 2026-09-04, sur un démenti — et CONFIRMÉE par la
  mesure le 2026-09-07.** La note du même jour exigeait `/boot` *dans* le sous-volume Btrfs
  pour `grub-btrfs`. La disposition Fedora par défaut (`/boot` ext4 séparé) est finalement
  **conservée sciemment**, parce que `grub-btrfs` gère le cas et qu'un `/boot` chiffré
  interdirait le déverrouillage TPM — GRUB ne sait pas déchiffrer par TPM. Raisonnement
  complet dans `installation/README.md`.
  **Vérifié le 2026-09-07** : `grub-btrfs` installé détecte le `/boot` séparé sans qu'on
  touche à `GRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION`, et génère des entrées qui
  prennent le noyau sur la partition `/boot` vivante (`search --fs-uuid` sur l'ext4, chemin
  `/vmlinuz-…` relatif à cette partition). 11 entrées, sourcées par le `grub.cfg` principal.
  La décision reprise ne reposait donc pas sur une seconde déduction : elle est mesurée.
