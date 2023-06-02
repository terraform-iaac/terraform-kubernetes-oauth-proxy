resource "kubernetes_secret" "this" {
  metadata {
    name      = "${var.global_prefix}-secrets"
    namespace = var.namespace
  }

  data = {
    OAUTH2_PROXY_CLIENT_ID     = var.oauth_client_id
    OAUTH2_PROXY_CLIENT_SECRET = var.oauth_client_secret
    OAUTH2_PROXY_COOKIE_SECRET = random_password.cookie_secret.result
  }
  type = "Opaque"
}
resource "random_password" "cookie_secret" {
  length           = 32
  override_special = "-_"
}
