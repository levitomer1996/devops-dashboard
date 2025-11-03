# ---------- Images ----------
# Pull official MongoDB image
resource "docker_image" "mongo" {
  name         = "mongo:7"
  keep_locally = true
}

# Use your locally built app images (build these first; see commands below)
resource "docker_image" "users_service" {
  name         = "devops/users-service:local"
  keep_locally = true
}

resource "docker_image" "tasks_service" {
  name         = "devops/tasks-service:local"
  keep_locally = true
}

# ---------- Volumes ----------
resource "docker_volume" "users_db" { name = "users-db" }
resource "docker_volume" "tasks_db" { name = "tasks-db" }

# ---------- users-mongo ----------
resource "docker_container" "users_mongo" {
  name  = "users-mongo"
  image = docker_image.mongo.image_id

  networks_advanced { name = docker_network.app.name }

  env = [
    "MONGO_INITDB_ROOT_USERNAME=admin",
    "MONGO_INITDB_ROOT_PASSWORD=adminpass",
    "MONGO_INITDB_DATABASE=usersdb"
  ]

  volumes {
    volume_name    = docker_volume.users_db.name
    container_path = "/data/db"
  }

  # optional: expose to host for Compass
  ports {
    internal = 27017
    external = 27017
  }

  healthcheck {
    test         = ["CMD", "mongosh", "--quiet", "-u", "admin", "-p", "adminpass", "--eval", "db.adminCommand('ping')"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }
}

# ---------- users-service ----------
resource "docker_container" "users" {
  name  = "users-service"
  image = docker_image.users_service.image_id

  networks_advanced { name = docker_network.app.name }

  env = [
    "PORT=3001",
    "MONGO_URI=mongodb://admin:adminpass@users-mongo:27017/usersdb?authSource=admin"
  ]

  ports {
    internal = 3001
    external = 3001
  }

  depends_on = [docker_container.users_mongo]
}

# ---------- tasks-mongo ----------
resource "docker_container" "tasks_mongo" {
  name  = "tasks-mongo"
  image = docker_image.mongo.image_id

  networks_advanced { name = docker_network.app.name }

  env = [
    "MONGO_INITDB_ROOT_USERNAME=admin",
    "MONGO_INITDB_ROOT_PASSWORD=adminpass",
    "MONGO_INITDB_DATABASE=tasksdb"
  ]

  volumes {
    volume_name    = docker_volume.tasks_db.name
    container_path = "/data/db"
  }

  # optional: expose to host; use a different external port
  ports {
    internal = 27017
    external = 27018
  }

  healthcheck {
    test         = ["CMD", "mongosh", "--quiet", "-u", "admin", "-p", "adminpass", "--eval", "db.adminCommand('ping')"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }
}

# ---------- tasks-service ----------
resource "docker_container" "tasks" {
  name  = "tasks-service"
  image = docker_image.tasks_service.image_id

  networks_advanced { name = docker_network.app.name }

  env = [
    "PORT=3002",
    "MONGO_URI=mongodb://admin:adminpass@tasks-mongo:27017/tasksdb?authSource=admin"
  ]

  ports {
    internal = 3002
    external = 3002
  }

  depends_on = [docker_container.tasks_mongo]
}
