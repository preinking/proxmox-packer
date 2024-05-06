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

variable "centos_image" {
  type    = string
  default = "CentOS-7-x86_64-dvd.iso"
}

variable "template_description" {
  type    = string
  default = "CentOS 7 Template"
}

variable "template_name" {
  type    = string
  default = "centos7-packer-template"
}

variable "version" {
  type    = string
  default = ""
}

source "proxmox-iso" "centos7" {
  boot_command            = ["<up><tab> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
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
  http_directory           = "centos7"
  insecure_skip_tls_verify = true
  iso_file                 = "${var.proxmox_iso_pool}/${var.centos_image}"
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
  vm_id                = "9001"
}

build {
  sources = ["source.proxmox-iso.centos7"]

  provisioner "shell" {
    inline = ["yum install -y cloud-init qemu-guest-agent cloud-utils-growpart gdisk", "shred -u /etc/ssh/*_key /etc/ssh/*_key.pub", "if [ -f /etc/machine-id ]; then rm -f /etc/machine-id; touch /etc/machine-id; fi", "if [ -f /var/lib/dbus/machine-id ]; then rm -f //var/lib/dbus/machine-id; touch /var/lib/dbus/machine-id; fi", "rm -f /var/run/utmp", ">/var/log/lastlog", ">/var/log/wtmp", ">/var/log/btmp", "rm -rf /tmp/* /var/tmp/*", "unset HISTFILE; rm -rf /home/*/.*history /root/.*history", "rm -f /root/*ks", "passwd -d root", "passwd -l root"]
    only   = ["proxmox-iso"]
  }

}
