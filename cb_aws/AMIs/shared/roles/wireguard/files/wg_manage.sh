#!/bin/bash

usage () {
        clear
        echo "<------------------------------------------------------------------------------------------------>"
        echo "Example usage: "
        echo "./wg_manage.sh -h       -->  Print This help message"
        echo "./wg_manage.sh -l       -->  List wireguard VPN clients"
        echo "./wg_manage.sh -c NAME  -->  Create client config for NAME provided"
        echo "<------------------------------------------------------------------------------------------------>"
        exit 0
}


check_client () {
CLIENT=${1}
if $(ls /etc/wireguard/client-configs/ | grep ${CLIENT} 2>/dev/null 1>&2) ;then
        echo "Client: ${client} already exists"
        echo "You can use the following config:"
        echo "<--------------------------------------->"
        cat /etc/wireguard/client-configs/${CLIENT}.config
        exit 0
fi
}

list_clients () {
        clear
        echo "These are all existing wireguard client configs"
        echo "<--------------------------------------------->"
        for cl in $(ls /etc/wireguard/client-configs/);do
                echo ${cl} | awk -F"." '{print $1}'
        done
}

generate_client () {
CLIENT=${1}
TIMESTAMP=$(date "+%Y-%m-%d-%H:%M")

cp /etc/wireguard/wg0.conf /etc/wireguard/backups/${TIMESTAMP}-wg0.conf-backup

wg genkey | tee /etc/wireguard/keys/clients/${CLIENT}-private-key | wg pubkey > /etc/wireguard/keys/clients/${CLIENT}-public-key
CLIENT_PRIV=$(cat /etc/wireguard/keys/clients/${CLIENT}-private-key)
CLIENT_PUB=$(cat /etc/wireguard/keys/clients/${CLIENT}-public-key)

SERVER_KEY=$(cat /etc/wireguard/keys/server/public_key)

if [ ! -f "/etc/wireguard/client-ips" ];then
        echo "Client IPs file not found"
        exit 0
fi

CLIENT_IP=$(( $(tail -1 /etc/wireguard/client-ips) + 1 ))
echo $CLIENT_IP >> /etc/wireguard/client-ips

cat > /etc/wireguard/client-configs/${CLIENT}.config << EOF
[Interface]
Address = 10.10.10.${CLIENT_IP}/24
PrivateKey = ${CLIENT_PRIV}
DNS = 10.10.10.1

[Peer]
PublicKey = ${SERVER_KEY}
Endpoint = ${PUBLIC_IP}:61443
AllowedIPs = 0.0.0.0/0,::/0
PersistentKeepalive = 21
EOF

echo "#<----------------- ${CLIENT} ------------------->" >> /etc/wireguard/wg0.conf
echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "PublicKey = ${CLIENT_PUB}" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = 10.10.10.${CLIENT_IP}/32" >> /etc/wireguard/wg0.conf
echo "PersistentKeepalive = 25" >> /etc/wireguard/wg0.conf

systemctl restart wg-quick@wg0
echo "<------------------ ${CLIENT} config -------------------->"
cat /etc/wireguard/client-configs/${CLIENT}.config
}


[ $# -eq 0 ] && usage
while getopts "ihlc:" arg; do
  case $arg in
    i)
      echo "You have choosen to install wireguard VPN server"
      read -n 1 -s -r -p "Press any key to continue"
      install_wireguard
      ;;
    h)
      usage
      ;;
    c)
      client=$OPTARG
      check_client ${client}
      generate_client ${client}
      ;;
    l)
      list_clients
      ;;
    *)
      usage
      ;;
  esac
done

