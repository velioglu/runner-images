# Simple Packer Template for Building Ubuntu AMI
# This is a minimal template to get you started with Packer

# Packer Configuration Block
# This tells Packer which plugins are required
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

# Variable Definitions
# These are like parameters you can customize when running the build

# Name of the AMI that will be created
variable "ami_name" {
  type        = string
  description = "Name for the AMI"
  default     = "my-simple-ubuntu-ami"
}

# Description for the AMI
variable "ami_description" {
  type        = string
  description = "Description for the AMI"
  default     = "Simple Ubuntu 22.04 AMI created with Packer"
}

# AWS region where the AMI will be built
variable "region" {
  type        = string
  description = "AWS region to build the AMI in"
  default     = "us-east-1"
}

# Instance type to use for building (smaller = cheaper)
variable "instance_type" {
  type        = string
  description = "EC2 instance type for building"
  default     = "t3.micro"
}

# VPC ID for the build environment
variable "vpc_id" {
  type        = string
  description = "VPC ID where the build instance will be launched"
  default     = ""
}

# Subnet ID for the build environment
variable "subnet_id" {
  type        = string
  description = "Subnet ID where the build instance will be launched"
  default     = ""
}

# Security Group ID for the build environment
variable "security_group_id" {
  type        = string
  description = "Security Group ID for the build instance"
  default     = ""
}

# Source Block - This defines HOW to build the AMI
# "amazon-ebs" is a predefined builder that creates EBS-backed AMIs
source "amazon-ebs" "simple_ubuntu" {
  
  # Basic AMI Configuration
  ami_name        = "${var.ami_name}"
  ami_description = "${var.ami_description}"
  region          = "${var.region}"
  
  # Instance Configuration
  instance_type = "${var.instance_type}"
  ssh_username  = "ubuntu"  # Default user for Ubuntu AMIs
  
  # VPC Configuration
  vpc_id                      = "${var.vpc_id}"
  subnet_id                   = "${var.subnet_id}"
  security_group_ids          = ["${var.security_group_id}"]
  associate_public_ip_address = true

  # Source AMI Filter - This finds the base Ubuntu AMI to build from
  source_ami_filter {
    filters = {
      # Look for Ubuntu 22.04 LTS
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      # Use HVM virtualization (modern, better performance)
      virtualization-type = "hvm"
      # Use EBS-backed (not instance store)
      root-device-type    = "ebs"
    }
    # Canonical's AWS account ID (they publish official Ubuntu AMIs)
    owners      = ["099720109477"]
    # Use the most recent matching AMI
    most_recent = true
  }
  
  # Storage Configuration
  # This configures the root volume of the build instance
  launch_block_device_mappings {
    device_name           = "/dev/sda1"  # Root device
    volume_size           = 8            # 8GB (minimum for Ubuntu)
    volume_type           = "gp3"        # Modern, cost-effective storage
    delete_on_termination = true         # Delete when instance terminates
    encrypted             = false        # Not encrypted (can be changed)
  }
  
  # Security and Access
  # Allow Packer to connect via SSH
  ssh_clear_authorized_keys = true
  
  # Tags for the build instance (temporary)
  run_tags = {
    Name    = "packer-build-${var.ami_name}"
    Purpose = "AMI Build"
  }
  
  # Tags for the final AMI
  tags = {
    Name        = "${var.ami_name}"
    Description = "${var.ami_description}"
    CreatedBy   = "Packer"
  }
  
  # Tags for the EBS snapshot
  snapshot_tags = {
    Name        = "${var.ami_name}-snapshot"
    CreatedBy   = "Packer"
  }
}

# Build Block - This defines WHAT to do during the build process
build {
  # Use the source we defined above
  sources = ["source.amazon-ebs.simple_ubuntu"]
  
  # Provisioner 1: Update the system
  # This runs commands on the instance after it boots
  provisioner "shell" {
    # Execute commands as root using sudo
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    # Inline commands to run
    inline = [
      "echo 'Starting system update...'",
      "apt-get update",
      "apt-get upgrade -y",
      "echo 'System update completed'"
    ]
  }
  
  # Provisioner 2: Install basic tools
  # Install some common utilities
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "echo 'Installing basic tools...'",
      "apt-get install -y curl wget git vim htop",
      "echo 'Basic tools installed'"
    ]
  }
  
  # Provisioner 3: Create a welcome message
  # Add a custom message that shows when someone logs in
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "echo 'Creating welcome message...'",
      "echo 'Welcome to your custom Ubuntu AMI!' > /etc/motd",
      "echo 'Built with Packer on $(date)' >> /etc/motd",
      "echo 'Welcome message created'"
    ]
  }
  
  # Provisioner 4: Clean up
  # Remove temporary files and caches to reduce AMI size
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "echo 'Cleaning up...'",
      "apt-get clean",
      "rm -rf /tmp/*",
      "rm -rf /var/tmp/*",
      "echo 'Cleanup completed'"
    ]
  }
}
