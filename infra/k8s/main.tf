terraform {
  required_version = ">= 1.6"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.33" }
    helm       = { source = "hashicorp/helm", version = "~> 2.13" }
  }
}

provider "kubernetes" {
  config_path    = "C:/Users/levit/.kube/config"
  config_context = "docker-desktop" # or k3d-devops / aks-tomerdashboard-admin
}

provider "helm" {
  kubernetes {
    config_path    = "C:/Users/levit/.kube/config"
    config_context = "docker-desktop"
  }
}
