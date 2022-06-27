terraform {
  cloud {
    organization = "titan-syndicate"

    workspaces {
      name = "rian-space"
    }
  }
}