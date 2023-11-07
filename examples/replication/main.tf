terraform {
  required_version = ">= 1.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace_v1" "infra" {
  metadata {
    name = "replication-svc"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "primary_pv" {
  wait_until_bound = false

  metadata {
    name      = "primary-pv"
    namespace = kubernetes_namespace_v1.infra.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "random_password" "password" {
  lower   = true
  length  = 6
  special = false
}

module "this" {
  source = "../.."

  infrastructure = {
    namespace = kubernetes_namespace_v1.infra.metadata[0].name
  }

  deployment = {
    type     = "replication"
    password = random_password.password.result
  }

  seeding = {
    type = "url"
    url = {
      location = "https://raw.githubusercontent.com/seal-io/terraform-provider-byteset/main/byteset/testdata/mysql-lg.sql"
    }
  }

  replication = {
    primary = {
      resources = {
        requests = {
          cpu    = 1
          memory = 1024
        }
        limits = {
          cpu    = 2
          memory = 2024
        }
      }
      storage = {
        type = "persistent"
        persistent = {
          name = kubernetes_persistent_volume_claim_v1.primary_pv.metadata[0].name
        }
      }
    }
    secondary = {
      storage = {
        type = "ephemeral"
        ephemeral = {
          size = 20 * 1024
        }
      }
    }
  }
}

output "context" {
  value = module.this.context
}

output "endpoint_internal" {
  value = module.this.endpoint_internal
}

output "endpoint_internal_readonly" {
  value = module.this.endpoint_internal_readonly
}

output "database" {
  value = module.this.database
}

output "username" {
  value = module.this.username
}

output "password" {
  value = nonsensitive(module.this.password)
}
