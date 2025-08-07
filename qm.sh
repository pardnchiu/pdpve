#!/bin/sh

VMID=""
NAME=""
CPU=""
DISK=""
RAM=""
STORAGE=""
OS=""
VERSION=""
IP=""
GW=""
USER=""
PASSWD=""

# 新增 OS 類型和版本參數
OPTIONS=$(getopt -o i:s:o:v:n:c:r: -l id:,storage:,os:,version:,name:,cpu:,ram: -- "$@")

if [ $? != 0 ] ; then echo "參數解析錯誤" >&2 ; exit 1 ; fi

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    -i | --id )
      VMID="$2"; shift 2 ;;
    -s | --storage )
      STORAGE="$2"; shift 2 ;;
    -o | --os )
      OS="$2"; shift 2 ;;
    -v | --version )
      VERSION="$2"; shift 2 ;;
    -n | --name )
      NAME="$2"; shift 2 ;;
    -c | --cpu )
      CPU="$2"; shift 2 ;;
    -r | --ram )
      RAM="$2"; shift 2 ;;
    -h | --help )
      HELP="true"; shift ;;
    -- )
      shift; break ;;
    * )
      break ;;
  esac
done

if [ "$HELP" = "true" ]; then
  echo "-i, --id [VMID]"
  echo "-s, --storage [Storage ID]"
  echo "-o, --os [OS: ubuntu/debian/rockylinux]"
  echo "-v, --version [Version Number]"
  echo "-n, --name [VM Name | default qemu]"
  echo "-c, --cpu [vCPU Number | default 2]"
  echo "-r, --ram [RAM | default 2048]"
  exit 0
fi

while true; do
  if [ "$VMID" = "" ]; then
    read -p "請輸入虛擬機 ID: " VMID
  fi
  
  if /usr/sbin/qm config $VMID >/dev/null 2>&1; then
    echo "虛擬機 ID $VMID 已存在，請重新輸入"
    VMID=""
  else
    break
  fi
done

while true; do
  if [ "$STORAGE" = "" ]; then
    read -p "請輸入存儲 ID: " STORAGE
  fi

  if ! /usr/sbin/pvesm status -storage $STORAGE >/dev/null 2>&1; then
    echo "儲存池 $STORAGE 不存在"
  else
    break
  fi
done

while true; do
  if [ "$OS" = "" ]; then
    echo "請選擇作業系統："
    echo "1) Debian"
    echo "2) RockyLinux" 
    echo "3) Ubuntu"
    read -p "請輸入選項 (1-3): " OS_CHOICE
    
    case "$OS_CHOICE" in
      1)
        OS="debian"
        ;;
      2)
        OS="rockylinux"
        ;;
      3)
        OS="ubuntu"
        ;;
      *)
        echo "無效選項，預設使用 Debian"
        OS="debian"
        ;;
    esac
  fi

  if [ "$OS" != "ubuntu" ] && [ "$OS" != "debian" ] && [ "$OS" != "rockylinux" ]; then
    echo "不支援的作業系統類型: $OS (僅支援 ubuntu/debian/rockylinux)"
  else
    break
  fi
done

while true; do
  if [ "$VERSION" = "" ]; then
    read -p "請輸入版本號: " VERSION
  fi
  
  # 根據作業系統設定 URL
  case "$OS" in
    ubuntu)
      IMAGE_URL="https://mirror.twds.com.tw/ubuntu-cloud-images/releases/22.04/release/ubuntu-${VERSION}-server-cloudimg-amd64.img"
      ;;
    debian)
      IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-${VERSION}-generic-amd64.qcow2"
      ;;
    rockylinux)
      IMAGE_URL="https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-${VERSION}-GenericCloud-Base.latest.x86_64.qcow2"
      ;;
  esac
  
  # 檢查 URL 是否存在
  if curl --head --silent --fail "$IMAGE_URL" >/dev/null 2>&1; then
    break
  else
    echo "版本 $VERSION 不存在，請重新輸入"
    VERSION=""
  fi
done

# 設定下載 URL 和檔案路徑
case "$OS" in
  ubuntu)
    IMAGE_FILE="/tmp/ubuntu-${VERSION}-server-cloudimg-amd64.img"
    ;;
  debian)
    IMAGE_FILE="/tmp/debian-${VERSION}-generic-amd64.qcow2"
    ;;
  rockylinux)
    IMAGE_FILE="/tmp/Rocky-${VERSION}-GenericCloud-Base.latest.x86_64.qcow2"
    ;;
esac

if [ ! -f "$IMAGE_FILE" ]; then
  read -p "映像檔不存在，是否要下載 ${OS} ${VERSION} 映像檔？ (y/n): " DOWNLOAD
  if [ "$DOWNLOAD" != "y" ] && [ "$DOWNLOAD" != "Y" ]; then
    echo "取消下載，動作停止"
    exit 1
  fi
  
  echo "下載 ${OS} ${VERSION} 映像檔..."
  curl -L -o "$IMAGE_FILE" "$IMAGE_URL"
  if [ $? -ne 0 ]; then
    echo "下載失敗"
    exit 1
  fi
fi

if [ "$NAME" = "" ]; then
  read -p "請輸入虛擬機名稱 [預設: qemu]: " NAME
  NAME=${NAME:-"qemu"}
fi

if [ "$CPU" = "" ]; then
  read -p "請輸入虛擬機 vCPU 數量 [預設: 2]: " CPU
  CPU=${CPU:-2}
fi

if [ "$OS" = "rockylinux" ]; then
  if [ "$DISK" = "" ]; then
    read -p "請輸入虛擬機磁碟大小 [最低: 16G]: " DISK
    DISK=${DISK:-16G}
  fi
else
  if [ "$DISK" = "" ]; then
    read -p "請輸入虛擬機磁碟大小 [最低: 8G]: " DISK
    DISK=${DISK:-8G}
  fi
fi

DISK_SIZE=$(echo "$DISK" | sed 's/[^0-9]//g')
if [ "$OS" = "rockylinux" ]; then
  if [ "$DISK_SIZE" -lt 16 ]; then
    echo "RockyLinux 映像檔高於 10G，自動調整為 16G"
    DISK="16G"
  fi
else
  if [ "$DISK_SIZE" -lt 8 ]; then
    echo "自動調整為 8G"
    DISK="8G"
  fi
fi

if [ "$RAM" = "" ]; then
  read -p "請輸入虛擬機 RAM 大小 [預設: 2048]: " RAM
  RAM=${RAM:-2048}
fi

while true; do
  if [ "$IP" = "" ]; then
    read -p "請輸入 IP 設定 [預設: dhcp]: " IP
    IP=${IP:-"dhcp"}
  fi
  
  if [ "$IP" = "dhcp" ]; then
    break
  fi
  
  if ! echo "$IP" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$'; then
    echo "IP 格式錯誤，請輸入包含遮罩的 IP 地址 (例如: 192.168.1.100/24)"
    IP=""
  else
    break
  fi
done

if [ "$IP" != "dhcp" ]; then
  while true; do
    if [ "$GW" = "" ]; then
      read -p "請輸入 Gateway 設定: " GW
    fi
    
    if [ -n "$GW" ]; then
      break
    else
      echo "Gateway 不能為空"
    fi
  done
fi

if [ "$USER" = "" ]; then
  read -p "請輸入虛擬機使用者名稱 [預設: user]: " USER
  USER=${USER:-user}
fi

if [ "$PASSWD" = "" ]; then
  read -p "請輸入虛擬機使用者密碼 [預設: passwd]: " PASSWD
  PASSWD=${PASSWD:-passwd}
fi

cleanup_vm() {
  if [ -n "$VMID" ] && /usr/sbin/qm config $VMID >/dev/null 2>&1; then
    echo "清理失敗的虛擬機 $VMID..."
    /usr/sbin/qm destroy $VMID --purge >/dev/null 2>&1
  fi
}

# 建立虛擬機
echo "建立虛擬機 $VMID..."
/usr/sbin/qm create $VMID \
--name $NAME \
--cores $CPU \
--cpu x86-64-v2-AES \
--scsihw virtio-scsi-pci \
--memory $RAM \
--ostype l26 \
--agent 1 \
--net0 virtio,bridge=vmbr0

if [ $? -ne 0 ]; then
  echo "虛擬機建立失敗"
  exit 1
fi

echo "匯入磁碟映像檔..."
/usr/sbin/qm importdisk $VMID \
$IMAGE_FILE \
$STORAGE

if [ $? -ne 0 ]; then
  echo "磁碟匯入失敗"
  cleanup_vm
  exit 1
fi

/usr/sbin/qm set $VMID --ciuser $USER
/usr/sbin/qm set $VMID --cipassword $PASSWD
/usr/sbin/qm set $VMID --scsi0 $STORAGE:vm-$VMID-disk-0
/usr/sbin/qm set $VMID --ide2 $STORAGE:cloudinit
/usr/sbin/qm set $VMID --boot c --bootdisk scsi0

echo "調整硬碟大小到 $DISK"
/usr/sbin/qm resize $VMID scsi0 $DISK

if [ $? -ne 0 ]; then
  echo "硬碟調整失敗"
  cleanup_vm
  exit 1
fi

if [ "$IP" = "dhcp" ]; then
  /usr/sbin/qm set $VMID --ipconfig0 ip=dhcp
else
  /usr/sbin/qm set $VMID --ipconfig0 ip=$IP,gw=$GW
fi
