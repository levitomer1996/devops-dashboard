###############################################
# General settings
###############################################

# Namespace for all your Kubernetes resources
variable "namespace" {
  type        = string
  default     = "devops-dashboard"
  description = "Kubernetes namespace for the application"
}

###############################################
# MongoDB authentication (used by both Helm releases)
###############################################

variable "mongo_root_user" {
  type        = string
  default     = "admin"
  description = "Root user for MongoDB"
}

variable "mongo_root_password" {
  type        = string
  default     = "adminpass"
  sensitive   = true
  description = "Root password for MongoDB"
}

variable "users_app_user" {
  type        = string
  default     = "usersapp"
  description = "Application user for users-service MongoDB"
}

variable "users_app_password" {
  type        = string
  default     = "userspass"
  sensitive   = true
  description = "Application password for users-service MongoDB"
}

variable "tasks_app_user" {
  type        = string
  default     = "tasksapp"
  description = "Application user for tasks-service MongoDB"
}

variable "tasks_app_password" {
  type        = string
  default     = "taskspass"
  sensitive   = true
  description = "Application password for tasks-service MongoDB"
}

###############################################
# Image configuration (optional overrides)
###############################################

variable "mongodb_image_registry" {
  type        = string
  default     = "ghcr.io"
  description = "Registry for Bitnami MongoDB image (use ghcr.io to avoid Docker Hub limits)"
}

variable "mongodb_image_repository" {
  type        = string
  default     = "bitnami/mongodb"
  description = "Repository name for Bitnami MongoDB image"
}

variable "mongodb_image_tag" {
  type        = string
  default     = "7.0"
  description = "Tag for MongoDB image"
}

###############################################
# Kubernetes / Helm provider configuration (optional for Docker Desktop)
###############################################
# These are only needed if you plan to pass explicit kube credentials later.
# For local Docker Desktop, the providers usually just read ~/.kube/config.

variable "kube_config_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Path to kubeconfig file"
}
