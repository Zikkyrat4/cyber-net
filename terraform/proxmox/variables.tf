variable "proxmox_api_url" {
  description = "URL API Proxmox"
  type        = string
}

variable "proxmox_user" {
  description = "Пользователь Proxmox"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Пароль для Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Имя ноды Proxmox"
  type        = string
}

variable "storage_name" {
  description = "Имя хранилища в Proxmox"
  type        = string
  default     = "local-lvm"
}

variable "pfsense_template" {
  description = "Имя шаблона pfSense"
  type        = string
  default     = "pfsense-template"
}

variable "ubuntu_template" {
  description = "Имя шаблона Ubuntu"
  type        = string
  default     = "ubuntu-2004-template"
}

variable "k8s_master_count" {
  description = "Количество мастер нод Kubernetes"
  type        = number
  default     = 3
}

variable "k8s_worker_count" {
  description = "Количество worker нод Kubernetes"
  type        = number
  default     = 3
}

variable "student_vm_count" {
  description = "Количество VM для студентов"
  type        = number
  default     = 10
}

variable "ci_user" {
  description = "Пользователь для cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "ci_password" {
  description = "Пароль для cloud-init"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH публичный ключ"
  type        = string
}