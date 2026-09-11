#!/usr/bin/env bash
# snapshot.sh — capture l'état du système dans une itération du journal.
#
# Ne demande aucun privilège.
#
# DEUX DESTINATIONS, À NE PAS CONFONDRE
#
#   baseline/          La photo FIGÉE de l'installation vierge. C'est la
#                      référence qui sert à comparer les distributions entre
#                      elles : elle est écrite UNE SEULE FOIS et ne doit jamais
#                      être réécrite. Le script refuse de l'écraser.
#
#   etats/<AAAA-MM-JJ>/  Toutes les captures ultérieures. C'est là que va une
#                      relance « après quelques jours d'usage » ou la capture
#                      finale avant une bascule.
#
# C'est cette séparation qui rend la relance utile — sans elle, une seconde
# exécution détruisait la référence au lieu de s'y comparer :
#
#     diff baseline/packages-explicit.txt etats/<date>/packages-explicit.txt
#
# LE POSTE DE RÉFÉRENCE N'EST PAS UNE ITÉRATION
#
# `installation/` est la pile retenue pour travailler, pas une distro en cours
# d'évaluation : le protocole de baseline ne s'y applique pas, et une baseline
# y mesurerait l'image ISO, pas la distribution. D'où `--poste`, qui écrit dans
# `installation/etats/<AAAA-MM-JJ>/` et n'écrit JAMAIS de baseline. L'écart
# affiché est alors celui avec la capture datée précédente — la question utile
# ici n'est pas « qu'ai-je ajouté à la distro » mais « qu'ai-je changé depuis
# la dernière fois ».
#
# Usage : ./uc/bin/snapshot.sh [--baseline | --poste] [dossier-iteration]
#         (depuis la racine du dépôt ; ./bin/snapshot.sh si on est dans uc/)
#         Sans argument      : dernière itération de journal/ par ordre alpha,
#                              et destination choisie automatiquement.
#         --baseline         : force l'écriture de baseline/ — refusée si elle
#                              existe déjà et n'est pas vide.
#         --poste            : capture le poste de référence dans
#                              installation/etats/<date>/, sans baseline.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FORCE_BASELINE=0
POSTE=0
case "${1:-}" in
    --baseline) FORCE_BASELINE=1; shift ;;
    --poste)    POSTE=1;          shift ;;
esac

if [ "$POSTE" -eq 1 ]; then
    ITER="$REPO/installation"
elif [ $# -ge 1 ]; then
    ITER="$REPO/journal/$(basename "$1")"
else
    ITER="$(find "$REPO/journal" -mindepth 1 -maxdepth 1 -type d | sort | tail -1)"
fi

if [ ! -d "$ITER" ]; then
    echo "Cible introuvable : ${ITER:-<aucune>}" >&2
    exit 1
fi

# --- Choix de la destination ---------------------------------------------
# Règle : baseline/ tant qu'elle n'existe pas, etats/<date>/ ensuite. La
# baseline n'est jamais écrasée en silence — c'est tout l'objet de ce bloc.
if [ -d "$ITER/baseline" ] && [ -n "$(ls -A "$ITER/baseline" 2>/dev/null)" ]; then
    BASELINE_EXISTE=1
else
    BASELINE_EXISTE=0
fi

if [ "$POSTE" -eq 1 ]; then
    # Pas de baseline ici, jamais : voir l'en-tête. La référence de comparaison
    # est la capture datée précédente, cherchée avant de créer la nouvelle.
    OUT="$ITER/etats/$(date +%F)"; KIND=etat
    # `grep -v` sur la destination du jour : sans lui, une seconde exécution le
    # même jour se comparerait à elle-même et n'afficherait jamais d'écart.
    PRECEDENTE="$(find "$ITER/etats" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
                  | grep -vFx "$OUT" | sort | tail -1)"
elif [ "$FORCE_BASELINE" -eq 1 ]; then
    if [ "$BASELINE_EXISTE" -eq 1 ]; then
        cat >&2 <<MSG
REFUS : ${ITER#$REPO/}/baseline existe déjà et n'est pas vide.

  La baseline est une photo figée de l'installation vierge : la réécrire
  ferait perdre la référence qui sert à comparer les distributions.

  Pour une capture datée      : $0 $(basename "$ITER")
  Pour la refaire réellement  : rm -rf ${ITER#$REPO/}/baseline  puis relancer.
MSG
        exit 1
    fi
    OUT="$ITER/baseline"; KIND=baseline
elif [ "$BASELINE_EXISTE" -eq 1 ]; then
    OUT="$ITER/etats/$(date +%F)"; KIND=etat
else
    OUT="$ITER/baseline"; KIND=baseline
fi

mkdir -p "$OUT"
if [ "$KIND" = baseline ]; then
    echo "Capture INITIALE (référence figée) vers ${OUT#$REPO/}"
elif [ "$POSTE" -eq 1 ]; then
    echo "Capture du POSTE DE RÉFÉRENCE vers ${OUT#$REPO/}"
    echo "  (pas de baseline ici : le protocole de comparaison ne s'y applique pas)"
else
    echo "Capture datée vers ${OUT#$REPO/}"
    echo "  (la baseline du ${ITER#$REPO/} n'est pas touchée)"
fi

# Détection du gestionnaire de paquets : le lab change de distro, le script non.
if   command -v dnf     >/dev/null; then PKG=dnf
elif command -v apt     >/dev/null; then PKG=apt
elif command -v pacman  >/dev/null; then PKG=pacman
elif command -v zypper  >/dev/null; then PKG=zypper
else PKG=inconnu
fi

# --- Système ---
{
    if [ "$KIND" = baseline ]; then echo "# Baseline système"; else echo "# État du système"; fi
    echo
    echo "Capturé le $(date '+%Y-%m-%d à %H:%M') par \`bin/snapshot.sh\`."
    echo
    echo '## Distribution'
    echo '```'
    grep -E '^(PRETTY_NAME|ID|VERSION_ID|VARIANT)=' /etc/os-release 2>/dev/null
    echo "Noyau        : $(uname -r)"
    echo "Architecture : $(uname -m)"
    echo "Paquets      : $PKG"
    echo '```'
    echo
    echo '## Environnement de bureau'
    echo '```'
    echo "Bureau  : ${XDG_CURRENT_DESKTOP:-inconnu}"
    echo "Session : ${XDG_SESSION_TYPE:-inconnu}"
    command -v gnome-shell >/dev/null && gnome-shell --version
    command -v plasmashell >/dev/null && plasmashell --version
    command -v hyprctl >/dev/null && hyprctl version 2>/dev/null | head -1
    command -v swaymsg >/dev/null && swaymsg -t get_version 2>/dev/null | head -1
    echo "Shell   : $SHELL"
    echo '```'
    echo
    echo '## Matériel'
    echo '```'
    echo "Machine : $(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null) $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)"
    lscpu 2>/dev/null | grep -E 'Model name|Nom de modèle|^CPU\(s\)|^Architecture'
    echo "RAM     : $(free -h | awk '/^Mem/ {print $2}')"
    echo '```'
    echo
    echo '## Stockage'
    echo '```'
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT 2>/dev/null
    echo
    df -hT -x tmpfs -x devtmpfs -x efivarfs 2>/dev/null
    echo '```'
    echo
    echo '## Sécurité'
    echo '```'
    command -v getenforce >/dev/null && echo "SELinux  : $(getenforce)"
    command -v aa-status  >/dev/null && echo "AppArmor : présent"
    # `firewall-cmd --state` passe par polkit et échoue sans agent de session :
    # il renvoyait une parenthèse vide. `systemctl is-active` ne demande rien.
    command -v firewall-cmd >/dev/null && echo "Pare-feu : firewalld ($(systemctl is-active firewalld))"
    command -v ufw >/dev/null && echo "Pare-feu : ufw"
    # Chiffrement et Secure Boot : structurants pour ce poste, et invisibles dans
    # tout le reste de la capture. `bootctl status` répond même sans privilège,
    # malgré les erreurs de lecture qu'il affiche sur /boot/efi.
    echo "Chiffrement : $(lsblk -no FSTYPE | grep -c crypto_LUKS) volume(s) LUKS"
    command -v bootctl >/dev/null && bootctl status 2>/dev/null | grep -E 'Secure Boot|TPM2 Support'
    echo '```'
} > "$OUT/system.md"

# --- Paquets installés explicitement ---
case "$PKG" in
    dnf)    dnf repoquery --userinstalled --qf '%{name}\n' 2>/dev/null | sort -u ;;
    apt)    apt-mark showmanual 2>/dev/null | sort -u ;;
    pacman) pacman -Qqe 2>/dev/null | sort -u ;;
    zypper) zypper --quiet se -i -t package 2>/dev/null | awk -F'|' 'NR>2 {gsub(/ /,"",$2); print $2}' | sort -u ;;
esac > "$OUT/packages-explicit.txt"

# --- Dépôts configurés ---
case "$PKG" in
    dnf)    dnf repolist --enabled 2>/dev/null ;;
    apt)    grep -rhE '^\s*deb ' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null ;;
    pacman) grep -E '^\s*\[' /etc/pacman.conf 2>/dev/null ;;
    zypper) zypper lr 2>/dev/null ;;
esac > "$OUT/repos.txt"

# --- Divers ---
# La colonne « installation » n'est pas cosmétique : une application peut être
# posée en portée « system » (/var/lib/flatpak, tous les comptes) ou « user »
# (~/.local/share/flatpak, ce compte seul). Réinstaller à l'identique après une
# bascule suppose de savoir laquelle — constaté le 2026-09-03, où Mattermost
# était en system et WinBox en user.
command -v flatpak >/dev/null && flatpak list --app --columns=application,version,branch,installation > "$OUT/flatpaks.txt" 2>/dev/null
systemctl list-unit-files --state=enabled --type=service --no-pager 2>/dev/null > "$OUT/services-enabled.txt"
command -v dconf >/dev/null && dconf dump /org/gnome/ > "$OUT/gnome-settings.ini" 2>/dev/null

find "$OUT" -type f -empty -delete

echo "Fichiers écrits :"
ls -1sh "$OUT"

# --- Écart avec la référence ----------------------------------------------
# C'est la raison d'être de la séparation baseline/etats : une capture datée ne
# vaut que par ce qu'elle révèle face à la photo d'origine.
if [ "$POSTE" -eq 1 ]; then
    BASE="${PRECEDENTE:-}/packages-explicit.txt"
    REF="capture du $(basename "${PRECEDENTE:-aucune}")"
else
    BASE="$ITER/baseline/packages-explicit.txt"
    REF="la baseline"
fi
if [ "$KIND" != baseline ] && [ -s "$BASE" ] && [ -s "$OUT/packages-explicit.txt" ]; then
    ajouts=$(comm -13 <(sort "$BASE") <(sort "$OUT/packages-explicit.txt"))
    retraits=$(comm -23 <(sort "$BASE") <(sort "$OUT/packages-explicit.txt"))
    echo
    echo "Écart avec $REF :"
    if [ -n "$ajouts" ];   then echo "$ajouts"   | sed 's/^/  + /'; fi
    if [ -n "$retraits" ]; then echo "$retraits" | sed 's/^/  - /'; fi
    [ -z "$ajouts$retraits" ] && echo "  aucun paquet ajouté ni retiré"
elif [ "$POSTE" -eq 1 ]; then
    echo
    echo "Première capture de ce poste : aucun écart à afficher."
fi

# Rappel de ce qu'une liste explicite ne dit PAS — piège payé le 2026-09-03 :
# `dnf repoquery --userinstalled` bouge quand la *raison* d'un paquet change
# (Dependency -> Group), sans qu'il ait été installé. Un diff de listes dit ce
# qui a été VOULU, pas ce qui est ARRIVÉ.
if [ "$KIND" != baseline ]; then
    echo
    echo "Rappel : ce diff dit ce qui a été voulu, pas ce qui est arrivé."
    echo "  Pour la raison exacte d'un paquet :"
    echo "  dnf repoquery --installed --qf '%{name} reason=%{reason} from=%{from_repo}\\n' <paquet>"
fi
