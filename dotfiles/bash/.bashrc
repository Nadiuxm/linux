# .bashrc — version portable du lab (voir dépôt ~/linux)
# Rendu agnostique de la distro : le chemin du bashrc système diffère
# entre Fedora/RHEL (/etc/bashrc) et Debian/Ubuntu (/etc/bash.bashrc).

# Shell non interactif : on ne fait rien.
case $- in
    *i*) ;;
      *) return;;
esac

# --- Définitions système ---
for _sysrc in /etc/bashrc /etc/bash.bashrc; do
    [ -f "$_sysrc" ] && . "$_sysrc" && break
done
unset _sysrc

# --- PATH utilisateur ---
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
esac
case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) PATH="$HOME/bin:$PATH" ;;
esac
export PATH

# --- Historique : indispensable en lab, on veut retrouver ce qu'on a tapé ---
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth        # pas de doublons, pas de lignes préfixées d'un espace
HISTTIMEFORMAT='%F %T '       # horodatage : quand ai-je cassé la machine ?
shopt -s histappend           # append au lieu d'écraser (plusieurs terminaux)
shopt -s checkwinsize

# --- Fragments locaux : ~/.bashrc.d/*.sh ---
if [ -d "$HOME/.bashrc.d" ]; then
    for _rc in "$HOME"/.bashrc.d/*.sh; do
        [ -f "$_rc" ] && . "$_rc"
    done
    unset _rc
fi
