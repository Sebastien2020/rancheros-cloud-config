# RancherOS cloud-config
rancheros-cloud-config.yml for RancherOS iPXE boot

# Use in conjunction with iPXE boot script
```
#!ipxe
# Boots RancherOS in Ramdisk

# Location of Kernel/Initrd images
set base-url http://releases.rancher.com/os/latest

kernel ${base-url}/vmlinuz -- rancher.cloud_init.datasources=[url:https://raw.githubusercontent.com/sanderdewitte/rancheros-cloud-config/master/rancheros-cloud-config.yml]

initrd ${base-url}/initrd

boot
```

# After iPXE boot
rancheros-cloud-config.yml will be stored in /var/lib/rancher/conf/cloud-config.d/ as boot.yml.

Install RancherOS to disk /dev/vda (this will wipe everything from disk /dev/vda if there is any data!):

`sudo ros install -t generic -c /var/lib/rancher/conf/cloud-config.d/boot.yml -d /dev/vda`
