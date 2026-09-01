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
**Machine unique** : aucun poste de secours pendant une réinstallation.

## Structure

| Chemin | Rôle |
|---|---|
| `journal/` | Une itération = une distro. Fiche + entrées datées + `baseline/` capturée. |
| `dotfiles/` | Paquets **GNU Stow**. `stow -v -t ~ bash git sway nas` depuis `dotfiles/`. |
| `bin/snapshot.sh` | Capture l'état système. Agnostique du gestionnaire de paquets. |

Itération en cours : `journal/01-fedora-44-workstation/` (Fedora 44, GNOME 50.4, Wayland).

**Second axe ouvert le 2026-09-01 : environnements de bureau.** Sway installé
(transaction 8) en plus de GNOME, hors protocole de baseline mais après sa capture,
donc sans la polluer. GNOME reste la session par défaut. Cadrage détaillé dans le
`README.md` de l'itération 01. Si l'axe grossit (KDE, Xfce), lui donner son dossier.

**Noctalia depuis le 2026-09-01** (transaction 10) : shell Wayland complet qui
remplace `swaybar` et `wmenu-run` sous Sway — barre, lanceur (`Super+D`),
notifications, verrouillage, 112 commandes IPC (`noctalia msg --help`). En
version **beta**, risque accepté : ce n'est pas le compositeur, s'il tombe Sway
continue. Configuré dans le paquet Stow `sway`. Le grief contre GNOME étant
esthétique et non technique, c'est bien l'interface qui est évaluée ici.

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
  de `rpm -q`, qui change à chaque mise à jour.
- **Vérifier `git config user.email` avant le premier commit.** Corriger après un push
  demande de réécrire l'historique côté distant.
- **`~/.bashrc.d` est un lien vers le dépôt** (tree folding de Stow). Tout fichier
  déposé dedans sera versionné : jamais de token ni de secret là-dedans.
- **Un fichier de conf dans `/etc` n'est pas lu par tout le monde.** `00-keyboard.conf`
  dit `fr/azerty` mais n'est lu que par **Xorg** ; GNOME lit `gsettings` ; Sway et les
  compositeurs wlroots ne lisent ni l'un ni l'autre et retombent sur **US QWERTY**.
  Avant de conclure qu'un réglage est « fait au niveau système », vérifier *qui* le lit.
  À refaire sur chaque distro où un compositeur Wayland est testé.
- **`~/.config/sway/config` remplace `/etc/sway/config`, il ne le complète pas.** D'où
  le `include /etc/sway/config` en tête du fichier versionné. `/etc/sway/config.d/`,
  lui, est bien fusionné — mais appartient à root, donc non versionnable.
- **`dnf history` affiche l'heure en UTC**, le journal est en heure locale (UTC+2).
  Deux heures d'écart au moment de recouper une transaction avec une entrée datée.
- **`bindsym` lie un *symbole*, pas une touche — piège AZERTY.** `bindsym $mod+1`
  exige le symbole `1`, qui sur AZERTY demande déjà `Maj` : `$mod+Shift+1` devient
  inatteignable. Correctif `bindsym --to-code` (traduit en code de touche physique),
  avec `unbindsym` de l'ancienne — symbole et code sont deux objets distincts pour
  Sway. Vaut pour toute config de WM tuilant écrite pour QWERTY, sur toute distro.
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
  symptômes système.** Claude Code n'a ni `SSH_AUTH_SOCK` ni accès à `/proc/<pid>/environ`
  (bac à sable, et retrait délibéré de l'accès à l'agent SSH). Un `git fetch` qui échoue
  de son côté pendant qu'il marche dans le terminal ne prouve **rien** sur la machine.
  Toujours refaire la mesure dans un vrai terminal avant de conclure.

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
- **Les chiffres font l'inverse de ce qui est écrit — `--to-code` suspect.** Constaté le
  2026-09-01 : `Super+chiffre` ne fait rien, `Super+Maj+chiffre` va sur l'espace au lieu
  d'y envoyer la fenêtre. Hypothèse à vérifier : `--to-code` traduit le keysym `1` en
  keycode, mais `1` est au **niveau 2** de `AE01` en AZERTY (il exige Maj) et Sway a pu
  garder ce Maj dans la liaison — `$mod+1` deviendrait `$mod+Shift+AE01`, et
  `$mod+Shift+1` demanderait deux Maj, donc inatteignable. Si c'est ça, le correctif du
  bloc 2 a **déplacé** le bug au lieu de le résoudre, et il faut passer à `bindcode` avec
  les codes physiques (`10` à `19`). Non bloquant, mais à trancher — et le journal est à
  corriger si l'hypothèse se confirme.
- **Scratchpad orphelin.** `$mod+minus` / `$mod+Shift+minus` ont été retirés (ils
  entraient en collision avec l'espace 6 en AZERTY), le scratchpad n'a donc plus de
  raccourci. À réattribuer — `²` (`$mod+twosuperior`) est libre et bien placé — ou à
  abandonner explicitement. À traiter avec le point ci-dessus, même zone de config.
- **Ressenti Sway à froid** : noter dans quelques jours si l'usage quotidien est plus
  rapide qu'avec GNOME, ou s'il y a repli vers GNOME dès qu'il y a urgence. C'est ça
  qui tranchera l'axe, pas la liste des raccourcis.
- **`waybar` laissée par défaut** — prochain fichier naturel du paquet Stow `sway`.
- **Snapshot à relancer** après quelques jours d'usage de Sway.
- **Disque non chiffré — à trancher avant l'itération 02.** Pas de LUKS, pas de
  `/etc/crypttab`. Le trousseau `gnome-keyring` protège les mots de passe contre les
  autres comptes de la machine, pas contre un démarrage sur clé USB ni contre le vol du
  SSD. Ce poste porte des accès au NAS de l'employeur. **Le chiffrement se décide à
  l'installation**, donc c'est une case à cocher à la prochaine bascule, pas un
  rattrapage. À décider, pas à débattre indéfiniment.
