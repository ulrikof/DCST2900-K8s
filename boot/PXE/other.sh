# https://linuxconfig.org/network-booting-with-linux-pxe
# https://factory.talos.dev/?arch=amd64&cmdline-set=true&extensions=-&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Futil-linux-tools&platform=metal&target=metal&version=1.9.4

sudo journalctl -u isc-dhcp-server --since "5 minutes ago"

sudo journalctl -u tftpd-hpa --since "5 minutes ago" 
 
atftp --trace -g -l metal-amd64 -r metal-amd64 10.100.38.20

 sudo tcpdump -i eno1 port 6