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

> **Statut : EN SERVICE sur le poste de référence depuis le 2026-09-07.**
> Reprise depuis le SSD USB, elle tourne, et l'agent invité répond (`guest-info` →
> **110.2.3**), ce qui règle le point « installé dans Windows ≠ joignable depuis l'hôte »
> plus bas.
>
> *Statut antérieur, gardé pour la chronologie :* construite le 2026-09-03 sur
> l'itération 01, installation de Windows en cours.

### Ce que l'audit du 2026-09-07 a mesuré

| Mesure | Valeur |
|---|---|
| Domaine libvirt | `win11`, `en cours d'exécution`, UUID `0f52632d-…` |
| Portée | **`qemu:///system`** — pas `qemu:///session`. `virsh` sans `-c` ne la voit pas |
| Mémoire / vCPU | 8 Go / 8 (`host-passthrough`, 13 `hyperv` enrichissements actifs) |
| Firmware | OVMF `secboot` + `enrolled-keys`, NVRAM `/var/lib/libvirt/qemu/nvram/win11_VARS.qcow2` |
| TPM | `tpm-crb` émulé par **swtpm** (`/run/libvirt/qemu/swtpm/1-win11-swtpm.sock`) |
| Disque | `/var/lib/libvirt/images/win11.qcow2`, `virtio-blk`, `discard=unmap` |
| **Occupation réelle** | **46 Go** (`du -sh`) |
| **Taille apparente** | **101 Go** (`du -sbh`) |
| Attribut | `+C` (NOCOW) sur le fichier **et** sur le sous-volume ID 259 |
| SELinux | `svirt_image_t:s0:c159,c991` (catégories MCS posées) |
| Réseau | `tap` sur **`br0`**, MAC invitée `52:54:00:f8:62:8b` |
| Affichage | `qxl-vga` + SPICE sur `127.0.0.1:5900`, `usb-redir` ×2 |
| CD | `virtio-win-0.1.302.iso` monté (836 Mo réels) |

**L'écart 46 Go / 101 Go est la preuve que la copie creuse a fonctionné**, et c'est la
seule façon de le vérifier après coup. Sans `cp --sparse=always`, le fichier occuperait ses
101 Go apparents — sans erreur, sans avertissement, sans rien pour le signaler. Le disque a
grossi depuis les 31 Go réels de septembre, ce qui est normal : Windows a tourné.

**L'étiquette SELinux avec ses catégories MCS confirme que le piège du `mv` a été évité.**
Un `mv` aurait conservé l'étiquette de l'ancien disque et `qemu`, confiné, n'aurait pas pu
lire le fichier — le symptôme aurait été un refus de démarrage sans mention de SELinux.

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

#### Prouvé le 2026-09-07

- **La survie au reboot est constatée.** Le pont a été refait sur le poste de référence le
  2026-09-07 à 09:36, la machine a redémarré à 10:27, et `br0` porte l'adresse
  `10.11.65.1/27` avec la route par défaut. Les trois profils sont dans
  `/etc/NetworkManager/system-connections/`.
- **Le profil Ethernet d'origine est bien neutralisé** : `Connexion filaire 2` porte
  `autoconnect=false` et `autoconnect-priority=-999`. C'est la moitié du travail qu'on
  oublie : laissé actif, il se dispute `enp0s31f6` avec `br0-port` à chaque démarrage, de
  façon non déterministe. Un quatrième profil, `Connexion filaire 1`, reste avec
  `autoconnect=oui` mais sans interface attachée — sans effet, à surveiller.
- **La MAC physique est reprise sur le pont** (`mac-address=E8:CF:83:89:18:D4`), donc le
  réseau de l'employeur ne voit pas apparaître une nouvelle adresse matérielle.

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

#### L'agent invité : installé dans Windows ≠ joignable depuis l'hôte

`virtio-win-guest-tools.exe` installe bien `qemu-ga` dans Windows, mais **virt-manager ne
crée pas le canal virtio-serial correspondant côté hôte**. L'agent tourne alors dans le
vide : pas d'IP remontée, pas d'arrêt propre, pas de gel du système de fichiers pour un
snapshot cohérent.

Même famille que « un paquet installé n'est pas un paquet utilisé » — ici, un agent
installé sans le tuyau qui le rend joignable.

Le canal à ajouter, VM **éteinte** (un redémarrage invité ne change pas le matériel virtuel) :

```xml
<channel type='unix'>
  <target type='virtio' name='org.qemu.guest_agent.0'/>
</channel>
```

```bash
virsh -c qemu:///system attach-device win11 canal.xml --config
```

Vérification, une fois la VM démarrée :

```bash
virsh -c qemu:///system qemu-agent-command win11 '{"execute":"guest-ping"}'   # -> {"return":{}}
virsh -c qemu:///system domifaddr win11 --source agent
```

La seconde donne l'IP de la VM depuis l'hôte, sans passer par `ipconfig`. C'est aussi la
façon la plus directe de vérifier que le pont fait son travail : **la VM doit apparaître
dans le même sous-réseau que l'hôte**. Constaté le 2026-09-03 — hôte `10.11.65.1/27`,
VM `10.11.65.29/27`, même bail DHCP, donc même LAN.

#### Deux canaux ne peuvent pas porter le même nom

En ajoutant le canal ci-dessus, la VM a refusé de démarrer :

```
virtio-serial-bus: A port already exists by name com.redhat.spice.0
```

La définition contenait **deux** canaux nommés `com.redhat.spice.0` : un `spicevmc` et un
`qemu-vdagent`. Les deux font la même chose — presse-papiers et souris — par deux
implémentations concurrentes. Avec un affichage **SPICE + QXL**, c'est `spicevmc` qui va
de pair avec le `spice-vdagent` installé par les guest tools ; `qemu-vdagent` est
l'alternative native de QEMU, utile quand on n'utilise *pas* SPICE. Il a été retiré.

> **Une configuration invalide n'échoue qu'au moment où elle est relue.** Le doublon
> existait avant l'ajout du canal, et la VM tournait quand même : elle vivait sur ce
> qu'elle avait lu à son démarrage, la définition sur disque ayant divergé depuis sans que
> rien ne le signale. C'est « recharger une config ≠ repartir d'un état neuf » vu par
> l'autre bout — ce n'est pas le rechargement qui n'applique pas, c'est **l'absence** de
> rechargement qui masque.
>
> Corollaire : après toute modification du XML d'une VM, seul un **arrêt/démarrage
> complet** est un test valable. Un redémarrage invité ne relit rien.

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
3. Recréer le dossier d'images. Depuis le 2026-09-03 ce n'est plus un dossier mais un
   **sous-volume Btrfs** (`btrfs subvolume create`), pour qu'il reste hors des instantanés
   — voir la fiche « Instantanés Btrfs » plus bas. Y poser `chattr +C` **tant qu'il est
   vide** : posé après, il ne fait rien sur les fichiers déjà écrits.
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

---

## RustDesk — prise en main à distance des postes

> **Statut : installé le 2026-09-07** (08:57 locales) sur le poste de référence,
> `rustdeskadmin` **1.4.9-0**, RPM local. Service actif, trois processus en cours.

### Rôle

**L'outil de traitement des tickets.** C'est par lui que se prend la main sur un poste
utilisateur pour dépanner. Avec la VM Windows, c'est le second outil **bloquant** du poste :
sans lui, la partie « support » du travail ne se fait pas depuis cette machine.

Le nom du binaire est `rustdeskadmin`, pas `rustdesk` : c'est un **client personnalisé**,
généré depuis la console RustDesk de l'entreprise. La distinction n'est pas cosmétique —
voir « Obtention ».

### Obtention

**Un RPM généré à la demande, pas téléchargé.** Le client est produit par la console
RustDesk de l'entreprise et embarque sa configuration dans
`/usr/share/rustdeskadmin/custom.txt` : adresse du serveur de rendez-vous, clé publique de
relais, nom d'application, options désactivées. Il n'existe à aucune URL publique.

```bash
sudo dnf install ~/rustdeskadmin-x86_64.rpm     # une seule commande, voir plus bas
```

- `Signature : (none)` — **le RPM n'est pas signé.** `Vendor : rustdeskadmin
  <info@rustdeskadmin.com>`, `Build Host : build-linx`, construit le 2026-09-01.
- Dépôt d'origine dans `dnf` : **`@commandline`**. C'est ainsi qu'un RPM local se signale,
  et le seul moyen de le repérer dans un inventaire de paquets :
  `dnf repoquery --installed --qf '%{name}|%{from_repo}\n' | grep commandline`.
- 81 Mo installés, 7 paquets avec les dépendances.

> **Son `%post` fait cinq choses que `rpm` ne suit pas** — lues avec
> `rpm -q --scripts rustdeskadmin`, et c'est le vrai enseignement de cette fiche :
>
> 1. copie l'unité dans `/etc/systemd/system/rustdeskadmin.service` ;
> 2. copie `rustdeskadmin.desktop` et `rustdeskadmin-link.desktop` dans
>    `/usr/share/applications/` ;
> 3. crée le lien `/usr/bin/rustdeskadmin` → `/usr/share/rustdeskadmin/rustdeskadmin` ;
> 4. `systemctl daemon-reload` ;
> 5. `enable` **puis** `start`.
>
> **Donc : ne pas taper `systemctl enable --now` après coup, c'est déjà fait.** Et surtout,
> **`rpm -qf` ne reconnaît aucun de ces quatre fichiers** : `rpm -qf /usr/bin/rustdeskadmin`
> répond « n'appartient à aucun paquet ». Un inventaire fondé sur `rpm -ql` rate le
> lanceur, le binaire dans `$PATH` et l'unité systemd. Le `%preun` les retire bien, donc
> l'état reste cohérent — mais tant que le paquet est installé, ces fichiers sont
> invisibles à toute question posée à `rpm`. Même famille que « un dépôt activé n'est pas
> un paquet installé », sur le versant inverse : ici c'est le paquet qui est là et les
> fichiers qui sont hors de sa connaissance.

### Portabilité

**La meilleure du poste, et c'est pour ça que l'outil a été retenu.** Le client est généré
par Julien lui-même : il peut demander un `.deb`, un `.rpm` ou un binaire selon la distro
d'accueil. Aucune dépendance à Fedora, aucune à GNOME.

Ce qui est à vérifier sur une nouvelle distro, dans l'ordre :

1. **Le format de paquet disponible dans la console** — c'est la première question, et elle
   ne se pose pas à la machine.
2. **Wayland.** Sur ce poste, RustDesk crée un périphérique **`rustdesk-uinput-keyboard`**,
   visible dans `hyprctl devices` : c'est ainsi qu'il injecte les frappes. Sous Wayland,
   l'injection d'événements et la capture d'écran passent par `uinput` et les portails, pas
   par X11 — donc à retester sur chaque compositeur, pas seulement sur chaque distro.
3. **Rien à ouvrir dans le pare-feu.** Vérifié le 2026-09-07 : la zone `public`
   (celle de `br0`) n'autorise que `dhcpv6-client`, `mdns` et `ssh`, et RustDesk
   fonctionne. Il sort vers son relais, il n'écoute pas. **Ne pas « corriger » un pare-feu
   qui n'a rien cassé.**

### À refaire à la main après une bascule

- **Régénérer le RPM** depuis la console de l'entreprise. « Réinstaller la même version »
  n'a pas de sens ici : la version installée est une trace, pas une adresse.
- **Rétablir l'identité de la machine dans la console**, si l'ID change. Un poste
  réinstallé est un nouvel appareil du point de vue du serveur.

### À sauvegarder avant un wipe

`~/.config/rustdeskadmin/` — **et ce dossier contient des secrets, il ne va pas au dépôt.**
Les clés présentes au 2026-09-07, sans leurs valeurs :

| Fichier | Contient |
|---|---|
| `RustDeskAdmin.toml` | `enc_id`, `password`, `salt`, `key_pair` — **l'identité et le mot de passe d'accès** |
| `RustDeskAdmin2.toml` | `rendezvous_server`, `serial`, `unlock_pin`, `trusted_devices` |
| `RustDeskAdmin_local.toml` | `access_token`, `remote_id`, `kb_layout_type`, réglages d'interface |
| `RustDeskAdmin_ab`, `RustDeskAdmin_group` | carnet d'adresses et groupes |
| `peers/*.toml` | un fichier par poste contacté |

> **Rien de tout ça n'est versionnable**, ni maintenant ni jamais : `password`, `key_pair`,
> `access_token` et `unlock_pin` sont des secrets. Sauvegarde par les moyens propres de
> Julien, comme la base KeePassXC — hors périmètre du dépôt.
>
> Le seul élément **récupérable sans sauvegarde** est le carnet d'adresses, s'il est
> synchronisé côté serveur. À vérifier avant de compter dessus, plutôt qu'après.

### Versionné dans le dépôt

**Rien.** Pas de fichier de configuration hors secrets, pas d'unité systemd à écrire (le
RPM la pose), pas d'entrée de lanceur à créer (le RPM en pose deux). C'est le cas le plus
propre du poste — et il n'est propre que parce que tout le reste est soit dans le RPM, soit
un secret.

---

## Mattermost — messagerie interne de l'entreprise

> **Statut : installé le 2026-09-03** (12:12 locales), Flatpak Flathub, version 6.3.0.
> **Réinstallé sur le poste de référence le 2026-09-07**, même version, portée `system`.

> **Sur une image minimale, `flatpak` n'est PAS livré.** Sur Fedora 44 Workstation il
> était présent et la case « dépôts tiers » du premier démarrage ajoutait Flathub — coût
> nul, donc jamais noté. Sur l'image minimale du poste de référence, il a fallu le paquet,
> le dépôt Flathub, **et** un réglage de `XDG_DATA_DIRS` sans lequel les applications sont
> installées mais invisibles au lanceur (détail dans `installation/procedure.md`).
> **Donnée de comparaison à retenir :** « Flatpak est le seul canal identique partout » vaut
> pour le *paquet applicatif*, pas pour le *coût d'obtention du système Flatpak lui-même* —
> celui-là dépend de l'édition de la distro, pas seulement de la distro.

### Rôle

Outil de communication interne de l'entreprise. Au même titre que la VM Windows, c'est un
**outil bloquant** : sans lui, on est coupé de l'équipe.

### Obtention

**Flatpak, et c'est un choix assumé** — pas un défaut de disponibilité.

```bash
flatpak install flathub com.mattermost.Desktop
```

| | |
|---|---|
| Référence | `app/com.mattermost.Desktop/x86_64/stable` |
| Version | 6.3.0 |
| Runtime | `org.freedesktop.Platform` 25.08 |

### Portabilité — c'est tout l'intérêt du canal

**Le même Flatpak s'installe à l'identique sur Debian, openSUSE, Arch ou Fedora.** Une
seule commande, la même partout, la même version. Coût de bascule : **zéro**.

C'est le contraire des deux autres entrées de ce dossier : `virt-manager` est un paquet
de distro dont le nom et la disponibilité changent, l'ISO `virtio-win` n'est dans aucun
dépôt. Ici il n'y a rien à réapprendre d'une distro à l'autre.

> À retenir pour la méthode de comparaison : **un outil livré en Flatpak sort de fait du
> périmètre de comparaison des distributions.** Il ne dira rien sur la distro puisqu'il
> s'y comporte pareil. Ce qui reste comparable, c'est ce qui l'entoure — présence de
> Flatpak, de Flathub, et intégration au bureau.

### Le coût réel du premier Flatpak

Mesuré ici, et c'est une donnée de comparaison à part entière :

| Composant | Taille installée |
|---|---|
| `com.mattermost.Desktop` | 357,3 Mo |
| `org.freedesktop.Platform` 25.08 | 659,9 Mo |
| `org.freedesktop.Platform.GL.default` (25.08) | 457,0 Mo |
| `org.freedesktop.Platform.GL.default` (25.08-extra) | 457,1 Mo |
| `org.freedesktop.Platform.VAAPI.Intel` | 46,3 Mo |
| `org.freedesktop.Platform.codecs-extra` | 43,4 Mo |
| **Total** | **≈ 2,0 Go** |

**Une application de 357 Mo a coûté 2 Go.** Le runtime est le prix d'entrée, payé une
seule fois : les Flatpaks suivants qui partagent `org.freedesktop.Platform 25.08` ne
coûteront que leur propre taille. À ne pas présenter comme un défaut de Flatpak sans
préciser ça — mais à garder en tête sur un SSD de 233 Go.

### Intégration au bureau — ce qui a été vérifié sous Sway

- **Wayland natif**, vérifié dans l'arbre Sway : `app_id = com.mattermost.Desktop`,
  aucune `class` X11. L'application ne passe pas par XWayland alors que le manifeste
  demande les deux permissions. Aucun défaut d'affichage constaté à l'usage.
- **L'icône de zone de notification fonctionne**, et le repli dans la barre est utilisable
  comme mode de travail normal. Le Flatpak demande `org.kde.StatusNotifierWatcher` ; ce
  service est enregistré sur le bus de session par **Noctalia**, pas par Sway
  (`busctl --user list | grep StatusNotifier`). Point pour l'axe « bureaux » : un WM
  tuilant nu ne fournit aucun hôte de tray, c'est le shell qui l'apporte.
- **Le partage d'écran est prévu pour Wayland.** Le lanceur passe
  `--enable-features=WebRTCPipeWireCapturer`, donc capture via PipeWire et portails plutôt
  que X11. À confirmer en usage réel — le partage d'écran est justement une des
  « frictions Wayland » listées dans l'itération 01.
- **Accès au trousseau** : le Flatpak demande `org.freedesktop.secrets`, déjà fonctionnel
  sous Sway (activé par D-Bus, déverrouillé par PAM au login GDM).

#### La méthode, pour le prochain outil

Le manifeste demandait **les deux** permissions (`wayland` et `x11`) : il ne tranchait
rien, beaucoup d'applications Electron retombant sur XWayland faute de
`--ozone-platform=wayland`. Seule la fenêtre ouverte répond :

```bash
swaymsg -t get_tree | grep -E '"(app_id|class)"'
```

`app_id` renseigné = client Wayland natif ; `class` seul = XWayland. Même méthode que pour
virt-manager. À refaire pour chaque application ajoutée au poste — une permission déclarée
dit ce qui est *possible*, pas ce qui est *utilisé*.

### Permissions déclarées

Relevé factuel, pour l'inventaire :

```
ipc  network  pcsc  pulseaudio  wayland  x11  devices
file access : home
dbus        : com.canonical.AppMenu.Registrar, org.freedesktop.Notifications,
              org.freedesktop.secrets, org.kde.StatusNotifierWatcher,
              org.kde.kwalletd, org.kde.kwalletd5, org.kde.kwalletd6
```

`file access: home` est un accès complet au dossier personnel, dépôt compris — c'est la
permission la plus large du lot, et elle est déclarée par l'application, pas imposée par
le canal. `pcsc` donne accès aux lecteurs de cartes à puce.

### À refaire à la main après une bascule

1. Vérifier que **Flathub est configuré** (`flatpak remotes`). Sur Fedora Workstation,
   les dépôts Flatpak s'ajoutent à l'écran de bienvenue ; ailleurs, c'est une manipulation
   à chronométrer.
2. `flatpak install flathub com.mattermost.Desktop`
3. Se reconnecter à l'instance de l'entreprise (URL du serveur + identifiants).

### À sauvegarder avant un wipe

Rien de critique. La configuration du client vit dans `~/.var/app/com.mattermost.Desktop/`
et se reconstitue en se reconnectant — l'historique est côté serveur. À noter simplement
pour ne pas chercher : ce dossier n'est **pas** dans `~/.config`, c'est le
cloisonnement Flatpak.

### Versionné dans le dépôt

Rien. Le `~/.var/app/` d'un Flatpak n'a pas vocation à être versionné, et il contiendrait
des jetons de session.

> **Conséquence sur le suivi du lab :** un Flatpak n'apparaît **pas** dans `dnf history`.
> Depuis cette installation, il faut interroger deux historiques pour savoir ce qui est
> présent sur la machine — et ils ne sont même pas dans le même fuseau horaire
> (`dnf` en UTC, `flatpak` en heure locale). `bin/snapshot.sh` couvre déjà les deux :
> il produit un `flatpaks.txt`, absent de la baseline du 28 août uniquement parce qu'il
> était vide et que le script supprime les fichiers vides.

---

## Instantanés Btrfs — snapper

> **Statut : en place le 2026-09-03** sur l'itération 01, et **remis en place le
> 2026-09-04 sur le poste de référence** (NVMe interne, LUKS, sous-volumes `root` et
> `home`). Détails de cette seconde mise en place à la fin de la fiche.

### Rôle

Retour arrière local : annuler une mise à jour qui casse, rattraper une manipulation
ratée, récupérer un fichier écrasé. Et, pour ce lab spécifiquement, **voir ce qu'une mise
à jour a changé** (`snapper diff`), ce qui est une donnée d'évaluation en soi.

> **Ce n'est PAS une sauvegarde.** Les instantanés vivent sur le disque qu'ils protègent.
> Ils ne survivent ni à une panne du support, ni au wipe de l'itération suivante.
>
> **Et l'échéance annoncée ici est arrivée — le 2026-09-04.** Ce paragraphe disait : « le
> choix est assumé, le disque interne porte un Windows opérationnel qui sert de secours ;
> le jour où ce Windows sera formaté, la question de la sauvegarde hors machine se
> reposera entièrement ». Ce Windows **n'existe plus**, le NVMe est entièrement Fedora.
> Il n'y a donc, à ce jour, **aucun secours hors du disque de travail** : ni second
> système amorçable, ni copie hors machine. Le NAS est monté depuis le 2026-09-04 et
> serait une destination possible, mais rien n'est configuré.
>
> Ce n'est pas une décision à prendre dans cette fiche — c'est un **point ouvert** à
> assumer explicitement, comme la contrainte fondatrice disparue l'a été dans `CLAUDE.md`.
> Le noter évite de croire plus tard que les instantanés tenaient ce rôle.

### Obtention

`snapper` 0.13.0, dépôt Fedora, 4 paquets pour 3 Mio. Rien d'autre à installer.

Trois choses **n'existent pas** sur Fedora et il vaut mieux le savoir avant d'espérer :

| Manquant | Conséquence |
|---|---|
| ~~`grub-btrfs` absent des dépôts~~ — **résolu le 2026-09-07** | Le paquet est absent des dépôts Fedora, mais un COPR le fournit : les instantanés **sont amorçables** depuis le menu GRUB. Voir la sous-fiche « grub-btrfs » plus bas |
| Pas de greffon snapper pour **dnf5** | **Aucun instantané automatique avant/après transaction.** `python3-dnf-plugin-snapper` existe mais vise dnf4 ; le système utilise dnf5 |
| Timeshift inutilisable en mode Btrfs | Sa propre description l'annonce : « supported only on BTRFS systems having an Ubuntu-type subvolume layout (with @ and @home subvolumes) ». Fedora nomme ses sous-volumes `root` et `home` |

Autrement dit, le scénario « la mise à jour casse, je reboote sur l'instantané d'avant »
qu'on associe à openSUSE **n'est pas livré clé en main ici**. Ce qui marche sans effort,
c'est l'instantané manuel avant opération risquée, et la récupération de fichiers.

> **Nuance apportée le 2026-09-07.** La moitié « je reboote sur l'avant » est désormais
> disponible : `grub-btrfs` installé depuis un COPR génère les entrées. Mais l'autre
> moitié — « la mise à jour crée l'instantané toute seule » — **manque toujours**, faute
> de greffon snapper pour dnf5. Le filet existe, il faut encore le tendre à la main avant
> chaque opération risquée. Ne pas lire la première ligne de ce tableau comme si le
> scénario openSUSE était reconstitué.

### Portabilité

Dépend entièrement du **système de fichiers**, pas de la distro : sans Btrfs (ou ZFS avec
un autre outillage), rien de tout ceci n'existe. À noter comme critère lors du choix du
partitionnement de la prochaine itération — c'est décidé **à l'installation**, comme le
chiffrement.

### Prérequis : sortir le disque de la VM des instantanés

`/var/lib/libvirt/images` a été converti en **sous-volume Btrfs**. Un sous-volume n'est
jamais inclus dans l'instantané de son parent, ce qui règle deux problèmes d'un coup :

1. **Le `nodatacow` serait annulé** — un instantané force le copy-on-write à revenir sur
   un fichier `chattr +C` : la première écriture après l'instantané doit recopier.
2. **L'espace exploserait** — chaque instantané quotidien retiendrait les anciens blocs du
   qcow2 à mesure que Windows écrit.

Vérifié après coup : le dossier existe dans l'instantané mais contient **0 entrée**.

### Configuration retenue

Deux configurations, `root` et `home`, réglages identiques :

```
TIMELINE_CREATE=yes      TIMELINE_CLEANUP=yes     TIMELINE_MIN_AGE=1800
TIMELINE_LIMIT_HOURLY=0  TIMELINE_LIMIT_DAILY=7   (weekly/monthly/yearly = 0)
NUMBER_CLEANUP=yes       NUMBER_LIMIT=10          NUMBER_LIMIT_IMPORTANT=5
ALLOW_USERS=jzielona     SYNC_ACL=yes
```

Deux minuteurs : `snapper-timeline.timer` crée, `snapper-cleanup.timer` applique la
rétention. Les deux `enabled`.

**Le « quotidien » de snapper fonctionne par soustraction** : le minuteur crée un
instantané *toutes les heures*, et c'est le nettoyage qui ne conserve que le premier de
chaque journée. Voir passer des instantanés horaires éphémères est le comportement normal,
pas un réglage raté. Passer `TIMELINE_LIMIT_HOURLY` à 6 garderait en plus les six
dernières heures, pour quasiment rien.

Les instantanés **manuels** (`single`) et **automatiques** (`timeline`) relèvent de deux
politiques distinctes : `NUMBER_LIMIT=10` pour les premiers, `TIMELINE_LIMIT_DAILY=7` pour
les seconds. **La rotation quotidienne n'efface donc jamais un instantané pris à la main.**

**État vérifié le 2026-09-07 sur le poste de référence** — et il confirme la théorie
ci-dessus, ce qui est rare assez pour être noté :

| Config | Instantanés | Nature |
|---|---|---|
| `root` | 1, 7, 8, 9, 10, 11 | `timeline` sauf le **10**, `single` : « avant grub-btrfs » |
| `home` | 1, 7, 8, 9 | tous `timeline` |

Un par jour depuis le 2026-09-04, plus celui pris à la main avant d'installer
`grub-btrfs` — qui a bien survécu à deux rotations quotidiennes. `ALLOW_USERS=jzielona` +
`SYNC_ACL=yes` expliquent au passage pourquoi `/.snapshots` est listable sans `sudo` :
c'est voulu, pas un défaut de permissions.

> **`grub-btrfsd` ne surveille QUE `/.snapshots`, pas `/home/.snapshots`.** Vérifié dans
> l'unité : `ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots`, et l'`inotifywait`
> associé ne regarde que ce dossier. **Les instantanés de `/home` n'apparaîtront donc
> jamais au menu GRUB** — ce qui est cohérent, on ne démarre pas sur un `/home`, mais qui
> se lit comme un oubli de configuration si on ne le sait pas. Restaurer `/home` se fait
> depuis un système démarré, avec `snapper -c home`, pas depuis GRUB.

### Usage

```bash
snapper -c root create -d "avant dnf update"   # avant toute opération risquée
snapper -c root list
snapper -c root status 1..2                    # quels fichiers ont changé
snapper -c root diff  1..2                     # ce qui a changé dedans
```

`ALLOW_USERS` + `SYNC_ACL` rendent tout ceci utilisable **sans `sudo`**.

Le cas le plus fréquent ne demande aucune commande snapper — les instantanés sont montés
en lecture seule et se parcourent comme des dossiers ordinaires :

```bash
cp -a /home/.snapshots/1/snapshot/jzielona/.config/foo ~/.config/
```

### Restaurer `/` sans casser `/home` — la nuance qui compte

Un `dnf update` écrit dans `/`, **jamais dans `/home`**. Restaurer `/` seul défait donc
complètement la mise à jour. Le risque résiduel est ailleurs : **les applications migrent
leur propre configuration dans `$HOME`** au premier lancement d'une nouvelle version
(schéma `gsettings`, base d'un client mail, `settings.toml`…). L'ancien binaire retrouve
alors une configuration qu'il ne comprend plus.

> **Instantanier les deux ne veut pas dire les restaurer ensemble.** Restaurer `/home` en
> entier écraserait tout le travail depuis l'instantané. La bonne séquence : restaurer `/`,
> puis, si une application boude encore, aller copier **son seul dossier** depuis
> l'instantané `/home`. Le `/home` est un filet, pas un bouton « tout annuler ».

### grub-btrfs — retenu pour la cible, **sans contrainte de partitionnement**

> **CORRIGÉ le 2026-09-04, quelques heures après avoir été écrit.** Ce qui suit affirmait
> que `grub-btrfs` ne peut pas fonctionner avec un `/boot` séparé, et en tirait une
> décision de partitionnement irrattrapable. **C'était faux**, et le poste de référence a
> été monté avec un `/boot` ext4 séparé en toute connaissance de cause. Raisonnement
> complet dans `installation/README.md` ; la leçon de méthode est dans `CLAUDE.md`.

C'est lui qui ajoute au menu GRUB une entrée par instantané, donc ce qui manque au scénario
« la mise à jour casse, je redémarre sur l'instantané d'avant » noté plus haut comme absent.

**Il gère nativement un `/boot` séparé.** Son README l'annonce — « Automatically detect if
`/boot` is in a separate partition » — et fournit
`GRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION` pour les cas où la détection échoue. Dans
cette disposition, il prend le noyau sur la partition `/boot` **vivante** et lui ajoute
`rootflags=subvol=<instantané>` : c'est la manipulation manuelle décrite plus bas, générée
automatiquement en entrée de menu.

**Ce qui était faux, et pourquoi.** Le raisonnement d'origine était : `grub-btrfs` cherche
le noyau *dans* l'instantané, or un `/boot` séparé y laisse un dossier vide, donc aucune
entrée n'est générée. Le mécanisme décrit est correct pour un `/boot` intégré ; la faute est
d'en avoir déduit une impossibilité sans lire ce que l'outil dit de lui-même.

**La seule limitation réelle**, acceptée : le noyau vient du `/boot` vivant, pas de
l'instantané. Remonter un instantané pris **avant** une mise à jour de noyau donne un
décalage avec `/lib/modules`. Contournement : choisir aussi l'ancienne entrée de noyau au
menu GRUB — Fedora en garde trois.

**Et un `/boot` chiffré serait pire.** Sur le poste de référence, `/` est dans LUKS. Y
mettre `/boot` obligerait **GRUB** à ouvrir LUKS lui-même, et son `cryptomount` ne connaît
que la phrase de passe et le fichier clé — **aucun support TPM2**. On perdrait le
déverrouillage automatique pour gagner une fonctionnalité qu'on a déjà. Le `/boot` séparé
n'est donc pas un pis-aller : c'est la bonne disposition.

**Attention à l'obtention : `grub-btrfs` n'est pas dans les dépôts Fedora** — vérifié le
2026-09-04, re-vérifié le 2026-09-07, `dnf` ne connaît aucun paquet de ce nom. C'est un
composant hors dépôt de plus, à traiter comme tel (origine et version notées dans
`installation/procedure.md`).

**Trois voies, et une seule tient — comparaison du 2026-09-07.**

| Voie | Verdict |
|---|---|
| **COPR `pego-copr/grub-btrfs`** | **retenu** — `grub-btrfs-4.14-1.fc44`, construit le 2 mars 2026 pour le chroot f44 |
| COPR `kylegospo/grub-btrfs` | **écarté** — instantané git de septembre 2022, release `.fc38` recopiée dans le chroot f44. Le nom du chroot ne dit rien de l'âge du paquet |
| `make install` depuis le git upstream | **écarté** — pose dans `/usr/local`, donc exactement le piège SELinux du greeter Noctalia, et aucune mise à jour |

> **Le nom d'un chroot COPR n'est pas une preuve de fraîcheur.** `kylegospo` apparaît bien
> avec `fedora-44-x86_64` dans ses chroots actifs, ce qui laisse croire à un paquet à jour ;
> la `release` dit `.fc38` et le `buildtime` dit 2022. Interroger le paquet, pas la liste
> des chroots : `dnf repoquery --repofrompath=… --qf '%{name}-%{version}-%{release} (%{buildtime})'`
> répond sans rien installer. Même famille que « un dépôt activé n'est pas un paquet installé ».

**Le RPM a été ouvert avant d'être installé** (`rpm -qlp`, `rpm -qRp`, `rpm -qp --scripts`,
`rpm2cpio`), et c'est ce qui a évité une mauvaise surprise :

- contenu propre et packagé — `/usr/bin/grub-btrfsd`, `/etc/grub.d/41_snapshots-btrfs`,
  `/etc/default/grub-btrfs/config`, `/usr/lib/systemd/system/grub-btrfsd.service`, deux
  pages de manuel. **Rien dans `/usr/local`**, donc étiquetage SELinux fait par RPM ;
- `Requires: grub2-tools btrfs-progs inotify-tools util-linux` — seul `inotify-tools`
  manquait sur la machine ;
- le `config` livré **détecte Fedora tout seul** (`if [ -f /etc/fedora-release ]`) et pose
  `GRUB_BTRFS_GRUB_DIRNAME=/boot/grub2`, `MKCONFIG=/usr/sbin/grub2-mkconfig`,
  `SCRIPT_CHECK=grub2-script-check`. Aucune édition nécessaire ;
- l'unité surveille déjà `/.snapshots`, le chemin exact de snapper ici ;
- **et le `%post` lance `grub2-mkconfig -o /boot/grub2/grub.cfg` de lui-même.** C'est le
  seul point qui demandait une précaution : `dnf install` réécrit `grub.cfg` sans le
  demander, sur une machine en UEFI + BLS. La copie de sauvegarde se prend **avant**
  l'installation, pas après. Lire les scriptlets d'un RPM hors distribution avant de
  l'installer, c'est ce qui permet de le savoir.

**La porte de sortie existe sans rien installer** — utile sur une distro où `grub-btrfs`
n'est pas disponible, et le jour où le menu généré serait lui-même cassé. `/boot` étant
séparé et partagé, le noyau est trouvé quelle que soit la racine choisie : au menu GRUB,
touche `e`, puis passer la racine voulue en option de noyau. Les instantanés étant en
lecture seule, le système démarre dégradé — assez pour restaurer, pas pour travailler.
**À répéter à froid une fois, pas le jour où ça casse.**

> **CORRIGÉ le 2026-09-07 — un chemin qui n'aurait pas démarré.** Cette ligne disait :
> « remplacer `rootflags=subvol=root` par `rootflags=subvol=.snapshots/<N>/snapshot` ».
> La **forme** était bonne, le **chemin** était faux.
>
> `/` est monté en `subvol=/root` et `.snapshots` est imbriqué *dedans* : depuis la racine
> Btrfs, un instantané est **`root/.snapshots/<N>/snapshot`**. C'est grub-btrfs qui l'a
> démenti en une ligne de sa propre sortie —
> `Found snapshot: … | root/.snapshots/10/snapshot | single | avant grub-btrfs |`.
>
> Manip correcte, mesurée sur l'entrée vivante (`sudo grubby --info=ALL`) :
>
> ```
> args="ro rootflags=subvol=root rd.luks.uuid=luks-680cb146-… rhgb quiet"
>                        ^^^^ remplacer par root/.snapshots/<N>/snapshot
> ```

> **Deux fichiers, deux formes de `rootflags` — ne pas les confondre.** L'entrée BLS
> vivante porte `rootflags=subvol=root`, `subvol` seul. Le `grub-btrfs.cfg` généré porte
> `rootflags=compress=zstd:1,x-systemd.device-timeout=0,subvol="root/…"`, car grub-btrfs
> reconstruit la ligne depuis `GRUB_CMDLINE_LINUX` et les options de `fstab` au lieu de
> reprendre les `args` BLS.
>
> *Piège de méthode qui en découle, vécu le 2026-09-07 :* un `grep -o 'rootflags=subvol=[^ ]*'`
> lancé sur le **fichier généré** ne renvoie **rien**, alors que le motif est parfaitement
> valable pour l'**entrée vivante**. Sortie vide, motif correct, mauvaise cible — et la
> conclusion tirée sur le coup (« la forme de l'option est différente de ce que dit la
> note ») était fausse. **Une sortie vide ne distingue pas un motif inadapté d'une cible
> inadaptée.**

### Démarrer sur un instantané : ce sera DÉGRADÉ, et c'est documenté

> **Recherché le 2026-09-07 dans la documentation de l'outil, pas déduit.** Le `ro` absent
> des entrées générées avait fait craindre un échec de montage. Ce n'est pas le sujet :
> dracut monte la racine depuis la ligne de commande du noyau, et un sous-volume en lecture
> seule se monte en lecture seule quoi qu'on demande. **Le vrai problème est en espace
> utilisateur**, et le projet l'annonce lui-même.

`/etc/grub.d/41_snapshots-btrfs`, lignes 11-12, porte l'avertissement en tête de fichier :

```
#   Warning : booting on read-only snapshots can be tricky.
#   (Read about it, https://github.com/Antynea/grub-btrfs#warning-booting-on-read-only-snapshots-can-be-tricky)
```

Et la section pointée dit la condition en une phrase :

> « If you wish to use read-only snapshots, `/var/log` or even `/var` must be on a separate
> subvolume. Otherwise, make sure your snapshots are writable. »

**Ce poste est exactement dans le cas qui échoue, et c'est mesuré :** `findmnt -t btrfs`
ne montre que deux sous-volumes montés, `root` et `home`. `/var` et `/var/log` sont
**dans** `root`, donc dans l'instantané, donc en lecture seule au démarrage. C'est la
disposition Fedora par défaut — pas une erreur de montage de notre part.

**Les deux échappatoires officielles sont fermées ici, chacune pour une raison propre :**

| Voie annoncée par le projet | Pourquoi elle ne s'applique pas |
|---|---|
| `/var` (ou au moins `/var/log`) en sous-volume séparé | Décision de **partitionnement**, à prendre à l'installation. Ne se rattrape pas d'un `mount` |
| overlayfs en RAM — `rd.live.overlay.overlayfs=1` / `rd.live.overlay.readonly=1`, à passer via `GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS` | Le module dracut `70overlayfs` **est bien présent**, mais le projet annonce que **dracut < 109 exige un correctif manuel** — et la machine est en **dracut-108-7.fc44** |
| Rendre l'instantané inscriptible (`btrfs property set -ts <chemin> ro false`) | Possible ponctuellement, mais casse la garantie qui fait l'intérêt d'un instantané. À réserver à une restauration en cours |

Et l'[issue #324](https://github.com/Antynea/grub-btrfs/issues/324) décrit **précisément** ce
cas — Fedora qui se fige juste avant l'écran de connexion GNOME depuis un instantané en
lecture seule. L'utilisateur a essayé les trois options ci-dessus, **aucune n'a marché**,
et l'issue est **toujours ouverte**. Ce n'est donc pas un réglage qui nous manque : c'est
un problème non résolu en amont.

> **Conclusion, et elle ne change pas la décision.** La phrase déjà écrite dans cette fiche
> — « le système démarre dégradé, assez pour restaurer, pas pour travailler » — était juste.
> Elle est maintenant **appuyée sur la documentation de l'outil et sur la disposition
> mesurée du disque**, plus sur une intuition. Ce qu'il faut en retenir pour le jour où ça
> sert : **ne pas attendre un bureau utilisable**. On démarre sur un instantané pour
> obtenir un shell et lancer une restauration, point. Espérer une session GNOME complète
> ferait perdre du temps à chercher une panne qui n'en est pas une.

**Ce qui reste à mesurer, et c'est plus étroit qu'avant :** jusqu'où va « dégradé ». Un
shell root sur tty suffit-il à lancer `snapper rollback` ? C'est la seule question ouverte,
et elle se répond en dix minutes à froid — pas le jour où ça casse.

### À refaire à la main après une bascule

1. Vérifier que la nouvelle distro est bien en **Btrfs** — sinon toute cette fiche tombe.
2. Installer `snapper`.
3. **Convertir `/var/lib/libvirt/images` en sous-volume avant tout instantané** (voir la
   fiche VM Windows) — sinon le disque de la VM entre dans les instantanés.
4. `create-config` pour `root` et `home`, réappliquer les réglages ci-dessus.
5. Activer `snapper-timeline.timer` et `snapper-cleanup.timer`.
6. **Installer `grub-btrfs`** — hors dépôt Fedora (vérifié le 2026-09-04, re-vérifié le
   2026-09-07). Aucune condition de partitionnement : il gère un `/boot` séparé, mesuré.
   Sur Fedora : COPR `pego-copr/grub-btrfs`. Vérifier tout de même qu'il **génère bien des
   entrées** après `grub2-mkconfig`, plutôt que de le supposer — et surtout que le
   `grub.cfg` principal **source** le fichier généré, sinon les entrées existent dans un
   fichier que personne ne lit.
7. **Activer `grub-btrfsd`** (`systemctl enable --now`), sans quoi le menu ne suit pas les
   instantanés créés ensuite.

### Mise en place sur le poste de référence — 2026-09-04

Ordre respecté à la lettre : **sous-volume `images` d'abord, snapper ensuite.** État
obtenu, tout vérifié plutôt que supposé :

| Mesure | Résultat |
|---|---|
| `var/lib/libvirt/images` | sous-volume ID 259, `+C` posé **à vide** (`lsattr` → `---------------C------`) |
| Contexte SELinux | `virt_image_t` |
| Configs | `root` (`/`) et `home` (`/home`), les 13 réglages relus un par un |
| Minuteurs | les deux `enabled` + `active` |
| `ALLOW_USERS=jzielona` | **effectif** — `snapper -c root list` répond sans `sudo` |

**Trois choses apprises ici et pas à l'itération 01.**

1. **Un sous-volume Btrfs fraîchement créé est `unlabeled_t`** — pas `var_lib_t`, pas le
   contexte de son parent : *rien*. Le `restorecon` a rapporté
   `Relabeled … from system_u:object_r:unlabeled_t:s0 to system_u:object_r:virt_image_t:s0`.
   Sans lui, `qemu` confiné n'aurait pas pu lire l'image, avec un « impossible d'ouvrir le
   disque » opaque — le même symptôme que le piège `mv`/`cp` noté dans la fiche VM, par une
   autre cause. Ici la politique connaît déjà le chemin, donc `restorecon` suffit et
   `semanage fcontext` est inutile (contrairement au greeter Noctalia le même jour).
2. **`systemctl enable` n'a annoncé qu'un lien sur deux.** Sa sortie ne mentionnait que
   `snapper-cleanup.timer`, alors que `/etc/systemd/system/timers.target.wants/` contient
   bien **les deux** liens, créés à la même seconde. Le message n'est pas l'inventaire de
   ce que la commande a fait : vérifier les liens, ou `is-enabled`.
3. **`snapper-timeline.timer` a `UnitFilePreset=disabled`** : il n'est pas activé par le
   preset Fedora. Il faut l'activer explicitement — installer `snapper` ne suffit pas à
   avoir des instantanés automatiques.

**Ce qui reste à faire sur ce poste :**

- [x] **Test d'exclusion de la VM — PROUVÉ le 2026-09-04.** Instantané `root` n°1 créé,
      puis `ls -a /.snapshots/1/snapshot/var/lib/libvirt/images/` → `.` et `..`
      seulement. Le dossier existe dans l'instantané et ne contient **rien** : c'est cette
      mesure qui prouve l'exclusion, le sous-volume seul ne la prouve pas.
      *Détail de notation :* `N` est le numéro rendu par `snapper list` — ne pas recopier
      un placeholder `<n>` dans une commande, le shell le prend pour une **redirection**
      et cherche un fichier nommé `n`.
      *Bénéfice constaté au passage :* la lecture a réussi **sans `sudo`**, ce qui prouve
      `SYNC_ACL=yes` — le `+` de `drwxr-x---+` sur `/.snapshots` est l'ACL posée pour
      `ALLOW_USERS`.
- [x] **`grub-btrfs` — en place le 2026-09-07.** Les instantanés sont amorçables depuis le
      menu GRUB. Compte rendu dans la sous-fiche ci-dessous.

### grub-btrfs en place — 2026-09-07

`grub-btrfs 4.14-1.fc44` (COPR `pego-copr/grub-btrfs`), script en version
`master-2026-05-31T15:55:08+00:00`. **Aucune ligne de configuration écrite** : le `config`
livré par le RPM détecte Fedora et l'unité surveille déjà `/.snapshots`. C'est le meilleur
cas possible pour un composant hors dépôt — encore fallait-il le vérifier avant, pas après.

État obtenu, chaque ligne mesurée :

| Mesure | Résultat |
|---|---|
| `rpm -q grub-btrfs` | `grub-btrfs-4.14-1.fc44.noarch` |
| `/etc/grub.d/41_snapshots-btrfs --version` | `master-2026-05-31T15:55:08+00:00` |
| Instantanés détectés au `%post` | **5**, chemins en `root/.snapshots/<N>/snapshot` |
| `grep -c menuentry /boot/grub2/grub-btrfs.cfg` | **11** = 1 en-tête + 5 instantanés × 2 noyaux |
| Le menu principal source-t-il le fichier ? | **oui** — `grub.cfg:266-274`, `configfile "${prefix}/grub-btrfs.cfg"` |
| `/boot` séparé détecté ? | **oui, sans rien forcer** — `GRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION` laissée commentée |
| `grub-btrfsd` | `enabled` + `active (running)`, `inotifywait` sur `/.snapshots` |

**Ce que la vérification du menu principal a évité.** Le script avertit lui-même :
« `grub2-mkconfig` needs to run at least once to generate the snapshots (sub)menu entry in
grub the main menu ». Compter 11 entrées dans `grub-btrfs.cfg` n'aurait rien prouvé — un
fichier plein d'entrées qu'aucun `configfile` ne lit est indiscernable, de l'extérieur,
d'une installation qui marche. Les deux mesures sont nécessaires, pas la première seule.

**Le `/boot` séparé, enfin mesuré et non plus déduit.** L'entrée générée est
`linux "/vmlinuz-7.1.13-200.fc44.x86_64"` — chemin relatif à la racine de la partition
`/boot` — précédé d'un `search --no-floppy --fs-uuid --set=root 4a4ba7f7-…`, l'UUID de
l'ext4. Le noyau vient donc du `/boot` **vivant**, et `rd.luks.uuid=` est conservé dans la
ligne de commande. C'est le démenti du 2026-09-04 confirmé par l'observation : la
disposition Fedora par défaut n'interdisait rien.

**Et le démon fait moins de dégâts que supposé.** On pouvait craindre qu'il relance un
`grub2-mkconfig` complet à chaque instantané — donc un `os-prober` toutes les heures.
`grub-btrfsd:209-216` dit l'inverse : il teste si `grub.cfg` contient `snapshots-btrfs`, et
si oui n'appelle que `/etc/grub.d/41_snapshots-btrfs`, qui régénère le seul
`grub-btrfs.cfg`. Le `grub2-mkconfig` complet reste réservé aux mises à jour de noyau.
**Lu dans le script, pas supposé** — et la supposition était pessimiste, ce qui arrive
aussi.

**Un effet de bord à connaître.** Le `grub2-mkconfig` du `%post` a rapporté
`Found Fedora Linux 44 (Workstation Edition) on /dev/sda3` : `os-prober` a trouvé le **SSD
USB du lab** (itération 01) et lui a ajouté une entrée de menu. Le menu GRUB du poste
dépend donc de ce qui est **branché au moment d'un `grub2-mkconfig` complet** — une entrée
vers l'itération 01 qui apparaît ou disparaît selon le câble. Sans conséquence, mais à ne
pas prendre pour une anomalie le jour où on la voit bouger.

**Ce qui reste vrai malgré tout : un instantané amorçable n'est pas une sauvegarde.** Voir
l'encadré en tête de fiche — les instantanés vivent toujours sur le disque qu'ils
protègent. `grub-btrfs` répare le scénario « la mise à jour casse », pas le scénario « le
disque meurt ».

### Versionné dans le dépôt

Rien. Les configurations vivent dans `/etc/snapper/configs/` et
`/etc/default/grub-btrfs/config`, hors du périmètre de Stow qui ne gère que `$HOME`. Le
fichier de grub-btrfs est **laissé tel que livré**, sans aucune modification : c'est une
information à conserver, puisqu'une future mise à jour du paquet ne rencontrera donc aucun
conflit. Les réglages snapper sont reproduits dans cette fiche — c'est elle qui fait foi.

---

## WinBox — administration des routeurs MikroTik

> **Statut : installé le 2026-09-03** (14:21 locales), Flatpak Flathub, version 4.3.

### Rôle

Accès à l'interface d'administration des **routeurs MikroTik** du parc. Outil
d'administration réseau, au même titre que RustDesk l'est pour les postes.

### Obtention

```bash
flatpak install flathub com.mikrotik.WinBox
```

| | |
|---|---|
| Référence | `app/com.mikrotik.WinBox/x86_64/stable` |
| Version | 4.3 |
| Licence | **propriétaire** (`LicenseRef-proprietary`) — seul outil du poste dans ce cas |
| Runtime | `org.freedesktop.Platform` 25.08, **déjà présent** |
| Taille installée | **1,6 Mo** |
| Portée | **`user`** — voir ci-dessous |

**1,6 Mo pour une application complète** : c'est la démonstration directe de ce qui est
écrit dans la fiche Mattermost. Le premier Flatpak a coûté ~2 Go de runtime ; celui-ci
partage le même `org.freedesktop.Platform 25.08` et ne coûte que sa propre taille.

### Attention : portée d'installation différente de Mattermost

> **RÉSOLU sur le poste de référence le 2026-09-07** — les deux applications y sont en
> portée **`system`**. L'écart décrit ci-dessous est celui de l'itération 01, gardé parce
> qu'il explique pourquoi la colonne `installation` a été ajoutée à `flatpaks.txt`.
> Réinstallation notée dans `installation/procedure.md`, section 8.

```
com.mattermost.Desktop   system   -> /var/lib/flatpak          (tous les comptes)
com.mikrotik.WinBox      user     -> ~/.local/share/flatpak    (ce compte seul)
```

WinBox a été installé en portée **utilisateur**, ce qui a ajouté au passage un dépôt
`flathub` au niveau utilisateur en plus de celui du système. Ce n'est pas un problème,
mais **c'est une incohérence à connaître** :

- une installation `user` vit dans `$HOME`, donc elle est **capturée par les instantanés
  `/home`** ; une installation `system` vit sous `/` ;
- « réinstaller à l'identique » après une bascule suppose de savoir laquelle des deux.

`bin/snapshot.sh` enregistre désormais cette colonne dans `flatpaks.txt` — elle manquait
jusqu'au 2026-09-03.

### Portabilité

Même argument que Mattermost : **le même Flatpak s'installe à l'identique sur n'importe
quelle distro**, coût de bascule nul. L'outil sort donc du périmètre de comparaison des
distributions, puisqu'il s'y comporte pareil.

### Intégration au bureau — XWayland, contrairement à Mattermost

Le manifeste ne demande **que** le socket X11 et force `QT_QPA_PLATFORM=xcb` :

```
sockets=x11;
QT_QPA_PLATFORM=xcb
```

WinBox passe donc par **XWayland**, là où Mattermost est un client Wayland natif. C'est un
point à surveiller pour l'axe « bureaux » : mise à l'échelle, presse-papiers et capture
d'écran suivent des chemins différents sous XWayland. À noter si une friction apparaît —
et à ne pas imputer à Sway sans avoir vérifié quel chemin l'application emprunte.

### Permissions déclarées

```
shared=ipc;network;
sockets=x11;
devices=dri;
filesystems=home;/media;/run/media;/mnt;xdg-run/gvfs;
```

Accès complet au dossier personnel et aux points de montage amovibles. Relevé factuel,
pour l'inventaire.

### À refaire à la main après une bascule

1. Vérifier que Flathub est configuré.
2. `flatpak install flathub com.mikrotik.WinBox` — **décider de la portée** (`--user` ou
   défaut système) plutôt que de la subir.
3. Reconfigurer les accès aux routeurs (adresses, identifiants) : rien de tout cela n'est
   dans le dépôt.

### Versionné dans le dépôt

Rien. La configuration vit dans `~/.var/app/com.mikrotik.WinBox/` et contiendrait des
accès à des équipements réseau.

---

## Cible pour l'installation finale — réflexion du 2026-09-03

> **CETTE NOTE A ÉTÉ DÉPASSÉE PAR LES FAITS le 2026-09-04.** L'installation a eu lieu, et
> les décisions qu'elle instruisait sont désormais prises et consignées dans
> **`installation/README.md`**, qui fait foi. Ce qui suit est conservé pour son travail de
> mesure (dépendances de Nautilus, lignes PAM de GDM, absence d'Hyprland des dépôts), pas
> pour ses conclusions.
>
> Trois points ont changé : « installation finale » est devenu **poste de référence** (une
> réinstallation est envisagée, donc la reproductibilité est une exigence) ; la contrainte
> sur `/boot` était **fausse** ; et le greeter retenu est **le greeter Noctalia**, dont les
> conditions réelles ont été vérifiées le 2026-09-04 — `greetd` reste obligatoire, le
> greeter est un projet séparé à compiler, et il embarque son propre compositeur wlroots.
>
> **Ce n'est pas une fiche d'outil, c'est une note de décision.** Elle sert à ne pas
> refaire ce raisonnement dans plusieurs semaines, un installateur ouvert devant soi.

### Le contexte, à ne pas confondre

Cette machine est un **lab** : on y empile Sway, Noctalia, Hyprland peut-être, pour les
éprouver côte à côte. L'accumulation y est volontaire et ne viole aucun protocole.

**L'installation finale est un autre moment** : une seule pile, aucune brique inutile.
Ce qui suit décrit cette cible-là. Le protocole de baseline reste inchangé pour comparer
les distributions entre elles.

### Ce dont la cible dépend réellement

L'itération 01 a suivi le chemin GNOME complet → Sway → Noctalia. La question posée est :
peut-on aller directement à la cible ? La réponse est oui, et la liste est courte.

| Composant | Statut pour la cible |
|---|---|
| **GNOME Shell, Mutter, gnome-session, Logiciels, Évince…** | **Inutiles.** Rien n'en dépend une fois Sway et Noctalia en place |
| `gnome-keyring`, `gvfs`, `gcr`, `xdg-desktop-portal-*` | **Gardés** — ce n'est pas « GNOME le bureau », c'est de la plomberie freedesktop que la plupart des environnements utilisent |
| **`gdm`** | **Remplaçable.** Voir ci-dessous |
| **`nautilus`** | **Gardé** — décision du 2026-09-03, il ne gêne pas. Vérifié installable seul |

### GDM n'est pas obligatoire — ce sont trois lignes PAM

Le journal du 1er septembre notait que `gnome-keyring` est déverrouillé « par PAM au login
GDM ». Exact, mais l'important n'est pas GDM : ce sont les lignes de sa pile PAM.

```
/etc/pam.d/gdm-password
  auth      optional  pam_gnome_keyring.so
  password  optional  pam_gnome_keyring.so use_authtok
  session   optional  pam_gnome_keyring.so auto_start
```

**N'importe quel greeter peut les porter.** `greetd` (0.10.3, dépôt Fedora) a sa propre
pile PAM à compléter, et `gtkgreet`/`tuigreet` sont également packagés.

Corollaire : GDM sort de la liste des dépendances GNOME incontournables. Ce qui restait le
principal argument pour garder un bout de GNOME tombe.

### Le greeter Noctalia existe, mais pas dans le paquet Fedora

L'IPC le nomme explicitement :

```
noctalia msg greeter-sync
  → « Sync wallpaper, colors, and monitor layout to Noctalia Greeter »
```

Mais `rpm -ql noctalia` ne contient aucun fichier de greeter et `dnf search noctalia` ne
retourne rien d'autre. **À récupérer en amont** — vraisemblablement une configuration
Quickshell lancée par `greetd`. **À vérifier avant de compter dessus.**

### Nautilus s'installe seul — vérifié

C'était la dernière vraie application GNOME de la liste. Mesure de ses dépendances :

```
89 exigences : glib2, gtk4, libadwaita, gvfs, gnome-autoar,
               gsettings-desktop-schemas, libcairo, libX11 …
gnome-shell / mutter / gnome-session / gdm  ->  0 occurrence
```

`gnome-autoar` est une bibliothèque d'archives, `gsettings-desktop-schemas` un jeu de
définitions : **des bibliothèques, pas le bureau**. Nautilus est donc installable seul,
et il est **gardé** dans la cible.

### La piste qui le rendrait superflu — à tester, pas acquise

Nautilus n'est en réalité nécessaire que pour **une seule opération** : écrire le mot de
passe du NAS dans le trousseau, `gio mount` ne sachant pas le faire (piège documenté le
1er septembre).

**`secret-tool store`** (paquet `libsecret`) sait écrire dans le trousseau. Reste à
vérifier si `gvfsd` retrouve ensuite le secret sous le bon schéma et les bons attributs.
Si oui, la cible n'a plus **aucune** application GNOME. **Rien de tout cela n'est
vérifié** — c'est une piste, notée pour ne pas être réinventée.

### Hyprland : friction à chronométrer

Absent des dépôts Fedora — seuls `hyprcursor` (une bibliothèque) et `hypre` (algèbre
linéaire, sans rapport) y figurent. Il faudra un **COPR**. À noter comme donnée de
comparaison : Sway est dans les dépôts officiels **avec un groupe dédié**, Hyprland non.

> **CHRONOMÉTRÉE, et la facture n'est pas où on l'attendait.** Relevé le 2026-09-07 :
> le COPR `dtutila/hyprland` fournit **13 paquets**, dont il **remplace** toutes les
> bibliothèques `hypr*` de Fedora (`hyprgraphics` 0.5.1 contre 0.1.5, `hyprutils` 0.14.1
> contre 0.7.1) et en ajoute deux que Fedora n'a pas (`hyprwire`, `hyprtoolkit`).
>
> **La friction réelle n'a pas été l'obtention — une commande — mais le format de
> configuration.** hyprlang est déprécié depuis la 0.55 au profit d'une API Lua, et tous
> les tutoriels en ligne sont encore en hyprlang : 425 lignes écrites pour rien le
> 2026-09-04. Puis `code:NN`, qui marche en hyprlang, échoue **silencieusement** en Lua.
> Un logiciel tiré d'un COPR est justement celui qui bouge vite, et c'est ça qui coûte,
> pas le dépôt supplémentaire.
>
> **Coût récurrent à retenir pour la comparaison :** `dnf upgrade` doit **toujours** voir
> ce COPR activé, sinon Fedora tente de redescendre les bibliothèques `hypr*`. Sway,
> étant dans les dépôts officiels, n'imposait rien de tel. C'est une vraie différence
> entre les deux, et elle se paiera à chaque mise à jour.

### Ce qui se décide à l'installation, et nulle part ailleurs

Deux choses ne se rattrapent pas après coup et tombent au même moment :

1. **Le chiffrement du disque** — point ouvert de `CLAUDE.md`, rendu plus pressant par le
   fait que le système vit sur un SSD **externe**, qui se débranche.
2. **Le partitionnement** — Btrfs conditionne toute la fiche « Instantanés ».
   **L'emplacement de `/boot`, en revanche, n'est PAS une contrainte** : la version
   antérieure de ce point l'affirmait sur une prémisse fausse (voir la fiche
   « Instantanés Btrfs », corrigée le 2026-09-04). `grub-btrfs` gère un `/boot` séparé,
   et un `/boot` chiffré coûterait le déverrouillage TPM. Le défaut Fedora convient.

Et une troisième, presque aussi difficile à rattraper : **le choix de l'image**
(Workstation complète, Everything netinstall, spin) détermine ce qu'il faudra désinstaller
ou composer.

### Navigateur

Passage de Firefox à **Chromium** (transaction 13, le 2026-09-03), par habitude — pas
pour une contrainte technique. Désinstallation de Firefox **envisagée, pas décidée**.

> **Question devenue sans objet sur le poste de référence.** Vérifié le 2026-09-07 :
> `firefox` **n'est pas installé** — l'image minimale ne l'a jamais posé, il n'y a donc
> rien à désinstaller. `chromium` 151.0.7922.173 tourne en `--ozone-platform=wayland`,
> nativement. La décision qui traînait depuis le 2026-09-03 a été tranchée par le choix de
> l'image, pas par une décision : c'est un cas où **changer de méthode a réglé une question
> qu'on croyait devoir arbitrer.** Reste valable pour le lab, où Firefox est présent.

À retenir pour la bascule : un navigateur porte sessions, extensions, marque-pages et mots
de passe enregistrés. **Aucun `stow` ne restaure ça** et rien n'est versionné ici — c'est
à traiter au même titre que les autres secrets, hors dépôt.
