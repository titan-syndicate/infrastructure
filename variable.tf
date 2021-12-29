variable "linode_token" {
  description = "Linode APIv4 Personal Access Token"
  sensitive   = true
}

variable "region" {
  description = "The region to deploy the LKE cluster in."
  default     = "us-east"
}

# variable "replica_count" {
#   description = "The number of replicas of the echo server."
#   default     = 1
# }

variable "pool_count" {
  description = "The number of instances to provision in the LKE cluster."
  default     = 2
}