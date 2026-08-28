# Itération 01 — Fedora 44 Workstation

| | |
|---|---|
| **Distribution** | Fedora Linux 44 (Workstation Edition) |
| **Environnement** | GNOME Shell 50.4, session Wayland |
| **Noyau** | 6.19.10-300.fc44.x86_64 |
| **Installation** | ISO Workstation officielle, options par défaut |
| **Début** | 2026-08-28 |
| **Fin** | — |
| **Statut** | 🟢 en cours |

## Pourquoi celle-ci en premier

Point de départ volontairement banal. Fedora Workstation est la référence de fait
du desktop Linux « moderne » : GNOME récent, Wayland par défaut, noyau très à jour,
SELinux actif. C'est la **baseline** — la distro contre laquelle je comparerai les
suivantes, pas nécessairement celle que je garderai.

Cycle court (~6 mois par version, ~13 mois de support) : bon pour voir vite ce que
donne un système à jour, à surveiller de près pour un poste d'alternance où je ne
veux pas passer mes journées à réparer des mises à jour.

## Configuration installée

**Install strictement vierge.** C'est délibéré : une baseline ne vaut que si elle est
reproductible à l'identique sur les distros suivantes.

Chronologie réelle, lue dans `dnf history` :

| Date | Transaction | Contenu |
|---|---|---|
| 22 avr. 2026 | 1 – 2 (`kiwi`) | Construction de l'image ISO **chez Fedora**. Pas une action de ma part : c'est la date de fabrication de l'ISO. |
| 28 août 16:09 | 3 | Langpacks français (`langpacks-fr`, dictionnaires LibreOffice, `man-pages-fr`). Déclenché **automatiquement** par le choix de langue au premier démarrage. |
| 28 août 16:18 | 4 | `dnf update` — 1550 paquets |
| 28 août 16:29 | 5 | `dnf install keepassxc` — 16 paquets |

**Le seul `dnf install` volontaire de cette machine est KeePassXC.** Tout le reste
vient de l'image de base ou de la mise à jour.

### Les dépôts tiers ne sont pas des ajouts

Quatre dépôts non-Fedora sont activés (google-chrome, RPM Fusion nonfree NVIDIA,
RPM Fusion nonfree Steam, COPR `phracek/PyCharm`). Ce ne sont **pas** des ajouts
manuels : les fichiers `.repo` appartiennent au paquet `fedora-workstation-repositories`,
livré dans l'image de base et désactivé par défaut.

```console
$ rpm -qf /etc/yum.repos.d/google-chrome.repo
fedora-workstation-repositories-38-9.fc44.x86_64
```

La case « Activer les dépôts tiers » de l'écran de bienvenue les bascule sur
`enabled=1`. Rien n'en a été installé pour autant : `google-chrome-stable` n'est
pas présent sur le système, le dépôt est simplement ouvert et disponible.

À retenir pour la comparaison : cette facilité est **spécifique à Fedora**. Sur
Debian ou openSUSE, obtenir les codecs, le pilote propriétaire ou Chrome demandera
des manipulations à chronométrer — ce sera une donnée de comparaison à part entière.

### Caractéristiques héritées de l'installateur

- **Btrfs** sur `/` et `/home` (sous-volumes), `/boot` en ext4, `/boot/efi` en vfat
- Swap sur **zram** — 8 Go compressés en RAM, aucune partition swap sur disque
- **SELinux** en mode `Enforcing`, firewalld actif

Détail complet et reproductible dans [`baseline/`](baseline/).

## Contrainte non négociable : KeePassXC

KeePassXC n'est pas un confort, c'est mon accès à mes mots de passe personnels.

**Conséquence : c'est un critère éliminatoire, pas une ligne de note.** Une distro
qui ne le fournit pas facilement n'est pas évaluable, quelles que soient ses autres
qualités. À vérifier **avant** d'installer quoi que ce soit :

- présent dans les dépôts officiels ? à quelle version ?
- sinon, disponible en Flatpak — et l'intégration au trousseau/navigateur suit-elle ?

Ici : `keepassxc-2.7.12`, dépôt Fedora officiel, sans manipulation. C'est la
référence à battre.

> La base `.kdbx` est exclue du dépôt par le `.gitignore`, volontairement.
> Mais l'exclure de git signifie que **rien ne la sauvegarde automatiquement** :
> c'est le point le plus dangereux de la méthode bare-metal. Sauvegarde hors machine
> obligatoire avant chaque bascule (voir `journal/README.md`, étape 5).

## Ce que je veux évaluer sur cette itération

- **Stabilité au quotidien** : est-ce que les mises à jour cassent quelque chose ?
- **Matériel Dell** : veille/reprise, gestion écrans, audio, périphériques USB.
- **Outillage SRC** : Podman, conteneurs, virtualisation (Boxes/libvirt), Ansible,
  clients réseau. Est-ce que les paquets sont présents et à jour dans les dépôts ?
- **SELinux** : combien de fois est-ce qu'il me gêne, et est-ce que je sais le diagnostiquer ?
- **Frictions Wayland** : partage d'écran, outils X11 anciens, accès distant.

## Verdict

*À remplir en fin d'itération, avant la bascule.*

| Critère | Note /5 | Commentaire |
|---|---|---|
| KeePassXC disponible | *éliminatoire* | ✅ dépôt officiel, 2.7.12, sans manipulation |
| Stabilité | | |
| Support matériel | | |
| Outillage SRC | | |
| Documentation / communauté | | |
| Confort quotidien | | |

**Conclusion :**
