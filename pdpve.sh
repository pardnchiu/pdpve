#!/bin/bash

programName="pdpve"
appVersion="v1.0.9"
osKernel=$(uname -r)
gitLink="https://github.com/pardnchiu/pdpve.git"
appPath=/usr/local/sbin/$programName
appModulePath=/usr/local/bin/$programName

param2=$2
param3=$3
param4=$4

function _SHOW_TIP {
	printf "___________________________________________\n\n"
	printf "  qm, qemu      虛擬機\n"
	printf "  ip, findip    連接裝置\n"
	printf "  c,  cpu       CPU\n"
	printf "  f,  fan       FAN\n"
	printf "  k,  kernel    顯示 PVE 核心\n"
	printf "  u,  update    更新套件\n"
	printf "  v,  version   顯示 $programName 版本\n"
	printf "  r,  remove    移除 $programName\n"
	printf "  h,  help      顯示 $programName 指令\n"
	printf "___________________________________________\n\n"
}

function _INSTALL() {
  cp -f $0 $appPath
  chmod +x $appPath
  
  mkdir -p $appModulePath
  cp -rf ./module $appModulePath/
  chmod -R +x $appModulePath/module/*
  
  printf "[*] 已安裝 $programName 至系統\n"
  printf "[*] 當前 $programName 版本為 $appVersion\n"
  printf "[*] 後續可以直接執行 \"$programName\" 來使用\n"
}

function _REMOVE() {
  if [ -e $appPath ]; then
    read -p "[-] 是否從系統中移除 $programName? [y/N] " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -f $appPath
      rm -rf $appModulePath
      printf "[*] 已成功從系統中移除 $programName\n"
      exit 1
    fi
  else
    printf "[!] 並未安裝 $programName.\n"
  fi
}

function _CHECK_INSTALL() {
  isDiff=false

  # 已安裝
  if [ -e $appPath ]; then
    # 取得已安裝的版本號
    installedVersion=$($appPath -v | awk '{printf $0}')

    # 版本號不相同
    if [ $appVersion != $installedVersion ]; then
        printf "\n[!] 版本號不相同 (當前: $installedVersion | 新: $appVersion)\n"
        printf "[*] 安裝會直接覆蓋當前版本"
        isDiff=true
    fi
  # 未安裝
  else
    _INSTALL
  fi

  # 版本不相同
  if [ $isDiff == true ]; then
    printf "\n"
    read -p "[-] 是否更換版本至 $appVersion? [y/N]" -n 1 -r
    printf "\n"

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      _INSTALL
    fi
  fi
}

function _INIT {
	if [[ $EUID -ne 0 ]]; then
		printf "[!] 無 root 權限.\n"
		exit 1
	fi

  if [ "$param2" = "--no-header" ]; then
        return 
  else 
    printf "\n"
    printf "█▀▄ █▀▄ █▀▄ █ █ █▀▀\n"
    printf "█▀  █ █ █▀  █ █ █▀▀\n"
    printf "▀   ▀▀  ▀    ▀  ▀▀▀\n"
    printf "By Pardn Chiu [dev@pardn.io]\n"
  fi
	_SHOW_TIP
  _CHECK_INSTALL
}

function _CALL_MODULE() {
  local NAME="$1"
  
  # 檢查模組是否存在
  if [ -f "./module/${NAME}.sh" ]; then
    bash "./module/${NAME}.sh" "${@:2}"
  elif [ -f "$appModulePath/module/${NAME}.sh" ]; then
    bash "$appModulePath/module/${NAME}.sh" "${@:2}"
  else
    printf "[!] 找不到模組: %s\n" "$NAME"
  fi
}

function _UPDATE() {
	apt update
	apt upgrade -y
	apt autoremove -y
	apt autoclean -y
	apt clean
}

function _UPDATE_VERSION() {
	printf "[*] 下載最新資料\n"
  git clone $gitLink /tmp/pdpve
  if [ $? -ne 0 ]; then
    printf "[!] 無法下載最新版本，請檢查網路連線或 GitHub 狀態。\n"
    exit 1
  fi
  printf "[*] 更新 $programName\n"
  cp -f /tmp/pdpve/pdpve.sh $appPath
  chmod +x $appPath
  if [ -d "/tmp/pdpve/module" ]; then
    mkdir -p $appModulePath
    cp -rf /tmp/pdpve/module $appModulePath/
    chmod -R +x $appModulePath/module/*
    printf "[*] 已更新 module 目錄至 $appModulePath/module/\n"
  fi
  printf "[*] 已更新 $programName 至 $appPath\n"
  printf "[*] 執行 \"$programName\" 來使用\n"
  printf "[*] 執行 \"$programName -r\" 來解除安裝.\n"
  printf "[*] 更新完成，請重新啟動程式以應用新版本。\n"
  rm -rf /tmp/pdpve
  exit 1
}

function _DO() {
	while true; do
	  read -p "[-] 執行 pdpve 指令? " -r
		case "$REPLY" in
		k | kernel)
	    printf "$osKernel\n"
			;;
		u | update)
			_UPDATE
			;;
		qm | --qemu)
			_CALL_MODULE "qm" "${@:2}"
      _SHOW_TIP
      _DO
			;;
		ip | findip)
			_CALL_MODULE "find-ip" "${@:2}"
			;;
		c | cpu)
      _CALL_MODULE "cpu" "${@:2}"
			;;
		f | fan)
			_CALL_MODULE "fan" "${@:2}"
			;;
		v | version)
      printf "$appVersion\n"
      _CHECK_INSTALL
			;;
		r | remove)
			_INIT
			_REMOVE
			;;
		h | help)
			_INIT
			;;
		*)
			_DO
			;;
		esac
		shift
	done
	exit 1
}

while true; do
	case "$1" in
	-k | --kernel)
	  printf "$osKernel\n"
    break 
    ;;
	-u | --update)
		_UPDATE 
    ;;
	-qm | --qemu)
		_CALL_MODULE "qm" "${@:2}"
    break
		;;
	-ip | --findip)
		_FIND_IP
    break
		;;
	-c | --cpu)
    _CALL_MODULE "cpu" "${@:2}"
    break
		;;
	-f | --fan)
		_CALL_MODULE "fan" "${@:2}"
    break
		;;
	-v | --version)
	  printf "$appVersion\n"
    break
		;;
	-uv | --update-version)
		_UPDATE_VERSION
		;;
	-r | --remove)
		_INIT
		_REMOVE
		;;
	-h | --help)
		_INIT
		exit 1
		;;
	*)
		_INIT
		_DO
    break
		;;
	esac
	shift
done