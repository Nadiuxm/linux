# Journal de lab

Une itération = une distribution installée en bare-metal, utilisée pour de vrai,
puis remplacée. Un dossier par itération, numéroté dans l'ordre chronologique.

| # | Dossier | Distro | Statut |
|---|---|---|---|
| 01 | [`01-fedora-44-workstation/`](01-fedora-44-workstation/) | Fedora 44 Workstation | 🟢 en cours |

## Comment tenir le journal

Dans chaque itération :

- **`README.md`** — la fiche : ce que j'installe, pourquoi, dans quelles conditions.
  Se remplit au début, et se conclut par un verdict à la fin.
- **`journal.md`** — les entrées **datées**, ajoutées au fil de l'eau.
  Un problème rencontré = une entrée, écrite **le jour même**, tant que le détail est frais.
- **`baseline/`** — l'état machine capturé par `bin/snapshot.sh`. Généré, pas écrit à la main.

Règle : noter **le problème et le temps perdu**, pas seulement la solution.
« J'ai perdu 40 min sur le pilote NVIDIA » est une donnée de décision.
« J'ai installé akmod-nvidia » n'en est pas une.

## Procédure de bascule (avant de réinstaller la machine)

En bare-metal, une réinstallation détruit tout — ce dépôt local inclus.
À dérouler **intégralement** avant de lancer le moindre installateur :

1. Clore l'itération : verdict dans son `README.md`, dernière entrée dans `journal.md`.
2. `./bin/snapshot.sh` — capture finale de l'état du système.
3. Reporter dans `dotfiles/` toute config à conserver (voir `dotfiles/README.md`).
4. `git add -A && git commit && git push` — **vérifier que le push est bien passé sur GitHub**.
5. Sauvegarder hors machine ce que git ne porte pas : clés SSH/GPG, base KeePassXC,
   comptes navigateur, documents. Le `.gitignore` les exclut volontairement du dépôt.
6. **Machines virtuelles** — trois fichiers, et le deuxième s'oublie :
   - l'image disque, `/var/lib/libvirt/images/*.qcow2` (des dizaines de Go) ;
   - **le NVRAM**, `/var/lib/libvirt/qemu/nvram/*_VARS.qcow2` — minuscule, mais il porte
     les variables UEFI : clés Secure Boot et entrées d'amorçage. Sans lui, la VM
     restaurée ne redémarre pas comme avant ;
   - la définition, `virsh -c qemu:///system dumpxml <vm>`, légère et lisible.

   Au retour, replacer les images **puis** `restorecon` : `mv` conserve l'étiquette
   SELinux d'origine et `qemu`, confiné, ne pourra pas lire les fichiers.
   Voir `poste/README.md` pour le détail.
7. Vérifier depuis un autre appareil que le dépôt distant est à jour et complet.
8. Seulement là, installer la distro suivante — puis `git clone` en premier geste.

Une fois la machine réinstallée et la baseline capturée, **`poste/README.md` se déroule
de haut en bas** pour retrouver un poste opérationnel. Rien de ce qu'il contient ne doit
être installé avant la capture de la baseline.
