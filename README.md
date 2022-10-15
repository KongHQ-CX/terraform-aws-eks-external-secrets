# terraform-aws-eks-external-secrets

A terraform module for provisioning an external-secrets operator to an EKS cluster

## Usage

### Using module defaults

The following will create an external-dns controller in an EKS cluster

```HCL
module "external-secrets" {
  source            = "KongHQ-CX/eks-external-secrets/aws"
  providers = {
    helm       = helm.cluster_1
    kubernetes = kubernetes.cluster_1
  }
  oidc_provider_arn = module.cluster-1.0.oidc_provider_arn
  tags              = local.tags
}
```

## Misc

This module uses the IRSA policies from [this](https://github.com/terraform-aws-modules/terraform-aws-iam)
TF AWS module and this helm
[chart](https://charts.external-secrets.io/external-secrets) to configure
and deploy external-dns
