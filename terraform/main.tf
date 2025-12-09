# Security Lab Infrastructure - Terraform/OpenTofu
# Deploys Red vs Blue Team environment on Proxmox

terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# Proxmox Provider Configuration
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = var.proxmox_tls_insecure
}

# Variables
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://proxmox.local:8006/api2/json"
}

variable "proxmox_user" {
  description = "Proxmox user"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Disable TLS verification"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "exercise_id" {
  description = "Unique exercise identifier"
  type        = string
  default     = "redblue-lab"
}

# Network Configuration
locals {
  networks = {
    management = "10.0.0.0/24"
    red_team   = "10.0.10.0/24"
    blue_team  = "10.0.20.0/24"
    target     = "10.0.30.0/24"
    purple     = "10.0.40.0/24"
    honeypot   = "10.0.50.0/24"
  }

  vlan_ids = {
    management = 1
    red_team   = 10
    blue_team  = 20
    target     = 30
    purple     = 40
    honeypot   = 50
  }
}

# ============================================================================
# RED TEAM VMs
# ============================================================================

# Kali Linux - Primary Attack Platform
resource "proxmox_vm_qemu" "red_team_kali" {
  name        = "red-team-kali-110"
  target_node = var.proxmox_node
  vmid        = 110

  clone       = "kali-linux-template"  # Pre-built template
  full_clone  = true

  cores   = 4
  sockets = 1
  memory  = 8192

  disk {
    slot    = 0
    size    = "50G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.red_team
  }

  # Cloud-init configuration
  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.10.110/24,gw=10.0.10.1"

  # SSH key
  sshkeys = var.ssh_public_key

  # Metadata
  tags = "red-team,offensive,kali"

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Parrot OS - Alternative Toolkit
resource "proxmox_vm_qemu" "red_team_parrot" {
  name        = "red-team-parrot-111"
  target_node = var.proxmox_node
  vmid        = 111

  clone       = "parrot-os-template"
  full_clone  = true

  cores   = 2
  sockets = 1
  memory  = 4096

  disk {
    slot    = 0
    size    = "40G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.red_team
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.10.111/24,gw=10.0.10.1"
  sshkeys   = var.ssh_public_key
  tags      = "red-team,offensive,parrot"
}

# Red Team C2 Server (Covenant/Sliver)
resource "proxmox_vm_qemu" "red_team_c2" {
  name        = "red-team-c2-112"
  target_node = var.proxmox_node
  vmid        = 112

  clone       = "ubuntu-22-04-template"
  full_clone  = true

  cores   = 2
  sockets = 1
  memory  = 4096

  disk {
    slot    = 0
    size    = "30G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.red_team
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.10.112/24,gw=10.0.10.1"
  sshkeys   = var.ssh_public_key
  tags      = "red-team,c2,infrastructure"
}

# ============================================================================
# BLUE TEAM VMs
# ============================================================================

# SOC Analyst Workstation
resource "proxmox_vm_qemu" "blue_team_soc" {
  name        = "blue-team-soc-121"
  target_node = var.proxmox_node
  vmid        = 121

  clone       = "ubuntu-22-04-template"
  full_clone  = true

  cores   = 4
  sockets = 1
  memory  = 8192

  disk {
    slot    = 0
    size    = "50G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.blue_team
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.20.121/24,gw=10.0.20.1"
  sshkeys   = var.ssh_public_key
  tags      = "blue-team,soc,defensive"
}

# Threat Intelligence Platform (MISP)
resource "proxmox_vm_qemu" "blue_team_misp" {
  name        = "blue-team-misp-122"
  target_node = var.proxmox_node
  vmid        = 122

  clone       = "ubuntu-22-04-template"
  full_clone  = true

  cores   = 2
  sockets = 1
  memory  = 4096

  disk {
    slot    = 0
    size    = "40G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.blue_team
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.20.122/24,gw=10.0.20.1"
  sshkeys   = var.ssh_public_key
  tags      = "blue-team,threat-intel,misp"
}

# Network Monitor (Security Onion/Zeek)
resource "proxmox_vm_qemu" "blue_team_network_monitor" {
  name        = "blue-team-netmon-123"
  target_node = var.proxmox_node
  vmid        = 123

  clone       = "ubuntu-22-04-template"
  full_clone  = true

  cores   = 4
  sockets = 1
  memory  = 16384

  disk {
    slot    = 0
    size    = "100G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.blue_team
  }

  # Additional network interface for traffic mirroring
  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = -1  # Promiscuous mode for all VLANs
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.20.123/24,gw=10.0.20.1"
  sshkeys   = var.ssh_public_key
  tags      = "blue-team,network-monitor,ids"
}

# ============================================================================
# TARGET VMs (Intentionally Vulnerable)
# ============================================================================

# Ubuntu Web Server (DVWA, WebGoat)
resource "proxmox_vm_qemu" "target_web" {
  name        = "target-web-130"
  target_node = var.proxmox_node
  vmid        = 130

  clone       = "ubuntu-22-04-template"
  full_clone  = true

  cores   = 2
  sockets = 1
  memory  = 4096

  disk {
    slot    = 0
    size    = "30G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.target
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.30.130/24,gw=10.0.30.1"
  sshkeys   = var.ssh_public_key
  tags      = "target,vulnerable,web"
}

# Windows Server 2022 (Active Directory)
resource "proxmox_vm_qemu" "target_windows" {
  name        = "target-ad-131"
  target_node = var.proxmox_node
  vmid        = 131

  clone       = "windows-server-2022-template"
  full_clone  = true

  cores   = 4
  sockets = 1
  memory  = 8192

  disk {
    slot    = 0
    size    = "60G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.target
  }

  os_type = "win11"
  agent   = 1
  tags    = "target,windows,active-directory"
}

# Docker Host (Container Escape Testing)
resource "proxmox_vm_qemu" "target_docker" {
  name        = "target-docker-132"
  target_node = var.proxmox_node
  vmid        = 132

  clone       = "ubuntu-22-04-template"
  full_clone  = true

  cores   = 4
  sockets = 1
  memory  = 8192

  disk {
    slot    = 0
    size    = "50G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.target
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.30.132/24,gw=10.0.30.1"
  sshkeys   = var.ssh_public_key
  tags      = "target,docker,container"
}

# ============================================================================
# HONEYPOT VMs
# ============================================================================

# SSH Honeypot (Cowrie)
resource "proxmox_vm_qemu" "honeypot_ssh" {
  name        = "honeypot-ssh-150"
  target_node = var.proxmox_node
  vmid        = 150

  clone       = "ubuntu-22-04-template"
  full_clone  = true

  cores   = 1
  sockets = 1
  memory  = 2048

  disk {
    slot    = 0
    size    = "20G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.honeypot
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.50.150/24,gw=10.0.50.1"
  sshkeys   = var.ssh_public_key
  tags      = "honeypot,ssh,cowrie"
}

# Web Application Honeypot
resource "proxmox_vm_qemu" "honeypot_web" {
  name        = "honeypot-web-151"
  target_node = var.proxmox_node
  vmid        = 151

  clone       = "ubuntu-22-04-template"
  full_clone  = true

  cores   = 1
  sockets = 1
  memory  = 2048

  disk {
    slot    = 0
    size    = "20G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.honeypot
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.50.151/24,gw=10.0.50.1"
  sshkeys   = var.ssh_public_key
  tags      = "honeypot,web,snare"
}

# ============================================================================
# PURPLE TEAM VMs
# ============================================================================

# Exercise Control Dashboard (n8n Integration Hub)
resource "proxmox_vm_qemu" "purple_control" {
  name        = "purple-control-140"
  target_node = var.proxmox_node
  vmid        = 140

  clone       = "ubuntu-22-04-template"
  full_clone  = true

  cores   = 4
  sockets = 1
  memory  = 8192

  disk {
    slot    = 0
    size    = "50G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = local.vlan_ids.purple
  }

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.40.140/24,gw=10.0.40.1"
  sshkeys   = var.ssh_public_key
  tags      = "purple-team,control,dashboard"
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "red_team_vms" {
  description = "Red Team VM information"
  value = {
    kali   = proxmox_vm_qemu.red_team_kali.default_ipv4_address
    parrot = proxmox_vm_qemu.red_team_parrot.default_ipv4_address
    c2     = proxmox_vm_qemu.red_team_c2.default_ipv4_address
  }
}

output "blue_team_vms" {
  description = "Blue Team VM information"
  value = {
    soc            = proxmox_vm_qemu.blue_team_soc.default_ipv4_address
    misp           = proxmox_vm_qemu.blue_team_misp.default_ipv4_address
    network_monitor = proxmox_vm_qemu.blue_team_network_monitor.default_ipv4_address
  }
}

output "target_vms" {
  description = "Target VM information"
  value = {
    web     = proxmox_vm_qemu.target_web.default_ipv4_address
    windows = proxmox_vm_qemu.target_windows.default_ipv4_address
    docker  = proxmox_vm_qemu.target_docker.default_ipv4_address
  }
}

output "honeypot_vms" {
  description = "Honeypot VM information"
  value = {
    ssh = proxmox_vm_qemu.honeypot_ssh.default_ipv4_address
    web = proxmox_vm_qemu.honeypot_web.default_ipv4_address
  }
}

output "purple_team_vms" {
  description = "Purple Team control infrastructure"
  value = {
    control = proxmox_vm_qemu.purple_control.default_ipv4_address
  }
}

output "network_configuration" {
  description = "Network segmentation details"
  value       = local.networks
}
