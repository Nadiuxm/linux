# linux — lab d'évaluation de distributions, et postes de référence

Dépôt de travail personnel pour **choisir la distribution et l'environnement Linux**
avec lesquels je vais travailler pendant mon alternance en **mastère SRC**
(Systèmes, Réseaux et Cloud computing).

Ce n'est pas un projet logiciel. C'est un **carnet de lab** : j'installe une distro,
je m'en sers pour de vrai, je note ce qui marche et ce qui me gêne, puis je passe
à la suivante — et à la fin je tranche avec des notes plutôt qu'avec une impression.

## Deux machines, deux dossiers

Le dépôt a été réorganisé par machine le 2026-09-11. Tout ce qui existait
jusque-là décrivait **une seule** machine, le poste fixe ; c'est aujourd'hui le
contenu de `uc/`. Un second poste, un portable, ouvre son propre dossier.

| Dossier | Machine | État |
|---|---|---|
| [`uc/`](uc/) | **Dell Pro Slim QCS1250**, le poste fixe. Tout l'historique du dépôt. | en service |
| [`portable/`](portable/) | Le **portable**, Fedora vierge fraîchement installée. | vide — rien n'y est encore écrit |

> **Convention de lecture.** À l'intérieur de `uc/`, les chemins cités dans les
> fichiers s'entendent **relatifs à `uc/`** : `installation/procedure.md` désigne
> `uc/installation/procedure.md`. Les fichiers n'ont pas été réécrits pour porter
> le préfixe — ç'aurait été des centaines de retouches sans valeur. Le préfixe
> s'ajoute à la lecture, une fois, ici. `portable/` suivra la même convention le
> jour où il se remplira.

Ce que `portable/` devra contenir n'est **pas décidé**. Deux lectures possibles et
elles ne donnent pas la même arborescence : un **second poste de travail** (alors il
lui faut ses propres `installation/` et `dotfiles/`, portés depuis ceux de `uc/`), ou un
**banc d'essai de la procédure** de `uc/installation/procedure.md` (alors le livrable
n'est pas une machine mais une procédure corrigée). Trancher avant d'y écrire quoi
que ce soit — un dossier qu'on remplit sans savoir ce qu'il prouve ne prouve rien.

## Méthode : bare-metal successif

Chaque distro est installée **réellement sur la machine**, pas en VM. C'est le choix
le plus lent, mais c'est le seul qui donne le ressenti réel : gestion du matériel,
veille/reprise, performances, stabilité sur la durée.

> **La contrainte fondatrice a changé le 2026-09-04, et il faut le lire avant le reste.**
> Ce paragraphe disait : « chaque réinstallation efface la machine, ce dépôt compris ;
> rien n'existe tant que ce n'est pas poussé ». **C'est faux depuis que les deux disques
> ont échangé leurs rôles** — le poste de travail vit sur le NVMe interne, le lab sur un
> SSD USB formaté à volonté. Une itération ne touche plus ni le poste, ni le dépôt.
>
> **Ce que la contrainte disparue emportait avec elle, en revanche, doit être remplacé.**
> La méthode tirait sa force de l'obligation de *vivre* dans la distro testée. Avec un
> poste confortable à côté, une distro sur le disque externe risque d'être visitée une
> heure et jamais éprouvée. D'où une discipline explicite : **une itération ne compte que
> si elle a porté du travail réel plusieurs jours.** Sinon l'axe distro meurt en silence.
>
> **L'arrivée du portable pousse dans le même sens** : une seconde machine confortable
> rend encore plus facile de ne jamais habiter la distro qu'on prétend évaluer.
>
> Pousser sur GitHub reste la règle — ce n'est simplement plus une question de survie.
> La procédure de bascule est dans [`uc/journal/README.md`](uc/journal/README.md).

## Structure de `uc/`

| Chemin | Contenu |
|---|---|
| [`uc/journal/`](uc/journal/) | Une itération = une distro testée. Fiche + entrées datées + `baseline/` capturée. |
| [**`uc/installation/`**](uc/installation/) | **Le poste de référence** : cadrage des décisions, procédure rejouable, journal de construction, captures d'état. Ce n'est **pas** une itération. |
| [**`uc/poste/`**](uc/poste/) | Inventaire **vivant** des outils de travail, indépendant de la distro. Une fiche par outil. |
| [`uc/dotfiles/`](uc/dotfiles/) | Paquets **GNU Stow** à réappliquer sur machine nue (shell, git, compositeur, terminal, session). |
| [`uc/bin/`](uc/bin/) | Outillage du lab. `snapshot.sh` capture l'état du système — `--poste` pour le poste de référence. |

Les quatre dossiers répondent à quatre questions différentes, et les confondre casserait
la méthode : `journal/` dit *ce qui s'est passé sur cette distro*, `installation/` dit
*comment rebâtir le poste*, `poste/` dit *ce qu'il faut réinstaller pour retravailler*,
`dotfiles/` dit *ce qui revient tout seul*.

> **Le déplacement dans `uc/` casse les liens GNU Stow**, qui sont relatifs et pointaient
> vers `linux/dotfiles/…`. Après un `git pull` qui apporte cette réorganisation sur une
> machine où les dotfiles sont posés, il faut **reposer les liens** depuis le nouveau
> répertoire — voir [`uc/dotfiles/README.md`](uc/dotfiles/README.md). Rien ne le signale :
> un shell neuf perd simplement son `.bashrc`.

## Les deux disques du poste fixe

| Disque | Rôle | Contenu |
|---|---|---|
| **NVMe interne** — KIOXIA BG6, 238 Go | **le poste de travail réel** | Fedora 44 minimale, **LUKS**, Btrfs, Hyprland + Noctalia. Voir `uc/installation/` |
| **SSD USB** — 233 Go (`TRAN=usb`) | **le lab**, formaté à volonté | itération 01 (Fedora 44 Workstation), intacte |

## Itérations

| # | Distro | Environnement | Période | Statut |
|---|---|---|---|---|
| 01 | Fedora 44 Workstation | GNOME 50.4 / Wayland, puis Sway + Noctalia | 2026-08-28 → 2026-09-04 | ⏸️ en pause sur le SSD USB |

La numérotation est celle de `uc/journal/`. Le **poste de référence**
(`uc/installation/`) n'y entre pas : c'est la pile retenue pour travailler, pas une
distro en évaluation. Le protocole de baseline ne s'y applique pas — une baseline y
mesurerait l'image ISO, pas la distribution, et c'est d'ailleurs la même distribution
que l'itération 01.

## Machines

**Poste fixe** — Dell Pro Slim QCS1250, Intel Core i5-14500 (20 threads), 16 Go RAM,
trois écrans Dell. **Secure Boot activé**, TPM 2.0 présent. Détail du matériel dans
`CLAUDE.md`.

**Portable** — Fedora fraîchement installée, joignable en SSH sur `10.11.65.4`. **Le
reste du matériel n'est pas relevé** : ni modèle, ni écran interne, ni chiffrement, ni
Secure Boot, ni TPM. Rien de ce qui est écrit pour le poste fixe ne s'y transpose sans
mesure — `uc/installation/procedure.md` code en dur trois écrans Dell par nom de sortie,
dans `hyprland.lua` **et** dans le `greeter.toml`, et monte un pont réseau `br0` sur de
l'Ethernet.

Le poste fixe n'est donc plus la machine unique. La phrase « machine unique » qui figurait
ici jusqu'au 2026-09-11 n'a plus cours — et l'itération 01 sur le SSD USB, qui servait de
poste de secours amorçable, **va être formatée** (annoncé le 2026-09-07).
