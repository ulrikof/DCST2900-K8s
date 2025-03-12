https://flakrat.blogspot.com/2016/06/how-to-enable-pxe-and-configure-boot.html

racadm get nic.nicconfig

racadm get nic.nicconfig.1

racadm set nic.nicconfig.1.legacybootproto PXE

racadm get nic.nicconfig.1

racadm jobqueue create NIC.Integrated.1-1-1

racadm serveraction powercycle

racadm get nic.nicconfig.2

racadm jobqueue view

racadm get BIOS.biosbootsettings.BootSeq

racadm set BIOS.biosbootsettings.BootSeq NIC.Integrated.1-1-1

racadm jobqueue create BIOS.Setup.1-1 -r pwrcycle -s TIME_NOW -e TIME_NA