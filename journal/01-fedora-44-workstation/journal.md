# Journal — Fedora 44 Workstation

Entrées datées, les plus récentes en haut.
Noter **le problème et le temps perdu**, pas seulement la solution.

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
Constat en la relisant — l'install n'est **déjà plus vanilla** : RPM Fusion nonfree,
dépôt google-chrome, COPR PyCharm. À reproduire à l'identique sur les prochaines
distros, sinon la comparaison ne vaut rien.

**À suivre :** installer `stow` et poser les liens (pas encore fait).

---
