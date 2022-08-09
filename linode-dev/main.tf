resource "linode_instance" "bar_based" {
    type = "g6-standard-6"
    region = "us-central"
    image = "private/16961342"
}

provider "linode" {
  token = var.linode_token
}

terraform {
  required_providers {
    linode = {
      source = "linode/linode"
    }
  }
  cloud {
    organization = "titan-syndicate"

    workspaces {
      name = "linode"
    }
  }
}

output "linod-ip" {
  value = linode_instance.bar_based.ipv4
}

variable linode_token {
  type = string
  default = "REDACTED"
}