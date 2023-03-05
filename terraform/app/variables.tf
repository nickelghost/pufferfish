variable "domain" {
  type = string
}

variable "manager_cidr" {
  type    = string
  default = null
}

variable "key_name" {
  type    = string
  default = null
}

variable "log_retention_in_days" {
  type    = number
  default = 14
}
