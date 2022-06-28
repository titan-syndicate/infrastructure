variable image_id {
  type = string
  default = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable machine_type {
  type = string
  default = "e2-standard-4"
}

variable base_name {
  type = string
  default = "rianutu"
}

variable node_count {
  type = number
  default = 1
}

variable node_size{
  type = number
  default = 60
}