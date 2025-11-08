# -------------------------------
# Namespace
# -------------------------------
# Define a Kubernetes Namespace resource named "ns" in Terraform
resource "kubernetes_namespace" "ns" {
  metadata {
    # The actual name of the namespace that will be created in the cluster
    name = "devops-dashboard"
  }
}

# -------------------------------
# Internal hostnames for MongoDBs
# -------------------------------
# "locals" = local variables you can reuse in this file.
locals {
  # Take the name of the created namespace from the resource above
  ns = kubernetes_namespace.ns.metadata[0].name

  # Build the full internal DNS hostname for the users Mongo service
  # <service-name>.<namespace>.svc.cluster.local
  users_mongo_svc = "users-mongo.${local.ns}.svc.cluster.local"

  # Same for the tasks Mongo service
  tasks_mongo_svc = "tasks-mongo.${local.ns}.svc.cluster.local"
}

# ===============================
# MONGODB (USERS) - OFFICIAL IMAGE
# ===============================
# Deployment for the USERS MongoDB
resource "kubernetes_deployment" "users_mongo" {
  metadata {
    # Name of the Deployment
    name      = "users-mongo"
    # Namespace where it will be created
    namespace = local.ns

    # Labels used for selecting this deployment/pods
    labels = {
      app = "users-mongo"
    }
  }

  spec {
    # Number of pod replicas for this deployment
    replicas = 1

    # Selector that matches pods by label
    selector {
      match_labels = {
        app = "users-mongo"
      }
    }

    # Pod template (what each pod looks like)
    template {
      metadata {
        # Labels applied to the pods created by this deployment
        labels = {
          app = "users-mongo"
        }
      }

      spec {
        # Define the container that runs inside each pod
        container {
          # Container name
          name  = "mongodb"
          # Docker image used for MongoDB
          image = "mongo:7"
          # Extra args passed to the MongoDB process
          args  = ["--bind_ip_all"]

          # ---------- ENV VARS ----------
          # Root username for Mongo
          env {
            name  = "MONGO_INITDB_ROOT_USERNAME"
            value = "admin"
          }
          # Root password for Mongo
          env {
            name  = "MONGO_INITDB_ROOT_PASSWORD"
            value = "adminpass"
          }
          # Default DB that will be created on init
          env {
            name  = "MONGO_INITDB_DATABASE"
            value = "usersdb"
          }

          # Port that the container listens on for MongoDB
          port {
            container_port = 27017
          }

          # ---------- RESOURCE LIMITS ----------
          # Requests/limits for CPU & memory to keep it light
          resources {
            # Minimum resources requested
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            # Maximum memory allowed
            limits = {
              memory = "256Mi"
            }
          }

          # ---------- VOLUMES ----------
          # Mount a volume at /data/db (Mongo data dir)
          volume_mount {
            # Must match the volume's name below
            name       = "data"
            mount_path = "/data/db"
          }
        }

        # Define the volume used above
        volume {
          name = "data"
          # emptyDir = ephemeral storage (reset if pod is rescheduled)
          empty_dir {}
        }
      }
    }
  }
}

# Service exposing USERS MongoDB inside the cluster
resource "kubernetes_service" "users_mongo" {
  metadata {
    # Service name
    name      = "users-mongo"
    # Namespace where the service lives
    namespace = local.ns
    # Labels on the Service itself
    labels = {
      app = "users-mongo"
    }
  }

  spec {
    # ClusterIP = internal-only service
    type = "ClusterIP"

    # Selects pods that have this label (from the deployment)
    selector = {
      app = "users-mongo"
    }

    # The port that the service exposes
    port {
      # Logical name for the port
      name        = "mongodb"
      # Port clients use to connect to the service
      port        = 27017
      # Port on the pod/container
      target_port = 27017
    }
  }
}

# ===============================
# MONGODB (TASKS) - OFFICIAL IMAGE
# ===============================
# Deployment for the TASKS MongoDB
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

          # Root username
          env {
            name  = "MONGO_INITDB_ROOT_USERNAME"
            value = "admin"
          }
          # Root password
          env {
            name  = "MONGO_INITDB_ROOT_PASSWORD"
            value = "adminpass"
          }
          # Default DB for tasks
          env {
            name  = "MONGO_INITDB_DATABASE"
            value = "tasksdb"
          }

          # Expose MongoDB port
          port {
            container_port = 27017
          }

          # Resource requests/limits for this Mongo
          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              memory = "256Mi"
            }
          }

          # Mount data volume
          volume_mount {
            name       = "data"
            mount_path = "/data/db"
          }
        }

        # Ephemeral volume for Mongo data
        volume {
          name = "data"
          empty_dir {}
        }
      }
    }
  }
}

# Service exposing TASKS MongoDB inside the cluster
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

    # Match tasks-mongo pods
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
# Deployment for your NestJS USERS API service
resource "kubernetes_deployment" "users" {
  metadata {
    name      = "users-service"
    namespace = local.ns
    labels = {
      app = "users-service"
    }
  }

  spec {
    # One replica of users-service
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
          # Container name
          name              = "users-service"
          # Image to run (here a local tag; in prod you’d use ACR)
          image             = "devops/users-service:local" # or your ACR image
          # Only pull if not present on the node
          image_pull_policy = "IfNotPresent"

          # ------------ ENV VARS ------------
          # Port your NestJS app listens on
          env {
            name  = "PORT"
            value = "3001"
          }

          # Connection string for users MongoDB
          # Uses the internal DNS from locals defined at the top
          env {
            name  = "MONGO_URI"
            value = "mongodb://admin:adminpass@${local.users_mongo_svc}:27017/usersdb?authSource=admin"
          }

          # Container port exposed (matches PORT)
          port {
            container_port = 3001
          }
        }
      }
    }
  }

  # Make sure Mongo service exists before deploying users-service
  depends_on = [
    kubernetes_service.users_mongo
  ]
}

# Service for users-service (exposes the NestJS API)
resource "kubernetes_service" "users" {
  metadata {
    name      = "users-service"
    namespace = local.ns
    labels = {
      app = "users-service"
    }
  }

  spec {
    # This selector attaches the service to the users-service pods
    selector = {
      app = "users-service"
    }

    # NodePort = expose this service on each node’s IP and a random high port
    type = "NodePort"

    port {
      # Logical name for HTTP traffic
      name        = "http"
      # Service port inside the cluster
      port        = 3001
      # Port on the pod/container
      target_port = 3001
      # NodePort is auto-assigned if we don't specify node_port here
    }
  }
}

# -------------------------------
# tasks-service Deployment
# -------------------------------
# Deployment for your NestJS TASKS API service
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

          # Port the tasks service listens on
          env {
            name  = "PORT"
            value = "3002"
          }

          # Connection string for tasks MongoDB
          env {
            name  = "MONGO_URI"
            value = "mongodb://admin:adminpass@${local.tasks_mongo_svc}:27017/tasksdb?authSource=admin"
          }

          # Container port exposed
          port {
            container_port = 3002
          }
        }
      }
    }
  }

  # Ensure tasks Mongo service exists before tasks-service
  depends_on = [
    kubernetes_service.tasks_mongo
  ]
}

# Service for tasks-service (exposes the NestJS API)
resource "kubernetes_service" "tasks" {
  metadata {
    name      = "tasks-service"
    namespace = local.ns
    labels = {
      app = "tasks-service"
    }
  }

  spec {
    # Attach this service to tasks-service pods
    selector = {
      app = "tasks-service"
    }

    # NodePort so it’s reachable from outside the cluster (via node IP)
    type = "NodePort"

    port {
      name        = "http"
      port        = 3002
      target_port = 3002
    }
  }
}
