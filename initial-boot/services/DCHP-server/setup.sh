# Install ISC DHCP server
sudo apt update
sudo apt install -y isc-dhcp-server

# Copy your custom DHCP configuration into place
# This assumes the config file in the same directory as this script is present in the folder your terminal is. This config file needs to be adapted to match the IP ranges of your LAN
sudo cp dhcpd.conf /etc/dhcp/dhcpd.conf

# Optional: check that the interface to serve DHCP on is correct
# Edit /etc/default/isc-dhcp-server and set INTERFACESv4 to your LAN interface (e.g. eth0 or enp3s0)
sudo nano /etc/default/isc-dhcp-server

# Example inside that file:
# INTERFACESv4="eth0"

# Enable and start the DHCP server
sudo systemctl enable isc-dhcp-server
sudo systemctl restart isc-dhcp-server

# Check status
sudo systemctl status isc-dhcp-server

# (Optional) Monitor DHCP logs for activity
journalctl -u isc-dhcp-server -f