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

resource "kubernetes_namespace_v1" "example" {
  metadata {
    name = "replication-svc"
  }
}

resource "random_password" "password" {
  length  = 10
  lower   = true
  special = false
}

module "this" {
  source = "../.."

  infrastructure = {
    namespace = kubernetes_namespace_v1.example.metadata[0].name
  }

  architecture                  = "replication"
  replication_readonly_replicas = 3
  password                      = random_password.password.result
  resources = {
    cpu    = 2
    memory = 2048
  }

  seeding = {
    type = "url"
    url = {
      location = "https://raw.githubusercontent.com/seal-io/terraform-provider-byteset/main/byteset/testdata/mysql-lg.sql"
    }
  }
}

output "context" {
  value = module.this.context
}

output "refer" {
  value = nonsensitive(module.this.refer)
}

output "connection" {
  value = module.this.connection
}

output "connection_readonly" {
  value = module.this.connection_readonly
}

output "address" {
  value = module.this.address
}

output "address_readonly" {
  value = module.this.address_readonly
}

output "port" {
  value = module.this.port
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

output "endpoints" {
  value = module.this.endpoints
}

output "endpoints_readonly" {
  value = module.this.endpoints_readonly
}
