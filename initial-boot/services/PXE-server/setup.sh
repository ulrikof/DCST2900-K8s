# Update packages
sudo apt update

# Install TFTP server
sudo apt install -y tftpd-hpa

# Create the TFTP root directory if it doesn’t exist
sudo mkdir -p /srv/tftp

# Download netboot.xyz. This version works for older NICs. New NICs should be able to use the standard version.
wget -O netboot.xyz-undionly.kpxe https://boot.netboot.xyz/ipxe/netboot.xyz-undionly.kpxe

# Move the downloaded file to the TFTP directory
sudo mv netboot.xyz-undionly.kpxe /srv/tftp/

# Set correct ownership and permissions
sudo chown -R tftp:tftp /srv/tftp
sudo chmod -R 755 /srv/tftp

# Edit the TFTP config to make sure it serves from /srv/tftp
# You can use nano, vim, or any editor
sudo nano /etc/default/tftpd-hpa

# Make sure the config file looks like this:
# ---------------------------------------------
# TFTP_USERNAME="tftp"
# TFTP_DIRECTORY="/srv/tftp"
# TFTP_ADDRESS=":69"
# TFTP_OPTIONS="--secure"
# ---------------------------------------------

# Restart the TFTP service to apply the changes
sudo systemctl restart tftpd-hpa

# Enable the service to start on boot
sudo systemctl enable tftpd-hpa

# Check that the service is running
sudo systemctl status tftpd-hpa

# (Optional) Check that the file is exposed correctly
ls -lh /srv/tftp