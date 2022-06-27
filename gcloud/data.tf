data "cloudinit_config" "conf" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = file("./scripts/add-gh-ssh.yaml")
    filename     = "conf.yaml"
  }
}