locals {
  kubeconfig_string = base64decode(linode_lke_cluster.my-cluster.kubeconfig)
  kubeconfig        = yamldecode(local.kubeconfig_string)

  api_endpoint   = linode_lke_cluster.my-cluster.api_endpoints[0]
  api_token      = local.kubeconfig.users[0].user.token
  ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])

  loadbalancer_ingress = kubernetes_service.loadbalancer.status.0.load_balancer.0.ingress.0

  #   echo_labels = {
  #     app = "echo-server"
  #   }
}

resource "linode_lke_cluster" "my-cluster" {
  label       = "really-cool-cluster"
  k8s_version = "1.22"
  region      = var.region

  pool {
    type  = "g6-standard-2"
    count = var.pool_count
  }
}

resource "kubernetes_service" "loadbalancer" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"
      "app.kubernetes.io/instance" = "ingress-nginx"
      "app.kubernetes.io/version" = "1.1.0"
      "app.kubernetes.io/component" = "controller"
    }
  }
  spec {
    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
    # ip_family_policy        = "SingleStack"
    # ip_families             = ["IPv4"]
    selector = {
      "app.kubernetes.io/name"      = "ingress-nginx"
      "app.kubernetes.io/instance"  = "ingress-nginx"
      "app.kubernetes.io/component" = "controller"
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = "http"
    }
  }
}

resource "kubernetes_namespace" "ingress-nginx" {
  metadata {

    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name"      = "ingress-nginx"
      "app.kubernetes.io/instance"  = "ingress-nginx"
    }
  }
}

# resource "kubernetes_service" "loadbalancer" {
#   metadata {
#     name = "my-loadbalancer"
#   }

#   spec {
#     selector = local.echo_labels

#     port {
#       protocol    = "TCP"
#       port        = 80
#       target_port = 5678
#     }

#     type = "LoadBalancer"
#   }
# }

# resource "kubernetes_deployment" "echo-server" {
#   metadata {
#     name = "my-echo-server"
#   }

#   spec {
#     replicas = var.replica_count

#     selector {
#       match_labels = local.echo_labels
#     }

#     template {
#       metadata {
#         labels = local.echo_labels
#       }

#       spec {
#         container {
#           image = "hashicorp/http-echo"
#           name  = "echo"
#           args  = ["-text", var.echo_message]

#           port {
#             container_port = 5678
#           }
#         }
#       }
#     }
#   }
# }
