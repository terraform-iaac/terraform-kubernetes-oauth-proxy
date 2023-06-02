output "name" {
  value = var.global_prefix
}
output "namespace" {
  value = var.namespace
}
output "cookie_secret" {
  value = random_password.cookie_secret.result
}