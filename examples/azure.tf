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

# OAuth module
module "oauth_proxy" {
  source = "../"

  namespace     = "applicaiton_namespace"

  provider_type       = "azure"
  oauth_client_id     = azuread_application.oauth2.application_id
  oauth_client_secret = azuread_application_password.oauth2_secret.value
  oidc_issuer_url     = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"

  oauth_proxy_domain_name = "oauth.your_auth_domain.com"
  oauth_proxy_ingress_annotations = {
    "cert-manager.io/cluster-issuer" = "cluster_issuer_name"
  }
  oauth_custom_labels = {
    "azure.workload.identity/use" = "true"
  }
  oauth_arguments = [
    "--reverse-proxy=true",
    "--config=/path/to/config/file(could be base on custom ConfigMap)"
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
  ingress_with_oauth_annotations = {
    "cert-manager.io/cluster-issuer" = "cluster_issuer_name"
  }
}