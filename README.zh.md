# PDPVE 管理工具
> Proxmox VE 的管理腳本，提供虛擬機管理、CPU 控制、風扇調節、核心管理等功能。

![lang](https://img.shields.io/badge/lang-Bash-green)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![version](https://img.shields.io/badge/version-v0.1.1-orange)](https://github.com/pardnchiu/pdpve/releases)<br>
[![readme](https://img.shields.io/badge/readme-EN-white)](README.md)
[![readme](https://img.shields.io/badge/readme-ZH-white)](README.zh.md)

## 核心功能

### 虛擬機管理 (QM)
- 自動化虛擬機安裝
- 支援 Debian、Ubuntu、RockyLinux
- 雲端映像檔自動下載
- SSH 金鑰配置
- 網路設定 (DHCP/靜態IP)
- 虛擬機狀態控制 (啟動/關閉/重啟)

### CPU 頻率控制
- 動態調整 CPU 頻率
- 核心數量控制
- 效能/節能模式切換
- 溫度監控
- EPYC CPU 相容性檢查

### 風扇控制
- 支援多品牌伺服器 (Dell、Supermicro、HPE、ASRock Rack)
- IPMI 指令控制
- 自動/手動模式切換
- 轉速百分比設定

### 系統管理
- PVE 核心管理
- 網路裝置掃描
- 系統更新
- 核心清理

## 系統需求

- Proxmox VE 環境
- root 權限
- IPMI 工具 (風扇控制)
- curl (映像檔下載)

## 安裝方式

```bash
# 下載腳本
git clone https://github.com/pardnchiu/pdpve.git
cd pdpve

# 執行腳本
chmod +x pdpve
./pdpve
```

## 提供的 Cloud Image

### Debian
`debian-{version}-generic-amd64.qcow2`

### Ubuntu
`ubuntu-{version}-server-cloudimg-amd64.img`

### RockyLinux  
`Rocky-{version}-GenericCloud-Base.latest.x86_64.qcow2`

## 支援的伺服器品牌

### IPMI 風扇控制

| 品牌 | 型號 | IPMI 指令 |
|------|------|-----------|
| Dell | PowerEdge | `0x30 0x30` |
| Supermicro | X 系列 | `0x30 0x45` |
| HPE | - | `0x3a 0x07` |
| ASRock Rack | - | `0x3a 0x01` |

## 錯誤處理

### 虛擬機建立失敗
- 自動清理失敗的虛擬機
- 檢查儲存池可用性
- 驗證映像檔完整性

### CPU 控制限制
- EPYC CPU 跳過頻率調整
- 頻率範圍驗證
- 權限檢查

### 風扇控制錯誤
- IPMI 指令執行狀態檢查
- 品牌自動偵測失敗處理
- 轉速範圍限制

## 授權條款

此專案採用 [MIT](LICENSE) 授權條款。

## 作者

<img src="https://avatars.githubusercontent.com/u/25631760" align="left" width="96" height="96" style="margin-right: 0.5rem;">

<h4 style="padding-top: 0">邱敬幃 Pardn Chiu</h4>

<a href="mailto:dev@pardn.io" target="_blank">
  <img src="https://pardn.io/image/email.svg" width="48" height="48">
</a> <a href="https://linkedin.com/in/pardnchiu" target="_blank">
  <img src="https://pardn.io/image/linkedin.svg" width="48" height="48">
</a>

***

©️ 2025 [邱敬幃 Pardn Chiu](https://pardn.io)