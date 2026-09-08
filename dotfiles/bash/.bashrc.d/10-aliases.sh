# Alias du lab — volontairement minimal et portable.

alias ll='ls -lah'
alias ..='cd ..'
alias grep='grep --color=auto'

# Journal : ouvrir l'itération en cours
alias lab='cd ~/linux'

# Quelle distro suis-je en train de tester, déjà ?
alias whoami-distro='cat /etc/os-release | grep -E "^(PRETTY_NAME|VERSION_ID)="'

# VM Windows d'administration : démarre la machine si elle est arrêtée, puis
# ouvre sa console. Détachée du terminal, donc le shell reste utilisable.
# La fenêtre s'ouvre sur l'espace qui a le focus : il n'y a aucune règle de
# placement sur le poste de référence. Ce commentaire invoquait la règle
# « assign » de Sway jusqu'au 2026-09-07 — paquet non posé ici, lab uniquement.
# Même commande que l'entrée de lanceur du paquet Stow « desktop ».
win() {
    virsh -c qemu:///system start win11 2>/dev/null
    ( virt-manager --connect qemu:///system --show-domain-console win11 >/dev/null 2>&1 & )
}
