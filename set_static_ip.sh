#!/bin/bash

# 引数の数を確認
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <interface> <static_ip/cidr> <gateway> <dns1,dns2>"
    exit 1
fi

# 引数を変数に割り当て
INTERFACE=$1
STATIC_IP_CIDR=$2
GATEWAY=$3
DNS_SERVERS=$4

# netplan設定ファイルのパス
NETPLAN_CONFIG_FILE="/etc/netplan/${INTERFACE}-netcfg.yaml"

# netplan設定ファイルのバックアップ
if [ -f $NETPLAN_CONFIG_FILE ]; then
    sudo cp $NETPLAN_CONFIG_FILE $NETPLAN_CONFIG_FILE.bak
fi

sudo bash -c "cat > $NETPLAN_CONFIG_FILE" <<EOL
network:
  version: 2
  ethernets:
    $INTERFACE:
      optional: true
      dhcp4: no
      dhcp6: no
      addresses: [$STATIC_IP_CIDR]
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS_SERVERS]
EOL

# netplanの適用
sudo netplan apply

echo "Static IP configuration applied successfully."
