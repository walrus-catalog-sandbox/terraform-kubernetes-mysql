# Standalone Example

Deploy MySQL service in standalone architecture by root moudle.

```bash
# setup infra
$ tf apply -auto-approve \
  -target=kubernetes_namespace_v1.example

# create service
$ tf apply -auto-approve
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.11.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.23.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.23.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_namespace_v1.example](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_context"></a> [context](#output\_context) | n/a |
| <a name="output_selector"></a> [selector](#output\_selector) | n/a |
| <a name="output_endpoint_internal"></a> [endpoint\_internal](#output\_endpoint\_internal) | n/a |
| <a name="output_endpoint_internal_readonly"></a> [endpoint\_internal\_readonly](#output\_endpoint\_internal\_readonly) | n/a |
| <a name="output_database"></a> [database](#output\_database) | n/a |
| <a name="output_username"></a> [username](#output\_username) | n/a |
| <a name="output_password"></a> [password](#output\_password) | n/a |
<!-- END_TF_DOCS -->
