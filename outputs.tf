output "context" {
  description = "The input context, a map, which is used for orchestration."
  value       = var.context
}

output "endpoint_internal" {
  description = "The internal endpoints, a string list, which are used for internal access."
  value       = [format("%s-primary.%s.svc:3306", local.name, local.namespace)]
}

output "endpoint_internal_readonly" {
  description = "The internal readonly endpoints, a string list, which are used for internal readonly access."
  value       = var.deployment.type == "replication" ? [format("%s-secondary.%s.svc:3306", local.name, local.namespace)] : []
}

output "database" {
  description = "The name of database to access."
  value       = var.deployment.database
}

output "username" {
  description = "The username of the account to access the database."
  value       = var.deployment.username
}

output "password" {
  description = "The password of the account to access the database."
  value       = local.password
  sensitive   = true
}
