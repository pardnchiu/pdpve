#!/bin/bash

CORE=""
MAX=""
MIN=""
ACTION=""

OPTIONS=$(getopt -o sc:x:n:ih -l set,core:,max:,min:,info,help -- "$@")
if [ $? != 0 ]; then echo "參數解析錯誤" >&2; exit 1; fi
eval set -- "$OPTIONS"

while true; do
  case "$1" in
    -s|--set)
      ACTION="set"; shift ;;
    -c|--core)
      CORE="$2"; shift 2 ;;
    -x|--max)
      MAX="$2"; shift 2 ;;
    -n|--min)
      MIN="$2"; shift 2 ;;
    -i|--info)
      ACTION="info"; shift ;;
    -h|--help)
      HELP="true"; shift ;;
    --)
      shift; break ;;
    *)
      break ;;
  esac
done

if [ "$HELP" = "true" ]; then
	printf "___________________________________________\n\n"
  printf "  -s,  --set      設定 CPU 頻率\n"
  printf "  -c,  --core     選擇核心數\n"
  printf "  -x,  --max      設定最高頻率\n"
  printf "  -n,  --min      設定最低頻率\n"
  printf "  -i,  --info     顯示 CPU 資訊\n"
  printf "  -h,  --help     顯示說明\n"
	printf "___________________________________________\n\n"
  exit 0
fi

# 檢查 CPU 型號
check_cpu_support() {
  local cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | tr '[:upper:]' '[:lower:]')
  
  if [[ "$cpu_model" == *"epyc"* ]]; then
    printf "[!] EPYC CPU 不支援頻率調整，跳過設定\n"
    return 1
  fi
  return 0
}

get_cpu_temp() {
  # 優先使用 Tctl，再用 CPUTIN
  local tctl_temp=$(sensors | grep "Tctl:" | grep -o '+[0-9.]*°C' | head -1)
  local cputin_temp=$(sensors | grep "CPUTIN:" | grep -o '+[0-9.]*°C' | head -1)
  
  if [[ -n "$tctl_temp" ]]; then
    echo "[*] 目前 CPU 溫度: $tctl_temp (Tctl)"
  elif [[ -n "$cputin_temp" ]]; then
    echo "[*] 目前 CPU 溫度: $cputin_temp (主機板感測器)"
  else
    echo "[!] 無法取得 CPU 溫度"
  fi
}

# 動作選擇
if [[ -z "$ACTION" ]]; then
	printf "___________________________________________\n\n"
	printf "  s,  set       設定 CPU 頻率\n"
	printf "  i,  info      顯示 CPU 資訊 \n"
  printf "  h,  help      顯示說明\n"
	printf "  bye           停止動作 \n"
	printf "___________________________________________\n\n"
  read -p "[-] 請選擇 cpu 動作? " -r
  ACTION=$REPLY
fi

# 執行動作
case "$ACTION" in
  "set"|"s")
    # 檢查 CPU 支援
    if ! check_cpu_support; then
      exit 0
    fi
    
    # 互動式輸入
    if [ -z "$CORE" ]; then
      current_cores=$(nproc)
      read -p "[-] 核心數 ? (目前: $current_cores) " -r
      CORE="$REPLY"
    fi

    if [ -z "$MAX" ]; then
      # 取得可用頻率清單
      available_freqs=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies 2>/dev/null)
      
      if [ -n "$available_freqs" ]; then
        # 轉換為陣列並顯示選項
        freq_array=($available_freqs)
        echo "請選擇最大主頻："
        for i in "${!freq_array[@]}"; do
          ghz=$(awk "BEGIN {printf \"%.1f\", ${freq_array[$i]}/1000000}")
          echo "$((i+1))) ${ghz}GHz"
        done
        
        while true; do
          read -p "請輸入選項 (1-${#freq_array[@]}): " choice
          if [[ "$choice" -ge 1 && "$choice" -le ${#freq_array[@]} ]]; then
            selected_freq=${freq_array[$((choice-1))]}
            MAX=$(awk "BEGIN {printf \"%.1f\", $selected_freq/1000000}")
            break
          else
            echo "[!] 無效選項，請重新輸入"
          fi
        done
      else
        read -p "[-] 最大主頻 ? " -r
        MAX="$REPLY"
      fi
    fi

    if [ -z "$MIN" ]; then
      read -p "[-] 最小主頻 ? (可留空) " -r
      MIN="$REPLY"
    fi

    # 計算核心範圍
    max_freq="${MAX}00000"
    min_freq="${MIN}00000"

    # 設定頻率
    if [[ -n "$CORE" && -n "$MAX" ]]; then
      # 取得系統最低頻率
      min_available_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null || echo "800000")
      
      # 設定前 CORE 個核心
      for i in $(seq 0 $((CORE - 1))); do
        cpufreq-set -c $i -g performance 2>/dev/null || true
        echo $max_freq >/sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq 2>/dev/null || true
        if [[ -n "$MIN" ]]; then
          echo $min_freq >/sys/devices/system/cpu/cpu$i/cpufreq/scaling_min_freq 2>/dev/null || true
        else
          echo $max_freq >/sys/devices/system/cpu/cpu$i/cpufreq/scaling_min_freq 2>/dev/null || true
        fi
      done
      
      # 設定剩餘核心為最低頻率
      total_cores=$(nproc)
      for i in $(seq $CORE $((total_cores - 1))); do
        cpufreq-set -c $i -g powersave 2>/dev/null || true
        echo $min_available_freq >/sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq 2>/dev/null || true
        echo $min_available_freq >/sys/devices/system/cpu/cpu$i/cpufreq/scaling_min_freq 2>/dev/null || true
      done
      
      printf "[*] 已設置前 $CORE 核心 | 剩餘核心設為最低頻率\n"
    fi
    ;;
  "info"|"i")
	  printf "___________________________________________\n\n"
    echo "[*] CPU 型號: $(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)"
    echo "[*] 總核心數: $(nproc)"
    get_cpu_temp
    echo "[*] 目前頻率設定:"
    for i in $(seq 0 $(($(nproc) - 1))); do
      current_freq=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq 2>/dev/null || echo "N/A")
      if [[ "$current_freq" != "N/A" ]]; then
        freq_ghz=$(awk "BEGIN {printf \"%.1f\", $current_freq/1000000}")
        echo "  核心 $i: ${freq_ghz}GHz"
      fi
    done
	  printf "___________________________________________\n\n"
    ;;
  "bye")
    exit 0
    ;;
  *)
    echo "[!] 無效動作"
    exit 1
    ;;
esac