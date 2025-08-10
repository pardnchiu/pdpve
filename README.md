> [!NOTE]
> This README was translated by ChatGPT 4o

# PDPVE Management Tool
> A comprehensive management script for Proxmox VE, providing virtual machine management, CPU control, fan regulation, and kernel management capabilities.

![lang](https://img.shields.io/badge/lang-Bash-green)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![version](https://img.shields.io/badge/version-v0.1.1-orange)](https://github.com/pardnchiu/pdpve/releases)<br>
[![readme](https://img.shields.io/badge/readme-EN-white)](README.md)
[![readme](https://img.shields.io/badge/readme-ZH-white)](README.zh.md)

## Core Features

### Virtual Machine Management (QM)
- Automated VM installation
- Support for Debian, Ubuntu, RockyLinux
- Automatic cloud image download
- SSH key configuration
- Network setup (DHCP/Static IP)
- VM state control (start/stop/restart)

### CPU Frequency Control
- Dynamic CPU frequency adjustment
- Core count control
- Performance/power saving mode switching
- Temperature monitoring
- EPYC CPU compatibility check

### Fan Control
- Multi-brand server support (Dell, Supermicro, HPE, ASRock Rack)
- IPMI command control
- Auto/manual mode switching
- Speed percentage configuration

### System Management
- PVE kernel management
- Network device scanning
- System updates
- Kernel cleanup

## System Requirements

- Proxmox VE environment
- root privileges
- IPMI tools (for fan control)
- curl (for image downloads)

## Installation

```bash
# Download script
git clone https://github.com/pardnchiu/pdpve.git
cd pdpve

# Execute script
chmod +x pdpve
./pdpve
```

## Available Cloud Images

### Debian
`debian-{version}-generic-amd64.qcow2`

### Ubuntu
`ubuntu-{version}-server-cloudimg-amd64.img`

### RockyLinux  
`Rocky-{version}-GenericCloud-Base.latest.x86_64.qcow2`

## Supported Server Brands

### IPMI Fan Control

| Brand | Model | IPMI Command |
|-------|-------|--------------|
| Dell | PowerEdge | `0x30 0x30` |
| Supermicro | X Series | `0x30 0x45` |
| HPE | - | `0x3a 0x07` |
| ASRock Rack | - | `0x3a 0x01` |

## Error Handling

### VM Creation Failure
- Automatic cleanup of failed VMs
- Storage pool availability check
- Image file integrity verification

### CPU Control Limitations
- Skip frequency adjustment for EPYC CPUs
- Frequency range validation
- Permission checks

### Fan Control Errors
- IPMI command execution status check
- Brand auto-detection failure handling
- Speed range limitations

## License

This project is licensed under the [MIT](LICENSE) License.

## Author

<img src="https://avatars.githubusercontent.com/u/25631760" align="left" width="96" height="96" style="margin-right: 0.5rem;">

<h4 style="padding-top: 0">邱敬幃 Pardn Chiu</h4>

<a href="mailto:dev@pardn.io" target="_blank">
  <img src="https://pardn.io/image/email.svg" width="48" height="48">
</a> <a href="https://linkedin.com/in/pardnchiu" target="_blank">
  <img src="https://pardn.io/image/linkedin.svg" width="48" height="48">
</a>

***

©️ 2025 [邱敬幃 Pardn Chiu](https://pardn.io)