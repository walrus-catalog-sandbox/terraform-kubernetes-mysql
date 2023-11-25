locals {
  project_name     = coalesce(try(var.context["project"]["name"], null), "default")
  project_id       = coalesce(try(var.context["project"]["id"], null), "default_id")
  environment_name = coalesce(try(var.context["environment"]["name"], null), "test")
  environment_id   = coalesce(try(var.context["environment"]["id"], null), "test_id")
  resource_name    = coalesce(try(var.context["resource"]["name"], null), "example")
  resource_id      = coalesce(try(var.context["resource"]["id"], null), "example_id")

  namespace = coalesce(try(var.infrastructure.namespace, ""), join("-", [
    local.project_name, local.environment_name
  ]))
  image_registry = coalesce(var.infrastructure.image_registry, "registry-1.docker.io")
  domain_suffix  = coalesce(var.infrastructure.domain_suffix, "cluster.local")

  annotations = {
    "walrus.seal.io/project-id"     = local.project_id
    "walrus.seal.io/environment-id" = local.environment_id
    "walrus.seal.io/resource-id"    = local.resource_id
  }
  labels = {
    "walrus.seal.io/catalog-name"     = "terraform-kubernetes-mysql"
    "walrus.seal.io/project-name"     = local.project_name
    "walrus.seal.io/environment-name" = local.environment_name
    "walrus.seal.io/resource-name"    = local.resource_name
  }

  architecture = coalesce(var.architecture, "standalone")
}

#
# Random
#

# create a random password for blank password input.

resource "random_password" "password" {
  length      = 10
  special     = false
  lower       = true
  min_lower   = 3
  min_upper   = 3
  min_numeric = 3
}

# create the name with a random suffix.

resource "random_string" "name_suffix" {
  length  = 10
  special = false
  upper   = false
}

locals {
  name     = join("-", [local.resource_name, random_string.name_suffix.result])
  database = coalesce(var.database, "mydb")
  username = coalesce(var.username, "rdsuser")
  password = coalesce(var.password, random_password.password.result)
}

#
# Seeding
#

# store text content for seeding.

resource "kubernetes_config_map_v1" "text_seeding" {
  count = try(var.seeding.type == "text", false) && try(lookup(var.seeding, "text", null), null) != null ? 1 : 0

  metadata {
    namespace   = local.namespace
    name        = join("-", ["seeding-text", local.name])
    annotations = local.annotations
    labels      = local.labels
  }

  data = {
    "init.sql" = var.seeding.text.content
  }
}

# download seeding content according to the url.

resource "kubernetes_persistent_volume_claim_v1" "url_seeding" {
  count = try(var.seeding.type == "url", false) && try(lookup(var.seeding, "url", null), null) != null ? 1 : 0

  wait_until_bound = false

  metadata {
    namespace   = local.namespace
    name        = join("-", ["seeding-url", local.name])
    annotations = local.annotations
    labels      = local.labels
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = try(var.seeding.url.storage.class, null)
    resources {
      requests = {
        "storage" = try(format("%dMi", var.seeding.url.storage.size), "10240Mi")
      }
    }
  }
}

#
# Deployment
#

locals {
  resources = {
    requests = try(var.resources != null, false) ? {
      cpu    = var.resources.cpu
      memory = "${var.resources.memory}Mi"
    } : null
    limits = try(var.resources != null, false) ? {
      memory = "${var.resources.memory}Mi"
    } : null
  }
  persistence = {
    enabled      = try(var.storage != null, false)
    storageClass = try(var.storage.class, "")
    accessModes  = ["ReadWriteOnce"]
    size         = try(format("%dMi", var.storage.size), "20480Mi")
  }

  values = [
    # basic configuration.

    {
      # global parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#global-parameters
      global = {
        image_registry = local.image_registry
      }

      # common parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#common-parameters
      fullnameOverride  = local.name
      commonAnnotations = local.annotations
      commonLabels      = local.labels
      clusterDomain     = local.domain_suffix

      # mysql common parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-common-parameters
      architecture = local.architecture
      image = {
        repository = "bitnami/mysql"
        tag        = coalesce(var.engine_version, "8.0")
      }
      auth = {
        database = local.database
        username = local.username == "root" ? "" : local.username
      }
    },

    # standalone configuration.

    local.architecture == "standalone" ? {
      # mysql primary parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-primary-parameters
      primary = {
        name        = "primary"
        resources   = local.resources
        persistence = local.persistence
      }
    } : null,

    # replication configuration.

    local.architecture == "replication" ? {
      # mysql primary parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-primary-parameters
      primary = {
        name        = "primary"
        resources   = local.resources
        persistence = local.persistence
      }
      # mysql secondary parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-secondary-parameters
      secondary = {
        name         = "secondary"
        replicaCount = var.replication_readonly_replicas == 0 ? 1 : var.replication_readonly_replicas
        resources    = local.resources
        persistence  = local.persistence
      }
    } : null,

    # seeding configuration.

    try(lookup(var.seeding, var.seeding.type, null), null) != null ? {
      primary = {
        initContainers = var.seeding.type == "url" ? [
          {
            name  = "init-sql"
            image = "alpine"
            command = [
              "sh", "-c",
              "test -f /docker-entrypoint-initdb.d/init.sql || wget -c -S -O /docker-entrypoint-initdb.d/init.sql ${var.seeding.url.location}"
            ],
            volumeMounts = [
              {
                name      = "init-sql"
                mountPath = "/docker-entrypoint-initdb.d"
              }
            ]
          }
        ] : []
        extraVolumeMounts = [
          {
            name      = "init-sql"
            mountPath = "/docker-entrypoint-initdb.d"
          }
        ]
        extraVolumes = [
          {
            name = "init-sql"
            configMap = var.seeding.type == "text" ? {
              name = join("-", ["seeding-text", local.name])
            } : null
            persistentVolumeClaim = var.seeding.type == "url" ? {
              claimName = join("-", ["seeding-url", local.name])
            } : null
          }
        ]
        startupProbe = {
          initialDelaySeconds = var.seeding.type == "url" ? 30 : 10
          failureThreshold    = var.seeding.type == "url" ? 30 : 10
        }
      }
      secondary = {
        startupProbe = {
          initialDelaySeconds = var.seeding.type == "url" ? 30 : 10
          failureThreshold    = var.seeding.type == "url" ? 30 : 10
        }
      }
    } : null
  ]
}

resource "helm_release" "mysql" {
  chart       = "${path.module}/charts/mysql-9.14.2.tgz"
  wait        = false
  max_history = 3
  namespace   = local.namespace
  name        = local.name

  values = [
    for c in local.values : yamlencode(c)
    if c != null
  ]

  # mysql common parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-common-parameters.
  set_sensitive {
    name  = "auth.rootPassword"
    value = local.password
  }
  set_sensitive {
    name  = "auth.replicationPassword"
    value = local.password
  }
  set_sensitive {
    name  = "auth.password"
    value = local.password
  }
}
