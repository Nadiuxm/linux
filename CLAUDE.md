# Contexte du projet — à lire avant toute intervention

Ce fichier est la mémoire durable du lab. Il est versionné : il survit aux
réinstallations, contrairement à `~/.claude/`. Le tenir à jour fait partie du travail.

## Ce qu'est ce dépôt

Un **lab d'évaluation de distributions Linux**, pas un projet logiciel. Objectif :
choisir la distribution et l'environnement de travail pour une alternance en
**mastère SRC** (Systèmes, Réseaux et Cloud computing), sur des notes prises au fil
de l'usage réel plutôt que sur une impression.

Utilisateur : Julien Zielona (`Nadiuxm` sur GitHub), **début d'alternance**.
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

## Hors périmètre — ne pas relancer le sujet

**La gestion et la sauvegarde des secrets** (clé SSH du dépôt, base KeePassXC) est
prise en charge par Julien, en dehors de ce dépôt et par ses propres moyens.
Ne pas auditer la clé, ne pas proposer de passphrase, de rotation ni de stratégie
de sauvegarde : le sujet a été explicitement clos le 2026-08-28.

La sauvegarde des secrets reste listée à l'étape 5 de la procédure de bascule
(`journal/README.md`) comme point de contrôle avant un wipe — c'est une case à
cocher, pas une invitation à rouvrir le débat.

## Points ouverts

- **`SSH_AUTH_SOCK` non persistant sous Sway.** `gcr-ssh-agent.socket` est activé
  (donc relancé au démarrage), mais la variable n'est posée que dans le gestionnaire
  systemd utilisateur en cours — rien sur le disque, elle disparaîtra à la
  déconnexion. À figer dans `~/.config/environment.d/`, versionnable via Stow.
  Cause de fond : l'agent SSH de GNOME vient d'un autostart XDG marqué
  `OnlyShowIn=GNOME;Unity;MATE;` que Sway ne traite pas.
  **Piste révisée (2026-09-01)** : `sway-session.target` *et* `graphical-session.target`
  sont actives — Fedora fournit une vraie intégration systemd pour Sway. Une unité
  `systemd --user` accrochée à `graphical-session.target` vaut donc **sous GNOME comme
  sous Sway**, avec un seul fichier. Probablement meilleur que `environment.d/`. Modèle
  déjà en place : le paquet Stow `nas`.
- **Friction agent SSH pas encore au journal** — première vraie friction de l'axe
  « bureaux », elle a bloqué un `git push`. À écrire.
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
