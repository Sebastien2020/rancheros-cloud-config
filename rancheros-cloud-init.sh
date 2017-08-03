#!/usr/bin/env bash

VULTR_API_KEY=""
VULTR_API_URL=https://api.vultr.com
VULTR_API_VER=v1

VULTR_SVR_CREATION_DATETIMES_LIST=$(wget -qO- --header="API-Key: ${VULTR_API_KEY}" ${VULTR_API_URL}/${VULTR_API_VER}/server/list | grep -Po "\"date_created\":\"\K\d{4}(?:-\d{2}){2}\s+(?:\d{2}:){2}\d{2}")
VULTR_SVR_CREATION_DATETIMES=($(echo $VULTR_SVR_CREATION_DATETIMES_LIST | sed -re 's/(-[0-9]{2})[[:space:]]{1,}([0-9]{2}:)/\1T\2/g'))

IDX=0
MAX_IDX=0
MAX_VULTR_SVR_CREATION_TIMESTAMP=$(date --date=${VULTR_SVR_CREATION_DATETIMES[0]} +%s)
for VULTR_SVR_CREATION_DATETIME in ${VULTR_SVR_CREATION_DATETIMES[@]}; do
  VULTR_SVR_CREATION_TIMESTAMP=$(date --date=${VULTR_SVR_CREATION_DATETIME} +%s)
  expr $VULTR_SVR_CREATION_TIMESTAMP \> $MAX_VULTR_SVR_CREATION_TIMESTAMP > /dev/null && { MAX_IDX=$IDX; MAX_VULTR_SVR_CREATION_TIMESTAMP=$VULTR_SVR_CREATION_TIMESTAMP; }
  : $((IDX++))
done
LAST_BUILT_VULTR_SVR_CREATION_DATETIME=${VULTR_SVR_CREATION_DATETIMES[$MAX_IDX]/T/ }

SUBID=...

VULTR_PVT_IPV4=$(wget -qO- --header="API-Key: ${VULTR_API_KEY}" --header="Label: ${VULTR_SVR_LBL}" ${VULTR_API_URL}/${VULTR_API_VER}/server/list | grep -Po "\"internal_ip\":\"\K(?:\d{1,3}\.){3}\d{1,3}")

cat > "cloud-config.yml" <<EOF
#cloud-config
hostname: ${VULTR_SRV_LABEL:-'rancher'}
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
      eth1:
        dhcp: false
        address: ${VULTR_PVT_IPV4}/16
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
