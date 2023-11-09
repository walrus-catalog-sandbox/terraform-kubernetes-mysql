#
# Contextual Fields
#

variable "context" {
  description = <<-EOF
Receive contextual information. When Walrus deploys, Walrus will inject specific contextual information into this field.

Examples:
```
context:
  project:
    name: string
    id: string
  environment:
    name: string
    id: string
  resource:
    name: string
    id: string
```
EOF
  type        = map(any)
  default     = {}
}

#
# Infrastructure Fields
#

variable "infrastructure" {
  description = <<-EOF
Specify the infrastructure information for deploying.

Examples:
```
infrastructure:
  namespace: string, optional
  image_registry: string, optional
  domain_suffix: string, optional
```
EOF
  type = object({
    namespace      = optional(string)
    image_registry = optional(string, "registry-1.docker.io")
    domain_suffix  = optional(string, "cluster.local")
  })
  default = {}
}

#
# Deployment Fields
#

variable "deployment" {
  description = <<-EOF
Specify the deployment action, like architecture, connection account and so on.

Examples:
```
deployment:
  type: string, optional         # i.e. standalone, replication
  version: string, optional      # https://hub.docker.com/r/bitnami/mysql/tags
  username: string, optional
  password: string, optional
  database: string, optional
  resources:
    requests:
      cpu: number     
      memory: number             # in megabyte
    limits:
      cpu: number
      memory: number             # in megabyte
  storage:                       # convert to empty_dir volume if null or dynamic volume claim template
    class: string
    size: number, optional       # in megabyte
```
EOF
  type = object({
    type     = optional(string, "standalone")
    version  = optional(string, "8.0")
    username = optional(string, "root")
    password = optional(string)
    database = optional(string, "mydb")
    resources = optional(object({
      requests = object({
        cpu    = optional(number, 0.25)
        memory = optional(number, 256)
      })
      limits = optional(object({
        cpu    = optional(number, 0)
        memory = optional(number, 0)
      }))
    }), { requests = { cpu = 0.25, memory = 256 } })
    storage = optional(object({
      class = optional(string)
      size  = optional(number, 20 * 1024)
    }), { size = 20 * 1024 })
  })
  default = {
    version  = "8.0"
    type     = "standalone"
    username = "root"
    database = "mydb"
    resources = {
      requests = {
        cpu    = 0.25
        memory = 256
      }
    }
    storage = {
      size = 20 * 1024
    }
  }
  validation {
    condition     = var.deployment.type == null || contains(["standalone", "replication"], var.deployment.type)
    error_message = "Invalid type"
  }
  validation {
    condition     = var.deployment.username == null || can(regex("^[A-Za-z_]{0,15}[a-z0-9]$", var.deployment.username))
    error_message = format("Invalid username: %s", var.deployment.username)
  }
  validation {
    condition     = var.deployment.password == null || can(regex("^[A-Za-z0-9\\!#\\$%\\^&\\*\\(\\)_\\+\\-=]{8,32}", var.deployment.password))
    error_message = "Invalid password"
  }
  validation {
    condition     = var.deployment.database == null || can(regex("^[a-z][-a-z0-9_]{0,61}[a-z0-9]$", var.deployment.database))
    error_message = format("Invalid database: %s", var.deployment.database)
  }
}

#
# Seeding Fields
#

variable "seeding" {
  description = <<-EOF
Specify the configuration to seed the database at first-time creating.

Seeding increases the startup time waiting and also needs proper permission, 
like root account.

Examples:
```
seeding:
  type: url/text
  url:                           # store the content to a volume
    location: string
    storage:                     # convert to dynamic volume claim template
      class: string, optional
      size: number, optional     # in megabyte
  text:                          # store the content to a configmap
    content: string
```
EOF
  type = object({
    type = optional(string, "url")
    url = optional(object({
      location = string
      storage = optional(object({
        class = optional(string)
        size  = optional(number, 10 * 1024)
      }))
    }))
    text = optional(object({
      content = string
    }))
  })
  default = {}
  validation {
    condition     = var.seeding.type == null || contains(["url", "text"], var.seeding.type)
    error_message = "Invalid type"
  }
}
