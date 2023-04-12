packer {
  required_version = "~> 1.8"
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.2.1"
    }
  }
}

locals {
  timestamp          = formatdate("YYMMDD-HHMM", timestamp())
  # Change to jsondecode(var.regions) when deploy to PROD
  region_kms_key_ids = { for _region in ["us-east-1"] : _region => var.kms_key_id }
}

variable env {
  default = env("env")
}

variable name {
  default = env("name")
}

variable user {
  default = env("user")
}

variable product {
  default = env("product")
}

variable path {
  default = env("path")
}

variable owner {
  default = env("owner")
}

variable epic_org_arn {
  default = env("epic_org_arn")
}

variable region {
  default = env("region")
}

variable regions {
  default = env("regions")
}

variable vpc_id {
  default = env("vpc_id")
}

variable kms_key_id {
  default = env("kms_key_id")
}

variable subnet_id {
  default = env("subnet_id")
}

variable iam_instance_profile {
  default = env("iam_instance_profile")
}

variable security_profile {
  default = env("security_profile")
}

/*
variable cloud_init_script {
  default = env("cloud_init_script")
}

variable user_data {
  default   = env("user_data")
  sensitive = true
}

variable cis_script {
  default   = env("cis_script")
}
*/

data "amazon-ami" "image" {
  filters = {
    name                = var.path
    virtualization-type = "hvm"
    root-device-type    = "ebs"
  }
  owners      = [var.owner]
  most_recent = true
  region      = var.region
}

source "amazon-ebs" "image" {
  source_ami              = data.amazon-ami.image.id
  ami_org_arns            = [var.epic_org_arn]
  ami_name                = "${var.name}-${local.timestamp}"
  ami_description         = "Epic ${var.name} secure image. Managed by CloudSec team"
  instance_type           = "c5.large"
  region                  = var.region
  # Change to jsondecode(var.regions) when deploy to PROD
  ami_regions             = ["us-east-1"]
  ami_virtualization_type = "hvm"
  vpc_id                  = var.vpc_id
  subnet_id               = var.subnet_id
  iam_instance_profile    = var.iam_instance_profile
  encrypt_boot            = true
  kms_key_id              = var.kms_key_id
  region_kms_key_ids      = local.region_kms_key_ids

  ssh_interface = "session_manager"
  communicator  = "ssh"
  ssh_username  = var.user
}

build {
  sources = ["source.amazon-ebs.image"]
  name    = var.name
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
