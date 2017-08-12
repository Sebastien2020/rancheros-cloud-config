# RancherOS cloud-config
rancheros-cloud-config.sh script to generate cloud-config.yml for RancherOS iPXE boot and install on Vultr hosts (https://www.vultr.com). Docker version set to v1.12.6 to be able to run Kubernetes.

# Use in conjunction with iPXE boot script
```
#!ipxe
# Boots RancherOS in Ramdisk

# Location of Kernel and Initrd images
set base-url http://releases.rancher.com/os/latest

kernel ${base-url}/vmlinuz rancher.state.formatzero=true -- rancher.cloud_init.datasources=[url:https://raw.githubusercontent.com/sanderdewitte/rancheros-cloud-config/vultr/rancheros-cloud-init.sh]

initrd ${base-url}/initrd

boot
```
