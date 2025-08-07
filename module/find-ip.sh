#!/bin/bash

printf "[*] 掃描區網裝置...\n"

# 取得 vmbr0 的 IP 和子網路遮罩
BRIDGE_IP=$(ip route | grep vmbr0 | grep -E 'scope link' | awk '{print $1}' | head -n1)

if [ -z "$BRIDGE_IP" ]; then
  printf "[!] 無法取得 vmbr0 網段資訊\n"
  exit 1
fi

# 取得網段前綴
NETWORK_PREFIX=$(echo $BRIDGE_IP | cut -d'/' -f1 | cut -d'.' -f1-3)

printf "[*] 掃描網段: ${NETWORK_PREFIX}.0/24\n"

# 掃描整個網段
for i in {1..254}; do
  ip="${NETWORK_PREFIX}.${i}"
  arp -d $ip >/dev/null 2>&1
  ping -c 1 -W 1 $ip >/dev/null 2>&1 &
done

wait
printf "[*] 已完成掃描.\n"
printf "___________________________________________\n\n"
printf "%-18s %-22s %-16s %s\n" "IP位址" "MAC位址" "廠商"
printf "___________________________________________\n\n"

# 顯示詳細結果
arp -n | grep -v incomplete | grep "${NETWORK_PREFIX}\." | while read line; do
  ip=$(echo $line | awk '{print $1}')
  mac=$(echo $line | awk '{print $3}')
  
  # 檢查是否為 Proxmox MAC 位址
  if [[ "$mac" == bc:24:11* ]]; then
    vendor="Proxmox VM"
  elif [[ "$mac" == 00:50:56* ]] || [[ "$mac" == 00:0c:29* ]]; then
    vendor="VMware VM"
  elif [[ "$mac" == 52:54:00* ]]; then
    vendor="QEMU/KVM VM"
  else
    # 取得廠商資訊
    vendor=$(curl -s "https://api.macvendors.com/$mac" 2>/dev/null)
    # 檢查是否為錯誤回應或空值
    if [[ "$vendor" == *'{"errors"'* ]] || [ -z "$vendor" ]; then
      vendor=""
    fi
  fi
  
  printf "%-16s %-20s %-16s %s\n" "$ip" "$mac" "$vendor"
done

printf "___________________________________________\n\n"