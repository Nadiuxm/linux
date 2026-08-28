# Alias du lab — volontairement minimal et portable.

alias ll='ls -lah'
alias ..='cd ..'
alias grep='grep --color=auto'

# Journal : ouvrir l'itération en cours
alias lab='cd ~/linux'

# Quelle distro suis-je en train de tester, déjà ?
alias whoami-distro='cat /etc/os-release | grep -E "^(PRETTY_NAME|VERSION_ID)="'
