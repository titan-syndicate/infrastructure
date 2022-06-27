resource "google_compute_instance" "vm_instance" {
  name         = "rian-test"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
      size  = 60
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
