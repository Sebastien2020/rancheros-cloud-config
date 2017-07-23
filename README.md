# RancherOS cloud-config
rancheros-cloud-config.yml

# Use in conjunction with PXE boot script
```
#!ipxe
# Boots RancherOS in Ramdisk with persistent storage on disk /dev/vda

# Location of Kernel/Initrd images
set base-url http://releases.rancher.com/os/latest

kernel ${base-url}/vmlinuz rancher.state.dev=LABEL=RANCHER_STATE rancher.state.autoformat=[/dev/vda] rancher.cloud_init.datasources=[url:http://example.com/cloud-config]

initrd ${base-url}/initrd

boot
```
