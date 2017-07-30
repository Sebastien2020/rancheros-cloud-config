#!/bin/sh

VULTR_API_URL=https://api.vultr.com
VULTR_API_VER=v1
VULTR_API_KEY=<VULTR_API_KEY>
VULTR_IP_V4="$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' | xargs echo -n $1)"
VULTR_HOST=$(curl ${VULTR_API_URL}/${VULTR_API_VER}/server/list?api_key=${VULTR_API_KEY} | jq ".[] | select(.main_ip==\"${VULTR_IP_V4}\") | .label" | xargs echo -n $1)

cat > "cloud-config.yml" <<EOF
#cloud-config
hostname: $VULTR_HOST
ssh_authorized_keys:
  - ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAD6hltyl1MpRm6Q2KWr2QwaPGwa2RgGvyQh1u7Fgl+BsHJZiwmjhBMVdwH+CfJ3dD9m2cTnDXqdYJF5qfUl55DOsQHRYaqBywpv3bQ6LF+nJQNKSA0/BJJl2ONUWdQ7LmcUJmD6QtsKEY1JQEvRUtr6KfShokN7hYW0fn47HeolqlKQkA==
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

sudo ros install --no-reboot -f -t generic -c cloud-config.yml -d /dev/vda
sudo reboot
