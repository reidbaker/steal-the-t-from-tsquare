

Easy way 
    use the installer as root
    ./installer.sh
Hard way

First extract sslstrip and in the directory you extract to 
run the command below as root.

python setup.py install

Then run the commands below
sudo apt-get install dnsmasq
sudo apt-get install dhcp3-server
sudo apt-get install ettercap

Then run the script named ETMITM.sh
