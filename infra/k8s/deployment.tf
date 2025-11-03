# -------------------------------
# Namespace
# -------------------------------
resource "kubernetes_namespace" "ns" {
  metadata {
    name = "devops-dashboard"
  }
}

# -------------------------------
# Internal hostnames for MongoDBs
# -------------------------------
locals {
  ns              = kubernetes_namespace.ns.metadata[0].name
  users_mongo_svc = "users-mongo.${local.ns}.svc.cluster.local"
  tasks_mongo_svc = "tasks-mongo.${local.ns}.svc.cluster.local"
}

# ===============================
# MONGODB (USERS) - OFFICIAL IMAGE
# ===============================
resource "kubernetes_deployment" "users_mongo" {
  metadata {
    name      = "users-mongo"
    namespace = local.ns
    labels = {
      app = "users-mongo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "users-mongo"
      }
    }

    template {
      metadata {
        labels = {
          app = "users-mongo"
        }
      }

      spec {
        container {
          name  = "mongodb"
          image = "mongo:7"
          args  = ["--bind_ip_all"]

          # Root + default DB (official image)
          env {
            name  = "MONGO_INITDB_ROOT_USERNAME"
            value = "admin"
          }
          env {
            name  = "MONGO_INITDB_ROOT_PASSWORD"
            value = "adminpass"
          }
          env {
            name  = "MONGO_INITDB_DATABASE"
            value = "usersdb"
          }

          port {
            container_port = 27017
          }

          # Small footprint for local clusters
          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              memory = "256Mi"
            }
          }

          # Data dir (ephemeral for local dev)
          volume_mount {
            name       = "data"
            mount_path = "/data/db"
          }
        }

        volume {
          name = "data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "users_mongo" {
  metadata {
    name      = "users-mongo"
    namespace = local.ns
    labels = {
      app = "users-mongo"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "users-mongo"
    }

    port {
      name        = "mongodb"
      port        = 27017
      target_port = 27017
    }
  }
}

# ===============================
# MONGODB (TASKS) - OFFICIAL IMAGE
# ===============================
resource "kubernetes_deployment" "tasks_mongo" {
  metadata {
    name      = "tasks-mongo"
    namespace = local.ns
    labels = {
      app = "tasks-mongo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "tasks-mongo"
      }
    }

    template {
      metadata {
        labels = {
          app = "tasks-mongo"
        }
      }

      spec {
        container {
          name  = "mongodb"
          image = "mongo:7"
          args  = ["--bind_ip_all"]

          env {
            name  = "MONGO_INITDB_ROOT_USERNAME"
            value = "admin"
          }
          env {
            name  = "MONGO_INITDB_ROOT_PASSWORD"
            value = "adminpass"
          }
          env {
            name  = "MONGO_INITDB_DATABASE"
            value = "tasksdb"
          }

          port {
            container_port = 27017
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              memory = "256Mi"
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/data/db"
          }
        }

        volume {
          name = "data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "tasks_mongo" {
  metadata {
    name      = "tasks-mongo"
    namespace = local.ns
    labels = {
      app = "tasks-mongo"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "tasks-mongo"
    }

    port {
      name        = "mongodb"
      port        = 27017
      target_port = 27017
    }
  }
}

# -------------------------------
# users-service Deployment
# -------------------------------
resource "kubernetes_deployment" "users" {
  metadata {
    name      = "users-service"
    namespace = local.ns
    labels = {
      app = "users-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "users-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "users-service"
        }
      }

      spec {
        container {
          name              = "users-service"
          image             = "devops/users-service:local" # or your ACR image
          image_pull_policy = "IfNotPresent"

          env {
            name  = "PORT"
            value = "3001"
          }
          # Use root creds from official image; authSource=admin
          env {
            name  = "MONGO_URI"
            value = "mongodb://admin:adminpass@${local.users_mongo_svc}:27017/usersdb?authSource=admin"
          }

          port {
            container_port = 3001
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.users_mongo
  ]
}

# users-service Service
resource "kubernetes_service" "users" {
  metadata {
    name      = "users-service"
    namespace = local.ns
    labels = {
      app = "users-service"
    }
  }

  spec {
    selector = {
      app = "users-service"
    }

    type = "NodePort"

    port {
      name        = "http"
      port        = 3001
      target_port = 3001
    }
  }
}

# -------------------------------
# tasks-service Deployment
# -------------------------------
resource "kubernetes_deployment" "tasks" {
  metadata {
    name      = "tasks-service"
    namespace = local.ns
    labels = {
      app = "tasks-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "tasks-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "tasks-service"
        }
      }

      spec {
        container {
          name              = "tasks-service"
          image             = "devops/tasks-service:local" # or your ACR image
          image_pull_policy = "IfNotPresent"

          env {
            name  = "PORT"
            value = "3002"
          }
          env {
            name  = "MONGO_URI"
            value = "mongodb://admin:adminpass@${local.tasks_mongo_svc}:27017/tasksdb?authSource=admin"
          }

          port {
            container_port = 3002
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.tasks_mongo
  ]
}

# tasks-service Service
resource "kubernetes_service" "tasks" {
  metadata {
    name      = "tasks-service"
    namespace = local.ns
    labels = {
      app = "tasks-service"
    }
  }

  spec {
    selector = {
      app = "tasks-service"
    }

    type = "NodePort"

    port {
      name        = "http"
      port        = 3002
      target_port = 3002
    }
  }
}
