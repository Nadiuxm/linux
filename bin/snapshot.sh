#!/usr/bin/env bash
# snapshot.sh — capture l'état du système dans la baseline d'une itération.
#
# À lancer au début d'une itération (état initial) et juste avant la bascule
# vers la distro suivante (état final). Ne demande aucun privilège.
#
# Usage : ./bin/snapshot.sh [dossier-iteration]
#         Sans argument, prend la dernière itération de journal/ par ordre alpha.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ $# -ge 1 ]; then
    ITER="$REPO/journal/$(basename "$1")"
else
    ITER="$(find "$REPO/journal" -mindepth 1 -maxdepth 1 -type d | sort | tail -1)"
fi

if [ ! -d "$ITER" ]; then
    echo "Itération introuvable : ${ITER:-<aucune>}" >&2
    exit 1
fi

OUT="$ITER/baseline"
mkdir -p "$OUT"
echo "Capture vers ${OUT#$REPO/}"

# Détection du gestionnaire de paquets : le lab change de distro, le script non.
if   command -v dnf     >/dev/null; then PKG=dnf
elif command -v apt     >/dev/null; then PKG=apt
elif command -v pacman  >/dev/null; then PKG=pacman
elif command -v zypper  >/dev/null; then PKG=zypper
else PKG=inconnu
fi

# --- Système ---
{
    echo "# Baseline système"
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
    command -v firewall-cmd >/dev/null && echo "Pare-feu : firewalld ($(firewall-cmd --state 2>/dev/null))"
    command -v ufw >/dev/null && echo "Pare-feu : ufw"
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
command -v flatpak >/dev/null && flatpak list --app --columns=application,version,branch > "$OUT/flatpaks.txt" 2>/dev/null
systemctl list-unit-files --state=enabled --type=service --no-pager 2>/dev/null > "$OUT/services-enabled.txt"
command -v dconf >/dev/null && dconf dump /org/gnome/ > "$OUT/gnome-settings.ini" 2>/dev/null

find "$OUT" -type f -empty -delete

echo "Fichiers écrits :"
ls -1sh "$OUT"
