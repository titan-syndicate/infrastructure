# makes it easy to test that ssh works and cloud init did its thing
output "ips" {
  // value = values(google_compute_instance.vm_instance)[*].network_interface.0.access_config.0.nat_ip
  //   value = google_compute_instance.vm_instance
  // sensitive = true

  value = formatlist("%v", google_compute_instance.vm_instance.*.network_interface.0.access_config.0.nat_ip)
}
