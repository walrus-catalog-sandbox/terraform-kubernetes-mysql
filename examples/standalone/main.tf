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
    name = "standalone-svc"
  }
}

resource "kubernetes_persistent_volume_claim_v1" "pv" {
  wait_until_bound = false

  metadata {
    name      = "pv"
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
    type     = "standalone"
    password = random_password.password.result
  }

  seeding = {
    type = "text"
    text = {
      content = <<-EOF
-- company table
DROP TABLE IF EXISTS company;
CREATE TABLE company
(
    id      INTEGER PRIMARY KEY AUTO_INCREMENT,
    name    TEXT NOT NULL,
    age     INT  NOT NULL,
    address CHAR(50),
    salary  NUMERIC
);


-- company data
INSERT INTO company (name, age, address, salary)
VALUES ('Paul', 32, 'California', 20000.00);
INSERT INTO company (name, age, address, salary)
VALUES ('Allen', 25, 'Texas', 15000.00);
INSERT INTO company (name, age, address, salary)
VALUES ('Teddy', 23, 'Norway', 20000.00);
INSERT INTO company (name, age, address, salary)
VALUES ('Mark', 25, 'Rich-Mond ', 65000.00);
INSERT INTO company (name, age, address, salary)
VALUES ('David', 27, 'Texas', 85000.00);
INSERT INTO company (name, age, address, salary)
VALUES ('Kim', 22, 'South-Hall', 45000.00);
INSERT INTO company (name, age, address, salary)
VALUES ('James', 24, 'Houston', 10000.00);
EOF
    }
  }

  standalone = {
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
        name = kubernetes_persistent_volume_claim_v1.pv.metadata[0].name
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

