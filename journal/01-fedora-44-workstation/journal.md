# Journal — Fedora 44 Workstation

Entrées datées, les plus récentes en haut.
Noter **le problème et le temps perdu**, pas seulement la solution.

---

## 2026-09-04 — KeePassXC fournisseur Secret Service : la chaîne NAS fonctionne sans gnome-keyring

Test du point ouvert ouvert la veille. **Résultat : la chaîne complète fonctionne** —
entrée KeePassXC → greffon FdoSecrets → `libsecret` → `gvfsd` → partage SMB monté, avec
**aucun processus `gnome-keyring` sur la machine**.

> **Ce que ça vaut, et ce que ça ne vaut pas.** C'est une preuve de faisabilité obtenue
> dans une session bricolée à la main. Rien n'a été désinstallé, rien n'est persistant :
> au prochain login PAM relance `gnome-keyring`, qui reprend le nom D-Bus avant même que
> KeePassXC ne soit lancé. **L'ordonnancement au login n'est pas testé** — c'est tout le
> chantier qui reste.

### Le filet, et une découverte sur les instantanés

Instantané manuel `snapper` n° 4 sur `root` et `home` avant de commencer. En le préparant,
deux choses sont ressorties :

- **Les instantanés automatiques n'encadrent pas une opération risquée.** Il n'existe pas
  de greffon snapper pour dnf5 : ce qui tourne est `snapper-timeline.timer`, **horaire**.
  Le dernier instantané peut donc avoir presque une heure et ne sait rien de ce qu'on
  s'apprête à faire. L'instantané manuel n'est pas un supplément de prudence, c'est le
  seul qui encadre quoi que ce soit. Il est en plus protégé de la rotation quotidienne
  (`NUMBER_LIMIT` et `TIMELINE_LIMIT_DAILY` sont deux politiques distinctes).
- **`grub-btrfs` est retenu pour la configuration finale, et il impose un partitionnement.**
  Il cherche noyau et initramfs *dans* l'instantané ; or `/boot` est ici une partition ext4
  séparée, donc le `boot/` d'un instantané est vide. **`/boot` devra être placé dans le
  sous-volume Btrfs à l'itération 02.** Détail dans `poste/README.md`. En attendant, la
  porte de sortie ne demande rien à installer : au menu GRUB, `e`, puis
  `rootflags=subvol=.snapshots/<N>/snapshot`.

  > **[CORRECTION ajoutée le 2026-09-04 en fin de journée — ce point est FAUX.]**
  > `grub-btrfs` gère nativement un `/boot` séparé : « Automatically detect if `/boot` is
  > in a separate partition ». Il prend alors le noyau sur la partition `/boot` vivante et
  > lui ajoute `rootflags=subvol=<instantané>` — exactement la porte de sortie décrite
  > ci-dessus, mais automatisée. La déduction sur le `boot/` vide était juste sur le
  > mécanisme et fausse sur la conclusion, faute d'avoir lu la documentation de l'outil.
  > L'entrée est laissée telle quelle, la correction s'ajoute : c'est l'erreur qui a de la
  > valeur ici. Voir `installation/README.md` pour la décision retenue et `CLAUDE.md` pour
  > la leçon de méthode.

### Les cinq attributs — et celui qu'on ne voit pas

`gvfsd` ne demande pas « un mot de passe » : il cherche un item **par attributs**. Il a
donc fallu reproduire à l'identique, sur une entrée KeePassXC, ceux de l'entrée
`gnome-keyring` existante :

| Attribut | Valeur |
|---|---|
| `protocol` | `smb` |
| `domain` | `/` |
| `server` | `pdc-nas-info.te-mgmt.io` |
| `user` | `jzielona` |
| `xdg:schema` | `org.gnome.keyring.NetworkPassword` |

**Le cinquième a coûté deux échecs de montage, parce qu'il est invisible selon la façon
dont on regarde.** Un `secret-tool search --all` sur l'entrée **déverrouillée** n'affiche
que les quatre premiers. `xdg:schema` n'est apparu que par accident, dans la liste
**hachée** (`attribute.gkr:compat:hashed:…`) affichée quand la même entrée était
**verrouillée**.

> **Leçon : la façon dont on lit un objet change ce qu'on voit de lui.** Une liste
> d'attributs obtenue dans un état n'est pas la liste des attributs. Même famille que
> « un paquet installé n'est pas un paquet utilisé ».

Symptôme correspondant, à reconnaître : `gio mount` retombe sur la saisie interactive
(« Saisissez l'utilisateur et le mot de passe »), l'unité sort en `status=2`. Ce n'est pas
une erreur d'authentification — c'est une **recherche sans résultat**.

### KeePassXC publie ses champs natifs sous ses propres noms

Question posée en cours de route : le champ « Nom d'utilisateur » intégré ne suffirait-il
pas, plutôt qu'un attribut personnalisé `user` ? Réponse mesurée, pas déduite — le dépôt
d'attributs réellement publié contient :

```
attribute.UserName = jzielona      <- champ intégré, nommé par KeePassXC
attribute.user     = jzielona      <- attribut personnalisé
attribute.Title / URL / Uuid / Path / Notes
```

KeePassXC expose ses champs natifs en **CamelCase**, avec sa propre nomenclature. `gvfsd`
cherche `user` en minuscules, et les noms d'attributs Secret Service sont sensibles à la
casse. **Le champ intégré ne peut pas remplacer l'attribut personnalisé.**

Corollaire de méthode : s'appuyer sur le champ intégré aurait rendu un échec **ambigu** —
« KeePassXC n'expose pas les attributs personnalisés » ou « il les renomme » ? Une seule
variable à la fois, sinon la mesure ne dit rien.

### Deux réglages distincts, sur deux écrans qui se ressemblent — 20 minutes perdues

Le plus gros du temps perdu de la séance. Il y a **deux** réglages sans rapport :

1. **Application** — *Outils → Paramètres → Intégration Secret Service* : autorise
   KeePassXC à **devenir** fournisseur.
2. **Base de données** — *Paramètres de la base de données → Intégration Secret Service* :
   désigne le **groupe exposé**.

Avec seulement le premier, KeePassXC **détient bien le nom D-Bus** — tout a l'air correct
côté système — mais ne sert aucune collection. Le symptôme est trompeur : une fenêtre
« Déverrouiller la base de données KeePassXC » **qui ne dit pas de quelle base il s'agit**,
alors qu'une base est déjà ouverte.

### La confirmation d'accès est rédhibitoire pour un service

FdoSecrets peut demander confirmation à chaque lecture d'entrée. Tant que l'option est
active, `secret-tool` renvoie `Retour d'erreur avec un corps vide` si la fenêtre n'est pas
validée — et **un montage déclenché par une unité systemd ne peut par construction pas
cliquer**. À désactiver, ce qui revient à accepter que tout programme de la session lise
les entrées exposées, comme le faisait `gnome-keyring`.

### KeePassXC lâche le nom D-Bus, et gnome-keyring reprend la main

**Le mode d'échec principal, observé deux fois.** Dès qu'aucune base exposée n'est
déverrouillée — un clic sur « Fermer » suffit — KeePassXC **libère**
`org.freedesktop.secrets`. Le client suivant déclenche alors l'activation D-Bus de
`gnome-keyring`, qui reprend le nom.

Piège de lecture associé : la sortie de `secret-tool` ressemblait à un succès partiel alors
qu'elle venait de l'**ancien** fournisseur. Les indices qui ne trompent pas sont dans les
noms — préfixe `gkr:` et `schema = org.gnome.keyring.NetworkPassword`. **Vérifier qui
répond avant d'interpréter ce qui est répondu** (`busctl --user status org.freedesktop.secrets`).

### `gnome-keyring`, ce sont DEUX processus

```
5164  gnome-keyring-daemon --daemonize --login                       <- lancé par PAM
6137  gnome-keyring-daemon --start --foreground --components=secrets <- activé par D-Bus
```

Le second correspond mot pour mot à la ligne `Exec=` de
`/usr/share/dbus-1/services/org.freedesktop.secrets.service`. C'est le premier, celui de
PAM, qui **détient le nom**. Deux conséquences :

- la formule « `gnome-keyring` est activable par D-Bus à la demande », écrite dans le point
  ouvert du 03/09, est **incomplète** : les deux mécanismes coexistent, et c'est PAM qui
  gagne parce qu'il démarre avant l'ouverture de session ;
- **le tuer ne suffit pas à le faire rester mort.** Le fichier d'activation est toujours là ;
  au premier client qui demande le nom, D-Bus le relance. D'où la nécessité d'enchaîner
  vite et de vérifier le propriétaire à chaque étape.

Vérifier sans déclencher d'activation : `busctl --user list | grep secrets` interroge le bus
lui-même. `busctl --user status <nom>` sur un nom libre, en revanche, peut le réveiller.

### Friction confirmée : toutes les bases ouvertes doivent être déverrouillées

La recherche du 03/09 l'annonçait comme *rapportée*, c'est maintenant **vérifié** : une
seconde base simplement ouverte et verrouillée fait apparaître une demande de
déverrouillage à chaque recherche, parce que `SearchItems` balaie toutes les collections.
**Contrainte pour la configuration cible** : une seule base, ou ne pas rouvrir les autres
au démarrage — sinon le déverrouillage automatique au login ne suffira pas.

### Ce qui reste à faire

- **L'ordonnancement au login**, seul vrai sujet restant. Piste : `keepassxc.service` en
  `Type=dbus` + `BusName=org.freedesktop.secrets`, ce qui fait de « KeePassXC détient le
  nom » un contrat systemd, et `nas-infoadmin.service` en `After=`. Ne couvre pas
  « la base est déverrouillée » — systemd ne sait pas l'exprimer.
- **Retirer `gnome-keyring`**, ce qui emporte GDM (`gdm` → `gnome-keyring-pam` →
  `gnome-keyring`), donc installer `greetd` + `tuigreet`. Le greeter Noctalia est écarté :
  absent du paquet Fedora, à construire depuis les sources.
- **`keepassxc-unlock`** et son empreinte SHA512 du binaire, invalidée à chaque mise à jour
  du paquet.
- Rappel : le modèle de sécurité ne s'améliore pas tant que le disque n'est pas chiffré.
  Ce chantier se monte **à l'itération 02**, avec LUKS.

Un piège de shell rencontré au passage et consigné dans `CLAUDE.md` : un glob est développé
par le shell **appelant**, avant que `sudo` n'élève quoi que ce soit.

---

## 2026-09-03 — VM Windows d'administration : le poste de travail devient un axe

Premier outil ajouté au titre du **travail réel** et non de l'évaluation. Ça a
justifié d'ouvrir `poste/`, un troisième type de contenu dans le dépôt.

### Pourquoi un dossier de plus

`baseline/` est une photo figée : elle sert à comparer les distros entre elles, elle ne
doit jamais bouger. `journal.md` est daté et ne vaut que pour l'itération en cours.
Aucun des deux ne répond à la question qui va se poser à chaque bascule :

> qu'est-ce que je dois réinstaller et reconfigurer pour **retravailler** ?

D'où `poste/`, inventaire vivant, explicitement hors protocole de baseline. Il se
déroulera de haut en bas après une réinstallation. Une fiche par outil, toujours la même
structure : rôle, obtention, portabilité, ce qu'aucun `stow` ne restaurera, ce qu'il faut
sauvegarder.

### Donnée de comparaison : la virtualisation ne coûte rien sur Fedora Workstation

Avant d'installer quoi que ce soit, j'ai regardé ce qui était déjà là. Toute la pile est
présente — `qemu-kvm`, `libvirt` en démons modulaires activés par socket, OVMF/UEFI,
SPICE, `swtpm`, `qemu-guest-agent` — tirée par `gnome-boxes`, livré dans l'image
Workstation. `virtqemud.socket` était déjà actif.

**Seul `virt-manager` manquait**, 714 Ko. Boxes est bien là mais ne sait faire ni réseau
ponté ni gestion fine des snapshots, donc il ne suffisait pas.

C'est à noter comme donnée de comparaison à part entière : sur Debian ou openSUSE, cette
pile sera à installer et le temps est à chronométrer. Même logique que les dépôts tiers
de Fedora — une facilité qui appartient à la distro, pas au projet.

Recoupé dans `dnf history` : **transaction 11**, `dnf install virt-manager -y`,
**9 paquets**, horodatée `2026-09-03 07:57:12` — soit **09:57 locales**, le décalage UTC
habituel de ce fichier.

### Protected Users n'est pas une option de sécurité, c'est une contrainte d'architecture

Le compte utilisé pour l'administration est membre de **Protected Users**. Ça a dicté
toute la configuration de la VM, pas seulement des précautions :

| Contrainte | Ce que ça impose |
|---|---|
| NTLM, RC4, DES refusés → Kerberos seul | **FQDN toujours, IP jamais** : une IP ne permet pas de construire le SPN et fait retomber sur NTLM, bloqué |
| Pas de cache d'identifiants | Un DC joignable à chaque connexion, aucune session hors ligne |
| TGT de 4 h non renouvelable | Ré-authentification en journée : normal, pas une dérive |
| Pas de délégation | Tout « double saut » échouera |
| Horloge synchrone < 5 min | **Piège propre aux VM** : une VM suspendue dérive au réveil |

Deux conséquences en cascade : la VM **doit** être jointe au domaine (depuis un groupe de
travail, `mstsc` retombe sur NTLM pour la NLA), et donc le réseau doit être **ponté** et
non NAT.

Ce que ça apprend au-delà du cas : une contrainte d'annuaire peut décider de la topologie
réseau d'une machine. Je ne l'aurais pas deviné en partant du réseau.

### Le pont br0 — deux paramètres seulement, et un seul était vraiment utile

Le reste de la configuration est le strict minimum : `ipv4.method auto`, comme le profil
existant, tout venant du bail DHCP. Deux exceptions.

**`bridge.stp no`.** Un pont Linux avec STP actif *émet des BPDU*. Sur un port protégé par
BPDU guard, ça met le port en `err-disable` : réseau coupé, et la remise en service se
fait côté switch, pas côté poste. Mon collègue a préféré désactiver le STP côté pont
plutôt que toucher au port — c'est la bonne réponse, un pont de poste de travail est un
équipement terminal, il n'a rien à faire dans le spanning-tree. Bénéfice annexe constaté :
le port passe directement en `forwarding`, sans les ~30 s de `listening` + `learning`.

**`bridge.mac-address`** — et là je me suis fait avoir dans l'autre sens. Le raisonnement
était bon : un pont Linux prend la MAC la plus basse de ses ports, donc l'arrivée d'un
`vnetX` de VM pourrait changer la MAC du pont, donc le `dhcp_client_identifier`, donc le
bail : l'hôte changerait d'IP tout seul. Vérification au premier démarrage de la VM :
`vnet2` porte `fe:54:00:f8:62:8b`. **libvirt génère ses MAC de tap en `fe:` exprès**,
précisément pour rester au-dessus de n'importe quelle carte physique. Le problème est réel
dans l'absolu, mais l'outil le traite déjà. Le paramètre reste (il rend le comportement
déterministe quelle que soit l'origine du tap) mais ce n'est pas lui qui a sauvé la mise.

C'est exactement la leçon `SSH_AUTH_SOCK` de la semaine dernière : **avant de se féliciter
d'un correctif, vérifier si l'outil n'avait pas déjà traité le problème.**

### Un profil listé par nmcli n'est pas un profil enregistré

Premier script écrit : il désactivait « Connexion filaire 2 » pour la garder comme filet
de secours. Après un reboot, les profils avaient **changé d'UUID et de carte**.

```
/etc/NetworkManager/system-connections/   -> PROD.nmconnection        (persistant)
/run/NetworkManager/system-connections/   -> Connexion filaire 1, 2   (volatils)
```

Ce sont des profils **générés à la volée** par NetworkManager pour toute carte Ethernet
sans configuration enregistrée. Ils vivent dans `/run`, disparaissent au reboot, et
portent `autoconnect-priority: -999` — la valeur la plus basse, précisément pour que
n'importe quel profil réel les supplante.

Deux conséquences : mon filet de secours visait un fantôme, et il n'y avait rien à
désactiver non plus. Le retour arrière consiste à supprimer `br0` et `br0-port`,
NetworkManager régénère seul. Le script s'est simplifié.

Même famille que « un dépôt activé n'est pas un paquet installé » et « un paquet installé
n'est pas un paquet utilisé » : l'outil affiche l'état courant, pas ce qui est persistant.
**Vérifier d'où vient un objet avant de compter dessus** — ici `/etc` contre `/run`.

### Btrfs : `chattr +C` ne vaut que pour ce qui n'existe pas encore

`/` est en Btrfs avec copy-on-write, et une image de VM en CoW se fragmente
catastrophiquement. La parade est `chattr +C`, mais elle a une subtilité qui en fait un
vrai piège : **l'attribut ne s'applique qu'aux fichiers créés ensuite.** Posé sur un
fichier existant et non vide, il ne fait rien — pas d'erreur, pas d'effet.

Donc : le poser sur le **dossier**, **vide**, avant d'y mettre quoi que ce soit. J'ai
vérifié que le dossier était bien vide (`total 0`) avant, puis constaté l'héritage sur un
fichier réel plutôt que de le supposer :

```
$ lsattr /var/lib/libvirt/images/virtio-win-0.1.302.iso
---------------C------
```

Encore une commande qui réussit sans forcément faire quelque chose. Vérifier l'effet.

### SELinux : `mv` conserve l'étiquette, `cp` en hérite une

En déplaçant les deux ISO vers `/var/lib/libvirt/images`, je les ai retrouvées en
`user_home_t` dans un dossier `virt_image_t`. `qemu` étant confiné, il n'aurait pas pu les
lire — et le symptôme aurait été un « impossible d'ouvrir le disque » parfaitement opaque,
sans rapport apparent avec un déplacement de fichier.

```
$ sudo restorecon -Rv /var/lib/libvirt/images/
Relabeled ... from unconfined_u:object_r:user_home_t:s0
                to unconfined_u:object_r:virt_image_t:s0
```

Deux commandes qui « déplacent un fichier » et qui ne font pas la même chose vis-à-vis de
SELinux. `cp` aurait hérité du contexte de destination, `mv` non. À retenir pour toute
distro avec SELinux en `Enforcing` — donc pas pour toutes, ce qui en fait aussi une donnée
de comparaison.

### virt-manager : trois fois le même piège, le nom affiché ne décrit pas la chose

C'est la même famille que le cadre bleu « Claude Code » du 1er septembre.

**1. Il n'existe aucune option « Secure Boot ».** J'ai cherché une case à cocher, il n'y en
a pas : la liste des firmwares affiche des **chemins de fichiers**, et c'est le `.secboot.`
dans le chemin qui distingue. Pire, tant que le chipset est en i440FX, aucun firmware
`secboot` n'est proposé du tout — ce n'est pas caché, ça n'existe pas, le Secure Boot
exigeant le SMM que seul Q35 fournit. Ça se lit directement :

```
$ virsh domcapabilities --machine q35 --virttype kvm | sed -n '/<loader/,/<\/loader>/p'
```

Q35 propose `OVMF_CODE_4M.secboot.qcow2` et `<enum name='secure'><value>yes</value>`.
i440FX ne propose que `secure: no`.

**2. Il n'existe aucune catégorie « CD-ROM ».** Pour ajouter le second lecteur (celui des
pilotes virtio), c'est *Ajouter un matériel → Stockage*, puis *Type de périphérique →
Périphérique CD-ROM*. Aucun pool de stockage n'étant défini sur cette machine, le bouton
« Manage… » ouvre une liste vide : il faut passer par « Browse Local ».

**3. Le pilote de disque virtio-blk s'appelle « Red Hat VirtIO SCSI controller ».**
Vérifié dans les `.inf` de l'ISO plutôt que deviné :

| Fichier | Nom affiché | Périphériques PCI |
|---|---|---|
| `viostor` — virtio-**blk**, celui d'un disque `bus='virtio'` | « Red Hat VirtIO SCSI controller » | `DEV_1001`, `DEV_1042` |
| `vioscsi` — virtio-scsi | « Red Hat VirtIO SCSI **pass-through** controller » | `DEV_1004`, `DEV_1048` |

Il faut prendre celui **sans** « pass-through ». Chemin dans l'ISO : `\amd64\w11`.

### Vérifier le XML, pas l'interface

Une fois la VM créée, contrôle de ce qui a réellement été écrit :

```
machine='pc-q35-10.2'
<loader ... secure='yes' ...>/usr/share/edk2/ovmf/OVMF_CODE_4M.secboot.qcow2</loader>
<nvram template='.../OVMF_VARS_4M.secboot.qcow2'>
<smm state='on'/>
<tpm model='tpm-crb'><backend type='emulator' version='2.0'/>
<vcpu>8</vcpu>   currentMemory 8 Gio
disque virtio -> /var/lib/libvirt/images/win11.qcow2
<interface type='bridge'><source bridge='br0'/><model type='virtio'/>
```

Détail qui m'a fait croire un instant que la VM n'existait pas : **`virsh` sans `-c` vise
`qemu:///session` pour un utilisateur non-root**, où il n'y a rien, alors que la machine
tourne dans `qemu:///system`. La liste revient vide sans erreur. Toujours préciser
l'URI, ou poser `LIBVIRT_DEFAULT_URI`.

Le firmware est le **seul choix irréversible** de la création : il se fige avec la VM. Il
faut donc cocher « Personnaliser la configuration avant l'installation », sans quoi ni
firmware, ni TPM, ni bus VirtIO ne sont accessibles.

### Placement dans Sway : on désigne un espace, jamais une sortie

Je voulais la VM sur l'écran de droite. La bonne formulation était « sur le bureau 6 » :
l'affectation `workspace 6 output DP-1` existe déjà, donc les deux nomment le même
endroit, et une seule ligne fait foi. Si un câble change de prise, il n'y a que le bloc
`output` à corriger.

```
assign     [app_id="^virt-manager$"] workspace number 6
for_window [app_id="^virt-manager$"] focus
```

`assign` place la fenêtre dès sa création sans qu'elle apparaisse d'abord ailleurs ;
`for_window … focus` bascule l'affichage **et** le clavier. `assign` seul déposerait la
fenêtre sans y aller.

Critère `app_id` et non `class` : virt-manager est un client Wayland natif. Lu dans
`swaymsg -t get_tree` plutôt que supposé — le `.desktop` ne déclare pas de
`StartupWMClass`, il n'y avait donc aucun moyen de le deviner.

### Méthode : ne pas laisser déduire l'architecture réseau

Point à garder pour la suite du projet. Une commande locale rapporte un **réglage**,
jamais un **rôle**. Deux adresses dans `IP4.DNS` disent « voici les résolveurs
configurés » — ce sont chez nous des serveurs de cache DNS, pas des contrôleurs de
domaine. De même un `/27` observé ne dit ni s'il y a du DHCP, ni si une adresse est libre.

La fiche `poste/` liste donc les **questions à poser** à l'équipe plutôt que des réponses
inventées : adressage de la VM, VLAN d'administration éventuel, contrainte de port
(802.1X, port security), résolveurs à utiliser.

### Une note de piège se re-teste

En vérifiant le push, constat annexe : le piège de `CLAUDE.md` disant que l'agent
automatisé n'a pas `SSH_AUTH_SOCK` **était devenu faux**. Il l'a
(`/run/user/1000/gcr/ssh`), l'agent lui sert la clé, `git ls-remote` aboutit. C'est l'effet
de `gcr-ssh-agent.socket` + `sway-systemd/session.sh`, corrigé le 1er septembre — la note
avait simplement pris du retard sur le correctif.

Le raisonnement restait juste, la prémisse ne l'était plus. **Une note de piège qu'on ne
re-teste pas devient elle-même un piège.**

### L'agent invité, et une config invalide qui attendait son heure

Windows installé, guest tools posés, première série de mises à jour passée. Deux choses
se sont enchaînées et la seconde vaut mieux que la première.

**L'agent invité était installé sans être joignable.** `virtio-win-guest-tools.exe` pose
bien `qemu-ga` dans Windows, mais virt-manager n'avait créé aucun canal virtio-serial
`org.qemu.guest_agent.0` côté hôte. L'agent tournait dans le vide : pas d'IP remontée, pas
d'arrêt propre, pas de gel du système de fichiers. Encore « un paquet installé n'est pas
un paquet utilisé », version tuyauterie.

**Et en ajoutant ce canal, la VM a refusé de démarrer :**

```
virtio-serial-bus: A port already exists by name com.redhat.spice.0
```

Deux canaux portaient déjà le même nom — un `spicevmc` et un `qemu-vdagent`, deux
implémentations concurrentes du presse-papiers. Le doublon **existait avant** mon ajout,
et la VM tournait quand même. Elle vivait sur la définition qu'elle avait lue à son
démarrage ; celle sur disque avait divergé depuis sans que rien ne le signale.

C'est le piège « recharger une config ≠ repartir d'un état neuf » vu par l'autre bout :
là il s'agissait d'un rechargement qui n'appliquait pas tout, ici c'est **l'absence** de
rechargement qui masque une configuration déjà cassée.

> **Une configuration invalide n'échoue qu'au moment où elle est relue.** Après toute
> modification du XML d'une VM, seul un arrêt/démarrage **complet** est un test valable —
> un redémarrage invité ne relit rien côté hôte.

L'affichage étant en SPICE + QXL, c'est `spicevmc` qui va de pair avec le `spice-vdagent`
des guest tools ; `qemu-vdagent` a été retiré.

#### Ce que ça débloque, et la validation du pont

```console
$ virsh -c qemu:///system qemu-agent-command win11 '{"execute":"guest-ping"}'
{"return":{}}

$ virsh -c qemu:///system domifaddr win11 --source agent
 Ethernet   52:54:00:f8:62:8b   ipv4   10.11.65.29/27
```

**C'est la validation de bout en bout du pont.** L'hôte est en `10.11.65.1/27`, la VM en
`10.11.65.29/27` : même sous-réseau, même serveur DHCP, même domaine de recherche. Elle
est une machine de plus sur le LAN, ce qui était toute la raison de préférer le pont au
NAT — sans ça, la jointure au domaine et Kerberos n'avaient aucune chance.

### Mattermost en Flatpak — et une règle du dépôt prise en défaut

Deuxième outil du poste ajouté aujourd'hui : la messagerie interne de l'entreprise.
Installé en **Flatpak délibérément**, pas faute de mieux — le même paquet s'installera à
l'identique sur la distro suivante, quelle qu'elle soit. Coût de bascule nul.

**Effet de bord sur la méthode de comparaison :** un outil livré en Flatpak sort de fait
du périmètre de comparaison des distros, puisqu'il s'y comporte pareil. Ce qui reste
comparable, c'est ce qui l'entoure : Flatpak est-il présent, Flathub configuré, et
l'intégration au bureau suit-elle.

#### `dnf history` ne fait plus foi à lui seul

J'ai cherché Mattermost dans `dnf history` : rien. C'est normal, mais ça invalide une
règle que j'avais écrite dans `CLAUDE.md` comme si elle était absolue. L'historique d'un
Flatpak est ailleurs :

```console
$ flatpak history --columns=time,change,application,branch
sept.  3 12:12:47	deploy install	com.mattermost.Desktop	stable
```

**Depuis aujourd'hui, aucune source unique ne dit ce qui est installé sur la machine.**
Il faut interroger les deux. Et pendant que j'y étais, un second écart :

| Historique | Fuseau | Aujourd'hui |
|---|---|---|
| `dnf history` | **UTC** | `07:57:12` pour 09:57 locales |
| `flatpak history` | **heure locale** | `12:12:47` pour 12:12 locales |

Deux historiques de la même machine, pas dans le même fuseau. Le piège UTC du 1er
septembre était donc à moitié faux lui aussi : il vaut pour `dnf`, pas pour `flatpak`.

`bin/snapshot.sh` couvre déjà les deux — il produit un `flatpaks.txt`. S'il est absent de
la baseline du 28 août, c'est parce qu'il était **vide** et que le script termine par
`find "$OUT" -type f -empty -delete`. Rien à corriger dans l'outil, et le prochain
snapshot en produira un vrai.

#### Le prix d'entrée d'un Flatpak, mesuré

| Composant | Taille |
|---|---|
| `com.mattermost.Desktop` | 357,3 Mo |
| `org.freedesktop.Platform` 25.08 | 659,9 Mo |
| `GL.default` ×2 (25.08 et 25.08-extra) | 914,1 Mo |
| `VAAPI.Intel` + `codecs-extra` | 89,7 Mo |
| **Total** | **≈ 2,0 Go** |

Une application de 357 Mo a coûté 2 Go. C'est le **runtime**, payé une seule fois : les
Flatpaks suivants qui partagent `org.freedesktop.Platform 25.08` ne coûteront que leur
propre taille. À citer honnêtement dans les deux sens — c'est cher au premier, gratuit
ensuite, et ça compte sur un SSD de 233 Go.

#### Point pour l'axe « bureaux » : Wayland natif, et le tray marche

Le manifeste Flatpak demande **les deux** permissions, `wayland` et `x11` : il ne tranche
rien, et beaucoup d'applications Electron retombent sur XWayland faute de
`--ozone-platform=wayland`. Seule la fenêtre ouverte répond :

```console
$ swaymsg -t get_tree | grep -E '"(app_id|class)"'
app_id : com.mattermost.Desktop
class  : None
```

**Wayland natif**, aucune `class` X11 — Xwayland tourne bien sur la session mais
Mattermost ne passe pas par lui. Aucun défaut d'affichage à l'usage. Une permission
déclarée dit ce qui est *possible*, pas ce qui est *utilisé* : à revérifier pour chaque
application ajoutée au poste.

Le repli dans la zone de notification fonctionne aussi, et c'est le mode de travail que
j'ai choisi. Le service qui le permet, vérifié sur le bus plutôt que supposé :

```console
$ busctl --user list | grep StatusNotifier
org.kde.StatusNotifierWatcher   9051   noctalia   jzielona
```

**C'est Noctalia qui l'expose**, pas Sway. Un WM tuilant nu n'en fournit aucun : sans le
shell, une application qui se replie dans la barre serait simplement introuvable. Bon
argument pour la combinaison retenue — le compositeur tuile, le shell fournit les services
de bureau que les applications attendent.

Le lanceur passe aussi `--enable-features=WebRTCPipeWireCapturer`, donc la capture passe
par PipeWire et les portails : le partage d'écran est prévu pour Wayland. À confirmer en
visio réelle, c'est justement une des frictions Wayland à évaluer.

### Instantanés Btrfs — et un garde-fou que j'avais écrit faux

Constat de départ : **rien ne sauvegarde le système.** `bin/snapshot.sh` porte un nom
trompeur de ce point de vue — il capture une *description* du système pour comparer les
distros, il ne restaure aucune donnée.

Trois besoins distincts, qu'il fallait séparer avant de choisir quoi que ce soit :

| Besoin | Réponse | État |
|---|---|---|
| Annuler une bêtise, une mise à jour ratée | Instantanés Btrfs, sur le même disque | traité aujourd'hui |
| Survivre à une panne ou au wipe | Copie **hors machine** | **toujours rien** |
| Reconstruire un poste opérationnel | Le dépôt + `poste/` | déjà fait |

Décision assumée : **instantanés locaux seulement**. Ils vivent sur le disque qu'ils
protègent et ne survivent ni à une panne du boîtier USB ni à la bascule suivante. Le
risque est cohérent tant que le Windows interne sert de secours — mais il faudra rouvrir
le sujet le jour où ce Windows sera formaté.

#### Ce que Fedora ne fournit PAS, et qu'il valait mieux savoir avant

- **`grub-btrfs` n'est pas dans les dépôts** : pas d'entrée GRUB pour démarrer sur un
  instantané. Si `/` ne boote plus, la restauration est manuelle.
- **Aucun greffon snapper pour dnf5.** `python3-dnf-plugin-snapper` existe mais vise
  dnf4 ; le système utilise dnf5. Donc pas d'instantané automatique avant/après
  transaction — c'est un geste manuel.
- **Timeshift est éliminé par sa propre description** : « supported only on BTRFS systems
  having an Ubuntu-type subvolume layout (with @ and @home subvolumes) ». Fedora nomme ses
  sous-volumes `root` et `home`. Il retomberait en mode rsync, c'est-à-dire des copies
  complètes — exactement ce qu'on veut éviter quand le système de fichiers sait faire des
  instantanés gratuits.

Le scénario « la mise à jour casse, je reboote sur l'instantané d'avant » qu'on associe à
openSUSE **n'est donc pas livré clé en main ici**. Ce qui marche sans effort : l'instantané
manuel avant opération risquée, et la récupération de fichiers.

#### Le prérequis : sortir le disque de la VM

`/var/lib/libvirt/images` est devenu un **sous-volume Btrfs**. Un sous-volume n'entre
jamais dans l'instantané de son parent, ce qui règle deux problèmes :

1. **Le `chattr +C` du matin aurait été annulé en pratique** — un instantané force le
   copy-on-write à revenir : la première écriture après doit recopier.
2. **L'espace aurait explosé** — chaque instantané quotidien retenant les anciens blocs du
   qcow2 à mesure que Windows écrit.

Vérifié après coup : le dossier existe dans l'instantané et contient **0 entrée**.

#### Le garde-fou faux — fichiers creux

Le script s'est arrêté net au premier essai :

```
taille apparente : 109G
ARRÊT : espace insuffisant (il en faut le double le temps de la copie)
```

J'avais mesuré avec `du -sb`, qui donne la taille **apparente**. Or un qcow2 est un fichier
**creux** : 100 Go annoncés pour 31 Go réellement occupés. Le besoin réel tenait
largement dans les 190 Go libres.

Deux corrections, et **la seconde était plus grave que la première** :

- `du -s --block-size=1` au lieu de `du -sb`, pour mesurer l'occupation réelle ;
- `cp --sparse=always`, car rien ne garantissait que la copie reproduise les trous. Sans
  ça, la copie aurait occupé ses **100 Go pleins** — sans erreur, sans avertissement. Elle
  serait passée, et le disque se serait rempli aux trois quarts pour rien.

> **La taille d'un fichier n'est pas son occupation disque**, et un outil qui copie un
> fichier creux doit être *explicitement* chargé de préserver les trous.

Ajout d'une étape de contrôle qui compare l'occupation réelle des deux côtés après la
copie, plutôt que de supposer que ça s'est bien passé.

À noter au passage : la tentation immédiate était de supprimer la VM et de la redéployer.
Ça aurait coûté la réinstallation de Windows, les mises à jour, les guest tools, le canal
de l'agent et la jointure au domaine — **pour un `du` mal choisi**. Vérifier la mesure
avant de renoncer à l'objet mesuré.

#### `restorecon` qui refuse, et qui a raison

Après la copie, deux messages :

```
Win11_25H2_French_x64_v2.iso not reset as customized by admin to ...virt_content_t
```

`virt_content_t` figure dans `/etc/selinux/targeted/contexts/customizable_types` :
**`restorecon` refuse délibérément de réinitialiser ces types-là**, parce qu'ils sont posés
intentionnellement par une application ou un administrateur. C'est libvirt qui avait
étiqueté les ISO ainsi — le type dédié au contenu virtuel en **lecture seule**, exactement
ce qu'est une ISO montée en CD-ROM. Le `win11.qcow2`, disque **inscriptible**, est resté en
`virt_image_t`. Chaque fichier porte l'étiquette de son rôle, et un refus de `restorecon`
n'est pas forcément un échec.

#### La configuration retenue

Deux configurations, `root` et `home` : quotidien, rétention **7 jours**, plus un
garde-fou séparé de 10 instantanés manuels. `ALLOW_USERS` + `SYNC_ACL` pour s'en servir
sans `sudo`.

Deux détails à ne pas mal lire plus tard :

- **Le « quotidien » fonctionne par soustraction** : le minuteur crée un instantané toutes
  les heures, le nettoyage ne garde que le premier de chaque journée. Les voir disparaître
  est normal.
- **Instantanier `/` et `/home` ne veut pas dire les restaurer ensemble.** Un `dnf update`
  n'écrit jamais dans `/home` — restaurer `/` seul suffit à défaire la mise à jour. Le
  `/home` sert à récupérer *chirurgicalement* la config d'une application qui aurait migré
  son format, pas à tout annuler. Restaurer `/home` en entier écraserait le travail de la
  journée.

### `snapshot.sh` écrasait la baseline, et j'ai failli le laisser faire

Le point ouvert de `CLAUDE.md` disait « **Snapshot à relancer** après quelques jours
d'usage de Sway ». Je l'ai relancé. Il a écrit dans `baseline/`.

`bin/snapshot.sh` ligne 25 : `OUT="$ITER/baseline"`, sans le moindre garde-fou. Or
`baseline/` est la **photo figée de l'installation vierge**, la référence qui sert à
comparer les distributions entre elles. Le point ouvert du fichier de mémoire invitait
donc, littéralement, à détruire la référence.

L'en-tête du script portait la contradiction depuis l'origine :

> « À lancer au début d'une itération (**état initial**) et juste avant la bascule
> (**état final**) »

Deux captures annoncées, une seule destination.

Rien n'a été perdu — `baseline/` est commitée depuis l'init, et la capture du jour a été
mise de côté **avant** la restauration. Mais le filet, c'était git, pas le script. Si
j'avais commité par-dessus sans regarder, la référence de l'itération 01 disparaissait.

#### Le correctif

- `baseline/` : écrite **une seule fois**. Le script refuse de l'écraser et explique quoi
  faire à la place.
- `etats/<AAAA-MM-JJ>/` : destination automatique dès que la baseline existe.
- En fin d'exécution, l'écart de paquets avec la baseline est affiché.

Ce dernier point est ce qui rend la relance enfin **utile** — l'information n'existait
nulle part jusqu'ici. Première capture datée, 19 paquets au-delà du protocole :

```
+ sway swaybg swayidle swaylock waybar xdg-desktop-portal-wlr
+ foot dunst grim slurp xorg-x11-server-Xwayland
+ noctalia
+ rustdeskadmin virt-manager snapper stow
+ chromium tuned-ppd tuned-switcher
```

Trois lignes restent à expliquer : **chromium**, **tuned-ppd** et **tuned-switcher**
n'apparaissent dans aucune transaction `dnf` examinée aujourd'hui. Probablement des
dépendances promues en « installé explicitement » par une mise à jour — à confirmer, ce
serait une donnée de comparaison intéressante.

> **Un script qui écrit là où il ne faut pas ne le dit jamais.** Il réussit, il affiche
> « fichiers écrits », et c'est git qui rattrape — s'il y a un git, et si on regarde. La
> destination d'une commande destructive mérite autant d'attention que son contenu.

### WinBox — et deux Flatpaks qui ne s'installent pas au même endroit

WinBox 4.3 installé en Flatpak pour l'administration des routeurs MikroTik. Troisième
outil du poste, et **1,6 Mo** : le runtime était déjà là depuis Mattermost. C'est la
démonstration directe de ce qui était noté ce matin — le premier Flatpak coûte ~2 Go, les
suivants ne coûtent que leur taille.

Deux constats en le documentant.

**Les deux applications ne sont pas installées au même endroit :**

```
com.mattermost.Desktop   system   -> /var/lib/flatpak
com.mikrotik.WinBox      user     -> ~/.local/share/flatpak
```

Une portée `user` vit dans `$HOME` — donc capturée par les instantanés `/home` — là où une
portée `system` vit sous `/`. Et « réinstaller à l'identique » après une bascule suppose de
savoir laquelle. `snapshot.sh` enregistre désormais cette colonne ; elle manquait.

Piste écartée en cours de route : j'ai d'abord cru à un **Flathub filtré** côté Fedora,
puisqu'un dépôt avait été ajouté juste avant l'installation. Vérification faite, le
fichier de filtre dit `# Unfiltered`, les deux dépôts exposent 5911 applications et WinBox
était bien visible du système. Le dépôt ajouté était simplement le flathub **utilisateur**.
Une explication plausible n'est pas une explication vérifiée.

**WinBox tourne sur XWayland, pas en Wayland natif :**

```
sockets=x11;
QT_QPA_PLATFORM=xcb
```

Contrairement à Mattermost. À garder en tête pour l'axe « bureaux » : mise à l'échelle,
presse-papiers et capture suivent des chemins différents sous XWayland. Si une friction
apparaît sur cette application, ne pas l'imputer à Sway avant d'avoir vérifié quel chemin
elle emprunte — le piège de méthode déjà noté le 1er septembre avec `gio mount`.

### Les trois paquets mystères, et un piège de méthode qu'ils révèlent

La capture datée montrait 19 paquets « ajoutés » depuis la baseline, dont trois
inexpliqués. Tous élucidés, et le troisième vaut mieux que les deux autres.

- **`chromium`** — transaction 13, 14:07. Moi. Passage à Chromium par habitude, pas pour
  une contrainte technique. Désinstallation de Firefox envisagée, pas décidée.
- **`tuned-switcher`** — transaction 8, venu avec le groupe `swaywm`, raison `Group`.
- **`tuned-ppd`** — installé le **22 avril**, c'est-à-dire à la **fabrication de l'ISO**.
  Il était donc déjà là le 28 août, au moment de la baseline. Mais il n'y figurait pas.

#### Un paquet listé n'est pas un paquet ajouté

`tuned-ppd` est **paquet par défaut du groupe `swaywm`** — la définition du groupe le dit :

```
Default packages : dunst foot grim polkit slurp tuned-ppd tuned-switcher
                   waybar xdg-desktop-portal-wlr xorg-x11-server-Xwayland
```

En installant le groupe, la transaction 8 a fait passer sa **raison** de `Dependency` à
`Group`. Le paquet n'a pas bougé d'un octet ; c'est son étiquette qui a bougé.

```console
$ dnf repoquery --installed --qf '%{name} -> %{reason}\n' tuned tuned-ppd chromium
tuned      -> Dependency
tuned-ppd  -> Group
chromium   -> User
```

Or `packages-explicit.txt` est construit sur `dnf repoquery --userinstalled`, qui inclut
`Group` et exclut `Dependency`. **La liste n'est donc pas stable dans le temps** : un
paquet peut y entrer sans avoir été installé.

Conséquence directe : mon « 19 paquets ajoutés » de tout à l'heure était **faux**. C'est
19 lignes de différence dans une liste, ce qui n'est pas la même chose — et le même piège
frappera la comparaison entre distributions, qui est l'objet du lab.

> Même famille que « un dépôt activé n'est pas un paquet installé » et « un paquet installé
> n'est pas un paquet utilisé ». Le suivant : **un paquet listé n'est pas un paquet
> ajouté.** Une liste d'installations explicites dit ce qui a été *voulu*, pas ce qui est
> *arrivé* — pour la seconde question il faut la liste complète des paquets installés.

### Ce que l'installation finale devra vraiment contenir

Question posée en cours de journée : l'itération 01 a suivi GNOME complet → Sway →
Noctalia ; peut-on aller directement à la cible sans poser tout GNOME ?

Il fallait d'abord lever une confusion — la mienne. Cette machine est un **lab**, où
l'accumulation est volontaire ; **l'installation finale est un autre moment**, épuré. Ce
ne sont pas deux protocoles en conflit, ce sont deux étapes.

Mesures faites, la liste est courte :

- **GNOME Shell, Mutter, gnome-session et le reste : inutiles.** Rien n'en dépend une fois
  Sway et Noctalia en place.
- **`gnome-keyring`, `gvfs`, `gcr`, les portails : gardés.** Ce n'est pas GNOME le bureau,
  c'est de la plomberie freedesktop.
- **GDM est remplaçable.** Le journal du 1er septembre disait que le trousseau était
  déverrouillé « par PAM au login GDM ». Exact, mais l'important n'est pas GDM — ce sont
  trois lignes `pam_gnome_keyring.so` dans sa pile PAM, que n'importe quel greeter peut
  porter. `greetd` est packagé dans Fedora. **L'argument principal pour garder un bout de
  GNOME tombe.**
- **Nautilus s'installe seul** — vérifié : 89 exigences, toutes des bibliothèques
  (`gtk4`, `libadwaita`, `gvfs`, `gnome-autoar`…), **zéro** composant du bureau. Gardé
  dans la cible, il ne gêne pas.

Un greeter Noctalia existe — l'IPC le nomme (`greeter-sync`) — mais **il n'est pas dans le
paquet Fedora**. À récupérer en amont et à vérifier avant de compter dessus.

Piste notée sans être vérifiée : Nautilus n'est nécessaire que pour **une seule
opération**, écrire le mot de passe du NAS dans le trousseau. `secret-tool store` sait le
faire ; reste à savoir si `gvfsd` retrouve le secret sous le bon schéma. Si oui, la cible
n'a plus aucune application GNOME.

Et **Hyprland n'est pas dans les dépôts Fedora** — il faudra un COPR. Donnée de
comparaison en soi : Sway y est, avec un groupe dédié.

### État en fin de journée

- `virt-manager` installé, groupe `libvirt` effectif après reboot
- `/var/lib/libvirt/images` en `+C`, héritage vérifié
- Pont `br0` : STP coupé, MAC figée, même bail DHCP, profils persistants dans `/etc`
- `br_netfilter` non chargé — le point ouvert se referme, aucun `sysctl` à poser
- VM `win11` : Q35, Secure Boot, TPM 2.0, 8 vCPU, 8 Gio, disque virtio, pont `br0`
- Windows 11 25H2 installé, guest tools posés, premières mises à jour passées
- Agent invité joignable (`guest-ping` OK), VM en `10.11.65.29/27` sur le LAN
- Mattermost installé en Flatpak (Flathub), **Wayland natif**, tray Noctalia fonctionnel
- `poste/` : quatre fiches (VM Windows, Mattermost, instantanés Btrfs, WinBox) plus une
  note de décision « Cible pour l'installation finale »
- Chromium installé, passage depuis Firefox envisagé
- `bin/snapshot.sh` corrigé : la baseline ne peut plus être écrasée, captures datées
  dans `etats/<date>/`. Première capture : `etats/2026-09-03/`
- `/var/lib/libvirt/images` converti en sous-volume ; snapper configuré sur `/` et `/home`
- Toujours **aucune sauvegarde hors machine** — décision assumée, à rouvrir quand le
  Windows interne de secours sera formaté

Reste à faire : `virtio-win-guest-tools.exe` dès le bureau ouvert (sans lui, aucun pilote
réseau, donc pas de jointure possible), puis la jointure au domaine et le test Kerberos
par FQDN.

<!-- TODO : compléter le temps passé sur chaque étape — c'est la donnée qui manque ici. -->

---

## 2026-09-01 — Sway : un second bureau, le clavier qui saute, et l'accès au NAS

Première sortie du protocole de baseline, assumée. La baseline Fedora était déjà
capturée et poussée, donc ce qui suit est daté et traçable sans la polluer.

### Mise à jour du matin

`dnf update` (transaction 7, 09:50) — **111 paquets, aucun problème constaté**.
C'est une donnée, pas un non-événement : le critère « stabilité » de cette itération
se construit exactement comme ça, une mise à jour à la fois. La deuxième depuis
l'install, la deuxième sans casse.

### Pourquoi un gestionnaire de fenêtres

Le projet vise à choisir une distro **et** un environnement de travail. GNOME est le
défaut de Fedora, pas un choix — il fallait bien un comparatif. Un WM tuilant est le
bon premier pas : il ne remplace rien, il ajoute une session dans GDM, et il se retire
sans traces. Un bureau complet type KDE aurait tiré SDDM en concurrence de GDM.

**Sway plutôt que Hyprland, et le dépôt a tranché tout seul :**

```console
$ dnf info sway        →  sway 1.11-3.fc44, dépôt « fedora »
$ dnf list hyprland    →  Aucun paquet correspondant à lister
```

Hyprland aurait demandé un COPR tiers. Ajouter un dépôt non maintenu par Fedora sur
la machine de baseline pour découvrir le tuilant : mauvais rapport risque/bénéfice.
À reconsidérer plus tard si Sway convainc.

### Ce que « minimal » veut dire — transaction 8

`dnf group install swaywm` (10:01) — **38 paquets**. Le détail de `dnf history info 8`
vaut le détour, grâce à la colonne `Reason` :

- **14 en `Group`** : ce que j'ai demandé (`sway`, `swaybg`, `swayidle`, `swaylock`,
  `foot`, `waybar`, `dunst`, `grim`, `slurp`, `xdg-desktop-portal-wlr`…)
- **le reste en `Dependency` / `Weak Dependency`** : `wlroots` (le moteur de
  compositeur sous Sway), les dépendances de `waybar`, les polices FontAwesome

**Le WM « léger » coûte donc 2,7× ce qu'on croit demander.** Retenir la colonne
`Reason` : elle distingue une intention d'une conséquence, ce que la simple liste
des paquets installés ne dit pas.

Le groupe `swaywm` valait mieux que `dnf install sway` seul : ce dernier aurait donné
un WM sans terminal, sans lanceur, sans barre et sans outil de capture — c'est-à-dire
un écran noir dont on ne sait pas sortir.

### Le vrai enseignement : trois piles clavier qui ne se parlent pas

En arrivant sur Sway, le clavier serait passé en **US QWERTY**. Repéré avant de me
connecter, en croisant trois vérifications :

```console
$ cat /etc/X11/xorg.conf.d/00-keyboard.conf
# Written by systemd-localed(8), read by systemd-localed and Xorg.
        Option "XkbLayout" "fr"
        Option "XkbVariant" "azerty"

$ grep -rl XKB_DEFAULT_LAYOUT /etc/environment /etc/environment.d/ ...
(rien)

$ grep -iE "xkb|input" /etc/sway/config
(rien)
```

Le système *sait* que je suis en AZERTY — mais chaque environnement l'apprend par un
canal différent, et aucun n'est partagé :

| Pile | Source lue |
|---|---|
| Xorg | `/etc/X11/xorg.conf.d/00-keyboard.conf` |
| GNOME | `gsettings` → `[('xkb', 'fr+azerty')]` |
| Sway / wlroots | `XKB_DEFAULT_LAYOUT`, ou sa propre section `input` — sinon **`us`** |

L'en-tête du fichier Xorg le dit lui-même : *« read by systemd-localed and Xorg »*.
Sway est Wayland, il ne le lit jamais.

**Leçon, et c'est la même que celle des dépôts tiers, vue sous un autre angle :
un fichier de configuration présent dans `/etc` n'est pas un fichier lu par tout
le monde.** Avant de conclure qu'un réglage est « fait au niveau système », vérifier
*qui* le lit. Le corollaire pratique : ce sera à refaire sur chaque distro où je
testerai un compositeur Wayland — ce n'est pas un défaut de Fedora.

Temps perdu : zéro, parce que le problème a été vu avant. Il aurait coûté un bon
quart d'heure de tâtonnement à taper des commandes en QWERTY sans le savoir.

### Config Sway versionnée — et le piège du `include`

Config posée en paquet Stow : `dotfiles/sway/.config/sway/config`, deux réglages
seulement (`include` + section `input`).

Le `include /etc/sway/config` n'est pas cosmétique : **dès que `~/.config/sway/config`
existe, Sway ignore `/etc/sway/config` entièrement, il ne fusionne pas.** Sans cette
ligne, tous les raccourcis par défaut disparaissaient d'un coup. À ne pas confondre
avec `/etc/sway/config.d/`, qui lui est bien fusionné — mais qui appartient à root et
ne peut donc pas vivre dans le dépôt.

### Tree folding, vu dans l'autre sens

```
LINK: .config/sway => ../linux/dotfiles/sway/.config/sway
```

Stow pose toujours le lien **le plus haut possible**. Pour `bash` il avait pu prendre
`~/.bashrc.d` en entier ; ici il s'arrête à `~/.config/sway` parce que `~/.config`
existait déjà avec 15 entrées à GNOME — impossible de monter plus haut sans les
écraser. Même mécanisme, résultat différent selon l'état de la cible.

Conséquence identique en revanche : `~/.config/sway/` **est** le dépôt. Tout fichier
déposé dedans sera versionné — jamais de secret là-dedans.

### Vérification finale

```console
$ swaymsg -t get_inputs | grep xkb_active_layout_name
    "xkb_active_layout_name": "French (AZERTY)"     (sur chaque périphérique)
```

`input type:keyboard` s'applique à toute la **classe**, pas à un modèle nommé : un
clavier USB branché demain sera en AZERTY sans rien toucher. Effet de bord amusant,
les faux claviers (`Power Button`, `Video Bus`, `Dell WMI hotkeys`) sont listés aussi.

### Trois écrans : Sway ne sait pas ce qu'est un « écran principal »

Disposition à remettre d'aplomb — le grand 27" devait être au centre, il était à
gauche dans le plan virtuel. Deux notions manquantes côté Wayland, et c'est le
vrai apprentissage du sujet :

- **Pas de numérotation d'écrans.** Sway ne connaît que des *sorties* nommées
  (`DP-3`, `HDMI-A-2`, `DP-1`) placées par **coordonnées en pixels** dans un plan
  virtuel commun. « Écran 1 » n'existe nulle part : c'est la position X qui décide
  du bord par lequel la souris passe, et rien d'autre.
- **Pas d'écran principal.** `--primary` est une notion **X11/RandR** qui n'a pas
  d'équivalent Wayland. Ce qui s'en rapproche, c'est de décider où atterrissent les
  espaces de travail (`workspace 1 output DP-3`) : la session s'ouvre sur l'espace 1,
  donc sur cet écran-là.

Identification physique des dalles avec `swaynag -o <sortie> -m "<sortie>"` : un
bandeau nommé s'affiche sur chaque écran. Indispensable — les noms de sortie ne
disent rien de la place sur le bureau, et inverser deux écrans se paie en souris
qui part du mauvais côté.

**Le détail qui compte, l'alignement vertical.** Le central fait 1440 de haut, les
deux latéraux 1080. Collés à `y=0`, leurs bords hauts sont alignés et les petits
« pendent » de 360 px : la souris décroche en traversant. `(1440-1080)/2 = 180`
les centre verticalement. Testé, adopté — le passage est fluide.

```
   HDMI-A-2            DP-3              DP-1
   1920x1080         2560x1440         1920x1080
   ┌────────┐      ┌──────────────┐      ┌────────┐
   │ y=180  │      │     y=0      │      │ y=180  │
   └────────┘      └──────────────┘      └────────┘
   x=0             x=1920                x=4480
```

**Méthode de travail à réutiliser :** `swaymsg output ... position ...` applique
**immédiatement et ne persiste pas**. On essaie à chaud, on compare, et seulement
une fois convaincu on écrit dans la config. Un `Super+Maj+C` annule tout.
Et avant de recharger une config modifiée :

```console
$ sway --validate --config ~/.config/sway/config
```

Elle vérifie la syntaxe **sans appliquer** — de quoi ne pas se retrouver avec une
session cassée pour une accolade oubliée.

**Nommage par port, choix assumé.** La config utilise `DP-3`/`HDMI-A-2`/`DP-1`,
c'est-à-dire les **prises**. Un câble déplacé d'un port à l'autre rend le bloc faux.
L'alternative durable est l'identifiant `marque modèle série`
(`"Dell Inc. DELL P2725DE FVTKM84"`), qui suit la dalle et pas le connecteur — noté
en commentaire dans la config. Le branchement ne bougeant pas, le plus lisible a été
préféré, en connaissance de cause.

### Deux pièges de raccourcis, dont un vrai bug AZERTY

Première vraie session d'usage. Deux frictions, et les deux sont des mécanismes à
comprendre plutôt que des réglages à ajuster.

#### `bindsym` lie un symbole, pas une touche

Constaté à l'usage : `Super+Maj+&` **changeait d'espace de travail** au lieu d'y
envoyer la fenêtre. Autrement dit, « déplacer une fenêtre vers l'espace N » était
purement **inatteignable au clavier**.

La cause est dans le manuel, noir sur blanc :

> *Bindings to keysyms are layout-dependent. This can be changed with the
> `--to-code` flag.* — `man 5 sway`

`/etc/sway/config` écrit `bindsym $mod+1`, ce qui lie le **symbole** `1`. Sur AZERTY,
ce symbole n'existe qu'avec `Maj` (la touche donne `&` sans). Donc `Super+Maj+&`
produit bien le symbole `1`, et déclenche la liaison **sans**-Maj — celle qui change
d'espace. Pour atteindre `$mod+Shift+1` il faudrait un *second* `Maj`. Il n'y en a pas.

Correctif : `bindsym --to-code`, qui traduit le symbole en **code de touche physique**
dans la première disposition configurée. C'est alors la touche qui compte, plus le
caractère qu'elle produit.

> **CORRECTION, fin de journée — ce correctif était faux.** `--to-code` traduit bien le
> symbole en code, mais **sans retirer le `Maj` que ce symbole exige** : `$mod+1` et
> `$mod+Shift+1` se retrouvaient tous deux sur `$mod+Shift+AE01`, et la première liaison
> inscrite gagnait. Le bug n'était pas résolu, il était **déplacé**. La bonne réponse est
> `bindcode` (codes `10`–`19`) — voir « Le point ouvert des chiffres, soldé » plus bas.

Détail qui a son importance : les anciennes liaisons ont été retirées à l'`unbindsym`
plutôt que simplement redéfinies. Une liaison par symbole et une liaison par code sont
**deux objets distincts** pour Sway ; les deux auraient coexisté et se seraient marché
dessus.

**Portée du problème :** ce n'est ni un défaut de Fedora ni de Sway, c'est la rencontre
entre une config écrite pour QWERTY et un clavier AZERTY. Le même piège attend sur i3,
Hyprland, et toute config de WM tuilant récupérée sur Internet. À vérifier
systématiquement : *ce raccourci lie-t-il un caractère ou une touche ?*

#### Une affectation d'espace ne vaut qu'à la création

Après avoir écrit `workspace 2 output DP-3` et rechargé, l'espace 2 restait obstinément
sur l'écran de gauche. Réflexe d'abord : « j'ai dû me tromper de manip ». Non.

`workspace <n> output <sortie>` s'applique **au moment où l'espace est créé**. Les
espaces 1 et 2 avaient été créés automatiquement au démarrage de la session — Sway en
ouvre un par écran — donc *avant* que la règle n'existe. `swaymsg reload` prend bien la
règle pour la suite, mais ne **déplace pas** ce qui est déjà là.

Deux sorties : relancer la session, ou déplacer à la main.

```console
$ swaymsg 'workspace number 2; move workspace to output DP-3'
```

**Leçon générale, et c'est la troisième fois de la journée que je la croise :**
recharger une configuration n'est pas la même chose que repartir d'un état neuf.
Certaines directives décrivent un *état* (`output ... position`, appliqué
immédiatement), d'autres une *règle appliquée à un événement futur*
(`workspace ... output`, appliqué à la création). Confondre les deux fait douter de
sa propre manipulation.

#### Réglages retenus

- **Flèches = déplacer la fenêtre**, `h/j/k/l` = déplacer le focus. Les flèches
  faisaient doublon avec `hjkl` sur le focus ; déplacer une fenêtre est le geste le
  plus fréquent, il méritait les touches les plus évidentes.
- **Une colonne d'écran par position dans la rangée de chiffres** : `1 4 7 10` à
  gauche, `2 5 8` au centre, `3 6 9` à droite. La rangée du clavier reproduit la
  disposition du bureau — `Super+&` part à gauche, `Super+é` au centre, `Super+"` à
  droite. Plus rien à mémoriser.
- **Pas besoin de `move container to output`.** Avec des espaces épinglés à des
  sorties, envoyer une fenêtre sur l'espace 4 l'envoie *de fait* sur l'écran de
  gauche. Le raccourci « déplacer vers l'écran voisin » devient superflu — une
  bonne répartition remplace une famille entière de raccourcis.
- `exec swaymsg workspace number 2` pour démarrer au centre, l'espace 1 étant
  désormais à gauche. C'est ce qui tient lieu d'« écran principal ».

### Accès au NAS de l'alternance — trois façons de garder un mot de passe

Le NAS `pdc-nas-info` contient mon travail d'alternance : sans accès, je ne travaille
pas. Il fallait donc un montage automatique. Contrainte que je me suis fixée : **pas de
mot de passe en clair sur le disque**, d'autant que ce disque n'est pas chiffré.

Ces deux exigences se sont révélées **incompatibles telles quelles**, et c'est le vrai
enseignement de la journée.

#### Un montage système ne peut pas interroger un trousseau

`mount.cifs` ne sait lire qu'un fichier ou une variable d'environnement. Aucun hook,
aucun rappel vers un gestionnaire de secrets. Ce n'est pas une lacune de configuration :
un montage déclaré dans `/etc/fstab` s'exécute **en root, avant mon login**, à un moment
où ni le bus de session ni le trousseau déverrouillé n'existent. Il n'y a rien à
appeler.

Donc : « monté par le système » et « secret dans un trousseau de session » ne peuvent
pas aller ensemble. Il faut lâcher l'un des deux. J'ai lâché « système » — le montage se
fait maintenant dans ma session, au login.

À retenir plus largement : **avant de chercher comment brancher deux composants,
vérifier qu'ils sont éveillés au même moment.** C'est la même erreur de raisonnement que
pour le clavier — croire qu'un réglage est disponible partout parce qu'il existe.

#### Le trousseau fonctionne sous Sway, l'agent SSH non — et ce n'est pas contradictoire

J'aurais parié le contraire, vu le point ouvert sur `SSH_AUTH_SOCK`. Vérifié :

```
org.freedesktop.secrets   3714  gnome-keyring-d  jzielona  session-2.scope
```

Le trousseau répond, déverrouillé, en session Sway. Écriture et lecture testées.

Alors que les trois `/etc/xdg/autostart/gnome-keyring-*.desktop` portent bien
`OnlyShowIn=GNOME;Unity;MATE;` — Sway ne les lance pas. La contradiction n'est
qu'apparente : **deux composants du même paquet démarrent par deux mécanismes
différents.**

| Composant | Démarrage | Sous Sway |
|---|---|---|
| `ssh` | autostart XDG, filtré `OnlyShowIn` | absent → d'où `SSH_AUTH_SOCK` vide |
| `secrets` | activation **D-Bus** à la demande | présent |
| déverrouillage | **PAM** (`pam_gnome_keyring` dans `/etc/pam.d/gdm-password`) | fait au login GDM, quel que soit le bureau lancé ensuite |

Correction de ma règle précédente : « vérifier *qui* lit un réglage » ne suffit pas, il
faut aussi vérifier **par quel mécanisme un service démarre**. Un même paquet peut être
à moitié disponible.

#### `gio mount` ne sait pas écrire dans le trousseau — une heure perdue

Le montage en ligne de commande fonctionnait, mais le mot de passe n'était jamais
enregistré. J'ai d'abord cru rater l'invite `[0] Never, [1] Session, [2] Permanently` :
en réalité **elle ne m'a jamais été proposée**, et `gio mount --help` ne montre aucune
option de sauvegarde.

Le composant qui écrit dans `gnome-keyring`, c'est le **dialogue GTK**
(`GtkMountOperation`), celui de Nautilus — pas l'outil en ligne de commande. Un montage
depuis Nautilus, « se souvenir pour toujours », et l'entrée apparaît :

```
label = jzielona@pdc-nas-info.te-mgmt.io
schema = org.gnome.keyring.NetworkPassword
attribute.server = pdc-nas-info.te-mgmt.io
attribute.domain = /
```

Ensuite seulement, `gio mount` monte sans rien demander : il ne sait pas écrire dans le
trousseau, mais `gvfsd` sait y lire.

**Ce n'est pas un problème de Sway** — `gio mount` se comporterait pareil sous GNOME.
Piège de méthode : quand on teste deux choses nouvelles en même temps (un bureau et un
protocole), la tentation est d'imputer chaque friction à la nouveauté la plus visible.
Ici ça aurait pollué l'axe « bureaux » avec une limite d'outil qui n'a rien à y voir.

#### Nautilus sous Sway : dégradé mais utilisable

Lancé depuis Sway, Nautilus crache une série d'erreurs — `org.gnome.Mutter.ServiceChannel`
sans propriétaire, portail `Inhibit` absent, `Tracker3.Miner.Files` en échec — puis
s'ouvre et fonctionne. L'indexation et la recherche sont mortes, le reste marche.

Donnée pour l'axe « bureaux » : les applications GNOME ne sont pas binaires sous un
compositeur tiers. Elles perdent des morceaux sans le dire clairement. Pour un usage
ponctuel c'est acceptable ; en usage quotidien il faudra voir ce qui manque vraiment.

#### Ce qui a été retenu

Montage GVFS déclenché par une unité `systemd --user` accrochée à
`graphical-session.target` (paquet Stow `nas`). Le mot de passe reste dans le trousseau,
l'unité ne contient aucun secret.

**Découverte au passage, qui vaut au-delà du NAS :** `sway-session.target` *et*
`graphical-session.target` sont toutes les deux actives — Fedora fournit une vraie
intégration systemd pour Sway. Une unité utilisateur accrochée à `graphical-session.target`
se déclenche donc **sous GNOME comme sous Sway**, avec un seul fichier. C'est
probablement la bonne piste pour régler `SSH_AUTH_SOCK`, plutôt que
`~/.config/environment.d/`.

Détail attrapé au test : `ExecStop` échouait quand le partage était déjà démonté à la
main, laissant l'unité en `failed` sans raison. Corrigé par un `-` préfixé
(`ExecStop=-/usr/bin/gio ...`), qui dit à systemd d'ignorer l'échec de cette commande.
Une commande d'arrêt doit tolérer que le travail soit déjà fait.

#### Ce que ça change pour la procédure de bascule

Le trousseau (`~/.local/share/keyrings/`) est chiffré par le mot de passe de session :
**il ne se transporte pas** d'une installation à l'autre, et n'a rien à faire dans le
dépôt. Donc après chaque réinstallation, `stow nas` remet l'unité en place, mais il
faudra **réenregistrer le mot de passe une fois via Nautilus**.

Trente secondes — à condition de savoir que l'étape existe. Sinon c'est un quart d'heure
à se demander pourquoi le partage ne monte pas. Noté dans `dotfiles/README.md`.

#### Constat non résolu : le disque n'est pas chiffré

`lsblk` : pas de LUKS, `/etc/crypttab` absent. Le trousseau protège le mot de passe
contre les autres comptes de la machine, mais quelqu'un qui démarre sur une clé USB ou
repart avec le SSD accède à tout — y compris à `login.keyring`, dont le chiffrement ne
tient qu'à mon mot de passe de session.

Pour un poste qui porte des accès à l'infrastructure d'un employeur, c'est le vrai trou,
et ni GVFS ni le trousseau n'y changent quoi que ce soit. **Le chiffrement se décide au
moment de l'installation** : c'est donc une case à cocher à la prochaine bascule de
distro, pas quelque chose à rattraper aujourd'hui. À trancher avant l'itération 02.

### L'agent SSH sous Sway : un problème qui n'en était plus un

Point ouvert depuis quelques jours : `SSH_AUTH_SOCK` réputé non persistant sous Sway,
après un `git push` bloqué. En voulant le régler, j'ai découvert qu'il **était déjà
réglé** — et la façon dont je m'en suis rendu compte vaut plus que le correctif.

Le fichier qui fait le travail, `/usr/lib/systemd/user/gcr-ssh-agent.socket` :

```ini
ListenStream=%t/gcr/ssh
ExecStartPost=-/usr/bin/systemctl --user set-environment SSH_AUTH_SOCK=%t/gcr/ssh
[Install]
WantedBy=sockets.target
```

Il vient du paquet `gcr`, il est `WantedBy=sockets.target`, donc **relancé à chaque
session, quel que soit le bureau**. La variable n'est pas un résidu volatil : elle est
reposée à chaque login. Mon point ouvert décrivait l'état d'*avant* l'activation du
socket, et je ne l'avais pas relu depuis.

Vérification dans le terminal :

```
SSH_AUTH_SOCK = /run/user/1000/gcr/ssh
256 SHA256:VVStpM… jzielona@fedora (ED25519)
56fdced…  refs/heads/main
```

Tout répond. Rien à corriger.

#### Deux fausses pistes, et ce qu'elles apprennent

**J'ai d'abord soupçonné un conflit GNOME/Sway** — Sway installé par-dessus GNOME,
d'où un environnement bâtard qu'une install propre n'aurait pas. Faux : le socket `gcr`
ne dépend d'aucun bureau. Le vrai clivage est ailleurs, et il est plus intéressant :
**qui lance le compositeur.** GNOME est démarré par `systemd --user` et hérite donc de
`set-environment` ; Sway est lancé par GDM dans `session-2.scope` et n'en hérite pas.
Fedora comble l'écart avec `/etc/sway/config.d/10-systemd-session.conf`, qui lance
`sway-systemd/session.sh` pour propager l'environnement dans les deux sens.

Leçon : **avant d'écrire un contournement, vérifier si la distro n'a pas déjà traité le
problème.** J'allais versionner un correctif pour quelque chose que Fedora gère.

**Ensuite j'ai cru reproduire la panne en direct** : un `git fetch` échouait
(`Permission denied (publickey)`) avec `SSH_AUTH_SOCK` vide, pendant que le mien passait
dans le terminal. Mais c'était l'assistant qui échouait, pas la machine — il tourne dans
un bac à sable qui retire l'accès à l'agent SSH et interdit même la lecture de
`/proc/<pid>/environ`. Un outil automatisé n'est pas un témoin fiable de l'état du
système : **refaire la mesure dans un vrai terminal avant de conclure.**

C'est la deuxième fois de la journée que je manque d'attribuer une friction à la mauvaise
cause — après `gio mount` qu'il aurait été facile d'imputer à Sway. Le point commun :
tester deux choses nouvelles en même temps rend la nouveauté la plus visible
suspecte par défaut.

#### Ce que ça change pour l'axe « bureaux »

L'agent SSH, le trousseau et le dialogue de montage viennent **tous** de la pile GNOME
installée par la baseline. Sway s'appuie dessus sans le dire. Une install Sway seule
n'aurait pas ce problème — elle en aurait un autre : monter un agent SSH et un
gestionnaire de secrets à la main.

Ce n'est pas une réserve sur la validité du test : ce que je reproche à GNOME est son
**interface**, pas sa plomberie. `gnome-keyring`, `gvfs`, Nautilus me vont très bien et
resteront. « Sway par-dessus les utilitaires GNOME » est donc la configuration que je
vise, pas un artefact.

Ce que ça change quand même, pour les itérations suivantes : sur une distro qui ne livre
pas ces utilitaires aussi facilement que Fedora Workstation, le temps passé à les gréer
sera à chronométrer comme n'importe quelle autre friction. C'est une donnée de
comparaison entre distros, pas un doute sur l'axe bureaux.

### Noctalia remplace swaybar et wmenu — et une collision AZERTY de plus

Point de départ trivial : le menu de `Super+D` est illisible et minuscule. En cherchant
à le remplacer, j'ai découvert deux choses que je croyais savoir et qui étaient fausses.

**Ma barre n'était pas `waybar`.** Le paquet est installé — tiré par le groupe
`swaywm` — mais rien ne le lance. Ce que j'avais en haut de l'écran, c'était `swaybar`,
démarré par le bloc `bar { }` de `/etc/sway/config`, avec pour toute barre d'état :

```
status_command while date +'%Y-%m-%d %X'; do sleep 1; done
```

Une boucle shell qui affiche la date. Mon point ouvert « waybar laissée par défaut »
était faux depuis le début : **un paquet installé n'est pas un paquet utilisé**, variante
directe du piège « un dépôt activé n'est pas un paquet installé » du 28 août.

**Noctalia n'est pas un lanceur.** C'est un shell Wayland complet — barre, lanceur,
notifications, verrouillage, fond d'écran, réglages, 112 commandes IPC. Le confondre
avec un remplaçant de `wmenu` aurait mené à un chantier trois fois plus gros que prévu
sans que je l'aie décidé. Ici c'est ce que je voulais, mais il fallait le savoir avant.

Bonne surprise : **packagé dans Fedora officiel** (dépôt `updates`), pas un COPR.
`noctalia 5.0.0~beta.10`, 9 paquets, 45 Mo. C'est une **beta**, ce qui sur une machine
unique mérite d'être pesé — mais le risque est plus faible qu'il n'y paraît : Noctalia
n'est pas le compositeur. S'il tombe, Sway continue et je perds la barre, pas la session.
Une beta de shell et une beta de noyau ne se jugent pas pareil.

#### La méthode qui a payé : tout tester à chaud avant d'écrire

Démon lancé à la main, `swaymsg bar bar-0 mode invisible`, lanceur testé en IPC —
**rien d'écrit tant que ce n'était pas validé de visu**. Un redémarrage de session
suffisait à tout effacer en cas d'échec. Ça n'a rien coûté et ça évite de versionner
une configuration qu'on n'a jamais vue tourner.

Détail de config qui vaut d'être noté : la barre de `/etc/sway/config` **ne peut pas être
supprimée**, puisque le `include` ne se retire pas. Il faut la neutraliser par son
identifiant — que Sway génère seul et que `swaymsg -t get_bar_config` révèle (`bar-0`) :

```sway
bar bar-0 mode invisible
```

Sans ça, deux barres se superposent. Même logique que les `unbindsym` : le fichier
personnel n'efface pas la config système, il la surcharge.

#### `Super+Maj+-` muet : le piège symbole/code, vu par l'autre bout

Un seul raccourci ne répondait plus. Un seul — et c'est ce détail qui a donné la cause.

En fr-azerty : `key <AE06> { [ minus, 6, bar, fiveeighths ] }`. La touche « 6 » produit
`minus` **sans** Maj. Or `/etc/sway/config` lie le scratchpad à ce symbole :

```sway
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+minus scratchpad show
```

Mes `unbindsym $mod+6` / `$mod+Shift+6` n'y touchaient pas : **un symbole et un code sont
deux objets distincts**, et je n'avais retiré que le mauvais des deux. Deux liaisons se
disputaient la même touche physique.

Et c'est la **seule** collision possible : la rangée AZERTY produit `& é " ' ( - è _ ç à`,
et `minus` est le seul de ces symboles que Sway lie par défaut. Le symptôme « une seule
touche est muette » n'était donc pas une anomalie à côté du problème — c'était la
signature exacte de la cause. Une panne qui ne touche qu'un seul cas mérite qu'on cherche
ce que ce cas a d'unique avant de suspecter le hasard.

Correctif : `unbindsym $mod+minus` et `unbindsym $mod+Shift+minus`. Conséquence assumée,
le scratchpad n'a plus de raccourci — noté dans les points ouverts plutôt que réattribué
à la va-vite.

#### Ce que ça met au jour, et qui reste à traiter

En vérifiant, j'ai constaté que `Super+chiffre` ne fait **rien** et que
`Super+Maj+chiffre` va sur l'espace au lieu d'y envoyer la fenêtre. Les deux rôles sont
décalés d'un cran.

Hypothèse : `--to-code` traduit le keysym `1` en keycode, mais `1` est au **niveau 2** de
`AE01` en AZERTY — il exige déjà Maj — et Sway a pu conserver ce Maj dans la liaison.
`$mod+1` serait devenu `$mod+Shift+AE01`, et `$mod+Shift+1` demanderait deux Maj, donc
serait inatteignable. Ce serait exactement le bug d'origine, déplacé d'un rang.

Si ça se confirme, **mon correctif du 1er septembre n'a pas résolu le problème, il l'a
déplacé** — et l'entrée correspondante de ce journal est à corriger. À vérifier avec
`bindcode` et les codes physiques (`10` à `19`) plutôt qu'avec `--to-code`. Non bloquant,
mais c'est le genre de chose qu'on ne retrouve jamais si on ne l'écrit pas le jour même.

### Le cadre bleu « Claude Code » — chercher le pixel du bon côté

Un cadre bleu portant « Claude Code » sur chaque fenêtre, entre la barre Noctalia et
l'invite. J'ai d'abord cherché du côté de Claude Code. Mauvaise piste.

C'est la **barre de titre de Sway**. `swaymsg -t get_tree` le dit sans ambiguïté :

```
'foot'                border='normal'  bw=2  name='◐ Cadre bleu Claude Code…'
'org.mozilla.firefox' border='normal'  bw=2  name='Fedora Start | …'
```

`border=normal`, c'est le défaut de Sway : un liseré **plus** une barre de titre. Le
texte est écrit par l'application (Claude Code renomme le titre du terminal, Firefox y
met le nom de l'onglet), le bleu vient de `client.focused` (`#285577`) — jamais redéfini,
`/etc/sway/config` ne contient aucune directive `border`, `client.*` ni `font`.

Réglé en `default_border pixel 2` : le liseré reste (il indique le focus, indispensable
en tuilage sur trois écrans), la barre de titre disparaît.

**Ce que ça apprend :** le programme dont le nom s'affiche n'est pas celui qui dessine.
Même famille que « un paquet installé n'est pas un paquet utilisé » — avant de chercher
un réglage dans une application, vérifier qui peint réellement le pixel.

Deux détails de méthode au passage. `default_border` est une règle appliquée à la
**création** d'une fenêtre : un `reload` ne retouche pas les fenêtres ouvertes, il faut
un sélecteur (`swaymsg '[title=".*"] border pixel 2'`) pour voir l'effet tout de suite.
Et en disposition onglets ou piles, les titres reviennent forcément — c'est le principe
de ces dispositions, pas la bordure.

### Le fond d'écran : deux surfaces sur la même couche

Voulu supprimer le papier peint de Sway pour laisser Noctalia gérer le fond. Le premier
réflexe — recouvrir avec `output * bg #000000 solid_color` — a produit un bug bien plus
instructif que le réglage lui-même : **à la connexion c'était le fond Noctalia, mais au
moindre `swaymsg reload` Sway reprenait la main.**

La cause n'est pas une histoire de priorité. La directive `bg` ne fait pas dessiner Sway :
elle lui fait **lancer un processus `swaybg`** (`pgrep -a swaybg` le montre). Or swaybg et
Noctalia peignent tous deux sur la même couche layer-shell `background`, où c'est la
surface **la plus récemment créée** qui passe devant. À la connexion, Noctalia démarre
après swaybg et gagne. Au rechargement, Sway tue et relance swaybg : le nouveau devient
le plus récent et recouvre Noctalia.

Deux corrections écartées, vérifiées et pas supposées :

- swaybg transparent (`#00000000`) pour voir Noctalia au travers : Sway refuse l'alpha,
  `Colors should be of the form #RRGGBB`. `swaybg -c` non plus.
- retirer la directive : impossible, le `include` se surcharge et `bg none` n'existe pas.

J'ai donc essayé de tuer le processus : `exec_always pkill -x swaybg`. **Ça n'a pas
marché, et l'échec était trompeur** — la commande tuait bien quelque chose, mais
`exec_always` s'exécute *avant* que Sway ait fini d'appliquer la config des sorties.
Elle tuait l'ancien swaybg, et le nouveau — celui qui gêne — survivait. Il a fallu
`exec_always sh -c 'sleep 1; pkill -x swaybg'` pour que ça tienne.

**Ce que ça apprend :** une commande qui réussit n'est pas une commande qui fait ce qu'on
croit. `pkill` renvoyait un succès en frappant la mauvaise cible. Et une temporisation qui
marche reste un aveu : on ne sait pas *quand* l'autre composant agit, on parie.

### Sortir de l'`include` — Sway ne fait plus que du tuilage

Le `sleep 1` m'a décidé. Ce n'est pas propre d'attendre qu'un processus se lance pour le
tuer aussitôt, et surtout ce n'était pas un cas isolé. Le fichier accumulait des
contournements qui disaient tous la même chose :

| Contournement | Ce qu'il compensait |
|---|---|
| 22 × `unbindsym` | les liaisons chiffres par symbole |
| `bar bar-0 mode invisible` | le bloc `bar { }` |
| `output * bg` + `sleep 1; pkill` | la ligne 24 du fichier système |

**Cause commune : `include /etc/sway/config`.** Sway ne sait pas *désactiver* une
directive — il n'existe aucun « défaire », seulement « en poser une autre par-dessus ».
Tant qu'on hérite d'un environnement de bureau complet dont on ne veut pas, on ne peut
que le recouvrir pièce par pièce.

D'où la bascule : reprendre le fichier au lieu de l'hériter. Les 91 directives actives du
fichier système découpées en deux, selon ce que je veux vraiment — **Sway ne fait que du
tuilage, Noctalia fait le shell.** Passent à Noctalia : le fond d'écran, le lanceur
(`wmenu-run`), le menu de session (`swaynag`), le son et la luminosité (`pactl`,
`brightnessctl`), la capture (`grim`), la barre. Reste à Sway : variables, focus et
déplacement, espaces de travail, dispositions, scratchpad, mode resize.

Résultat : **plus aucune directive `bg`, donc Sway ne lance plus swaybg du tout.** Rien à
tuer, pas de temporisation, pas de course entre deux surfaces. Les 22 `unbindsym` et le
`bar bar-0 mode invisible` disparaissent dans le même mouvement. 100 directives actives,
un seul fichier.

**Le piège de l'opération, à ne jamais oublier.** La *dernière* ligne de
`/etc/sway/config` est `include /etc/sway/config.d/*`. Abandonner l'include principal
sans reprendre celle-là aurait cassé la session : c'est elle qui charge
`10-systemd-session.conf`, donc `sway-systemd/session.sh`, donc la propagation de
l'environnement vers systemd et D-Bus (`WAYLAND_DISPLAY`, `SWAYSOCK`,
`XDG_CURRENT_DESKTOP`), le démarrage de `sway-session.target`, et par ricochet l'agent
SSH et les portails. Un fichier qu'on remplace, ça se lit **en entier** d'abord — la
ligne vitale était la dernière.

Ce que la bascule coûte, assumé : une mise à jour du paquet `sway` ne se propage plus
dans ma config. Pour le lab ça déplace aussi légèrement l'axe — l'`include` montrait *ce
que Fedora fournit*, un fichier possédé donne le même environnement partout. Compte tenu
de l'objectif « Sway ne fait que du tuilage », c'est le bon compromis.

Une précision qui a orienté tout le découpage : **les raccourcis restent dans Sway.**
Noctalia n'a aucun système de raccourcis — son `settings.toml` ne contient que `[theme]`
et `[wallpaper.*]` — et ne peut pas en avoir, puisque sous Wayland seul le compositeur
voit le clavier. Le partage réel est : Sway capte la frappe, Noctalia fournit le
comportement et l'affichage. Les lignes `bindsym … exec noctalia msg …` sont des appels
IPC, pas des implémentations. « Déléguer à Noctalia » ne veut donc pas dire « vider la
config Sway ».

### Le point ouvert des chiffres, soldé — `--to-code` était bien coupable

Hypothèse notée hier, confirmée aujourd'hui. `bindsym --to-code` traduit bien le symbole
en code de touche, **mais sans retirer le Maj que ce symbole exige**. Sur AZERTY, `1` est
au niveau 2 de `AE01` :

- `bindsym --to-code $mod+1` devenait `$mod+Shift+AE01`
- `bindsym --to-code $mod+Shift+1` devenait… la même chose

Les deux liaisons atterrissaient sur la même combinaison physique et la première inscrite
gagnait. D'où le symptôme exact : `Super+touche` ne faisait rien, `Super+Maj+touche`
changeait d'espace au lieu d'y envoyer la fenêtre.

**Mon correctif du matin n'avait donc pas résolu le bug, il l'avait déplacé d'un rang.**
C'est la vraie leçon de la journée, plus que la syntaxe : un symptôme qui change de forme
n'est pas un symptôme qui disparaît.

Corrigé en `bindcode`, qui prend le code de la touche **physique** sans passer par un
symbole ni par un niveau. Codes lus dans `/usr/share/X11/xkb/keycodes/evdev`, pas devinés :
rangée du haut `AE01`=10 … `AE10`=19, et `TLDE`=49. Testé : `Super+&` va sur l'espace 1,
`Super+Maj+&` y envoie la fenêtre. Les deux fonctionnent enfin.

Trois objets distincts, à ne plus confondre : un **symbole**, un **code de touche**, un
**niveau**. Toute config de WM tuilant écrite pour QWERTY est à relire avec ça en tête.

Le scratchpad, orphelin depuis que j'ai retiré les liaisons `minus` qui entraient en
collision avec l'espace 6, est réattribué à `²` (`bindcode 49`) — touche libre, isolée en
haut à gauche, hors de la rangée des chiffres.

### Détail à ne pas oublier en relisant ce journal

`dnf history` affiche les heures en **UTC**, alors que les dates de ce journal et du
`README.md` sont en heure locale (UTC+2). La transaction 8 y apparaît à 08:01, elle a
été lancée à 10:01. Deux heures d'écart, de quoi se tromper en recoupant plus tard.

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
