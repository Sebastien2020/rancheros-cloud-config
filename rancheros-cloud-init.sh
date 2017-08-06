#!/bin/sh

# Generate cloud config
cat > "cloud-config.yml" <<EOF
#cloud-config
ssh_authorized_keys:
  - ecdsa-sha2-nistp521 ...
write_files:
  - path: /etc/ssh/sshd_config
    permissions: "0600"
    owner: root:root
    content: |
      AuthorizedKeysFile .ssh/authorized_keys
      ClientAliveInterval 180
      Subsystem	sftp /usr/libexec/sftp-server
      UseDNS no
      PermitRootLogin no
      ServerKeyBits 2048
      AllowGroups docker
rancher:
  network:
    dns:
      override: true
      nameservers:
        - 208.67.222.222
        - 208.67.220.220
    interfaces:
      eth0:
        dhcp: true
  state:
    dev: LABEL=RANCHER_STATE
    fstype: auto
    autoformat:
      - /dev/vda
  services_include:
    centos-console: true
EOF

# Install RancherOS to disk, then reboot
sudo ros install --no-reboot -f -t generic -c cloud-config.yml -d /dev/vda
sudo reboot
