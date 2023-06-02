module "deployment_oauth_proxy" {
  source  = "terraform-iaac/deployment/kubernetes"
  version = "1.4.3"

  name          = var.global_prefix
  namespace     = var.namespace
  image         = "${var.image}:${var.image_tag}"
  internal_port = var.oauth_proxy_ports

  args = concat(
    [
      "--provider=${var.provider_type}",
      "--email-domain=${var.oauth_email_domain}",
      "--http-address=0.0.0.0:${var.oauth_proxy_ports[0].internal_port}",
      "--whitelist-domain=*.${var.oauth_proxy_domain_name},*.${var.ingress_with_oauth_domain_name},${var.oauth_proxy_domain_name},${var.ingress_with_oauth_domain_name}",
      "--oidc-issuer-url=${var.oidc_issuer_url}",
    ], var.oauth_arguments
  )

  resources = var.resources

  image_pull_policy = "Always"
  node_selector     = var.node_selector

  env        = var.env
  env_secret = merge(local.oauth2_secret_env, var.env_secret)

  custom_labels = merge({
    "app"     = var.global_prefix
    "k8s-app" = var.global_prefix
  }, var.oauth_custom_labels)

  service_account_name  = var.service_account_name
  service_account_token = var.service_account_token

  volume_config_map = var.volume_config_map

  liveness_probe  = var.liveness_probe
  readiness_probe = var.readiness_probe
}

module "ingress_oauth_proxy" {
  source  = "terraform-iaac/ingress/kubernetes"
  version = "2.0.1"

  service_name      = module.deployment_oauth_proxy.name
  service_namespace = var.namespace

  ingress_class_name = var.ingress_class_name

  annotations = merge({
    "nginx.ingress.kubernetes.io/auth-signin"          = "https://${var.oauth_proxy_domain_name}/oauth2/start?rd=$scheme://$http_host$request_uri"
    "nginx.ingress.kubernetes.io/proxy-buffer-size"    = "8k"
    "nginx.ingress.kubernetes.io/proxy-buffers-number" = "4"
  }, var.oauth_proxy_ingress_annotations)

  rule = [
    {
      domain        = var.oauth_proxy_domain_name
      path          = "/oauth2"
      service_name  = module.service_oauth_proxy.name
      external_port = var.oauth_proxy_ports.0.external_port
    }
  ]
  domain_name = var.oauth_proxy_domain_name
  tls_hosts   = [
    {
      secret_name = "${var.global_prefix}-secret"
      hosts       = [var.oauth_proxy_domain_name]
    }
  ]
}
module "service_oauth_proxy" {
  source  = "terraform-iaac/service/kubernetes"
  version = "1.0.3"

  app_name      = module.deployment_oauth_proxy.name
  app_namespace = var.namespace
  port_mapping  = var.oauth_proxy_ports
}

# Ingress which "closed" by OAuth
module "ingress_with_oauth" {
  count = var.create_ingress_with_oauth ? 1 : 0

  source  = "terraform-iaac/ingress/kubernetes"
  version = "2.0.1"

  service_name      = var.ingress_with_oauth_service_name
  service_namespace = var.namespace

  ingress_class_name = var.ingress_class_name

  annotations = merge(
    {
      "nginx.ingress.kubernetes.io/auth-signin" = "https://${var.oauth_proxy_domain_name}/oauth2/start?rd=$scheme://$http_host$request_uri"
      "nginx.ingress.kubernetes.io/auth-url"    = "https://${var.oauth_proxy_domain_name}/oauth2/auth"
    },
    var.ingress_with_oauth_annotations
  )

  rule        = var.ingress_with_oauth_rule
  domain_name = var.ingress_with_oauth_domain_name
  tls_hosts   = [
    {
      secret_name = "${var.ingress_with_oauth_service_name}-ingress-secret"
      hosts       = [var.ingress_with_oauth_domain_name]
    }
  ]
}
