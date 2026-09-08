# Journal — poste de référence

Entrées datées, les plus récentes en haut.
Noter **le problème et ce qu'il apprend**, pas seulement la solution.

Ce journal est celui de la **construction du poste de travail**, distinct de
`journal/<itération>/journal.md` qui reste celui de l'évaluation des distributions.

---

## 2026-09-08 — Les six paquets Stow posés, et un lien manuel qui bloquait tout

Le dépôt annonçait « 4 sur 6 » depuis le 2026-09-07, `bash` et `git` refusés pour conflit
avec les fichiers de l'ISO. C'était juste, et ça a duré quatre jours.

**Ce qui a rendu le diagnostic confus avant de le régler.** Le symptôme rapporté était
« rien du dépôt dotfiles n'est déployé, `~/.config/hypr` est un fichier réel ». La mesure
dit autre chose : `~/.config/hypr` est un **dossier** réel — Hyprland y écrit ses propres
fichiers — et `hyprland.lua` dedans est bien un **lien** vers le dépôt. C'est le
comportement normal de Stow quand le dossier cible existe déjà : il descend et lie la
feuille. Preuve à l'usage le même jour : éditer `dotfiles/hypr/…/hyprland.lua` a changé les
liaisons du compositeur vivant après un `hyprctl reload`.

> **Un paquet Stow peut être posé sans qu'aucun dossier ne soit un lien.** Chercher un lien
> au niveau du dossier fait conclure « non déployé » alors que la feuille est liée. Se
> mesure cible par cible (`readlink`), pas par l'allure de `~/.config`.

**Le vrai blocage, et il n'était pas dans les quatre conflits attendus.** `stow -n -v bash
git` a répondu, en plus des quatre `cannot stow … over existing target` :

```
* existing target is not owned by stow: .bashrc.d
All operations aborted.
```

`~/.bashrc.d` avait été lié à la main vers le dépôt, en **absolu**. Stow ne reconnaît comme
siens que les liens **relatifs** qu'il crée : un lien pourtant correct, qui chargeait bien
les fragments, faisait **abandonner les deux paquets entiers**. Remède : retirer le lien
(pas sa cible) et laisser Stow le refaire.

**Et les fichiers écartés n'étaient pas « ceux de la distro ».** Comparés avant de bouger :
`.bashrc` et `.bash_profile` étaient bien le squelette de l'ISO (16 janvier), mais
`.gitconfig` et `.config/git/ignore` étaient des versions **du 2026-09-04**, soit
antérieures à celles du dépôt (enrichies le 2026-09-07). Le dépôt était surensemble dans
les quatre cas, `[user] name/email` compris — sans quoi le piège « vérifier
`git config user.email` avant le premier commit » se rejouait. Écartés dans
`~/sauvegarde-dotfiles-2026-09-08/`, hors du dépôt.

Vérifié dans un **bash neuf**, pas seulement par `readlink` : `~/.local/bin` toujours dans
le `PATH` — sans quoi `claude` lui-même disparaissait —, `HISTTIMEFORMAT` et `histappend`
actifs, alias `ll` chargé, `PROMPT_COMMAND` = `history -a; printf …` (le titre de terminal
de la distro a survécu), `git config` répond `main`.

### Ce qui reste

- **`~/.bashrc.d/20-historique.sh` est devenu redondant, et son en-tête le dit.** Il a été
  écrit *parce que* le `.bashrc` du dépôt n'était pas déployé ; maintenant qu'il l'est, les
  deux posent les mêmes valeurs et seule la ligne `history -a` du fragment est unique. À
  réduire à cette ligne, ou à remonter dans le `.bashrc` en supprimant le fragment. Non
  tranché — mais à trancher, sinon c'est une duplication qui vieillira mal.
- La sauvegarde `~/sauvegarde-dotfiles-2026-09-08/` n'a plus d'usage une fois le
  déploiement éprouvé quelques jours.

---

## 2026-09-08 — Captures d'écran : le paquet qui manquait n'existait pas, et deux dépendances invisibles

Point de départ : « il n'y a pas de paquet pour faire une capture d'écran sur ce poste ».
La moitié de la phrase était vraie — ni `grim`, ni `slurp`, ni `swappy`, ni `flameshot` ne
sont installés — et la conclusion était fausse.

**Noctalia capture lui-même.** Le binaire parle `zwlr_screencopy_manager_v1` (symboles dans
`/usr/bin/noctalia`), les raccourcis existaient depuis le 2026-09-04 dans `hyprland.lua`, et
trois PNG datés du 2026-09-04 dormaient dans `~/Pictures`. La ligne
`hl.permission(".../grim", "screencopy", …)` de la config est restée **commentée** depuis le
premier jour : elle n'a jamais eu d'objet.

> **Une fonction absente n'est pas un paquet manquant.** Quand le shell intègre la
> fonction, la liste des paquets ne la montre pas — et chercher le paquet habituel fait
> conclure à l'inverse de la réalité. Même famille que « un paquet installé n'est pas un
> paquet utilisé », pris par l'autre bout.

### La touche Impr écran du K650 n'émet rien — mesuré, pas déduit

Le symptôme (« Noctalia ne reconnaît pas la touche ») désignait le compositeur. Trois
mesures l'ont innocenté :

- `hyprctl binds` donnait `key: Print`, `modmask: 0` / `1` — la forme **courte**, donc un
  bind correctement analysé (un bind inerte conserve la chaîne entière) ;
- `keycodes/evdev` : `<PRSC> = 107`, et `symbols/pc` : `key <PRSC> {[ Print, Sys_Req ],
  type="PC_ALT_LEVEL2"}`, **que `symbols/fr` ne surcharge pas** — sur AZERTY `Print` est au
  niveau 1, son niveau 2 s'atteint avec **Alt**. Le piège de la rangée des chiffres ne
  s'applique donc pas ici, contrairement au réflexe ;
- `sudo libinput debug-events --show-keycodes` sur les **15** périphériques : appui sur la
  touche à l'icône d'imprimante → **aucun événement**, sur aucune interface.

> **Pour séparer « le bind est faux » de « la touche n'existe pas », mesurer en amont du
> compositeur.** `libinput` lit l'evdev avant que Hyprland ne voie quoi que ce soit : une
> trace vide y prouve que le noyau n'a rien reçu, et clôt le débat sans toucher à la config.
> Écouter **tous** les périphériques (sans `--device`) évite en plus de deviner lequel.

Cause probable, et elle vaut pour tout le clavier : le récepteur **Bolt `046d:c548`** est
piloté par **`hid-generic`** (journal noyau : `hid-generic 0003:046D:C548.0002`), et `c548`
**n'est pas dans les alias de `hid_logitech_dj`**. Sans le pilote Logitech, les touches
programmables HID++ du K650 ne sont traduites par personne. Récupérable avec `solaar`
(1.1.20 dans les dépôts Fedora, non installé) — non fait, parce que non nécessaire.

> **Erreur commise en cours de route, et corrigée :** avoir présenté « le périphérique
> déclare `KEY_SYSRQ` dans son bitmap » comme la preuve que la touche existe. Un récepteur
> annonce un descripteur de clavier **générique**, indépendant de l'appareil apparié : ce
> bitmap ne dit rien du clavier physique. Même famille que « une commande locale rapporte un
> réglage, jamais un rôle ».

**Décision, prise plutôt que contournée :** les deux liaisons `Print` sont **retirées** de
`hyprland.lua` et remplacées par des combinaisons que le clavier émet réellement —
`SUPER + SHIFT + P` pour la région, `SUPER + CTRL + SHIFT + P` pour l'écran entier. Le
commentaire du fichier porte la mesure, pour qu'on ne réécrive pas `Print` dans six mois.
À noter au passage : un `SHIFT + P` **nu** aurait capté la lettre P majuscule dans toutes
les applications — sous Wayland un raccourci sans modificateur de bureau vole la touche.

### Le collage : ce n'était ni le terminal, ni Noctalia

Symptôme suivant : la capture ne se collait pas dans le terminal, et le soupçon portait sur
`kitty`. La copie, elle, avait bien lieu — mesurée par recoupement de tailles :

| Élément | Horodatage | Taille |
|---|---|---|
| `~/Pictures/screenshot_20260908_123746-region.png` | 12:37:46 | 115 033 o |
| `~/.local/state/noctalia/clipboard/entries/1788863866523-82.enc` | 12:37:46 | 115 087 o |

Même image, même seconde : `copy_to_clipboard = true` fonctionne, Noctalia a bien pris la
sélection. Le vrai mécanisme est ailleurs : **un terminal ne transporte jamais une image**,
`Ctrl+V` n'envoie que du texte. Claude Code intercepte donc la frappe et va lire la
sélection **lui-même**, en appelant `xclip` ou `wl-paste` — visible dans les chaînes de son
binaire :

```
xclip -selection clipboard -t TARGETS -o | grep -E "image/(png|jpeg|…)" || wl-paste -l | grep -E "image/(png|…)"
xclip … || wl-paste --type image/png > <fichier temporaire>
```

Aucun des deux n'était installé. `wl-clipboard-2.2.1` posé le 2026-09-08 à 12:43:56 — le
collage fonctionne depuis.

> **Un binaire installé hors gestionnaire de paquets n'a personne pour tirer ses
> dépendances, et l'échec est MUET.** Claude Code vit dans `~/.local/share/claude/versions/`,
> aucun RPM ne le décrit : sa dépendance à `wl-paste`/`xclip` n'apparaît dans aucune liste
> qu'on lit, et son absence ne produit ni erreur ni avertissement — juste un collage qui ne
> fait rien. Même famille que le piège SELinux sur `/usr/local` : ce qui est posé à la main
> n'a personne derrière lui.

### Ce qui reste

- **Annotation des captures — non tranché.** Pour un ticket, il manque de quoi entourer,
  flécher et surtout **flouter** un mot de passe ou un nom de client. `swappy` 1.5.1 est
  dans les dépôts Fedora et Noctalia prévoit le crochet (`pipe_to_command = true`,
  `pipe_command = "swappy -f -"`). `satty`, souvent recommandé, n'est **pas** packagé dans
  Fedora 44. À décider à l'usage.
- **Pas de mode « fenêtre »** : `screenshot-fullscreen` accepte `pick` et `all`, plus la
  région. Sur trois écrans, un raccourci `all` serait le complément logique.
- La touche du K650 reste morte. `solaar` la ressusciterait ; ça n'a d'intérêt que si le
  raccourci actuel déplaît à l'usage.

---

## 2026-09-08 — `procedure.md` découpé : un registre de constats n'est pas un mode opératoire

L'ancien `procedure.md` s'annonçait « la **séquence**, dans l'ordre, avec les versions
exactes ». C'était faux depuis un moment, et le mot juste est celui-ci : **c'était un
registre de constats.** On pouvait y vérifier le poste bien mieux qu'on ne pouvait le
construire.

### Le diagnostic ne vient pas d'une relecture

Il vient d'avoir **déroulé le fichier comme un mode opératoire**, sur papier, en
n'exécutant rien. Le résultat, sur 1 169 lignes très correctement mesurées :

| Ce qui manquait | Effet le jour de la réinstallation |
|---|---|
| `mesa-dri-drivers` | **Hyprland ne démarre pas du tout**, et le symptôme ne le désigne pas |
| réenregistrer le mot de passe SMB | `nas-infoadmin.service` échoue, le symptôme accuse le NAS |
| le bloc `nmcli` du pont | à aller chercher dans `poste/README.md` |
| `btrfs subvolume create` + `chattr +C` | idem, et l'ordre est irrattrapable |
| `snapper create-config` | les réglages étaient là, le geste non |
| `/etc/greetd/config.toml` | nulle part — toujours pas comblé, mais **marqué** |

**Aucune relecture n'aurait montré ça.** Un fichier qui contient la mesure d'une étape
*a l'air* de contenir l'étape. C'est la leçon de méthode de la journée, et elle est
générale : **écrire un constat n'est pas écrire un geste**, et les deux se ressemblent
assez pour qu'on ne voie pas la différence dans son propre texte.

### Le découpage retenu, et pourquoi les noms sont dans ce sens

| Fichier | Contenu | Lignes |
|---|---|---|
| `procedure.md` | **les gestes**, à l'impératif, seule source de ce qu'on tape | ~700 |
| `mesures.md` | les constats, versions, tableaux relevés, ce qu'ils apprennent | ~1 160 |

**`procedure.md` garde son nom parce que c'est lui que la règle des trois destinations
désigne.** Mettre la séquence dans un fichier neuf et laisser les constats sous le nom
« procedure » aurait fait pointer la règle vers le mauvais fichier — et une règle qui
désigne le mauvais endroit est pire qu'une règle absente.

**Les numéros de section se correspondent** (§7 ici documente §7 là-bas). C'est la seule
chose à maintenir entre les deux fichiers, et c'est volontairement la plus bête possible.

### Le test que `procedure.md` doit passer

> *Un lecteur qui ne lit que les blocs de code obtient-il la machine ?*

Il est écrit en tête du fichier. Trois conventions en découlent :
`→` pour la vérification qui dit que l'étape a marché, `⚠ ORDRE` pour une étape dont la
position est contrainte **avec ce qui casse si on l'inverse**, et `✎ INVENTÉ` pour un geste
reconstitué et non attesté — il y en a trois, dont le fuseau horaire et les
`snapper create-config`. **Marquer ce qu'on a deviné vaut mieux que de le lisser.**

### Une étape 0 qui n'existait pas

Les prérequis externes — ISO, phrase de passe, **clé SSH du dépôt**, RPM RustDesk à
régénérer, sauvegarde de la VM, mot de passe SMB, renseignements réseau de l'employeur —
sont maintenant une étape, en tête. Ils étaient dispersés ou implicites, et le blocage se
découvrait sinon **à l'étape 2, machine déjà formatée** : sans la clé `gitlinux`, pas de
dépôt, donc pas de procédure. La dépendance la plus grave du dépôt était invisible dans le
dépôt.

### Trois duplications supprimées au passage, et ce n'est pas du ménage cosmétique

Le `greeter.toml`, le `tmpfiles.d` du greeter et le bloc `~/.ssh/config` existaient
**en double** après le découpage. Deux copies d'un fichier de configuration dans deux
documents, c'est **deux vérités possibles** le jour où l'une est modifiée — exactement ce
qui a justifié de supprimer le script mort la veille. Le contenu vit dans `procedure.md`,
`mesures.md` garde ce qu'il faut **savoir** à son sujet.

### Les citations de ligne ont été converties en citations de section

Neuf `procedure.md:NNN-NNN` écrits la veille pointaient, après découpage, sur du vide.
Ils sont devenus `mesures.md §N`. **Une citation par numéro de ligne dans un document
vivant est fausse dès la prochaine édition** — je les avais introduites moi-même la veille,
et elles n'ont pas tenu vingt-quatre heures. Le dépôt cite par section ailleurs
(`§8quater`, `§6`) : c'était la bonne pratique, elle est maintenant la seule.

### Ce que ce découpage ne règle pas

Il ne comble pas les trous, il les **rend visibles** : `procedure.md` porte désormais sept
cases ouvertes en fin de fichier, dont l'enrôlement TPM2 et le `config.toml` du greeter.
C'est le progrès réel — une liste de restes qui décrit vraiment les restes, au lieu
d'orienter vers ce qui est déjà fait.

---

## 2026-09-07 (très fin de journée) — ménage : l'axe mort déclaré au présent

L'audit de l'entrée suivante mesurait une chose : **puis-je rebâtir la machine ?** Il en
manquait une autre, soulevée par Julien le soir même — **le dépôt décrit-il la machine qui
existe ?** Ce sont deux défaillances distinctes, et la seconde était plus grosse en volume.

### Le déclencheur, et il était juste

> « la simple citation de gdm ou de sway ça n'a plus rien à faire là »

Compté : **48 mentions de Sway dans `CLAUDE.md`**, 16 dans `poste/README.md`, 8 de GDM dans
`poste/README.md`. Le premier réflexe — repartir d'un dépôt vierge — a été écarté sur un
argument chiffré : les défauts non signalés se comptaient sur les doigts d'une main, contre
**70 pièges, 7 entrées de journal datées et 35 commits** qui ne se régénèrent pas. Et
trier « les bonnes choses » demande justement de savoir ce que les 6 800 lignes ont appris,
c'est-à-dire l'archéologie que `poste/README.md` a été écrit pour éviter.

**Mais le tri lui-même était légitime, et il était décidable en trois `grep`.**

### Ce qui distingue une mention légitime d'une mention morte

C'est la seule chose à retenir de ce ménage, parce que c'est elle qui empêche la rechute :

| Une mention de Sway / GDM est | … et donc |
|---|---|
| dans `journal/01-*` | **légitime** — c'en est le sujet, itération close |
| dans une entrée **datée** de journal | **légitime** — la date fait la valeur |
| dans un **piège**, comme exemple du mécanisme | **légitime** — l'outil ne fait que dater l'apprentissage |
| dans une **description d'état** au présent | **morte** — c'est ça qu'on purge |

D'où la règle écrite en tête de la section des pièges de `CLAUDE.md` : **un piège peut
nommer Sway ; une description d'état, jamais.**

### La cause, et elle n'est pas de la négligence

`poste/README.md` s'annonce « inventaire **vivant** ». Il contenait trois choses :
l'inventaire vivant, l'archive de l'itération 01, et une note de décision périmée de
148 lignes — celle où vivaient **6 des 8 mentions de GDM**. **Aucune règle n'en éjectait
jamais rien.** Même mode de défaillance que le retard de trois jours : pas un défaut de
rigueur, un défaut de **règle**. D'où la règle ajoutée en tête du fichier — une fiche
décrit le poste actuel, ce qui décrit un état passé va en archive datée.

### Les huit endroits, et le pire des huit

Le pire n'était pas une prose vieillie mais une affirmation **doublement fausse** présentée
comme un acquis : la fiche VM listait la règle de placement Sway sous « **Versionné dans le
dépôt — revient seule avec `stow`** ». Or `sway` n'est pas posé sur ce poste, **et** il n'y
a aucune règle équivalente : `hyprland.lua` ne contient aucune règle de fenêtre. Quelqu'un
qui rebâtit le poste aurait coché cette ligne et attendu un comportement qui n'existe pas.

Deux autres méritent d'être nommées parce qu'elles étaient **dans du code destiné à être
posé** : le commentaire de `10-aliases.sh` (paquet `bash`, celui qu'il reste à stower) et
celui de `vm-win11.desktop` invoquaient tous deux la règle `assign` de Sway.

### Le code mort : un script qui contredisait la procédure

`installation/scripts/01-bureau-hyprland.sh` a été **supprimé**. Il installait `foot` au
lieu de `kitty`, omettait `hyprland-guiutils`, annonçait que le trousseau et le NAS ne
marcheraient pas, et faisait lancer Hyprland **à la main depuis un tty** — ce qui est
exactement ce qui a produit les deux sessions Hyprland simultanées du 2026-09-04. Il
n'était référencé par aucun document.

**Ce qui le rendait dangereux n'est pas d'être faux, c'est d'être une SECONDE SOURCE.**
Deux fichiers décrivant la même séquence, dont un invisible et périmé : le dépôt connaît
déjà cette famille de problème sous une autre forme (« deux composants qui peignent la même
couche »). Son unique contenu irremplaçable — `mesa-dri-drivers`, sans quoi Hyprland ne
démarre pas du tout — a été repris dans `procedure.md` §4.0 **avant** la suppression. Le
relevé `versions-01.txt` reste : c'est une photo datée, pas du code.

> **Leçon de méthode, la seule vraiment neuve de la journée.** Un script d'installation
> non référencé par la procédure n'est pas un doublon inoffensif : c'est un **piège à
> retardement**, parce qu'il a l'air exécutable et qu'il ne l'est plus. Un fichier
> exécutable qui n'est cité nulle part est soit à câbler, soit à supprimer — jamais à
> laisser dormir. Même famille que « un paquet installé n'est pas un paquet utilisé »,
> appliquée au dépôt lui-même.

### Deux trous bloquants comblés au passage

Trouvés en rejouant la procédure **sur papier** — et c'est la méthode qui compte, aucun des
deux n'était visible en relisant :

1. **`mesa-dri-drivers` n'était pas dans la procédure.** Sans lui Hyprland ne démarre pas,
   et le symptôme ne le désigne pas.
2. **Le réenregistrement du mot de passe SMB n'y était pas non plus.** Il vivait dans
   `dotfiles/README.md`, au titre des limites de `stow`. Sans lui,
   `nas-infoadmin.service` échoue au premier login d'une machine neuve, et le symptôme
   accuse le NAS ou l'unité, pas le trousseau.

Et un troisième, **laissé ouvert et marqué comme tel** : le contenu de
`/etc/greetd/config.toml` n'est nulle part. C'est le seul fichier de la chaîne du greeter
dans ce cas — l'audit du matin avait rapatrié le `greeter.toml` et le `tmpfiles.d`, et raté
celui-là. Écrit en clair dans la procédure plutôt que comblé de mémoire : le relever coûte
une minute sur la machine, l'inventer coûterait un greeter en écran texte.

### Trois points ouverts clos sans verdict

Les trois points Sway du lab — `swaybg` résiduel, ressenti à froid, `waybar` inutilisée.
Raison : le SSD USB **va être formaté**, donc ils ne sont plus mesurables. Les garder,
c'était garder des cases que personne ne pourrait jamais cocher. Le précédent existait et
il était bon : « ressenti Sway à froid » avait déjà été clos comme ça le 2026-09-04.

**Ce qui compte est d'écrire la clôture, pas de la faire.** Sans ça, dans six mois, on ne
saurait pas si Sway avait été jugé ou seulement traversé.

---

## 2026-09-07 (fin de journée) — audit complet : le dépôt avait trois jours de retard

Le poste a été inventorié de bout en bout, puis le dépôt réécrit **en prenant la machine
pour source de vérité** plutôt que l'inverse. C'est la première fois que le mouvement se
fait dans ce sens, et le résultat justifie de le refaire périodiquement.

### Le chiffre, d'abord

**Neuf cases faites sans avoir été notées. Cinq affirmations devenues fausses. Trois
configurations réelles n'appartenant à aucune des trois destinations.**

Aucune de ces vingt-et-une erreurs ne vient d'un raisonnement fautif. Toutes viennent d'un
**écrit qui n'a pas suivi un geste posé**. C'est important pour la suite : la parade
n'est pas « être plus rigoureux au moment du geste » — c'était déjà la règle de tenue
inscrite en tête de `procedure.md`, et elle n'a pas tenu trois jours. La seule parade qui
marche est celle qui a été employée aujourd'hui : **confronter le dépôt à la machine**, à
intervalles réguliers, avec des commandes plutôt qu'avec de la mémoire.

### Ce que « neuf cases faites non notées » veut dire concrètement

La liste « Reste à faire avant de considérer le poste monté » du cadrage comptait douze
entrées. Étaient en réalité faits : `grub-btrfs`, Hyprland depuis le COPR, la plomberie
`uwsm`, la config du compositeur, le greeter compilé et **en service**, les lignes PAM du
trousseau, le montage NAS de bout en bout, snapper, la reprise de la VM Windows, et le
relevé LUKS. Restait vraiment : **l'enrôlement du TPM2**.

**Une liste de restes qui décrit un travail déjà accompli est pire qu'une liste absente.**
Elle ne se contente pas d'être inexacte : elle oriente le travail vers ce qui est déjà
fait, et masque la seule chose qui manque. C'est un piège de tenue, pas de technique.

Corollaire découvert dans la foulée : **c'est le titre de section qu'on lit, pas les cases
en dessous.** §6 de la procédure s'intitulait « FAIT le 2026-09-04, **non activé** » alors
que la ligne `systemctl enable greetd` était cochée quinze lignes plus bas et que le
greeter ouvrait la session depuis trois jours. Quand on coche une case, il faut relire le
titre.

### Les trois configurations orphelines — et pourquoi la règle des trois destinations ne suffit pas

La règle du dépôt dit : tout geste atterrit dans `procedure.md`, `dotfiles/` ou `poste/`,
sinon il sera perdu. Trois fichiers vivaient hors de tout ça :

| Fichier | Pourquoi il échappait à la règle |
|---|---|
| `/var/lib/noctalia-greeter/greeter.toml` | root, hors du home → hors de portée de `stow` ; livré par aucun paquet → hors de `dnf` |
| `/etc/tmpfiles.d/noctalia-greeter.conf` | idem |
| `~/.config/git/ignore` | dans le home, mais dans aucun paquet `stow` existant |

Le `greeter.toml` est le cas grave : il porte la session par défaut, la disposition
`fr/azerty` de l'écran de connexion et les positions des trois écrans. **Sans lui, on tape
son mot de passe en QWERTY sur un clavier AZERTY** — et il aurait disparu à la première
réinstallation, silencieusement.

**Ce que ça apprend : `stow` couvre le home, pas le poste.** Un geste posé dans `/etc` ou
`/var` n'a qu'une destination possible — la procédure — et rien, au moment où on le pose,
ne le rappelle. Le contrôle ne peut donc pas être « y ai-je pensé ». Les trois fichiers
sont maintenant recopiés intégralement (les deux premiers dans `procedure.md`, le troisième
rapatrié dans `dotfiles/git/`).

**Décision prise en même temps, et écrite pour rester un choix :** les réglages Noctalia
(`~/.local/state/noctalia/settings.toml`) ne seront **pas** versionnés. Noctalia écrit dans
`XDG_STATE_HOME`, au milieu de son historique de notifications, de son presse-papiers
chiffré et de ses compteurs d'usage — versionner ce dossier serait versionner un flux. La
perte est assumée : les réglages se refont à la main. Ce qui distingue le `greeter.toml`,
c'est qu'il est **déclaratif** et que le greeter ne le réécrit jamais, pas qu'il soit plus
important.

### Une note de piège fausse depuis le jour où elle a été écrite

`CLAUDE.md` justifiait la solution AZERTY d'Hyprland ainsi : « puisque
`input:resolve_binds_by_sym` vaut **`true`** par défaut, lier les symboles réels ».

Mesuré : `hyprctl getoption input:resolve_binds_by_sym` → **`bool: false set: false`**.

Le geste est bon — 61 liaisons, aucune inerte. Mais il marche **pour la raison inverse**
de celle écrite : avec `false`, Hyprland traduit le keysym de la config en **code de
touche** via le keymap courant, donc `eacute` désigne la touche physique `AE02` quel que
soit son niveau. C'est ce qui permet à `$mod+eacute` et `$mod+SHIFT+2` de cohabiter.
Avec `true`, la comparaison se ferait sur le symbole reçu et le problème de niveau
reviendrait.

**Ce qui est instructif, c'est que la note a « marché » trois jours.** Un geste qui
fonctionne ne valide pas l'explication qu'on en donne — et une explication fausse coûte
le jour où on veut transposer le raisonnement ailleurs. La règle du dépôt « une note de
piège se re-teste » s'applique aussi aux notes qui n'ont jamais échoué.

### Deux découvertes qui n'étaient pas dans le dépôt du tout

**Le `%post` du RPM RustDesk crée des fichiers hors de la base rpm.** Il copie l'unité dans
`/etc/systemd/system/`, deux `.desktop` dans `/usr/share/applications/`, crée le lien
`/usr/bin/rustdeskadmin`, puis lance `systemctl enable` **et** `start` de lui-même.
Résultat : `rpm -qf /usr/bin/rustdeskadmin` répond « n'appartient à aucun paquet » alors
que c'est ce paquet qui l'a créé. Un inventaire fondé sur `rpm -ql` rate le binaire, le
lanceur et le service. Et le `systemctl enable --now` que j'avais écrit dans la procédure
était inutile — le paquet l'avait déjà fait.

C'est le deuxième RPM hors distribution à surprendre par son `%post` sur cette machine,
après `grub-btrfs` qui réécrit `grub.cfg`. Le piège du dépôt disait « lire les scriptlets
avant d'installer » ; il faut y ajouter : **ils ne modifient pas seulement l'état du
système, ils créent des fichiers que `rpm` ne suivra pas.**

**`sssd.service` est `enabled` et la machine n'est pas jointe au domaine.** De quoi
conclure l'inverse en regardant `systemctl list-unit-files`. Vérification :
`authselect current` → profil **`local`**, et `/etc/sssd/` ne contient **aucun
`sssd.conf`**. C'est un préréglage de Fedora. Un service sans configuration démarre, ne
fait rien, et n'échoue pas — donc ne se signale jamais. Troisième variante d'un piège
déjà connu sous deux formes : « un dépôt activé n'est pas un paquet installé », « une
unité chargée n'est pas une unité exécutée », et maintenant **« un service activé n'est
pas un service configuré »**.

### Une erreur commise pendant l'audit, à ne pas refaire

`secret-tool search` a été employé pour vérifier que l'entrée SMB du NAS existait dans le
trousseau. **La commande affiche les secrets en clair** : le mot de passe du partage s'est
retrouvé dans la transcription de la session. Rien n'est allé au dépôt, mais l'erreur est
bête et évitable. Pour vérifier l'existence et l'état d'une collection sans la lire :

```bash
busctl --user get-property org.freedesktop.secrets \
  /org/freedesktop/secrets/collection/login \
  org.freedesktop.Secret.Collection Locked
```

Vaut a fortiori pour un agent automatisé, dont la sortie est conservée.

### Ce qui a été corrigé sur le dépôt

- `bin/snapshot.sh` : option **`--poste`**. Le script ne savait écrire que dans
  `journal/<itération>/`, et le poste n'en est pas une — la case « première capture d'état
  de ce poste » était **infaisable**. Elle écrit maintenant dans
  `installation/etats/<date>/`, sans baseline (une baseline y mesurerait l'image ISO, pas
  la distribution), et compare à la **capture précédente**. Trois mesures ajoutées à
  `system.md` : version du compositeur, volumes LUKS, Secure Boot + TPM2.
- `dotfiles/git/.gitconfig` : la ligne `editor = vim` retirée. **`vim` n'existe pas sur ce
  poste** — l'image minimale fournit `vim-minimal`, donc `vi`. Un `git commit` sans `-m`
  aurait échoué sur « command not found », et le paquet n'ayant jamais été posé, personne
  ne s'en était aperçu. Sans `core.editor`, git suit `$VISUAL`/`$EDITOR`/`vi` : plus
  portable que de nommer un binaire.
- `poste/README.md` : fiche **RustDesk** créée, fiche **VM Windows** passée en « en
  service » avec les mesures, pont `br0` prouvé au reboot, fiche snapper complétée.
- Ajouts de sections à `procedure.md` : kitty (§8bis), RustDesk (§8ter), virtualisation et
  `br0` (§8quater), outils réseau (§8quinquies).

### Le chiffre qui résume l'écart entre le dépôt et la machine

**53 paquets explicites à l'installation, 101 au 2026-09-07. 419 au total, 1235
aujourd'hui.** Le poste a triplé de volume en trois jours, et le dépôt en documentait la
moitié.

### Ce qui reste, et par ordre

1. **Enrôler le TPM2 sur LUKS.** Seule case du départ qui n'a pas bougé, et la plus
   visible au quotidien. À faire d'autant plus que `luksDump` montre **un seul emplacement
   de clé** : aujourd'hui, perdre la phrase de passe c'est perdre le disque.
2. **Poser `bash` et `git`.** Tourner avec l'historique par défaut de Fedora (1000 lignes,
   sans horodatage) sur un poste de lab dont toute la méthode repose sur « retrouver ce
   qu'on a tapé » est la perte la plus concrète.
3. **Configurer kitty.** Le raisonnement du `foot.ini` ne s'applique à rien.
4. **Nommer la machine.**
5. Répéter **à froid** la porte de sortie GRUB vers un instantané.

### Temps passé

Environ 2 h, dont la plus grande part en écriture et non en mesure. L'inventaire lui-même
tient en une trentaine de commandes, dont une moitié n'exige aucun privilège.

---

## 2026-09-07 — `grub-btrfs` posé, et une note du dépôt qui n'aurait pas démarré

Point de départ : « où en est la config, surtout niveau sauvegarde ? ». La réponse a
d'abord été un état des lieux, et il a sorti deux choses que personne ne cherchait.

### L'état des lieux avant de toucher à quoi que ce soit

Le dépôt est propre et poussé — rien de perdu de ce côté. Mais **la dernière écriture
datait du 4 septembre** : trois jours d'usage réel du poste Hyprland n'ont pas été
journalisés, et la VM Windows annoncée « prévue le lundi 7 septembre » ne l'est pas encore.
C'est exactement le risque que `CLAUDE.md` s'était donné en ouvrant l'axe du poste de
référence — le confort du poste interne fait qu'on ne note plus.

**Et `stow` n'est appliqué qu'à moitié sur ce poste.** Seuls `hypr` et `foot` sont posés.
`~/.bashrc`, `~/.bash_profile` et `~/.gitconfig` sont encore **les fichiers par défaut de
Fedora**, `~/.bashrc.d` n'existe pas — donc rien du paquet `bash` du dépôt n'est en
service. `procedure.md:365` le disait sans marqueur de date, ce qui se lit comme un reste
à faire ; c'en était bien un. Le paquet `nas`, lui, est déployé et l'unité tourne, mais la
procédure ne le notait pas fait : **un `[ ]` peut aussi bien vouloir dire « pas fait » que
« fait, pas noté »**, et la seule façon de trancher est de regarder la machine.

À noter que l'écart va dans le bon sens : le dépôt a mieux que la machine. Rien n'est
perdu, il y a juste un `stow` à passer.

### Le choix d'obtention — un chroot COPR ne dit rien de l'âge du paquet

`grub-btrfs` reste absent des dépôts Fedora (re-vérifié aujourd'hui, la note du 4 tient).
Deux COPR annoncent `fedora-44-x86_64` dans leurs chroots actifs. Ça ressemble à deux
candidats équivalents ; ce n'en est pas :

| Voie | Ce que le paquet dit de lui-même |
|---|---|
| `pego-copr/grub-btrfs` | `grub-btrfs-4.14-1.fc44`, `buildtime` = 2 mars 2026 |
| `kylegospo/grub-btrfs` | `grub-btrfs-0.0.git.275.8c61d8ef-1.**fc38**`, `buildtime` = 2 sept **2022** |

Un vieux paquet recopié dans un chroot récent y apparaît comme disponible. La page COPR
affiche « fedora-44 » dans les deux cas et ne raconte pas ça. La question exacte se pose au
paquet, sans rien installer :

```bash
dnf repoquery --repofrompath="c,https://download.copr.fedorainfracloud.org/results/<owner>/grub-btrfs/fedora-44-x86_64/" \
  --repo=c --nogpgcheck --qf '%{name}-%{version}-%{release} (%{buildtime})\n'
```

> **Leçon, déjà connue sous une autre forme.** « Un dépôt activé n'est pas un paquet
> installé » a un cousin : **un chroot listé n'est pas un paquet à jour.** Dans les deux
> cas l'outil rapporte un fait étroit — ici « ce chroot existe » — et c'est le lecteur qui
> ajoute « donc le paquet est construit pour cette version ».

La troisième voie, `make install` depuis le git upstream, a été écartée sans hésiter : le
Makefile pose dans `$PREFIX=/usr` par défaut, mais tout écart y mène à `/usr/local`, et le
greeter Noctalia a déjà coûté une séance de `semanage fcontext` pour cette raison. Un RPM
laisse RPM étiqueter.

### Ouvrir le RPM avant de l'installer — et ce que ça a évité

`rpm -qlp`, `rpm -qRp`, `rpm -qp --scripts` puis `rpm2cpio` sur le fichier téléchargé,
avant tout `dnf install`. Trois choses en sont sorties.

Deux bonnes : le `config` livré **détecte Fedora tout seul**
(`if [ -f /etc/fedora-release ]` → `/boot/grub2`, `grub2-mkconfig`, `grub2-script-check`),
et l'unité systemd surveille déjà `/.snapshots`, le chemin exact de snapper ici.
**Zéro ligne de configuration à écrire** — mais on ne pouvait pas le savoir sans regarder.

Une qui demandait une précaution : **le `%post` lance `grub2-mkconfig -o /boot/grub2/grub.cfg`
de lui-même.** Donc `dnf install` réécrit le `grub.cfg` d'une machine en UEFI + BLS sans
rien demander. La copie de sauvegarde se prend **avant** l'installation. Sans avoir lu le
scriptlet, on l'aurait prise après — c'est-à-dire jamais.

### Vérifier en DEUX mesures, parce que la première seule ne prouve rien

Le script l'annonce lui-même dans sa sortie : « `grub2-mkconfig` needs to run at least once
to generate the snapshots (sub)menu entry in grub the main menu ».

- `grep -c menuentry /boot/grub2/grub-btrfs.cfg` → **11** (1 en-tête + 5 instantanés × 2 noyaux) ;
- `grep -n 41_snapshots /boot/grub2/grub.cfg` → **`grub.cfg:266-274`**, avec
  `configfile "${prefix}/grub-btrfs.cfg"`.

La première mesure sans la seconde aurait laissé croire à une installation réussie alors
que les entrées auraient pu vivre dans un fichier qu'aucun `configfile` ne lit. **Un
fichier bien rempli et un fichier bien rempli mais jamais lu se ressemblent beaucoup.**
Même famille que « un paquet installé n'est pas un paquet utilisé ».

### Le vrai gain de la journée : une note du dépôt était fausse

`poste/README.md` décrivait la porte de sortie manuelle — éditer l'entrée GRUB avec `e` le
jour où la racine ne boote plus. Elle disait : remplacer `rootflags=subvol=root` par
`rootflags=subvol=.snapshots/<N>/snapshot`. **Le chemin était faux**, et c'est la sortie de
grub-btrfs qui l'a démenti :

```
Found snapshot: 2026-09-07 08:58:24 | root/.snapshots/10/snapshot | single | avant grub-btrfs |
```

`/` est monté en `subvol=/root` et `.snapshots` est imbriqué dedans : depuis la racine
Btrfs, c'est `root/.snapshots/<N>/snapshot`. Sans le préfixe, ça ne démarre pas.

Cette note était le plan de secours *du jour où ça casse*. On ne l'aurait découvert qu'à ce
moment-là. **Une procédure de secours qu'on n'a jamais exécutée n'est pas une procédure,
c'est une intention** — la case « répéter à froid » existait dans `procedure.md` et n'a
jamais été cochée. Elle reste ouverte.

### Trois pièges de lecture dans ma propre vérification — dont deux de mes conclusions fausses

**Mon `grep` a produit un faux négatif, et j'en ai tiré une conclusion fausse.** J'avais
proposé `grep -o "rootflags=subvol=[^ ]*"` : il n'a **rien** renvoyé sur
`grub-btrfs.cfg`, et j'en ai déduit que la note du dépôt avait aussi tort sur la *forme* de
l'option, pas seulement sur le chemin. Faux. Il y a **deux fichiers, deux formes** :

| Où | Forme |
|---|---|
| Entrée BLS vivante (`grubby --info=ALL`) | `ro rootflags=subvol=root` — `subvol` seul |
| `grub-btrfs.cfg` généré | `rootflags=compress=zstd:1,…,subvol="root/…"` |

Le motif était **valable pour l'entrée vivante**, je l'ai lancé sur le fichier généré. Ni
motif mal formé, ni absence : **mauvaise cible.** La note du dépôt avait donc raison sur la
forme, et une seule erreur — le chemin. Corollaire : quand une mesure revient vide, lire le
contenu brut (`sed -n '1,60p'`), et vérifier qu'on interroge bien **le fichier dont parle
la note**. Une sortie vide ne distingue pas un motif inadapté d'une cible inadaptée.

**Et j'ai enchaîné avec une seconde déduction, aussi fausse.** Voyant `ro` absent des
entrées générées, j'ai annoncé un risque de montage `rw` sur un sous-volume `ro`, et laissé
la question « non mesurée ». Elle était **documentée depuis le début**, en tête du script
livré (lignes 11-12 de `41_snapshots-btrfs`) : *« Warning : booting on read-only snapshots
can be tricky »*, avec un lien vers la section du README qui donne la condition —
« `/var/log` or even `/var` must be on a separate subvolume ». Le problème n'est pas le
montage de la racine, il est en **espace utilisateur**. Détail complet dans la fiche de
`poste/README.md` ; ce qu'il faut retenir ici, c'est la mécanique de l'erreur : **deux
déductions plausibles enchaînées, alors que la réponse était dans les douze premières
lignes d'un fichier déjà extrait sur mon disque.**

> **Ce que ça coûte, dit franchement.** Julien a dû interrompre pour demander une recherche
> claire plutôt qu'une nouvelle hypothèse. Trois erreurs de la journée ont la même forme :
> un indice réel, un mécanisme plausible, et aucune lecture de ce que l'outil dit de
> lui-même. C'est exactement le piège que `CLAUDE.md` porte déjà — « un mécanisme plausible
> n'est pas une contrainte » — appliqué trois fois de suite sans être reconnu.

**Et une supposition pessimiste s'est retournée aussi.** J'avais craint que `grub-btrfsd`
relance un `grub2-mkconfig` complet à chaque instantané — donc un `os-prober` toutes les
heures. Lecture de `/usr/bin/grub-btrfsd`, lignes 209-216 : il teste si `grub.cfg` contient
`snapshots-btrfs`, et si oui n'appelle que `/etc/grub.d/41_snapshots-btrfs`, qui régénère
le seul `grub-btrfs.cfg`. Le `grub2-mkconfig` complet reste réservé aux mises à jour de
noyau. **Le code était lisible en trois lignes de `grep` ; la supposition, elle, était
gratuite.** À noter que la déduction gratuite peut aussi être pessimiste — ce n'est pas
seulement l'optimisme qui trompe.

### Un effet de bord qui apparaîtra et disparaîtra tout seul

Le `grub2-mkconfig` du `%post` a rapporté
`Found Fedora Linux 44 (Workstation Edition) on /dev/sda3` : `os-prober` a trouvé le **SSD
USB du lab** et lui a ajouté une entrée. Le menu GRUB du poste dépend donc de ce qui est
branché au moment d'un `grub2-mkconfig` complet. Sans conséquence — mais consigné pour ne
pas le prendre pour une anomalie le jour où on verra l'entrée bouger. C'est aussi la
première fois que les deux axes du dépôt se croisent dans un même fichier de
configuration : le lab et le poste de référence partagent le bootloader.

### Ce que cette journée ne règle PAS

`grub-btrfs` répare le scénario « la mise à jour casse, je reboote sur l'avant ». Il ne
touche pas à l'autre moitié :

- **Toujours aucune sauvegarde hors machine.** Les instantanés vivent sur le disque qu'ils
  protègent. Le point ouvert du 4 septembre — le Windows de secours disparu — reste
  entièrement ouvert. Un instantané amorçable n'est pas une copie.
- **Toujours pas d'instantané automatique avant/après transaction**, faute de greffon
  snapper pour dnf5. Le filet existe, il faut encore le tendre à la main.

### Ce qui reste, et quand

- **La porte de sortie manuelle à répéter à froid** — avec le chemin corrigé. C'est
  maintenant la case la plus rentable du dépôt, puisqu'on vient de prouver que son contenu
  pouvait être faux sans que personne le sache.
- **Sauvegarde hors machine** — le NAS est monté et serait une destination. Non tranché.
- `stow -n -v -t ~ bash git desktop` puis le vrai, pour combler l'écart constaté ce matin.
- **VM Windows d'administration** — annoncée pour aujourd'hui, non commencée.
- Retirer les deux lignes redondantes de `hyprland.lua`, après quelques jours d'`uwsm`.
- Enrôlement TPM2 pour LUKS.

### Temps passé

<!-- TODO : à compléter. Toujours la donnée qui manque. -->

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
