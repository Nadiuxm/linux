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
| **SSD USB** — boîtier générique « Generic PCIE », 233 Go (`TRAN=usb`) | **le lab** — formaté à volonté | itération 01 (Fedora 44 Workstation), intacte |

Le Windows interne n'existe plus : le NVMe est entièrement Fedora.

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

| Chemin | Rôle |
|---|---|
| `journal/` | Une itération = une distro. Fiche + entrées datées + `baseline/` capturée. |
| `poste/` | Inventaire **vivant** des outils de travail, indépendant de la distro. |
| `installation/` | **Le poste de référence** : cadrage, procédure rejouable, journal de construction. |
| `dotfiles/` | Paquets **GNU Stow**. `stow -v -t ~ bash git sway nas desktop foot` depuis `dotfiles/`. |
| `bin/snapshot.sh` | Capture l'état système. Agnostique du gestionnaire de paquets. |

Itération 01 : `journal/01-fedora-44-workstation/` (Fedora 44, GNOME 50.4, Wayland) —
sur le SSD USB, plus le poste de travail.

**Troisième axe, ouvert le 2026-09-04 : le poste de référence** (`installation/`). Ce
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
Deux fiches à ce jour : **VM Windows d'administration** et **Mattermost**.

**Second axe ouvert le 2026-09-01 : environnements de bureau.** Sway installé
(transaction 8) en plus de GNOME, hors protocole de baseline mais après sa capture,
donc sans la polluer. GNOME reste la session par défaut. Cadrage détaillé dans le
`README.md` de l'itération 01. Si l'axe grossit (KDE, Xfce), lui donner son dossier.

**Noctalia depuis le 2026-09-01** (transaction 10) : shell Wayland complet — barre,
lanceur, notifications, fond d'écran, OSD, verrouillage, menu de session, 112 commandes
IPC (`noctalia msg --help`). En version **beta**, risque accepté : ce n'est pas le
compositeur, s'il tombe Sway continue de tuiler. Le grief contre GNOME étant esthétique
et non technique, c'est bien l'interface qui est évaluée ici.

**Partage assumé depuis le 2026-09-01 (fin de journée) : Sway ne fait que du TUILAGE,
Noctalia fait tout le shell.** La config Sway n'inclut donc plus `/etc/sway/config` —
elle est **possédée**, pas héritée (voir les pièges). Conséquence : une mise à jour du
paquet `sway` ne se propage plus dans le fichier versionné.
Attention à ne pas mal lire ce partage : **les raccourcis restent dans Sway** et
appellent `noctalia msg …`. Noctalia n'a aucun système de raccourcis et ne peut pas en
avoir — sous Wayland, seul le compositeur voit le clavier.

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

## Convention du journal

Noter **le problème et ce qu'il apprend**, pas seulement la solution.
« J'ai perdu 40 min sur le pilote NVIDIA » est une donnée de décision ;
« j'ai installé akmod-nvidia » n'en est pas une. Une entrée est datée et écrite le
jour même, tant que le détail est frais.

## Pièges déjà rencontrés — ne pas refaire l'erreur

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
- **Un fichier de conf dans `/etc` n'est pas lu par tout le monde.** `00-keyboard.conf`
  dit `fr/azerty` mais n'est lu que par **Xorg** ; GNOME lit `gsettings` ; Sway et les
  compositeurs wlroots ne lisent ni l'un ni l'autre et retombent sur **US QWERTY**.
  Avant de conclure qu'un réglage est « fait au niveau système », vérifier *qui* le lit.
  À refaire sur chaque distro où un compositeur Wayland est testé.
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

## Hors périmètre — ne pas relancer le sujet

**La gestion et la sauvegarde des secrets** (clé SSH du dépôt, base KeePassXC) est
prise en charge par Julien, en dehors de ce dépôt et par ses propres moyens.
Ne pas auditer la clé, ne pas proposer de passphrase, de rotation ni de stratégie
de sauvegarde : le sujet a été explicitement clos le 2026-08-28.

La sauvegarde des secrets reste listée à l'étape 5 de la procédure de bascule
(`journal/README.md`) comme point de contrôle avant un wipe — c'est une case à
cocher, pas une invitation à rouvrir le débat.

## Points ouverts

- **L'axe « bureaux » porte sur l'interface, pas sur la pile logicielle.** Ce que Julien
  reproche à GNOME est esthétique et ergonomique ; les utilitaires GNOME
  (`gnome-keyring`, `gvfs`, Nautilus, l'agent SSH) ne posent aucun problème et sont
  assumés. « Sway par-dessus les utilitaires GNOME » est donc la **configuration cible**,
  pas un artefact de test — ne pas présenter cette dépendance comme un biais.
  Ce qui reste utile à en tirer : sur une distro qui ne fournit pas ces utilitaires aussi
  facilement, le coût d'installation sera à noter comme n'importe quelle autre friction.
- **Un `swaybg` résiduel après la bascule — à confirmer d'un coup d'œil.** La config ne
  contient plus aucune directive `bg`, mais après `swaymsg reload` un processus `swaybg`
  reste lancé par Sway, cette fois **sans aucun argument** (ni `-i` ni `-c`) — l'ancien
  portait `-o * -c #000000`. Reste à voir s'il peint quoi que ce soit : si le fond
  d'écran Noctalia est bien visible, c'est un processus inerte et le sujet est clos ;
  s'il y a du noir, il faudra comprendre pourquoi Sway le lance sans configuration.
  Se règle en regardant le bureau, pas en lisant du code.
- **Ressenti Sway à froid** : noter dans quelques jours si l'usage quotidien est plus
  rapide qu'avec GNOME, ou s'il y a repli vers GNOME dès qu'il y a urgence. C'est ça
  qui tranchera l'axe, pas la liste des raccourcis.
- **`waybar` est installée mais inutilisée** (tirée par le groupe `swaywm`). Depuis que
  Noctalia fournit la barre et que le bloc `bar { }` n'est plus hérité, elle n'a plus de
  rôle. À laisser dormir, ou à retirer si la baseline doit rester lisible.
- **`bin/snapshot.sh` écrasait la baseline — corrigé le 2026-09-03.** Il écrivait sans
  condition dans `baseline/`, alors que ce dossier est la photo figée qui sert de
  référence. Le point ouvert « snapshot à relancer » invitait donc à détruire la
  référence. Désormais : `baseline/` est écrite **une seule fois** et le script refuse de
  l'écraser ; les captures suivantes vont dans `etats/<AAAA-MM-JJ>/`, et le script affiche
  l'écart de paquets avec la baseline. Première capture datée : `etats/2026-09-03/`,
  19 paquets au-delà du protocole.
- **KeePassXC à la place de `gnome-keyring` comme fournisseur Secret Service.**
  Demandé par Julien le 2026-09-03, **instruit et testé le 2026-09-04**.

  > **FAISABILITÉ PROUVÉE le 2026-09-04** — la chaîne entrée KeePassXC → FdoSecrets →
  > `libsecret` → `gvfsd` → montage SMB fonctionne, `gnome-keyring` absent de la machine.
  > **Compte rendu détaillé, attributs exacts et pièges : entrée de journal du 2026-09-04.**
  > Ce qui reste : l'ordonnancement au login, non testé. La discussion ci-dessous garde sa
  > valeur de cadrage, mais elle n'est plus l'état de l'art — le journal l'est.

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

- **`/boot` séparé : décision inversée le 2026-09-04, sur un démenti.** La note du même
  jour exigeait `/boot` *dans* le sous-volume Btrfs pour `grub-btrfs`. La disposition
  Fedora par défaut (`/boot` ext4 séparé) est finalement **conservée sciemment**, parce
  que `grub-btrfs` gère le cas et qu'un `/boot` chiffré interdirait le déverrouillage
  TPM — GRUB ne sait pas déchiffrer par TPM. Raisonnement complet dans
  `installation/README.md`.
