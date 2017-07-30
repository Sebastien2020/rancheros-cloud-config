#!/bin/sh

PRIVATE_IP_V4=`wget -q -O - http://169.254.169.254/current/meta-data/local-ipv4`
HOSTNAME=`wget -q -O - http://169.254.169.254/current/meta-data/hostname`

cat > "cloud-config.yml" <<EOF
#cloud-config
hostname: $HOSTNAME
ssh_authorized_keys:
  - ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAD6hltyl1MpRm6Q2KWr2QwaPGwa2RgGvyQh1u7Fgl+BsHJZiwmjhBMVdwH+CfJ3dD9m2cTnDXqdYJF5qfUl55DOsQHRYaqBywpv3bQ6LF+nJQNKSA0/BJJl2ONUWdQ7LmcUJmD6QtsKEY1JQEvRUtr6KfShokN7hYW0fn47HeolqlKQkA==
write_files:
  - container: ntp
    path: /etc/ntp.conf
    permissions: "0644"
    owner: root:root
    content: |
      server 0.pool.ntp.org iburst
      server 1.pool.ntp.org iburst
      server 2.pool.ntp.org iburst
      server 3.pool.ntp.org iburst
      # Allow only time queries, at a limited rate, sending KoD when in excess.
      # Allow all local queries (IPv4, IPv6)
      restrict default nomodify nopeer noquery limited kod
      restrict 127.0.0.1
      restrict [::1]
  - path: /etc/ssh/sshd_config
    permissions: "0600"
    owner: root:root
    content: |
      AuthorizedKeysFile .ssh/authorized_keys
      ClientAliveInterval 180
      Subsystem	sftp /usr/libexec/sftp-server
      UseDNS no
      PermitRootLogin no
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
      eth1:
        address: ${PRIVATE_IP_V4}/16
        mtu: 1450
  state:
    dev: LABEL=RANCHER_STATE
    fstype: auto
    autoformat:
      - /dev/vda
  services_include:
    centos-console: true
EOF

sudo ros install --no-reboot -f -t generic -c cloud-config.yml -d /dev/vda
sudo reboot
