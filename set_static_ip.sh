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
NETPLAN_CONFIG_FILE="/etc/netplan/01-netcfg.yaml"

# netplan設定ファイルのバックアップ
if [ -f $NETPLAN_CONFIG_FILE ]; then
    sudo cp $NETPLAN_CONFIG_FILE $NETPLAN_CONFIG_FILE.bak
else
    echo "network:
  version: 2
  ethernets:" | sudo tee $NETPLAN_CONFIG_FILE
fi

# 既存の設定ファイルを一時ファイルにコピー
sudo cp $NETPLAN_CONFIG_FILE /tmp/netplan_config.yaml

# 新しい設定を追加または既存のインターフェース設定を更新
if grep -q "ethernets:" /tmp/netplan_config.yaml; then
    if grep -q "    $INTERFACE:" /tmp/netplan_config.yaml; then
        # 既存のインターフェース設定を更新
        sudo sed -i "/    $INTERFACE:/,/^    [a-zA-Z]/c\    $INTERFACE:\n      dhcp4: no\n      addresses: [$STATIC_IP_CIDR]\n      gateway4: $GATEWAY\n      nameservers:\n        addresses: [$DNS_SERVERS]" /tmp/netplan_config.yaml
    else
        # 新しいインターフェース設定を追加
        sudo sed -i "/ethernets:/a\    $INTERFACE:\n      dhcp4: no\n      addresses: [$STATIC_IP_CIDR]\n      gateway4: $GATEWAY\n      nameservers:\n        addresses: [$DNS_SERVERS]" /tmp/netplan_config.yaml
    fi
else
    # 新しい設定を追加
    sudo bash -c "cat > $NETPLAN_CONFIG_FILE" <<EOL
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses: [$STATIC_IP_CIDR]
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS_SERVERS]
EOL
fi

# 一時ファイルを設定ファイルに上書き
sudo mv /tmp/netplan_config.yaml $NETPLAN_CONFIG_FILE

# netplanの適用
sudo netplan apply

echo "Static IP configuration applied successfully."
