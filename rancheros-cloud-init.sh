#!/usr/bin/env bash

# API information
API_KEY="XMZSERJNBBR3DJA63ZHJKP26FIYJBOSIBZ5A"
API_URL="https://api.vultr.com"
API_VER="v1"

# Get metadata from all servers
SVR_INFO=($(wget -qO- --header="API-Key: ${API_KEY}" ${API_URL}/${API_VER}/server/list \
            | grep -E -o '\"[^\"]+\":\"[^\"]+\"' \
            | grep -E    'SUBID|date_created|internal_ip|label' \
            | sed  -E -e '/date_created/ s/-([0-9]{2})/.\1/g' \
                      -e '/date_created/ s/(\.[0-9]{2})[[:space:]]{1,}([0-9]{2}:)/\1-\2/'))

# Store metadata in separate arrays
SVR_COUNT=0
for SVR_ITEM in "${SVR_INFO[@]}"; do
  SVR_ITEM_KEY=$(echo "$SVR_ITEM" | cut -d: -f1 | sed -e 's/^"//' -e 's/"$//')
  SVR_ITEM_VALUE=$(echo "$SVR_ITEM" | cut -d: -f2- | sed -e 's/^"//' -e 's/"$//')
  if [[ "$SVR_ITEM_KEY" == "SUBID" ]]; then
    : $((SVR_COUNT++))
    SVR_IDS+=("$SVR_ITEM_VALUE")
  fi
  if [ ${#SVR_IDS[@]} -eq $SVR_COUNT ]; then
    if [[ "$SVR_ITEM_KEY" == "date_created" ]]; then
      SVR_CREATION_DATETIMES+=("$SVR_ITEM_VALUE")
    fi
    if [[ "$SVR_ITEM_KEY" == "internal_ip" ]]; then
      SVR_PVT_IPV4S+=("$SVR_ITEM_VALUE")
    fi
    if [[ "$SVR_ITEM_KEY" == "label" ]]; then
      SVR_LABELS+=("$SVR_ITEM_VALUE")
    fi
  fi
done

# Find the most recent server
if [ ${#SVR_CREATION_DATETIMES[@]} -eq $SVR_COUNT ]; then
  IDX=0
  MAX_IDX=0
  MAX_SVR_CREATION_TIMESTAMP=$(date --date=${SVR_CREATION_DATETIMES[0]} +%s)
  for SVR_CREATION_DATETIME in "${SVR_CREATION_DATETIMES[@]}"; do
    SVR_CREATION_TIMESTAMP=$(date --date=${SVR_CREATION_DATETIME} +%s)
    expr $SVR_CREATION_TIMESTAMP \> $MAX_SVR_CREATION_TIMESTAMP > /dev/null && { MAX_IDX=$IDX; MAX_SVR_CREATION_TIMESTAMP=$SVR_CREATION_TIMESTAMP; }
    : $((IDX++))
  done
fi

# Use the array index of the most recent server
# to determine its label and private IP address
# If something went wrong, use defaults
if [ ! -z ${MAX_IDX+x} ] && [ ${#SVR_LABELS[@]} -eq $SVR_COUNT ]; then
  LAST_BUILT_SVR_LABEL=${SVR_LABELS[$MAX_IDX]}
else
  LAST_BUILT_SVR_LABEL="rancher"
fi
if [ ! -z ${MAX_IDX+x} ] && [ ${#SVR_PVT_IPV4S[@]} -eq $SVR_COUNT ]; then
  LAST_BUILT_SVR_PVT_IPV4=${SVR_PVT_IPV4S[$MAX_IDX]}
else
  LAST_BUILT_SVR_PVT_IPV4="192.168.99.99"
fi

# Generate cloud-config
cat > "cloud-config.yml" <<EOF
#cloud-config
hostname: ${LAST_BUILT_SRV_LABEL}
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
        address: ${LAST_BUILT_SVR_PVT_IPV4}/16
        mtu: 1450
  state:
    dev: LABEL=RANCHER_STATE
    fstype: auto
    autoformat:
      - /dev/vda
  services_include:
    centos-console: true
EOF

# Install rancheros to disk using cloud configi, then reboot
SVR_DISK="/dev/vda"
sudo ros install --no-reboot -f -t generic -c cloud-config.yml -d $SVR_DISK
sudo reboot
