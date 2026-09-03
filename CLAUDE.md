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

Dell Pro Slim QCS1250 — Intel Core i5-14500 (20 threads) — 16 Go RAM — SSD 233 Go.
**Le système tourne sur un SSD EXTERNE** (boîtier USB 3.2, pont générique — `lsblk`
donne `TRAN=usb`, modèle « Generic PCIE »). C'est délibéré et ça change la lecture de
toute la méthode :

- **Le disque interne porte toujours un Windows opérationnel**, intact. En cas d'urgence
  — quelque chose manque sous Fedora et il faut travailler tout de suite — il suffit de
  redémarrer dessus. **Il y a donc bien un poste de secours**, contrairement à ce que ce
  fichier a affirmé jusqu'au 2026-09-03.
- Une bascule de distro est un formatage du disque **externe** : elle ne touche pas au
  secours. La méthode bare-metal est nettement moins risquée qu'elle n'en a l'air.
- À terme, le Windows interne sera formaté pour une installation propre. **Ce jour-là le
  filet disparaît**, et les conclusions ci-dessus tombent avec lui.
- Contrepartie à surveiller : un boîtier USB ajoute des modes de panne qu'un disque
  interne n'a pas (débranchement, câble, puce du pont). Et un disque qui se débranche
  pèse plus lourd qu'un disque vissé dans le débat sur le chiffrement.

## Structure

| Chemin | Rôle |
|---|---|
| `journal/` | Une itération = une distro. Fiche + entrées datées + `baseline/` capturée. |
| `poste/` | Inventaire **vivant** des outils de travail, indépendant de la distro. |
| `dotfiles/` | Paquets **GNU Stow**. `stow -v -t ~ bash git sway nas desktop` depuis `dotfiles/`. |
| `bin/snapshot.sh` | Capture l'état système. Agnostique du gestionnaire de paquets. |

Itération en cours : `journal/01-fedora-44-workstation/` (Fedora 44, GNOME 50.4, Wayland).

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
- **Disque non chiffré — à trancher avant l'itération 02.** Pas de LUKS, pas de
  `/etc/crypttab`. Le trousseau `gnome-keyring` protège les mots de passe contre les
  autres comptes de la machine, pas contre un démarrage sur clé USB ni contre le vol du
  SSD. Ce poste porte des accès au NAS de l'employeur. **Le chiffrement se décide à
  l'installation**, donc c'est une case à cocher à la prochaine bascule, pas un
  rattrapage. À décider, pas à débattre indéfiniment.
