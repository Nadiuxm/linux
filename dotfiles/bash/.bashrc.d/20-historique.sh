# Historique exploitable : horodaté, et écrit à chaque commande.
#
# Ces réglages existent aussi dans le .bashrc du paquet, mais ce .bashrc n'est
# pas déployé sur le poste de référence : le .bashrc vivant est celui de la
# distribution, qui ne sait que charger ~/.bashrc.d/*. Le fragment est donc le
# seul endroit qui prend effet aujourd'hui. Les deux posent les mêmes valeurs,
# et le fragment est lu en dernier — aucun conflit possible.

HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth        # pas de doublons, pas de lignes préfixées d'un espace
HISTTIMEFORMAT='%F %T '       # sans ça, ~/.bash_history n'a aucune date
shopt -s histappend           # append au lieu d'écraser (plusieurs terminaux)

# Sans ceci, bash n'écrit l'historique qu'à la fermeture du terminal : un shell
# resté ouvert toute la journée ne laisse aucune trace avant le soir. `history -a`
# à chaque invite vide le tampon immédiatement, ce qui rend la journée en cours
# lisible — c'est ce dont le journal de travail a besoin.
case "${PROMPT_COMMAND:-}" in
    *'history -a'*) ;;
    *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
