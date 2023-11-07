locals {
  project_name     = coalesce(try(var.context["project"]["name"], null), "default")
  project_id       = coalesce(try(var.context["project"]["id"], null), "default_id")
  environment_name = coalesce(try(var.context["environment"]["name"], null), "test")
  environment_id   = coalesce(try(var.context["environment"]["id"], null), "test_id")
  resource_name    = coalesce(try(var.context["resource"]["name"], null), "example")
  resource_id      = coalesce(try(var.context["resource"]["id"], null), "example_id")

  namespace = coalesce(try(var.infrastructure.namespace, ""), join("-", [local.project_name, local.environment_name]))
  annotations = {
    "walrus.seal.io/project-id"     = local.project_id
    "walrus.seal.io/environment-id" = local.environment_id
    "walrus.seal.io/resource-id"    = local.resource_id
  }
  labels = {
    "walrus.seal.io/project-name"     = local.project_name
    "walrus.seal.io/environment-name" = local.environment_name
    "walrus.seal.io/resource-name"    = local.resource_name
  }
}

#
# Random
#

# create the name with a random suffix.

resource "random_string" "name_suffix" {
  length  = 10
  special = false
  upper   = false
}

locals {
  name = join("-", [local.resource_name, random_string.name_suffix.result])
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
        "storage" = try(format("%dMi", var.seeding.url.storage.size), "5Gi")
      }
    }
  }
}

#
# Deployment
#

locals {
  helm_release_values = [
    # basic configuration.

    {
      # global parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#global-parameters
      global = {
        image_registry = coalesce(var.infrastructure.image_registry, "registry-1.docker.io")
      }

      # common parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#common-parameters
      fullnameOverride  = local.name
      commonAnnotations = local.annotations
      commonLabels      = local.labels

      # mysql common parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-common-parameters
      architecture = var.deployment.type
      image = {
        repository = "bitnami/mysql"
        tag        = var.deployment.version
      }
      auth = {
        database = coalesce(var.deployment.database, "mydb")
        username = coalesce(var.deployment.username, "root") == "root" ? "" : var.deployment.username
      }
    },

    # standalone configuration.

    var.deployment.type == "standalone" ? {
      # mysql primary parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-primary-parameters
      primary = {
        name = "primary"
        resources = {
          requests = try(var.standalone.resources.requests != null, false) ? {
            for k, v in var.standalone.resources.requests : k => "%{if k == "memory"}${v}Mi%{else}${v}%{endif}"
            if v != null && v > 0
          } : null
          limits = try(var.standalone.resources.limits != null, false) ? {
            for k, v in var.standalone.resources.limits : k => "%{if k == "memory"}${v}Mi%{else}${v}%{endif}"
            if v != null && v > 0
          } : null
        }
        persistence = {
          enabled       = try(var.standalone.storage != null, false)
          storageClass  = try(var.standalone.storage.ephemeral.class, "")
          accessModes   = [try(var.standalone.storage.ephemeral.access_mode, "ReadWriteOnce")]
          size          = try(format("%dMi", var.standalone.storage.ephemeral.size), "8Gi")
          existingClaim = try(var.standalone.storage.persistent.name, "")
        }
      }
    } : null,

    # replication configuration.

    var.deployment.type == "replication" ? {
      # mysql primary parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-primary-parameters
      primary = {
        name = "primary"
        resources = {
          requests = try(var.replication.primary.resources.requests != null, false) ? {
            for k, v in var.replication.primary.resources.requests : k => "%{if k == "memory"}${v}Mi%{else}${v}%{endif}"
            if v != null && v > 0
          } : null
          limits = try(var.replication.primary.resources.limits != null, false) ? {
            for k, v in var.replication.primary.resources.limits : k => "%{if k == "memory"}${v}Mi%{else}${v}%{endif}"
            if v != null && v > 0
          } : null
        }
        persistence = {
          enabled       = try(var.replication.primary.storage != null, false)
          storageClass  = try(var.replication.primary.storage.ephemeral.class, "")
          accessModes   = [try(var.replication.primary.storage.ephemeral.access_mode, "ReadWriteOnce")]
          size          = try(format("%dMi", var.replication.primary.storage.ephemeral.size), "8Gi")
          existingClaim = try(var.replication.primary.storage.persistent.name, "")
        }
      }
      # mysql secondary parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-secondary-parameters
      secondary = {
        name = "secondary"
        resources = {
          requests = try(var.replication.primary.resources.requests != null, false) ? {
            for k, v in var.replication.primary.resources.requests : k => "%{if k == "memory"}${v}Mi%{else}${v}%{endif}"
            if v != null && v > 0
          } : null
          limits = try(var.replication.primary.resources.limits != null, false) ? {
            for k, v in var.replication.primary.resources.limits : k => "%{if k == "memory"}${v}Mi%{else}${v}%{endif}"
            if v != null && v > 0
          } : null
        }
        persistence = {
          enabled       = try(var.replication.primary.storage != null, false)
          storageClass  = try(var.replication.primary.storage.ephemeral.class, "")
          accessModes   = [try(var.replication.primary.storage.ephemeral.access_mode, "ReadWriteOnce")]
          size          = try(format("%dMi", var.replication.primary.storage.ephemeral.size), "8Gi")
          existingClaim = try(var.replication.primary.storage.persistent.name, "")
        }
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
        startupProbe = var.seeding.type == "url" ? { # turn up for seeding.
          enabled             = true
          initialDelaySeconds = 30
          periodSeconds       = 10
          timeoutSeconds      = 1
          failureThreshold    = 30
          successThreshold    = 1
        } : null
      }
      secondary = var.seeding.type == "url" ? {
        startupProbe = { # turn up for seeding.
          enabled             = true
          initialDelaySeconds = 30
          periodSeconds       = 10
          timeoutSeconds      = 1
          failureThreshold    = 30
          successThreshold    = 1
        }
      } : null
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
    for c in local.helm_release_values : yamlencode(c)
    if c != null
  ]

  # mysql common parameters: https://github.com/bitnami/charts/tree/main/bitnami/mysql#mysql-common-parameters.
  set_sensitive {
    name  = "auth.rootPassword"
    value = var.deployment.password
  }
  set_sensitive {
    name  = "auth.replicationPassword"
    value = var.deployment.password
  }
  set_sensitive {
    name  = "auth.password"
    value = var.deployment.password
  }
}
