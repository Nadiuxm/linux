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

### Le protocole de baseline

L'install est **strictement vierge**, et c'est volontaire. `dnf history` le confirme :
en dehors de la construction de l'ISO (avril, chez Fedora) et des langpacks français
posés automatiquement au choix de la langue, il n'y a que deux transactions à moi —
un `dnf update`, puis `dnf install keepassxc`.

**Un seul `dnf install` volontaire sur toute la machine.** C'est le protocole que je
dois reproduire à l'identique sur chaque distro suivante :

> install par défaut → mise à jour complète → KeePassXC → rien d'autre

Toute la valeur de la comparaison tient à ça. Si j'ajoute des outils sur une distro
et pas sur une autre, je ne compare plus les distros mais mes propres bricolages.

### Piège évité : les dépôts tiers ne sont pas des ajouts

En relisant la baseline j'ai d'abord cru que quatre dépôts non-Fedora avaient été
ajoutés à la main (google-chrome, RPM Fusion NVIDIA, RPM Fusion Steam, COPR PyCharm).
Faux — et `rpm -qf` le tranche en une commande :

```console
$ rpm -qf /etc/yum.repos.d/google-chrome.repo
fedora-workstation-repositories-38-9.fc44.x86_64
```

Les fichiers `.repo` sont **livrés par Fedora**, désactivés ; la case « Activer les
dépôts tiers » du premier démarrage les passe à `enabled=1`. Et rien n'en a été
installé : `google-chrome-stable` est absent du système, le dépôt est juste ouvert.

**Leçon de méthode :** un dépôt activé ≠ un paquet installé, et un fichier présent
dans `/etc` ≠ un fichier que j'ai mis là. Vérifier à qui appartient un fichier
(`rpm -qf`, ou `dpkg -S` côté Debian) avant d'en tirer une conclusion.

À noter pour la comparaison : cette facilité est propre à Fedora. Sur Debian ou
openSUSE, les codecs et pilotes propriétaires demanderont des manipulations —
**à chronométrer**, ce sera une donnée de comparaison.

### KeePassXC : critère éliminatoire

Seul logiciel installé volontairement, et pas par confort : c'est mon accès à mes
mots de passe personnels. Une distro qui ne le fournit pas facilement est
**éliminée d'office**, quelles que soient ses autres qualités. À vérifier avant
même de lancer une install : présent dans les dépôts officiels ? à quelle version ?

Ici : version 2.7.12, dépôt Fedora officiel, aucune manipulation. Référence à battre.

Point de vigilance associé : la base `.kdbx` est exclue du dépôt par le `.gitignore`.
C'est le bon choix — mais ça veut dire que **rien ne la sauvegarde automatiquement**.
En bare-metal, oublier cette sauvegarde avant une réinstall = perdre ses mots de
passe. C'est le risque n°1 de la méthode.

**À suivre :** installer `stow` et poser les liens (en cours).

---
