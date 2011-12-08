## This file assumes you are using backtrack 5R1 ##
###################################################
echo "extracting sslstrip"
tar -xf  sslstrip-0.9.tar.gz
cd 'sslstrip-0.9/'
echo "installing sslstrip"
python setup.py install

echo 'installing packages using apt-get'
apt-get install dnsmasq
apt-get install dhcp3-server
apt-get install ettercap
