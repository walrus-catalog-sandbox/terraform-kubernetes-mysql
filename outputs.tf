locals {
  port = 3306

  hosts = [
    format("%s-primary.%s.svc.%s", local.name, local.namespace, local.domain_suffix)
  ]
  hosts_readonly = local.architecture == "replication" ? [
    format("%s-secondary.%s.svc.%s", local.name, local.namespace, local.domain_suffix)
  ] : []

  endpoints = [
    for c in local.hosts : format("%s:%d", c, local.port)
  ]
  endpoints_readonly = [
    for c in(local.hosts_readonly != null ? local.hosts_readonly : []) : format("%s:%d", c, local.port)
  ]
}

#
# Orchestration
#

output "context" {
  description = "The input context, a map, which is used for orchestration."
  value       = var.context
}

output "refer" {
  description = "The refer, a map, including hosts, ports and account, which is used for dependencies or collaborations."
  sensitive   = true
  value = {
    schema = "k8s:mysql"
    params = {
      selector       = local.labels
      hosts          = local.hosts
      hosts_readonly = local.hosts_readonly
      port           = local.port
      database       = var.database
      username       = var.username
      password       = nonsensitive(local.password)
    }
  }
}

#
# Reference
#

output "connection" {
  description = "The connection, a string combined host and port, might be a comma separated string or a single string."
  value       = join(",", local.endpoints)
}

output "connection_without_port" {
  description = "The connection without port, a string combined host, might be a comma separated string or a single string."
  value       = join(",", local.hosts)
}

output "connection_readonly" {
  description = "The readonly connection, a string combined host and port, might be a comma separated string or a single string."
  value       = join(",", local.endpoints_readonly)
}

output "connection_without_port_readonly" {
  description = "The readonly connection without port, a string combined host, might be a comma separated string or a single string."
  value       = join(",", local.hosts_readonly)
}

output "database" {
  description = "The name of MySQL database to access."
  value       = var.database
}

output "username" {
  description = "The username of the account to access the database."
  value       = var.username
}

output "password" {
  value       = local.password
  description = "The password of the account to access the database."
  sensitive   = true
}

## UI display

output "endpoints" {
  description = "The endpoints, a list of string combined host and port."
  value       = local.endpoints
}

output "endpoints_readonly" {
  description = "The readonly endpoints, a list of string combined host and port."
  value       = local.endpoints_readonly
}
