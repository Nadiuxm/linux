# Archive — « Cible pour l'installation finale », note du 2026-09-03

> **Ce fichier est une ARCHIVE. Il ne décrit pas le poste actuel.**
>
> C'est la note de décision écrite le 2026-09-03, **avant** que le poste de référence
> n'existe, pour instruire les choix de l'installation. Elle a été **dépassée par les
> faits le 2026-09-04** : l'installation a eu lieu et les décisions sont consignées dans
> `installation/README.md`, qui fait foi.
>
> Elle vivait jusqu'au 2026-09-07 dans `poste/README.md`, défini comme « l'inventaire
> **vivant** des outils de travail ». Une note périmée dans un inventaire vivant ne se
> contente pas d'être inexacte : c'est là qu'étaient 6 des 8 mentions de GDM du dépôt, et
> elles se lisaient comme un état courant. D'où le déplacement ici.
>
> **Ce qu'elle garde de valeur, et pourquoi elle n'est pas supprimée :** son travail de
> mesure (les 89 dépendances de Nautilus, les trois lignes PAM de GDM, l'absence
> d'Hyprland des dépôts, le coût du premier Flatpak). Ce qui est périmé, ce sont ses
> conclusions — pas ses mesures.

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
