# Kubernetes MySQL Service

Terraform module which deploys containerized MySQL on Kubernetes, powered by [Bitnami Charts/MySQL](https://github.com/bitnami/charts/tree/main/bitnami/mysql).

- [x] Support standalone and replication(for high availability).
- [x] Support database seeding.

## Usage

```hcl
module "mysql" {
  source = "..."

  infrastructure = {
    namespace = "default"
  }

  architecture   = "replication"
  engine_version = "13"         # https://hub.docker.com/r/bitnami/mysql/tags
}
```

## Examples

- [Replication](./examples/replication)
- [Standalone](./examples/standalone)

## Contributing

Please read our [contributing guide](./docs/CONTRIBUTING.md) if you're interested in contributing to Walrus template.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.11.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.23.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.23.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.11.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.mysql](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map_v1.text_seeding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.url_seeding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Receive contextual information. When Walrus deploys, Walrus will inject specific contextual information into this field.<br><br>Examples:<pre>context:<br>  project:<br>    name: string<br>    id: string<br>  environment:<br>    name: string<br>    id: string<br>  resource:<br>    name: string<br>    id: string</pre> | `map(any)` | `{}` | no |
| <a name="input_infrastructure"></a> [infrastructure](#input\_infrastructure) | Specify the infrastructure information for deploying.<br><br>Examples:<pre>infrastructure:<br>  namespace: string, optional<br>  image_registry: string, optional<br>  domain_suffix: string, optional</pre> | <pre>object({<br>    namespace      = optional(string)<br>    image_registry = optional(string, "registry-1.docker.io")<br>    domain_suffix  = optional(string, "cluster.local")<br>  })</pre> | `{}` | no |
| <a name="input_architecture"></a> [architecture](#input\_architecture) | Specify the deployment architecture, select from standalone or replication. | `string` | `"standalone"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Specify the deployment engine version, select from https://hub.docker.com/r/bitnami/mysql/tags. | `string` | `"8.0"` | no |
| <a name="input_database"></a> [database](#input\_database) | Specify the database name. | `string` | `"mydb"` | no |
| <a name="input_username"></a> [username](#input\_username) | Specify the account username. | `string` | `"user"` | no |
| <a name="input_password"></a> [password](#input\_password) | Specify the account password. | `string` | `null` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Specify the computing resources.<br><br>Examples:<pre>resources:<br>  cpu: number, optional<br>  memory: number, optioanl       # in megabyte</pre> | <pre>object({<br>    cpu    = number<br>    memory = number<br>  })</pre> | <pre>{<br>  "cpu": 0.25,<br>  "memory": 256<br>}</pre> | no |
| <a name="input_storage"></a> [storage](#input\_storage) | Specify the storage resources.<br><br>Examples:<pre>storage:                         # convert to empty_dir volume or dynamic volume claim template<br>  class: string, optional<br>  size: number, optional         # in megabyte</pre> | <pre>object({<br>    class = optional(string)<br>    size  = optional(number, 20 * 1024)<br>  })</pre> | `null` | no |
| <a name="input_seeding"></a> [seeding](#input\_seeding) | Specify the configuration to seed the database at first-time creating.<br><br>Seeding increases the startup time waiting and also needs proper permission, <br>like root account.<br><br>Examples:<pre>seeding:<br>  type: url/text<br>  url:                           # store the content to a volume<br>    location: string<br>    storage:                     # convert to dynamic volume claim template<br>      class: string, optional<br>      size: number, optional     # in megabyte<br>  text:                          # store the content to a configmap<br>    content: string</pre> | <pre>object({<br>    type = optional(string, "url")<br>    url = optional(object({<br>      location = string<br>      storage = optional(object({<br>        class = optional(string)<br>        size  = optional(number, 10 * 1024)<br>      }))<br>    }))<br>    text = optional(object({<br>      content = string<br>    }))<br>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_context"></a> [context](#output\_context) | The input context, a map, which is used for orchestration. |
| <a name="output_selector"></a> [selector](#output\_selector) | The selector, a map, which is used for dependencies or collaborations. |
| <a name="output_endpoint_internal"></a> [endpoint\_internal](#output\_endpoint\_internal) | The internal endpoints, a string list, which are used for internal access. |
| <a name="output_endpoint_internal_readonly"></a> [endpoint\_internal\_readonly](#output\_endpoint\_internal\_readonly) | The internal readonly endpoints, a string list, which are used for internal readonly access. |
| <a name="output_database"></a> [database](#output\_database) | The name of database to access. |
| <a name="output_username"></a> [username](#output\_username) | The username of the account to access the database. |
| <a name="output_password"></a> [password](#output\_password) | The password of the account to access the database. |
<!-- END_TF_DOCS -->

## License

Copyright (c) 2023 [Seal, Inc.](https://seal.io)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [LICENSE](./LICENSE) file for details.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
