locals {
  oauth2_secret_env = {
    OAUTH2_PROXY_CLIENT_ID = {
      name = kubernetes_secret.this.metadata[0].name
      key  = "OAUTH2_PROXY_CLIENT_ID"
    },
    OAUTH2_PROXY_CLIENT_SECRET = {
      name = kubernetes_secret.this.metadata[0].name
      key  = "OAUTH2_PROXY_CLIENT_SECRET"
    },
    OAUTH2_PROXY_COOKIE_SECRET = {
      name = kubernetes_secret.this.metadata[0].name
      key  = "OAUTH2_PROXY_COOKIE_SECRET"
    }
  }
}