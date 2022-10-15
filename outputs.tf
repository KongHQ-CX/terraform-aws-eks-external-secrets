output "role_arn" {
  value = module.this_role.0.iam_role_arn 
}

output "role_name" {
  value = module.this_role.0.iam_role_name
}

output "service_account" {
  value = var.service_account
}

output "namespace" {
  value = var.namespace
}
