packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_iso_pool" {
  type    = string
  default = "local:iso"
}

variable "proxmox_node" {
  type    = string
  default = ""
}

variable "proxmox_password" {
  type    = string
  default = ""
}

variable "proxmox_storage_format" {
  type    = string
  default = "raw"
}

variable "proxmox_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "proxmox_url" {
  type    = string
  default = ""
}

variable "proxmox_username" {
  type    = string
  default = ""
}

variable "rocky_image" {
  type    = string
  default = "Rocky-8.9-x86_64-dvd.iso"
}

variable "template_description" {
  type    = string
  default = "Rocky Linux 8 Template"
}

variable "template_name" {
  type    = string
  default = "rocky8-packer-template"
}

variable "version" {
  type    = string
  default = ""
}

source "proxmox-iso" "rocky8" {
  boot_command            = ["<up><tab> text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
  boot_wait               = "10s"
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"
  cores                   = "2"
  cpu_type                = "host"
  disks {
    disk_size         = "8G"
    format            = "${var.proxmox_storage_format}"
    storage_pool      = "${var.proxmox_storage_pool}"
    type              = "scsi"
  }
  http_directory           = "rocky8"
  insecure_skip_tls_verify = true
  iso_file                 = "${var.proxmox_iso_pool}/${var.rocky_image}"
  memory                   = "8192"
  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
  }
  node                 = "${var.proxmox_node}"
  os                   = "l26"
  password             = "${var.proxmox_password}"
  proxmox_url          = "${var.proxmox_url}"
  scsi_controller      = "virtio-scsi-single"
  sockets              = "1"
  ssh_password         = "Packer"
  ssh_port             = 22
  ssh_timeout          = "60m"
  ssh_username         = "root"
  template_description = "${var.template_description}"
  template_name        = "${var.template_name}"
  unmount_iso          = true
  username             = "${var.proxmox_username}"
  vm_id                = "9002"
}

build {
  sources = ["source.proxmox-iso.rocky8"]

  # Consolidated provisioner to install packages, enable services, and clean up the system
  provisioner "shell" {
    inline = [
      # Install required packages
      "dnf install -y cloud-init cloud-utils-growpart qemu-guest-agent gdisk",
      # Enable cloud-init services
      "systemctl enable cloud-init-local.service",
      "systemctl enable cloud-init.service",
      "systemctl enable cloud-config.service",
      "systemctl enable cloud-final.service",
      # Shred SSH keys for security
      "shred -u /etc/ssh/*_key /etc/ssh/*_key.pub",
      # Clear logs and temporary files
      "rm -f /var/run/utmp",
      ">/var/log/lastlog",
      ">/var/log/wtmp",
      ">/var/log/btmp",
      "rm -rf /tmp/* /var/tmp/*",
      # Clear history files and user history
      "unset HISTFILE",
      "rm -rf /home/*/.*history /root/.*history",
      # Remove kickstart files and resolv.conf
      "rm -f /root/*ks",
      "rm -f /etc/resolv.conf",
      # Secure root user by clearing and locking password
      "passwd -d root",
      "passwd -l root"
    ]
    inline_shebang = "/bin/sh -xe"
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
  }
}
