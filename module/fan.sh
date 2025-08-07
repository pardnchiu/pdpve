#!/bin/bash

getBrand() {
  local manufacturer=$(dmidecode -s system-manufacturer 2>/dev/null | tr '[:upper:]' '[:lower:]')
  
  case "$manufacturer" in
    *dell*)
      echo "dell" ;;
    *supermicro*)
      echo "supermicro" ;;
    *hewlett*|*hp*)
      echo "hpe" ;;
    *asrock*)
      echo "asrockrack" ;;
    *)
      echo ""
      ;;
  esac
}

# 預設值
valSpeed=""
valBrand=""

OPTIONS=$(getopt -o s:b: -l speed:,brand: -- "$@")

if [ $? != 0 ] ; then echo "參數解析錯誤" >&2 ; exit 1 ; fi

eval set -- "$OPTIONS"

# 解析參數
while true; do
  case "$1" in
    -s|--speed)
      valSpeed="$2"; shift 2 ;;
    -b|--brand)
      valBrand="$2"; shift 2 ;;
    --)
      shift; break ;;
    *)
      break ;;
  esac
done

# 交互式輸入
if [ -z "$valSpeed" ]; then
  while true; do
    read -p "[-] 風扇轉速(%) ? [auto/20-80] (預設: auto): " -r
    valSpeed="${REPLY:-auto}"
    
    # 加入數字驗證和自動調整
    if [ "$valSpeed" = "auto" ]; then
      break
    elif echo "$valSpeed" | grep -q '^[0-9]\+$'; then
      # 自動調整範圍
      if [ "$valSpeed" -lt 20 ]; then
        valSpeed=20
        echo "數值調整為 20"
      elif [ "$valSpeed" -gt 80 ]; then
        valSpeed=80
        echo "數值調整為 80"
      fi
      break
    fi
  done
fi

# 轉換邏輯
if [ "$valSpeed" = "auto" ]; then
  valSpeedTo16="auto"
else
  # 使用百分比直接轉換 (80% = 0x50)
  decimal=$((valSpeed * 80 / 100))
  valSpeedTo16=$(printf "%02x" $decimal)
fi

if [ -z "$valBrand" ]; then
  detected_brand=$(getBrand)
  if [ -n "$detected_brand" ]; then
    valBrand="$detected_brand"
    echo "偵測到品牌: $valBrand"
  else
    while true; do
      echo "請選擇伺服器品牌："
      echo "1) Dell"
      echo "2) Supermicro" 
      echo "3) HPE"
      echo "4) ASRock Rack"
      read -p "請輸入選項 (1-4): " BRAND_CHOICE
      
      case "$BRAND_CHOICE" in
        1)
          valBrand="dell"
          break
          ;;
        2)
          valBrand="supermicro"
          break
          ;;
        3)
          valBrand="hpe"
          break
          ;;
        4)
          valBrand="asrockrack"
          break
          ;;
        *)
          echo "無效選項，請重新輸入"
          ;;
      esac
    done
  fi
fi
# IPMI 指令執行
case "$valBrand" in
  "dell")
    if [ "$valSpeedTo16" = "auto" ]; then
      printf "[*] 已切換自動.\n"
      ipmitool raw 0x30 0x30 0x01 0x01 || { printf "[!] IPMI 指令執行失敗\n"; exit 1; }
    else
      printf "[*] 已切換手動.\n"
      ipmitool raw 0x30 0x30 0x01 0x00 || { printf "[!] IPMI 指令執行失敗\n"; exit 1; }
      printf "[*] 固定轉速 $valSpeed%%.\n"
      ipmitool raw 0x30 0x30 0x02 0xff 0x"$valSpeedTo16" || { printf "[!] IPMI 指令執行失敗\n"; exit 1; }
    fi
    ;;
  "supermicro")
    if [ "$valSpeedTo16" = "auto" ]; then
      printf "[*] 已切換自動.\n"
      ipmitool raw 0x30 0x45 0x01 0x01 || { printf "[!] IPMI 指令執行失敗\n"; exit 1; }
    else
      printf "[*] 已切換手動.\n"
      ipmitool raw 0x30 0x45 0x01 0x00 || { printf "[!] IPMI 指令執行失敗\n"; exit 1; }
      printf "[*] 固定轉速 $valSpeed%%.\n"
      ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x"$valSpeedTo16" || { printf "[!] IPMI 指令執行失敗\n"; exit 1; }
    fi
    ;;
  "hpe")
    if [ "$valSpeedTo16" = "auto" ]; then
      printf "[*] 已切換自動.\n"
      ipmitool raw 0x3a 0x07 0x01 0x01 || { printf "[!] IPMI 指令執行失敗\n"; exit 1; }
    else
      printf "[*] 已切換手動.\n"
      ipmitool raw 0x3a 0x07 0x01 0x00 || { printf "[!] IPMI 指令執行失敗\n"; exit 1; }
      printf "[*] 固定轉速 $valSpeed%%.\n"
      ipmitool raw 0x3a 0x07 0x02 0x"$valSpeedTo16" || { printf "[!] IPMI 指令執行失敗\n"; exit 1; }
    fi
    ;;
  "asrockrack")
		if [ "$valSpeedTo16" == "auto" ]; then
			printf "[*] 已切換自動." && ipmitool raw 0x3a 0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
		else
			printf "[*] 已切換手動.\n"
			printf "[*] 固定轉速 $valSpeed. " && ipmitool raw 0x3a 0x01 0x00 0x"$valSpeedTo16" 0x"$valSpeedTo16" 0x"$valSpeedTo16" 0x00 0x00 0x00 0x00
		fi
    ;;
esac