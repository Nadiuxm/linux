# linux — lab d'évaluation de distributions

Dépôt de travail personnel pour **choisir la distribution et l'environnement Linux**
avec lesquels je vais travailler pendant mon alternance en **mastère SRC**
(Systèmes, Réseaux et Cloud computing).

Ce n'est pas un projet logiciel. C'est un **carnet de lab** : j'installe une distro,
je m'en sers pour de vrai, je note ce qui marche et ce qui me gêne, puis je passe
à la suivante — et à la fin je tranche avec des notes plutôt qu'avec une impression.

## Méthode : bare-metal successif

Chaque distro est installée **réellement sur la machine**, pas en VM. C'est le choix
le plus lent et le plus destructif, mais c'est le seul qui donne le ressenti réel :
gestion du matériel, autonomie, veille/reprise, performances, stabilité sur la durée.

> **Conséquence directe et non négociable :**
> chaque réinstallation efface la machine, **ce dépôt compris**.
> Rien n'existe tant que ce n'est pas **poussé sur GitHub**.
> La procédure de bascule est dans [`journal/README.md`](journal/README.md).

## Structure

| Chemin | Contenu |
|---|---|
| `journal/` | Une itération = une distro testée. Fiche + entrées datées + baseline machine. |
| `dotfiles/` | Configuration portable (shell, éditeur, terminal) à réappliquer sur machine nue. |
| `bin/` | Outillage du lab. `snapshot.sh` capture l'état du système dans une baseline. |

## Itérations

| # | Distro | Environnement | Période | Statut |
|---|---|---|---|---|
| 01 | Fedora 44 Workstation | GNOME 50.4 / Wayland | depuis 2026-08-28 | 🟢 en cours |

## Machine de test

Dell Pro Slim QCS1250 — Intel Core i5-14500 (20 threads) — 16 Go RAM — SSD 233 Go.
Machine unique : il n'y a pas de second poste de secours pendant une réinstall.
