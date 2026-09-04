#!/usr/bin/env bash
#
# 01-bureau-hyprland.sh — poser un bureau utilisable sur une Fedora minimale.
#
#   sudo ./installation/scripts/01-bureau-hyprland.sh
#
# CE QUE CE SCRIPT FAIT, ET RIEN D'AUTRE : installer des paquets. Il ne touche
# à aucun fichier de ton dossier personnel — lancé sous sudo, il y créerait des
# fichiers appartenant à root. La configuration est versionnée dans
# dotfiles/hypr/ et se pose avec stow, en utilisateur, après ce script.
#
# CE QU'IL N'INSTALLE VOLONTAIREMENT PAS :
#   - greetd et le greeter Noctalia  -> Hyprland se lance à la main pour l'instant
#   - gnome-keyring                  -> sans PAM de greeter il ne se déverrouillerait
#                                       pas tout seul ; il vient avec le greeter
#   - hyprlock / hypridle / hyprpaper -> Noctalia fait déjà verrouillage, veille
#                                       et fond d'écran. Deux composants sur la
#                                       même couche, c'est le piège swaybg.
#   - hyprpolkitagent                -> Noctalia fournit un panneau polkit
#
# Voir installation/README.md pour les décisions, installation/procedure.md pour
# la séquence complète.

set -euo pipefail

COPR_HYPRLAND="dtutila/hyprland"

if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être lancé en root :  sudo $0" >&2
    exit 1
fi

echo
echo "======================================================================"
echo " 1/4  Pilotes graphiques"
echo "======================================================================"
# Une image minimale n'installe AUCUN pilote graphique : sans mesa-dri-drivers,
# Hyprland ne démarre pas du tout. C'est la dépendance qu'on oublie parce
# qu'elle va de soi sur une image Workstation.
dnf install -y mesa-dri-drivers

echo
echo "======================================================================"
echo " 2/4  Dépôt COPR pour Hyprland"
echo "======================================================================"
# Hyprland n'est PAS dans les dépôts Fedora : seules ses bibliothèques y sont
# (hyprutils, hyprlang, hyprgraphics, hyprcursor, hyprland-protocols).
#
# ATTENTION, ce COPR est un dépôt tiers tenu par une personne — sa description
# est littéralement « my personal hyprland packages ». C'est un risque assumé
# et documenté : solopasha/hyprland, le COPR de référence, n'a AUCUN chroot
# fedora-44. Vérifié le 2026-09-04, celui-ci avait hyprland 0.56.2-3 construit
# avec succès deux jours plus tôt.
#
# Conséquence à surveiller : le COPR livre peut-être ses propres versions des
# bibliothèques hypr* que Fedora fournit déjà. Un décalage de versions entre
# les deux est le mode de panne le plus probable de cette pile.
dnf copr enable -y "$COPR_HYPRLAND"

echo
echo "======================================================================"
echo " 3/4  Compositeur, shell et terminal"
echo "======================================================================"
dnf install -y \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    noctalia \
    foot \
    stow \
    keepassxc

echo
echo "======================================================================"
echo " 4/4  Relevé des versions"
echo "======================================================================"
# Ces versions ont leur place dans installation/procedure.md : sans elles,
# « installer Hyprland depuis un COPR » n'est pas une instruction rejouable.
DEST="$(cd "$(dirname "$0")" && pwd)/versions-01.txt"

# ATTENTION — « rpm -q » RENVOIE UN CODE D'ERREUR pour tout paquet absent, et
# sous « set -e » ça tue le script. C'est exactement ce qui est arrivé au
# premier passage : « quickshell » avait été listé alors qu'il n'est PAS une
# dépendance de Noctalia 5 (livré en binaire natif, plus comme configuration
# Quickshell). Le script est mort ici, donc sans faire le chown ni afficher la
# suite — d'où un relevé appartenant à root dans un dépôt git utilisateur.
# Une commande d'inventaire ne doit jamais pouvoir interrompre un script :
# d'où le « || true ».
{
    echo "# Relevé produit par 01-bureau-hyprland.sh le $(date -Iseconds)"
    echo "# COPR utilisé : $COPR_HYPRLAND"
    echo
    echo "## Paquets installés"
    rpm -q hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
           noctalia foot stow keepassxc mesa-dri-drivers 2>&1 || true
    echo
    echo "## Bibliothèques hypr* — provenance réelle et écart avec Fedora"
    printf '%-24s %-16s %-28s %s\n' PAQUET VERSION VENDOR "VERSION FEDORA"
    rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{VENDOR}\n' 'hypr*' 2>/dev/null | sort |
      while IFS=$'\t' read -r n v ven; do
        fed=$(dnf repoquery --disablerepo='*copr*' --qf '%{version}-%{release}' "$n" 2>/dev/null | tail -1)
        printf '%-24s %-16s %-28s %s\n' "$n" "$v" "${ven:0:27}" "${fed:-absent de Fedora}"
      done
    echo
    echo "## Binaires en place"
    for b in Hyprland hyprctl noctalia foot keepassxc; do
        p=$(command -v "$b" 2>/dev/null || true)
        printf '  %-24s %s\n' "$b" "${p:-INTROUVABLE}"
    done
} > "$DEST"

# Le fichier est écrit sous sudo : il appartiendrait à root dans un dépôt git
# qui, lui, appartient à l'utilisateur.
if [ -n "${SUDO_USER:-}" ]; then
    chown "$SUDO_USER":"$(id -gn "$SUDO_USER")" "$DEST"
fi

cat "$DEST"

echo
echo "======================================================================"
echo " Terminé. La suite se fait EN UTILISATEUR, pas en root."
echo "======================================================================"
cat <<'SUITE'

  1. Poser la configuration (depuis ~/linux/dotfiles) :

         cd ~/linux/dotfiles
         stow -v -t ~ hypr foot

     stow ne remplace jamais un fichier existant : s'il refuse, c'est qu'un
     ~/.config/hypr/hyprland.conf est déjà là. L'écarter, ne pas forcer.

  2. Basculer sur un AUTRE terminal virtuel — Ctrl+Alt+F3 — et s'y connecter.
     Lancer Hyprland depuis le TTY courant le ferait passer sous le compositeur
     et emporterait la session en cours.

  3. Sur ce nouveau TTY :

         Hyprland

  4. À vérifier tout de suite, plutôt qu'à supposer :

         hyprctl devices    | grep -A2 layout     # AZERTY actif ?
         hyprctl monitors   | grep -E 'Monitor|at' # trois écrans bien placés ?

     Puis Super+Entrée (terminal), Super+D (lanceur), et Super + la rangée des
     chiffres pour changer d'espace.

  Ce qui ne marchera PAS encore, et c'est normal :
    - le trousseau ne se déverrouille pas tout seul (pas de greeter, donc pas
      de PAM) — KeePassXC s'ouvre à la main
    - ~/nas ne se monte pas : nas-infoadmin.service attend
      graphical-session.target, qui n'existe pas encore sous Hyprland

SUITE
