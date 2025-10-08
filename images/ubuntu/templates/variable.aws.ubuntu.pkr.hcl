variable "ami_name" {
  type    = string
  default = ""
}

variable "ami_description" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = ""
}

variable "source_ami_owner" {
  type    = string
  default = "099720109477"
}

variable "ubuntu_version" {
  type    = string
  default = ""
}

variable "source_ami_name" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-${var.ubuntu_version}.04-amd64-server-*"
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "security_group_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "volume_size" {
  type    = number
  default = 75
}

variable "volume_type" {
  type    = string
  default = "gp3"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for building"
  default     = "${env("INSTANCE_TYPE")}"
}
