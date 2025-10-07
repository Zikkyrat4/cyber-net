# Провайдер Proxmox
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
}

# Создание pfSense VM
resource "proxmox_vm_qemu" "pfsense" {
  count       = 1
  name        = "pfsense-fw"
  target_node = var.proxmox_node
  clone       = var.pfsense_template

  memory = 2048
  
  cpu {
    cores = 2
    sockets = 1
  }


  # WAN интерфейс
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # LAN интерфейс  
  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr1"
  }

  # OPT1 интерфейс (для дополнительных VLAN)
  network {
    id     = 2
    model  = "virtio"
    bridge = "vmbr2"
  }

  disk {
    slot    = "scsi0"
    storage = var.storage_name
    type    = "disk"
    size    = "20G"
  }

  os_type = "other"

  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

# Создание Kubernetes мастер нод
resource "proxmox_vm_qemu" "k8s_master" {
  count       = var.k8s_master_count
  name        = "k8s-master-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.ubuntu_template

  memory = 4096
  
  cpu {
    cores = 2
    sockets = 1
  }


  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr1"
  }

  disk {
    slot   = "scsi0"
    storage = var.storage_name
    type    = "disk"
    size    = "20G"
  }

  os_type = "cloud-init"

  # Cloud-init конфигурация
  ciuser     = var.ci_user
  cipassword = var.ci_password
  sshkeys    = var.ssh_public_key

  ipconfig0 = "ip=192.168.10.${count.index + 10}/24,gw=192.168.10.1"

  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

# Создание Kubernetes worker нод
resource "proxmox_vm_qemu" "k8s_worker" {
  count       = var.k8s_worker_count
  name        = "k8s-worker-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.ubuntu_template

  memory = 8192
  
  cpu {
    cores = 4
    sockets = 1
  }


  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr1"
  }

  disk {
    slot    = "scsi0"
    storage = var.storage_name
    type    = "disk"
    size    = "80G"
  }

  os_type = "cloud-init"

  # Cloud-init конфигурация
  ciuser     = var.ci_user
  cipassword = var.ci_password
  sshkeys    = var.ssh_public_key

  ipconfig0 = "ip=192.168.10.${count.index + 20}/24,gw=192.168.10.1"

  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

# Виртуальные машины для студентов (создаются динамически)
resource "proxmox_vm_qemu" "student_vms" {
  count       = var.student_vm_count
  name        = "student-vm-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.ubuntu_template

  memory = 2048
  
  cpu {
    cores = 2
    sockets = 1
  }


  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr1"
    tag    = 100 + count.index  # VLAN для изоляции студентов
  }

  disk {
    slot    = "scsi0"
    storage = var.storage_name
    type    = "disk"
    size    = "20G"
  }

  os_type = "cloud-init"

  ciuser     = var.ci_user
  cipassword = var.ci_password
  sshkeys    = var.ssh_public_key

  ipconfig0 = "ip=192.168.${100 + count.index}.10/24,gw=192.168.${100 + count.index}.1"
}