## configuration for tf cloud
terraform {
  cloud {
    organization = "titan-syndicate"

    workspaces {
      name = "rian-space"
    }
  }
}


data "cloudinit_config" "conf" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = file("./scripts/add-gh-ssh.yaml")
    filename     = "conf.yaml"
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "${var.base_name}-${count.index}"
  count        = var.node_count
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.image_id
      size  = var.node_size
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }

  # cloud init stuff
  metadata = {
    user-data = "${data.cloudinit_config.conf.rendered}"
  }

  tags = ["ssh-server"]
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}

# not using the default gcp network here
resource "google_compute_firewall" "ssh-server" {
  name    = "vpc-network-allow-ssh"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-server"]
}


provider "google" {
  project = "rian-dev"
  region  = "us-central1"
  zone    = "us-central1-a"
}
