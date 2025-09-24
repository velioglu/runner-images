// Authentication related variables
variable "client_cert_path" {
  type    = string
  default = "${env("ARM_CLIENT_CERT_PATH")}"
}
variable "client_id" {
  type    = string
  default = "${env("ARM_CLIENT_ID")}"
}
variable "client_secret" {
  type      = string
  default   = "${env("ARM_CLIENT_SECRET")}"
  sensitive = true
}
variable "object_id" {
  type    = string
  default = "${env("ARM_OBJECT_ID")}"
}
variable "oidc_request_token" {
  type    = string
  default = ""
}
variable "oidc_request_url" {
  type    = string
  default = ""
}
variable "subscription_id" {
  type    = string
  default = "${env("ARM_SUBSCRIPTION_ID")}"
}
variable "tenant_id" {
  type    = string
  default = "${env("ARM_TENANT_ID")}"
}
variable "use_azure_cli_auth" {
  type    = bool
  default = false
}

// AWS environment related
variable "ami_name" {
  type    = string
  default = "${env("AMI_NAME")}"
}

variable "ami_description" {
  type    = string
  default = "${env("AMI_DESCRIPTION")}"
}

variable "region" {
  type    = string
  default = "${env("REGION")}"
}

variable "source_ami_owner" {
  type    = string
  default = "099720109477"
}

variable "source_ami_name" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "vpc_id" {
  type    = string
  default = "${env("VPC_ID")}"
}

variable "security_group_id" {
  type        = string
  description = "Security Group ID for the build instance"
  default = "${env("SECURITY_GROUP_ID")}"
}

// make sure the subnet auto-assigns public IPs
variable "subnet_id" {
  type    = string
  default = "${env("SUBNET_ID")}"
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

// Image related variables
variable "dockerhub_login" {
  type    = string
  default = "${env("DOCKERHUB_LOGIN")}"
}
variable "dockerhub_password" {
  type    = string
  default = "${env("DOCKERHUB_PASSWORD")}"
}
variable "helper_script_folder" {
  type    = string
  default = "/imagegeneration/helpers"
}
variable "image_folder" {
  type    = string
  default = "/imagegeneration"
}
variable "image_os" {
  type    = string
  default = "${env("IMAGE_OS")}"
}
variable "image_version" {
  type    = string
  default = "${env("IMAGE_VERSION")}"
}
variable "imagedata_file" {
  type    = string
  default = "/imagegeneration/imagedata.json"
}
variable "installer_script_folder" {
  type    = string
  default = "/imagegeneration/installers"
}
variable "install_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "install_user" {
  type    = string
  default = "installer"
}
