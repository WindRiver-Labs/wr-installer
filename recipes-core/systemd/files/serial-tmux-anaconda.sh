# Detect if it is serial tty, if yes, we need to invoke
# tmux to attach anaconda
console=`/usr/bin/tty`
[ "${console##/dev/ttyS}" != "${console}" ] && /usr/bin/tmux attach -t anaconda

