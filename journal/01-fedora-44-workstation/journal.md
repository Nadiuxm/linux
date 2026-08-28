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

> install par défaut → mise à jour complète → KeePassXC → git + stow → rien d'autre

Toute la valeur de la comparaison tient à ça. Si j'ajoute des outils sur une distro
et pas sur une autre, je ne compare plus les distros mais mes propres bricolages.

`git` et `stow` ne sont pas des ajouts de confort : c'est l'outillage du lab, sans
lequel la méthode ne fonctionne pas sur la distro suivante. Ils font donc partie du
protocole, au même titre que KeePassXC — mais pour une raison différente, et cette
distinction compte quand je relirai ce journal dans six mois.

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

### Stow posé — ce que le conflit m'a appris

`stow -n -v -t ~ bash git` (simulation) a refusé de continuer :

```
WARNING! stowing bash would cause conflicts:
  * cannot stow .../bash/.bashrc over existing target .bashrc since neither
    a link nor a directory and --adopt not specified
All operations aborted.
```

Ce n'est pas un bug : Stow ne remplace **jamais** un fichier qu'il n'a pas créé.
Il ne gère que ses propres liens symboliques. Les `.bashrc` et `.bash_profile`
livrés par Fedora étaient de vrais fichiers, il fallait donc les écarter d'abord
(`mv` vers `~/.dotfiles-backup/`, pas `rm` — on ne détruit pas ce qu'on n'a pas relu).

Bien vu aussi : « All operations aborted ». Stow est **atomique**, il ne pose rien
tant qu'un seul conflit subsiste. Pas de demi-installation à rattraper.

Après nettoyage, les quatre liens se posent. Deux détails qui comptent :

- Ils sont **relatifs** (`.bashrc -> linux/dotfiles/bash/.bashrc`), pas absolus.
  Le dossier utilisateur peut être renommé ou remonté ailleurs, ça tient.
- `~/.bashrc.d` est un lien vers le **dossier** entier, pas un dossier réel contenant
  des liens : c'est le *tree folding* de Stow, qui pose le lien le plus haut possible.
  Conséquence pratique — tout fichier déposé dans `~/.bashrc.d/` atterrit dans le
  dépôt et sera versionné. Pratique, mais **jamais de secret ni de token là-dedans**.

### Dépôt distant — deploy key et identité

Poussé sur `github.com/Nadiuxm/linux` (privé).

Deux choses relevées au passage, à retenir pour la suite :

**La clé SSH est une deploy key, pas une clé de compte.** `ssh -T git@github.com`
répond `Hi Nadiuxm/linux!` — avec le nom du dépôt. Une clé de compte répondrait
`Hi Nadiuxm!` tout court. Une deploy key n'ouvre **qu'un seul dépôt**, et elle est
en lecture seule sauf si « Allow write access » a été coché. Ici l'écriture passe
(vérifié par `git push --dry-run`, qui teste les permissions sans rien envoyer).
Au prochain dépôt il faudra soit refaire une clé, soit l'enregistrer dans
*Settings → SSH and GPG keys* du compte pour qu'elle vaille partout.

**Identité git corrigée avant le premier push.** Les commits partaient avec mon
adresse pro alors que ce lab est personnel. Réécrit avec :

```bash
git rebase --root --exec "git commit --amend --no-edit --reset-author"
```

Trivial parce que rien n'était encore poussé. La même correction après un push
aurait demandé de réécrire l'historique côté GitHub — beaucoup plus pénible.
**Leçon : vérifier `git config user.email` avant le premier commit, pas après.**

---
