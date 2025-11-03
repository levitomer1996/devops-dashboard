terraform {
  required_version = ">= 1.6"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# For Windows + Docker Desktop
provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

resource "docker_network" "app" {
  name = "devops-dashboard-net"
}
