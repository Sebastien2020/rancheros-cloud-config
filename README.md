# RancherOS cloud-config
rancheros-cloud-config.sh script to generate cloud-config.yml for RancherOS iPXE boot and install.
See other branches for cloud provider specific versions of this script.

# Use in conjunction with iPXE boot script
```
#!ipxe
# Boots RancherOS in Ramdisk

# Location of Kernel and Initrd images
set base-url http://releases.rancher.com/os/latest

kernel ${base-url}/vmlinuz rancher.state.formatzero=true -- rancher.cloud_init.datasources=[url:https://raw.githubusercontent.com/sanderdewitte/rancheros-cloud-config/master/rancheros-cloud-init.sh]

initrd ${base-url}/initrd

boot
```
