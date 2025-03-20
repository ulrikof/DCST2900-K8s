https://flakrat.blogspot.com/2016/06/how-to-enable-pxe-and-configure-boot.html


### Set up PXE on a NIC
# Get all NIC, find the rigth one (in our case NIC 1)
racadm get nic.nicconfig

# See if PXE is enabled. Look for: LegacyBootProto=PXE
racadm get nic.nicconfig.1

# If not configure it
racadm set nic.nicconfig.1.legacybootproto PXE

# Verify it has been created. It should be pending.
racadm get nic.nicconfig.1

# Create job for it to be applied
racadm jobqueue create NIC.Integrated.1-1-1

# Powercycle
racadm serveraction powercycle

# See the progress of the job. When it is completed you can see if it is still pending. 
racadm jobqueue view


### Set correct boot order

# View current boot order
racadm get BIOS.biosbootsettings.BootSeq

# Set boot order to hard disk first, then PXE over Nic 1
racadm set BIOS.biosbootsettings.BootSeq HardDisk.List.1-1,NIC.Integrated.1-1-1

# Create a job to apply config. 
racadm jobqueue create BIOS.Setup.1-1 -r pwrcycle -s TIME_NOW -e TIME_NA