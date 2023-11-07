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
```
EOF
  type = object({
    namespace      = optional(string)
    image_registry = optional(string, "registry-1.docker.io")
  })
  default = {}
}

#
# Deployment Fields
#

variable "deployment" {
  description = <<-EOF
Specify the deployment action, including architecture and account.

Examples:
```
deployment:
  version: string, optional      # https://hub.docker.com/r/bitnami/mysql/tags
  type: string, optional         # i.e. standalone, replication
  username: string, optional
  password: string
  database: string, optional
```
EOF
  type = object({
    version  = optional(string, "8.2.0")
    type     = optional(string, "standalone")
    username = optional(string, "root")
    password = string
    database = optional(string, "mydb")
  })
}

#
# Seeding Fields
#

variable "seeding" {
  description = <<-EOF
Specify the configuration to seed the database after first time creating,
this action needs admin permission, like root user.

Examples:
```
seeding:
  url:                           # need a persistent volume to store the content
    location: string
    storage:
      class: string, optional
      size: number, optional     # in megabyte
  text:                          # convert to configmap, only support 4kb content
    content: string
```
EOF
  type = object({
    type = optional(string, "url")
    url = optional(object({
      location = string
      storage = optional(object({
        class = optional(string)
        size  = optional(number, 5 * 1024)
      }))
    }))
    text = optional(object({
      content = string
    }))
  })
  default = {}
}

#
# Main Fields
#

variable "standalone" {
  description = <<-EOF
Specify the configuration of standalone deployment type.

Examples:
```
standalone:                      # one instance
  resources:
    requests:
      cpu: number     
      memory: number             # in megabyte
    limits:
      cpu: number
      memory: number             # in megabyte
  storage:                       # convert to empty dir if null
    type: ephemeral/persistent
    ephemeral:                   # convert to volume claim template
      class: string
      access_mode: string
      size: number, optional     # in megabyte
    persistent:                  # convert to persistent volume claim
      name: string
```
EOF
  type = object({
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
      type = optional(string, "ephemeral")
      ephemeral = optional(object({
        class       = optional(string)
        access_mode = optional(string, "ReadWriteOnce")
        size        = optional(number)
      }))
      persistent = optional(object({
        name = string
      }))
    }))
  })
  default = {}
}

variable "replication" {
  description = <<-EOF
Specify the configuration of replication deployment type.

Examples:
```
replication:                     # two instances: one primary, one read-only secondary (same az)
  primary:
    resources:
      requests:
        cpu: number     
        memory: number           # in megabyte
      limits:
        cpu: number
        memory: number           # in megabyte
    storage:                     # convert to empty dir if null
      type: ephemeral/persistent
      ephemeral:                 # convert to volume claim template
        class: string
        access_mode: string
        size: number, optional   # in megabyte
      persistent:
        name: string             # convert to persistent volume claim
  secondary:
    replicas: number, optional
    resources:
      requests:
        cpu: number     
        memory: number           # in megabyte
      limits:
        cpu: number
        memory: number           # in megabyte
    storage:                     # convert to empty dir if null
      type: ephemeral/persistent
      ephemeral:                 # convert to volume claim template
        class: string
        access_mode: string
        size: number, optional   # in megabyte
      persistent:                # convert to persistent volume claim
        name: string 
```
EOF
  type = object({
    primary = optional(object({
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
        type = optional(string, "ephemeral")
        ephemeral = optional(object({
          class       = optional(string)
          access_mode = optional(string, "ReadWriteOnce")
          size        = optional(number)
        }))
        persistent = optional(object({
          name = string
        }))
      }))
    }), { requests = { cpu = 0.25, memory = 256 } })
    secondary = optional(object({
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
        type = optional(string, "ephemeral")
        ephemeral = optional(object({
          class       = optional(string)
          access_mode = optional(string, "ReadWriteOnce")
          size        = optional(number)
        }))
        persistent = optional(object({
          name = string
        }))
      }))
    }), { requests = { cpu = 0.25, memory = 256 } })
  })
  default = {}
}
