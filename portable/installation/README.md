# README — décisions du second poste (portable)

Même répartition que `uc/installation/` : ici les **décisions et leurs raisons**, pas les
gestes (`procedure.md`), pas les constats (`mesures.md`), pas le récit daté (`journal.md`).

## Ce que ce poste reprend de `uc`, et pourquoi

La pile logicielle retenue sur `uc` (Fedora minimale, LUKS + Btrfs, Hyprland + Noctalia,
greetd, `gnome-keyring`, GNU Stow) est reprise ici **à l'identique dans son principe** :
ce n'est pas une nouvelle évaluation de distribution, c'est le même poste de référence
posé sur une seconde machine. Le protocole de baseline (`journal/`) ne s'applique pas ici,
comme il ne s'applique pas à `uc/installation/` — décision demandée explicitement par
Julien : **installation minimale**, rien en plus de ce que `uc` a déjà validé.

## Dotfiles dupliqués, pas partagés

Décision de Julien, 2026-09-11 : `portable/dotfiles/` contient sa **propre copie**
indépendante des paquets Stow de `uc/dotfiles/` (`bash`, `git`, `kitty`, `nas`, `noctalia`,
`uwsm`), plutôt que de stower directement depuis `uc/dotfiles/`. Raison : modifier un
paquet sur un poste ne doit pas modifier l'autre en silence. Conséquence assumée : une
amélioration faite sur un poste ne se propage pas automatiquement à l'autre — à reporter à
la main si elle doit valoir des deux côtés.

`hypr` **n'a pas été dupliqué** : ses noms de sortie et positions d'écran sont propres à
chaque machine. Il sera reconstruit ici une fois Hyprland installé, depuis une mesure
réelle (`hyprctl monitors all`), jamais recopié.

## VM Windows — hors périmètre pour l'instant

Décision de Julien, 2026-09-11 : **pas de VM Windows sur ce poste**, et il n'est pas
certain qu'il y en ait une un jour. Conséquence sur la procédure : les sections
virtualisation (`libvirt`), pont réseau `br0` et reprise de la VM, présentes dans
`uc/installation/procedure.md` (§8quater, §8quinquies, §11), **ne sont pas reprises** dans
`procedure.md` ici. RustDesk, en revanche, est repris (outil bloquant, indépendant de la VM).

Si la décision change, reprendre `uc/installation/procedure.md` §8quater à §11 et les
adapter — en particulier la carte réseau et son adresse MAC, propres à cette machine, et
le mode de connexion employeur qui sera **Wi-Fi**, pas Ethernet en continu (câble
uniquement pour l'installation, cf. discussion du 2026-09-11) : un pont `br0` classique
ne se reproduit pas sur une carte Wi-Fi côté client (limitation 802.11, pas une
configuration à corriger) — point à rouvrir et rechercher le moment venu, pas à deviner.

## Ce qui diverge déjà de `uc`, mesuré

- **Disque** : Samsung 512 Go NVMe (contre KIOXIA BG6 238 Go).
- **Hostname** : `PDC-7VL5-1165`, déjà réglé — `uc` avait laissé le sien `(unset)`.
- **Locale/clavier/fuseau** : déjà réglés à l'installation (`fr_FR.UTF-8`, `Europe/Paris`,
  X11 `fr`/`oss`) — sur `uc` cette case était restée `✎ INVENTÉ` faute d'avoir été notée.
- **Écrans** : un seul écran interne + externe(s) au besoin (dock), contre trois écrans
  Dell fixes sur `uc`. La config `hypr` ne sera donc pas un décalque : elle doit gérer le
  branchement/débranchement dynamique.
- **Clavier** : un clavier physique interne, contre 14 périphériques vus par Hyprland sur
  `uc` (récepteur Logitech Unifying + casque Yealink). Disposition réelle à confirmer une
  fois Hyprland lancé (`hyprctl devices`), pas à supposer identique.
