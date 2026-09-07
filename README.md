# linux — lab d'évaluation de distributions, et poste de référence

Dépôt de travail personnel pour **choisir la distribution et l'environnement Linux**
avec lesquels je vais travailler pendant mon alternance en **mastère SRC**
(Systèmes, Réseaux et Cloud computing).

Ce n'est pas un projet logiciel. C'est un **carnet de lab** : j'installe une distro,
je m'en sers pour de vrai, je note ce qui marche et ce qui me gêne, puis je passe
à la suivante — et à la fin je tranche avec des notes plutôt qu'avec une impression.

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
> Pousser sur GitHub reste la règle — ce n'est simplement plus une question de survie.
> La procédure de bascule est dans [`journal/README.md`](journal/README.md).

## Structure

| Chemin | Contenu |
|---|---|
| `journal/` | Une itération = une distro testée. Fiche + entrées datées + `baseline/` capturée. |
| **`installation/`** | **Le poste de référence** : cadrage des décisions, procédure rejouable, journal de construction, captures d'état. Ce n'est **pas** une itération. |
| **`poste/`** | Inventaire **vivant** des outils de travail, indépendant de la distro. Une fiche par outil. |
| `dotfiles/` | Paquets **GNU Stow** à réappliquer sur machine nue (shell, git, compositeur, terminal, session). |
| `bin/` | Outillage du lab. `snapshot.sh` capture l'état du système — `--poste` pour le poste de référence. |

Les quatre dossiers répondent à quatre questions différentes, et les confondre casserait
la méthode : `journal/` dit *ce qui s'est passé sur cette distro*, `installation/` dit
*comment rebâtir le poste*, `poste/` dit *ce qu'il faut réinstaller pour retravailler*,
`dotfiles/` dit *ce qui revient tout seul*.

## Les deux disques

| Disque | Rôle | Contenu |
|---|---|---|
| **NVMe interne** — KIOXIA BG6, 238 Go | **le poste de travail réel** | Fedora 44 minimale, **LUKS**, Btrfs, Hyprland + Noctalia. Voir `installation/` |
| **SSD USB** — 233 Go (`TRAN=usb`) | **le lab**, formaté à volonté | itération 01 (Fedora 44 Workstation), intacte |

## Itérations

| # | Distro | Environnement | Période | Statut |
|---|---|---|---|---|
| 01 | Fedora 44 Workstation | GNOME 50.4 / Wayland, puis Sway + Noctalia | 2026-08-28 → 2026-09-04 | ⏸️ en pause sur le SSD USB |

Le **poste de référence** (`installation/`) n'entre pas dans cette numérotation : c'est la
pile retenue pour travailler, pas une distro en évaluation. Le protocole de baseline ne
s'y applique pas — une baseline y mesurerait l'image ISO, pas la distribution, et c'est
d'ailleurs la même distribution que l'itération 01.

## Machine

Dell Pro Slim QCS1250 — Intel Core i5-14500 (20 threads) — 16 Go RAM — trois écrans Dell.
**Secure Boot activé**, TPM 2.0 présent. Détail du matériel dans `CLAUDE.md`.

Machine unique. L'itération 01 sur le SSD USB a servi de poste de secours amorçable après
le 2026-09-04 — **mais ce disque va être formaté** (annoncé le 2026-09-07), et la machine
redeviendra alors unique au sens strict. À ne pas compter comme un acquis : c'est un état
transitoire, pas une propriété du montage.
