variable "vm_name"        { type = string }
variable "vm_id"          { type = number }
variable "proxmox_node"   { type = string }
variable "template"       { type = string }
variable "cores"          { type = number; default = 2 }
variable "memory"         { type = number; default = 2048 }
variable "disk_size"      { type = string; default = "20G" }
variable "storage"        { type = string }
variable "ip_address"     { type = string }
variable "gateway"        { type = string }
variable "dns"            { type = string }
variable "ssh_public_key" { type = string }
variable "tags"           { type = list(string); default = [] }
