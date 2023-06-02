Terraform module for Kubernetes OAuth Proxy
==========================================

Terraform module for easily deploy OAuth Proxy service to your kubernetes cluster, with multi provider supports.

## Wokrflow

Module creates all necessary resources for creating "closed" ingress inside your kubernetes cluster.
Module supports different providers for authentication: Google, Azure, KeyCloak, GitHub, GitLab, Facebook, BitBucket,
etc.
For more info, you could visit: https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider

## Software Requirements

Name | Description
--- | --- |
Terraform | > = v1.3.0
AzureRM provider | > = v3.53.0
AzureAD provider | > = v2.39.0
Random provider | > = v3.5.0
Kubernetes | > = v2.16.1
Kubernetes Server | > = v1.22.0

## Usage

#### Azure

For Azure, you should have AD with Global Administrator permissions, or make request to your AD Administrator to Grant
admin Contest for AD.
You could create Ingress with OAuth via module or disable it:
```create_ingress_with_oauth=false (default: true)```
If you don't want to deploy ingress, you could edit existing, by adding annotation:

```
  annotations:
    nginx.ingress.kubernetes.io/auth-signin: https://your.oauth.domain.com/oauth2/start?rd=$scheme://$http_host$request_uri
    nginx.ingress.kubernetes.io/auth-url: https://your.oauth.domain.com/oauth2/auth
```

Terrafrom Code example:

```terraform
data "azuread_client_config" current {}
data "azuread_service_principal" "msgraph" {
  display_name = "Microsoft Graph"
}

# Azure AD required resources
resource "azuread_application" "oauth2" {
  display_name = "azure-ad-oauth2"
  owners       = [data.azuread_client_config.current.object_id]
  web {
    redirect_uris = [
      "https://your_auth_domain.com/api-docs/",
      "https://your_auth_domain.com/oauth2/callback"
    ]
  }


  required_resource_access {
    resource_app_id = data.azuread_service_principal.msgraph.application_id

    resource_access {
      id   = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }
}
resource "azuread_application_password" "oauth2_secret" {
  application_object_id = azuread_application.oauth2.object_id
}
resource "azuread_service_principal" "oauth2" {
  application_id = azuread_application.oauth2.application_id
}
resource "azuread_service_principal_delegated_permission_grant" "oauth2" {
  service_principal_object_id          = azuread_service_principal.oauth2.object_id
  resource_service_principal_object_id = data.azuread_service_principal.msgraph.object_id
  claim_values                         = ["User.Read"]
}

# Edit most of parameters below:
# You should have K8S Applicaiton and Service or disable 'create_ingress_with_oauth' parameter.
module "oauth_proxy" {
  source = "terraform-iaac/oauth-proxy/kubernetes"

  namespace = "application_namespace"

  provider_type       = "azure"
  oauth_client_id     = azuread_application.oauth2.application_id
  oauth_client_secret = azuread_application_password.oauth2_secret.value
  oidc_issuer_url     = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"

  oauth_proxy_domain_name         = "oauth.your_auth_domain.com"
  oauth_proxy_ingress_annotations = {
    "cert-manager.io/cluster-issuer" = "cluster_issuer_name"
  }
  
  // Required block for Azure ----------------
  oauth_custom_labels = {
    "azure.workload.identity/use" = "true"
  }
  // -----------------------------------------
  
  oauth_arguments = [
    "--reverse-proxy=true",
  ]

  ingress_with_oauth_rule = [
    {
      domain        = "app.your_auth_domain.com"
      external_port = 80 // Service port
      path          = "/custom/path/"
      path_type     = "Prefix"
    }
  ]
  ingress_with_oauth_domain_name  = "app.your_auth_domain.com"
  ingress_with_oauth_service_name = "application_service_name"
  ingress_with_oauth_annotations  = {
    "cert-manager.io/cluster-issuer" = "cluster_issuer_name"
  }
}
```

## Inputs

#### General variables

| Name                    | Description                                                                                                                            | Type                                                                                                                                                                                              | Default                                                                                | Example                                                                                                                                                                    | Required |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------:|
| global_prefix           | Name of OAuth Proxy                                                                                                                    | `string`                                                                                                                                                                                          | `oauth-proxy`                                                                          | `oauth-proxy`                                                                                                                                                              |    no    |
| namespace               | Namespace in which OAuth deployment will create                                                                                        | `string`                                                                                                                                                                                          | `default`                                                                              | `application`                                                                                                                                                              |    no    |
| image_tag               | Docker image tag                                                                                                                       | `string`                                                                                                                                                                                          | `IfNotPresent`                                                                         | `Always`                                                                                                                                                                   |    no    |
| image                   | Docker image name                                                                                                                      | `string`                                                                                                                                                                                          | `quay.io/oauth2-proxy/oauth2-proxy`                                                    | `custom-image`                                                                                                                                                             |    no    |
| image\_pull_policy      | Image Pull Policy: One of Always, Never, IfNotPresent                                                                                  | `string`                                                                                                                                                                                          | `v7.4.0`                                                                               | `v1.0`                                                                                                                                                                     |    no    |
| oauth_proxy_domain_name | Global domain name for URLs                                                                                                            | `string`                                                                                                                                                                                          | n/a                                                                                    | `google.com`                                                                                                                                                               |   yes    |
| oauth_ingress_tls       | Enable https traffic & and include SSL Certificate for OAuth Proxy ingress                                                             | `string`                                                                                                                                                                                          | `[]`                                                                                   | `[tls_name1,tls_name2]`                                                                                                                                                    |    no    |
| env                     | Name and value pairs to set in the container's environmentq (Could start with 'OAUTH2_PROXY_')                                         | `map(string)`                                                                                                                                                                                     | `{}`                                                                                   | `{ "OAUTH2_PROXY_KEY" = "VALUE" }`                                                                                                                                         |    no    |
| env_secret                | Get secret keys from k8s and add as environment variables to pods                                                                      | <pre>object({<br>    request_cpu = string - (Optional)<br>    request_memory = string - (Optional)<br>    limit_cpu = string - (Optional)<br>    limit_memory = string - (Optional)<br>  })</pre> | `{}`                                                                                   | <pre>  {<br>    OAUTH2_PROXY_JWT_KEY = {<br>       name = kubernetes_secret.name_of_secret.metadata[0].name<br>       value = OAUTH2_PROXY_JWT_KEY <br>    }<br>  } </pre> |    no    |
| resources        | Compute Resources required by this container. CPU/RAM requests/limits                                                                  | <pre>object({<br>    request_cpu = string - (Optional)<br>    request_memory = string - (Optional)<br>    limit_cpu = string - (Optional) limit_memory = string - (Optional)<br>})                | <pre>  {<br>    request_cpu = "5m"<br>    request_memory = "20Mi" <br>  } </pre>       | `n\a`                                                                                                                                                                      |    no    |
| volume\_config\_map | The data stored in a ConfigMap object can be referenced in a volume of type configMap and then consumed by containerized applications running in a Pod | <pre>list(object({<br>    mode         = string<br>    name         = string<br>    volume_name  = string<br>  }))</pre>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `[]`                                                                                    | <pre>\[<br>  {<br>    mode           = "0777"<br>    name           = "config-map"<br>    volume_name    = "config-volume"<br>  }<br>]</pre>                                                                                                                                                                                                                                                                                                                                                                                                                     | no |
| oauth_custom_labels    | Add custom label to OAuth Proxy deployment. For Azure require: \"azure.workload.identity/use\" = \"true\"                                                              | `map(string)`                                                                                                                                                                                     | `null`                                                                                 | <pre> {<br>   "azure.workload.identity/use" = "true" <br> }</pre>                                                                                                          |    no    |
| service_account_token         | Indicates whether a service account token should be automatically mounted                                                      | `bool`                                                                                                                                                                                            | `null`                                                                                 | `true`                                                                                                                                                                     |    no    |
|service_account_name| Name of the ServiceAccount to use to run this pod                                                                                      | `string`                                                                                                                                                                                          | `null`                                                                                 | `gcloud-oauth-sa`                                                                                                                                                          |no|
| readiness\_probe | Periodic probe of container service readiness. Container will be removed from service endpoints if the probe fails.  | <pre>object({<br>    success_threshold     = number<br>    failure_threshold     = number<br>    initial_delay_seconds = number <br>    period_seconds        = number <br>    timeout_seconds       = number <br><br>    http_get = {<br>      http_header = list(object(    // (Optional)<br>        {<br>          name =  string<br>          value = string<br>        }<br>      )<br>      path   = string<br>      port   = number<br>      scheme = string<br>    } <br>    exec = {            // (Optional)<br>      command =list(string)<br>    }<br>    tcp_socket = {      // (Optional)<br>      port = number<br>    }<br> })</pre> | n/a                                                                                    | <pre>{<br>    success_threshold     = 1<br>    failure_threshold     = 3<br>    initial_delay_seconds = 10 <br>    period_seconds        = 30 <br>    timeout_seconds       = 10 <br><br>    http_get = {<br>      http_header = [<br>        {<br>          name =  "some-header"<br>          value = "some-value"<br>        }<br>      ]<br>      path   = "/"<br>      port   = 80<br>      scheme = "HTTP"<br>    } <br>    exec = {<br>      command = ["/bin/bash", "command"]<br>    }<br>    tcp_socket = {<br>      port = 5433<br>    }<br> })</pre> | no |
| liveness\_probe | Periodic probe of container liveness. Container will be restarted if the probe fails | same as on readiness_probe                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | n/a                                                                                    | same as on readiness_probe                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | no |
|node_selector| Node selector for OAAuth applicaiton pod                                                                                               | map(string)                                                                                                                                                                                       | `null`                                                                                 | <pre> {<br>    sytem_node_pool_key = system_node_pool_label_value <br> }</pre>                                                                                             | no                                                                                                                                                                                                |
|oauth_proxy_ports| OAuth application ports                                                                                                                | <pre>{<br>  name = string<br>  internal_port = number<br>  external_port = number<br>}                                                                                                            | <pre>{<br>  name = "web"<br>  internal_port = 4180<br>  external_port = 4180<br>}</pre> | n/a                                                                                                                                                                        | no |
|oauth_proxy_ingress_annotations| Custom annotations for ingress with OAuth                                                                                              | `map(string)`                                                                                                                                                                                     | `{}`                                                                                   | <pre> {<br>    "cert-manager.io/cluster-issuer" = local.cluster_issuer_name <br> }</pre>                                                                                   |    no    |


#### OAuth variables
| Name                    | Description                                                                                                                            | Type           | Default | Example                                            | Required |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------|----------------|--------|----------------------------------------------------|:--------:|
| provider_type           | Type of OAuth2 provider. Valid values: google, azure, keycloak, facebook, github, gitlab, etc. More info: https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider  | `string`       | n/a    | `google`                                           |   yes    |
| oauth_client_id               | OAuth Client ID                                                                                        | `string`       | n/a    | `aaaaaaaaa-ea1a-123c-321f-aa1234aa3210`            |   yes    |
| oauth_client_secret               | OAuth Client Secret                                                                                                                       | `string`       | n/a    | `rAnD()m=$E(ret`                                   |   yes    |
| oauth_arguments                   | OAuth Proxy command line arguments. More info: https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview#command-line-options                                                                                                                      | `list(string)` | `[]`   | n/a                                                |    no    |
| oidc_issuer_url      | OpenID Connect issuer URL                                                                                  | `string`       | n/a    | `https://login.microsoftonline.com/tenant_id/v2.0` |   yes    |
| oauth_email_domain | Authenticate emails with the specified domain                                                                                                            | `string`       | `*`     | `google.com`                                       |    no    |


#### Ingress with OAuth variables
| Name                    | Description                                                                                                                            | Type           | Default             | Example                                                              | Required |
|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------|----------------|---------------------|----------------------------------------------------------------------|:--------:|
| create_ingress_with_oauth           | Enable creation of ingress with authentication via OAuth Proxy  | `bool`         | `true`              | n/a                                                                  |    no    |
| ingress_class_name               | Ingress Class name                                                                                        | `string`       | `nginx`             | `nginx-public`                                                       |    no    |
| ingress_with_oauth_rule               | External Service port, ingress will redirect request to this service port. Also could add subdomain ( example: subdomain.domainname.com). And path for access ( example: domain.com/path ). And redefine domain. | `list(string)` | `[]`                | <pre>{<br>  domain = "google.com"<br>  external_port = 80<br>}</pre> |    no    |
| ingress_with_oauth_service_name                   | Name of service for ingress with OAuths                                                                                                                    | `string`       | `ingress-with-oauth` | n/a                                                                  |    no    |
| ingress_with_oauth_annotations      | Custom annotations for ingress with OAuth                                                                                  | `map(string)`  | `{}`                 | n/a                                                                  |    no    |
| ingress_with_oauth_domain_name | Global domain name for all URL                                                                                                            | `string`       | `app-with-oauth.example.com`                  | `ingress.google.com`                                                 |    no    |


## Outputs

| Name |                Description                |
|------|:-----------------------------------------:|
| name |          Name of the deployment           |
| namespace | Namespace in which created the deployment |
| cookie_secret |             Generated cookies             |