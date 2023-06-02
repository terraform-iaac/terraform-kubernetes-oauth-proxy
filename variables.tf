# General Variables
variable "global_prefix" {
  description = "Name of OAuth Proxy"
  default     = "oauth-proxy"
}
variable "namespace" {
  type        = string
  description = "Namespace in which to create the deployment"
  default     = "default"
}
variable "image_pull_policy" {
  default     = "IfNotPresent"
  description = "One of Always, Never, IfNotPresent"
}
variable "image" {
  type        = string
  description = "Docker image name"
  default     = "quay.io/oauth2-proxy/oauth2-proxy"
}
variable "image_tag" {
  type        = string
  description = "Docker image tag"
  default     = "v7.4.0"
}
variable "oauth_proxy_domain_name" {
  type        = string
  description = "Global domain name for all URL ( example: google.com)."
}
variable "oauth_ingress_tls" {
  type        = list(string)
  description = "Enable https traffic & and include SSL Certificate for OAuth Proxy ingress"
  default     = []
}
variable "env" {
  description = "Name and value pairs to set in the container's environment"
  default     = {}
}
variable "env_secret" {
  description = "Get secret keys from k8s and add as environment variables to pods"
  default     = {}
}
variable "resources" {
  description = "Compute Resources required by this container. CPU/RAM requests/limits"
  default     = {
    request_cpu    = "5m"
    request_memory = "20Mi"
  }
}
variable "volume_config_map" {
  type        = list(object({ mode = string, name = string, volume_name = string }))
  description = "The data stored in a ConfigMap object can be referenced in a volume of type configMap and then consumed by containerized applications running in a Pod"
  default     = []
}
variable "oauth_custom_labels" {
  description = "Add custom label to OAuth Proxy deployment. For Azure require: \"azure.workload.identity/use\" = \"true\""
  default     = null
}
variable "service_account_token" {
  type        = bool
  description = "Indicates whether a service account token should be automatically mounted"
  default     = null
}
variable "service_account_name" {
  type        = string
  description = "Is the name of the ServiceAccount to use to run this pod"
  default     = null
}
variable "liveness_probe" {
  description = "Periodic probe of container liveness. Container will be restarted if the probe fails. Cannot be updated. "
  default     = []
}
variable "readiness_probe" {
  description = "Periodic probe of container service readiness. Container will be removed from service endpoints if the probe fails. Cannot be updated. "
  default     = []
}
variable "node_selector" {
  description = "Specify node selector for pod"
  type        = map(string)
  default     = null
}
variable "oauth_proxy_ports" {
  default = [
    {
      name          = "web"
      internal_port = 4180
      external_port = 4180
    }
  ]
}
variable "oauth_proxy_ingress_annotations" {
  description = "Custom annotations for ingress with OAuth"
  default     = {}
}

# OAuth variables
variable "provider_type" {
  description = "Type of OAuth2 provider. Valid values: google, azure, keycloak, facebook, github, gitlab, etc. More info: https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider"
}
variable "oauth_client_id" {
  description = "OAuth Client ID"
}
variable "oauth_client_secret" {
  description = "OAuth Client Secret"
}
variable "oauth_arguments" {
  type        = list(string)
  description = "OAuth Proxy command line arguments. More info: https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview#command-line-options"
  default     = []
}
variable "oidc_issuer_url" {
  description = "OpenID Connect issuer URL"
}
variable "oauth_email_domain" {
  description = "Authenticate emails with the specified domain"
  default     = "*"
}


# Ingress with OAuth variables
variable "create_ingress_with_oauth" {
  type        = bool
  description = "Enable creation of ingress with authentication via OAuth Proxy"
  default     = true
}
variable "ingress_class_name" {
  description = "Ingress Class name"
  type        = string
  default     = "nginx"
}
variable "ingress_with_oauth_rule" {
  description = "External Service port, ingress will redirect request to this service port. Also could add subdomain ( example: subdomain.domainname.com). And path for access ( example: domain.com/path ). And redefine domain."
  default     = []
}
variable "ingress_with_oauth_service_name" {
  description = "Name of service for ingress with OAuths"
  default     = "ingress-with-oauth"
}
variable "ingress_with_oauth_annotations" {
  description = "Custom annotations for ingress with OAuth"
  default     = {}
}
variable "ingress_with_oauth_domain_name" {
  type        = string
  description = "Global domain name for all URL (example: google.com)."
  default     = "app-with-oauth.example.com"
}
