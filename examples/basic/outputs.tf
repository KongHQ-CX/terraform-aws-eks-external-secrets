output "aws_vpc" {
  value = data.aws_vpc.this
}

output "aws_subnet_ids" {
  value = data.aws_subnets.this
}

output "cluster" {
  value = data.aws_eks_cluster.global_cp_cluster
}

locals {
  cluster_cp     = try(module.cluster-1.0.cluster_id, "cluster-not-created")
  cluster_cp_arn = try(module.cluster-1.0.cluster_arn, "cluster-not-created")
  config_cp      = "aws eks update-kubeconfig --name ${local.cluster_cp}"
  context_cp     = "kubectl config use-context ${local.cluster_cp_arn}"
}

output "kubeconfigs" {
  value = [
    local.config_cp,
  ]
}

output "contexts" {
  value = [
    local.context_cp,
  ]
}
