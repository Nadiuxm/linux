# Poste de travail — ce qu'il ne faut pas oublier

Ce dossier répond à une question que ni `baseline/` ni `journal/` ne traitent :

> **Qu'est-ce que je dois réinstaller et reconfigurer pour retrouver un poste
> opérationnel après une bascule de distribution ou d'environnement ?**

Les trois ne se confondent pas, et les mélanger casserait la méthode :

| Emplacement | Rôle | Évolue ? |
|---|---|---|
| `journal/<itération>/baseline/` | État de la machine **vierge**, figé, pour comparer les distros entre elles | Non — c'est une photo datée |
| `journal/<itération>/journal.md` | Ce qui s'est passé, daté, sur **cette** distro | Non — ne vaut que pour son itération |
| **`poste/`** | L'inventaire **vivant** des outils de travail, indépendant de la distro | **Oui** — à tenir à jour au fil de l'usage |

Ce dossier est **explicitement hors protocole de baseline**, et c'est voulu. La baseline
compare des distributions ; ce dossier décrit le poste de travail réel, celui qui doit
exister pour bosser. Rien de ce qui est listé ici ne doit être installé avant la capture
de la baseline d'une nouvelle itération.

Il alimente l'étape de remontée en charge de la procédure de bascule
(`journal/README.md`) : après une réinstallation, ce fichier se déroule de haut en bas.

## Comment lire une fiche

Même structure pour chaque outil, pour que la bascule soit mécanique et pas archéologique :

- **Rôle** — à quoi il sert dans le travail réel. Si c'est vague, l'outil n'a rien à faire ici.
- **Obtention** — d'où il vient sur la distro actuelle, et ce que ça coûtera probablement ailleurs.
- **Portabilité** — la question qui compte : est-ce que ça dépend de la distro, du bureau, du matériel ?
- **À refaire à la main** — ce qu'aucun `stow` ne restaurera. C'est la partie qu'on oublie.
- **Versionné** — ce qui revient tout seul avec le dépôt.

---

## VM Windows — poste d'administration

> **Statut : construite le 2026-09-03**, installation de Windows en cours.
> Jointure au domaine et outils invités restent à faire.

### Rôle

Accès aux serveurs et aux postes utilisateurs avec un compte membre de **Protected Users** :

- administration des serveurs du domaine `toursevenements.local` ;
- RDP vers les postes lors des déploiements.

Ce n'est pas un confort : sans cette VM, la partie « administration » du travail ne se
fait pas depuis ce poste. C'est le premier outil du poste qui soit **bloquant**, au même
titre que KeePassXC l'est pour la baseline.

### Obtention

Sur Fedora 44 Workstation, **la pile de virtualisation est déjà entièrement présente** —
`qemu-kvm`, `libvirt` (démons modulaires, activés par socket), OVMF/UEFI, SPICE,
`swtpm` (TPM 2.0 virtuel), `qemu-guest-agent`. Elle est tirée par `gnome-boxes`, livré
dans l'image Workstation. Coût : **zéro manipulation**.

Ne manquent que :

| Élément | Source | Remarque |
|---|---|---|
| `virt-manager` | Dépôt Fedora, 714 Ko | Boxes ne sait pas faire de réseau ponté ni de gestion fine des snapshots |
| ISO `virtio-win` | **Hors dépôts Fedora** | Pilotes de stockage et réseau Windows. Seule vraie friction. |
| ISO Windows 11 Pro + licence | Fournie par l'employeur | Hors dépôt, hors dépôt git |

### Portabilité

- **La virtualisation KVM elle-même est portable** : `libvirt` + `qemu` existent partout.
  Ce qui change d'une distro à l'autre, c'est le *coût d'obtention* — ici gratuit parce
  que Fedora Workstation embarque Boxes. **Sur Debian ou openSUSE, à chronométrer :
  c'est une donnée de comparaison à part entière.**
- **Indépendant du bureau.** `virt-manager` est une application GTK ordinaire, elle
  tourne sous GNOME comme sous Sway. Cet outil ne pèse pas sur l'axe « bureaux ».
- **Dépend du matériel** : VT-x, vérifié présent sur l'i5-14500.
- **Dépend du système de fichiers** : voir le piège Btrfs ci-dessous.
- **Dépend du réseau physique** : le pont exige de l'**Ethernet**. En Wi-Fi il ne
  fonctionne pas (le point d'accès refuse plusieurs adresses MAC sur une association).
  Ici le poste est en filaire, donc c'est réglé — mais sur un portable ce serait bloquant.

### Contraintes imposées par Protected Users

Le compte utilisé est membre de **Protected Users**. Ce n'est pas un détail de
configuration : ça dicte l'architecture de la VM. Ces contraintes sont **fonctionnelles**,
pas des précautions optionnelles.

| Contrainte | Conséquence concrète |
|---|---|
| NTLM, RC4 et DES refusés → **Kerberos uniquement** | **Toujours se connecter par FQDN, jamais par IP.** Une IP ne permet pas de construire le SPN et fait retomber sur NTLM, qui est bloqué. Échec d'authentification qui ressemble à une VM cassée. |
| Pas de mise en cache des identifiants | Aucune ouverture de session hors ligne. Un DC doit être joignable **à chaque** connexion. |
| TGT de 4 h, non renouvelable | Ré-authentification en cours de journée. C'est le comportement normal, pas une dérive. |
| Pas de délégation | Tout outil faisant un « double saut » (relayer les identifiants vers un troisième hôte) échouera. |
| Kerberos exige une horloge synchrone (< 5 min d'écart) | **Piège propre aux VM** : une VM suspendue dérive au réveil. `qemu-guest-agent` + synchronisation sur le DC. |

**Conséquence structurante : la VM doit être jointe au domaine.** Depuis une machine en
groupe de travail, `mstsc` avec des identifiants de domaine bascule sur NTLM pour la NLA
— donc bloqué. La jointure n'est pas un confort ici, c'est ce qui rend Kerberos possible.

**Conséquence réseau : pont, pas NAT.** Kerberos exige que la VM résolve les
enregistrements SRV du domaine et joigne les contrôleurs de domaine. En NAT, la VM reçoit
les résolveurs de `dnsmasq` et se présente derrière l'adresse de l'hôte, dans un
sous-réseau qui n'est pas celui du parc. En pont, elle est une machine de plus sur le LAN,
adressée et résolue comme n'importe quel poste — c'est-à-dire comme le poste d'admin
qu'elle est censée être.

### Ce qui reste à demander — ne pas le deviner

Ce dépôt ne documente pas l'architecture réseau de l'employeur, et **elle ne se déduit pas
de la configuration du poste**. Ce que `nmcli` montre depuis cette machine, ce sont des
réglages, pas des rôles : deux adresses dans `IP4.DNS` disent « voici les résolveurs
configurés », rien de plus — ce ne sont pas nécessairement les contrôleurs de domaine.

À faire préciser par l'équipe avant de créer le pont :

- L'adressage de la VM : DHCP ou statique, et une adresse est-elle disponible ?
- Y a-t-il un VLAN ou un sous-réseau dédié aux postes d'administration ?
- Une seconde machine sur le même port physique pose-t-elle un problème
  (contrôle d'accès au port, 802.1X, filtrage MAC) ?
- Quels résolveurs la VM doit-elle utiliser, et voient-ils la zone du domaine ?

> **Piège de méthode, déjà payé une fois :** lire une valeur de configuration et en déduire
> un rôle d'infrastructure. Une adresse dans `IP4.DNS` est un résolveur — pas un
> contrôleur de domaine, pas un serveur DHCP, pas un site AD. Même famille que « un dépôt
> activé n'est pas un paquet installé » : l'outil rapporte un réglage, l'interprétation
> est ajoutée par le lecteur.

### Réseau — le pont `br0`

**En place et vérifié le 2026-09-03.** La VM se branche dessus directement dans
virt-manager (*Bridge device: `br0`*) : aucun objet réseau libvirt n'est nécessaire, et
le réseau NAT par défaut de libvirt reste inutilisé.

Configuration retenue, en deux profils NetworkManager persistants (`/etc/NetworkManager/system-connections/`) :

```bash
nmcli connection add type bridge con-name br0 ifname br0 \
    ipv4.method auto ipv6.method auto \
    bridge.stp no \
    bridge.mac-address e8:cf:83:89:18:d4 \
    connection.autoconnect yes

nmcli connection add type ethernet con-name br0-port ifname enp0s31f6 \
    controller br0 connection.autoconnect yes
```

Deux paramètres seulement sortent du minimum, et chacun répond à un problème précis :

- **`bridge.stp no`** — un pont Linux avec STP actif **émet des BPDU**. Sur un port
  d'accès protégé par BPDU guard, ça met le port en `err-disable` : réseau coupé, et la
  remise en service se fait **côté switch**, pas côté poste. Avec STP désactivé le pont
  est muet dans les deux sens (il n'émet rien, et `group_fwd_mask` à 0 empêche le relais
  des adresses réservées `01:80:C2:00:00:0X`). Bénéfice annexe : plus de délai de
  convergence, donc plus de ~30 s sans réseau à chaque montée de lien.
- **`bridge.mac-address`** — sans lui, un pont Linux prend **la MAC la plus basse parmi
  ses ports**. Tant qu'il n'y a que la carte physique, c'est la bonne ; mais dès qu'une VM
  démarre, son `vnetX` rejoint le pont avec une MAC générée. Si elle est plus basse, la
  MAC du pont change, donc le `dhcp_client_identifier`, donc le bail : **l'hôte change
  d'adresse IP tout seul**, sans qu'on ait rien modifié.

**Le port de switch reste en `access`.** `br0` est un pont L2 pur, `vlan_filtering` à 0 :
les trames de la VM sortent non taguées, comme celles de l'hôte, et les deux atterrissent
dans le VLAN d'accès du port. Un trunk ne serait nécessaire que pour placer la VM dans un
VLAN *différent* de l'hôte — ce qui demanderait une autre configuration Linux
(sous-interface `enp0s31f6.<vid>` enrôlée, ou `vlan_filtering` activé), pas seulement un
changement côté switch.

#### Vérifier l'effet, pas la commande

`nmcli` dit ce que le profil **déclare** ; ces fichiers disent ce que le noyau **applique** :

```bash
cat /sys/class/net/br0/address              # doit égaler la MAC de la carte
cat /sys/class/net/br0/bridge/stp_state     # 0
cat /sys/class/net/br0/bridge/group_fwd_mask # 0x0
cat /sys/class/net/br0/bridge/vlan_filtering # 0
bridge link show                            # la carte en « master br0 », état « forwarding »
```

`forwarding` immédiat est la preuve que STP est bien coupé : avec STP actif, le port
passerait par `listening` puis `learning`. À l'inverse, `forward_delay` reste affiché à
1500 (centisecondes) — c'est un paramètre *de* STP, sans effet tant que `stp_state` vaut 0.

#### Piège rencontré : un profil listé n'est pas un profil enregistré

Les profils « Connexion filaire 1 / 2 » ont **changé d'UUID et de carte** après un simple
redémarrage. Ils sont **générés à la volée** par NetworkManager pour toute carte Ethernet
sans configuration, vivent dans `/run/NetworkManager/system-connections/` et portent
`autoconnect-priority: -999` — la valeur la plus basse, pour que n'importe quel profil
réel les supplante.

Conséquences : il n'y avait **rien à préserver** comme filet de secours (le premier script
visait un fantôme), et **rien à désactiver** non plus. Le retour arrière consiste à
supprimer `br0` et `br0-port` : NetworkManager régénère seul un profil par défaut.

> Même famille que « un dépôt activé n'est pas un paquet installé » et « un paquet
> installé n'est pas un paquet utilisé » : l'outil affiche l'état courant, pas ce qui est
> persistant. Vérifier **d'où vient** un objet avant de compter dessus —
> ici, `/etc` contre `/run`.

#### Vérifié au premier démarrage de la VM

- **MAC du pont inchangée** (`e8:cf:83:89:18:d4`), adresse de l'hôte inchangée
  (`10.11.65.1/27`), alors que `vnet2` avait rejoint le pont.
- **`br_netfilter` toujours non chargé** : le trafic ponté ne traverse pas netfilter.
  Point ouvert refermé, aucun `sysctl` à poser.

> **À relativiser, et c'est instructif :** `vnet2` portait la MAC `fe:54:00:f8:62:8b`.
> libvirt génère ses MAC de tap en `fe:…` **délibérément**, pour qu'elles soient toujours
> supérieures à celle d'une carte physique et que le pont conserve la sienne. Le risque
> décrit plus haut est réel dans l'absolu, mais l'outil le traite déjà : `bridge.mac-address`
> rend le comportement déterministe quelle que soit l'origine du tap, ce n'est pas lui qui
> a sauvé la mise. Même leçon que le point `SSH_AUTH_SOCK` du journal — **vérifier si
> l'outil n'a pas déjà traité le problème avant de croire qu'on l'a résolu.**

#### Reste à prouver

- La survie au reboot. Les profils sont dans `/etc`, donc c'est attendu — pas encore constaté.

### Le piège Btrfs — à traiter AVANT de créer l'image

`/` est en **Btrfs avec copy-on-write**. Une image de VM en CoW se fragmente de façon
catastrophique : chaque écriture aléatoire dans le fichier crée un nouvel extent, et on
atteint des dizaines de milliers d'extents en quelques semaines d'usage.

La parade est `chattr +C`, mais elle a une subtilité qui en fait un vrai piège :

> **L'attribut `+C` ne s'applique qu'aux fichiers créés *ensuite*.** Le poser sur un
> fichier existant et non vide **ne fait rien** — pas d'erreur, pas d'effet. Il faut donc
> le poser sur le **dossier**, vide, *avant* d'y créer la moindre image.

Même famille que « recharger une config ≠ repartir d'un état neuf » : une commande qui
réussit n'est pas une commande qui a fait quelque chose.

À reproduire sur toute distro dont l'installateur choisit Btrfs — c'est le cas par défaut
de Fedora, d'openSUSE et proposé par plusieurs autres.

### Configuration retenue de la VM

Relevée dans le XML réel (`virsh -c qemu:///system dumpxml win11`), pas dans l'interface :

| Élément | Valeur | Pourquoi |
|---|---|---|
| Chipset | `pc-q35-10.2` | **Obligatoire** : le Secure Boot exige le SMM, que seul Q35 fournit |
| Firmware | `OVMF_CODE_4M.secboot.qcow2`, `secure='yes'` | Exigé par Windows 11 |
| NVRAM | template `OVMF_VARS_4M.secboot.qcow2` | Variante à **clés Microsoft pré-inscrites** (`enrolled-keys`) |
| SMM | `<smm state='on'/>` | Corollaire du Secure Boot |
| TPM | `tpm-crb`, backend émulateur, **2.0** | Exigé par Windows 11, fourni par `swtpm` |
| vCPU / RAM | 8 / 8 Gio | Sur 20 threads et 15 Gio |
| Disque | `virtio` → `/var/lib/libvirt/images/win11.qcow2` | 100 Gio annoncés, alloués à la demande |
| Réseau | `type='bridge'`, source `br0`, modèle `virtio` | Voir la section réseau |

**Le firmware est le seul choix irréversible** : il se fige à la création de la VM. Se
tromper impose de tout recréer. Il faut donc cocher « Personnaliser la configuration avant
l'installation » dans l'assistant, sinon ni le firmware, ni le TPM, ni le bus VirtIO ne
sont accessibles.

Vérifier le résultat dans le XML et non dans l'interface :

```bash
virsh -c qemu:///system dumpxml win11 | grep -E "machine=|<loader|<nvram|smm|<tpm"
```

> **`virsh` sans `-c` n'interroge pas la même chose.** Pour un utilisateur non-root il
> vise `qemu:///session`, où la VM n'existe pas — la liste revient vide alors que la
> machine tourne. Toujours préciser `-c qemu:///system`, ou poser `LIBVIRT_DEFAULT_URI`.

#### Trois pièges de l'interface virt-manager

Aucun n'est un dysfonctionnement : à chaque fois, le nom affiché ne décrit pas la chose.

1. **Il n'existe aucune option « Secure Boot ».** La liste des firmwares affiche des
   **chemins de fichiers** ; c'est le `.secboot.` dans le chemin qui distingue. Et tant
   que le chipset est en i440FX, aucun firmware `secboot` n'est proposé — libvirt n'en
   déclare pas pour ce chipset. Passer en **Q35 d'abord**, la liste se repeuple ensuite.
   Ce que libvirt propose se lit directement :
   `virsh domcapabilities --machine q35 --virttype kvm | sed -n '/<loader/,/<\/loader>/p'`
2. **Il n'existe aucune catégorie « CD-ROM ».** Un lecteur CD est un **Stockage** dont on
   change le *Type de périphérique* → *Périphérique CD-ROM*. Aucun pool de stockage n'étant
   défini ici, le bouton « Manage… » ouvre une liste vide : passer par « Browse Local »,
   qui adresse le fichier par son chemin absolu.
3. **Le pilote de disque virtio-blk s'appelle « Red Hat VirtIO SCSI controller ».**
   Vérifié dans les `.inf` de l'ISO :

   | Fichier | Nom affiché par Windows | Périphériques PCI |
   |---|---|---|
   | `viostor` (virtio-**blk**, celui d'un disque `bus='virtio'`) | « Red Hat VirtIO SCSI controller » | `DEV_1001`, `DEV_1042` |
   | `vioscsi` (virtio-scsi) | « Red Hat VirtIO SCSI **pass-through** controller » | `DEV_1004`, `DEV_1048` |

   Prendre celui **sans** « pass-through ». Chemin dans l'ISO : `\amd64\w11`
   (équivalent : `\viostor\w11\amd64`).

#### Après l'installation, dans cet ordre

1. **`virtio-win-guest-tools.exe`**, à la racine de l'ISO virtio-win. Windows n'a aucun
   pilote pour la carte réseau virtio : **sans lui, pas de réseau, donc pas de jointure
   au domaine.** Il installe NetKVM, le ballooning, l'agent invité et l'affichage.
2. **Jointure au domaine**, puis vérification Kerberos (`klist`, test par FQDN).

### Placement dans la session Sway

Règle ajoutée à `dotfiles/sway/.config/sway/config` :

```
assign     [app_id="^virt-manager$"] workspace number 6
for_window [app_id="^virt-manager$"] focus
```

`assign` place la fenêtre sur l'espace 6 dès sa création, `for_window … focus` bascule
l'affichage et le clavier dessus. **On désigne un espace, jamais une sortie** : l'espace 6
est déjà affecté à DP-1 par le bloc `workspace … output`, donc une seule affectation fait
foi et un changement de prise ne casse qu'un endroit.

Le critère est `app_id` et non `class` : virt-manager est un client **Wayland natif**.
Ne pas le deviner — le lire sur une fenêtre ouverte, `swaymsg -t get_tree`.

### À refaire à la main après une bascule

Dans cet ordre — chaque étape conditionne la suivante :

1. Installer `virt-manager` (ou l'équivalent) et vérifier que la pile libvirt **tourne**,
   pas seulement qu'elle est installée.
2. S'ajouter au groupe `libvirt`. **Effectif seulement après une nouvelle session** :
   ouvrir un autre terminal ne suffit pas.
3. Recréer le dossier d'images **et y poser `chattr +C` tant qu'il est vide**, avant toute
   image. Posé après, il ne fait rien sur les fichiers déjà écrits.
4. Recréer le pont réseau — la configuration NetworkManager est propre à la machine.
5. **Récupérer l'ISO `virtio-win`** : elle n'est dans aucun dépôt de distro.
6. Replacer les images sauvegardées, puis **`restorecon`** (voir ci-dessous).
7. Rejoindre le domaine.

> **`mv` conserve l'étiquette SELinux, `cp` hérite de celle du dossier de destination.**
> Un fichier déplacé dans `/var/lib/libvirt/images` y reste en `user_home_t` et `qemu`,
> confiné, ne peut pas le lire — le symptôme est un « impossible d'ouvrir le disque »
> parfaitement opaque. `sudo restorecon -Rv /var/lib/libvirt/images/` après tout
> déplacement, et vérifier avec `ls -Z`.

### À sauvegarder avant un wipe

- **L'image disque de la VM** — `/var/lib/libvirt/images/win11.qcow2`, plusieurs dizaines
  de Go, jamais dans git.
- **Le fichier NVRAM** — `/var/lib/libvirt/qemu/nvram/win11_VARS.qcow2`. Petit, facile à
  oublier, et c'est lui qui porte les variables UEFI : clés Secure Boot et entrées
  d'amorçage. Sans lui, la VM restaurée ne démarre pas comme avant.
- **Le XML de définition** — `virsh -c qemu:///system dumpxml win11`, léger et lisible.

> À ajouter comme point de contrôle dans la procédure de bascule de `journal/README.md`,
> au même titre que la base KeePassXC : c'est la seconde chose que la méthode bare-metal
> peut faire perdre définitivement.

### Versionné dans le dépôt

- **La règle de placement Sway** (`dotfiles/sway/.config/sway/config`) — revient seule
  avec `stow`.

Ne le sont pas, et ne le seront pas : l'image disque, le NVRAM, les ISO. Le XML de
définition pourrait l'être une fois la VM stabilisée — à décider alors, en vérifiant
qu'il ne porte aucun identifiant.
