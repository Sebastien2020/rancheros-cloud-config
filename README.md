# RancherOS cloud-config
rancheros-cloud-config.yml for RancherOS iPXE boot

# Use in conjunction with iPXE boot script
```
#!ipxe
# Boots RancherOS in Ramdisk with persistent storage on disk /dev/vda

# Location of Kernel/Initrd images
set base-url http://releases.rancher.com/os/latest

kernel ${base-url}/vmlinuz -- rancher.cloud_init.datasources=[url:https://raw.githubusercontent.com/sanderdewitte/rancheros-cloud-config/master/rancheros-cloud-config.yml]

initrd ${base-url}/initrd

boot
```
