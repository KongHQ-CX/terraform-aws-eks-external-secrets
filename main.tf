module "this_role" {
  count  = var.create_role ? 1 : 0
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                             = "eks_sm"
  attach_external_secrets_policy        = var.create_role
  external_secrets_secrets_manager_arns = ["*"]
  external_secrets_ssm_parameter_arns   = ["*"]
  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${var.service_account}"]
    }
  }
  tags = var.tags
}

data "aws_iam_policy_document" "kms" {
  count = var.create_role ? 1 : 0

  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "kms" {
  count = var.create_role ? 1 : 0

  name_prefix = "External_Secrets_kms_Policy-"
  path        = "/"
  description = "Provides permissions to for External access KMS"
  policy      = data.aws_iam_policy_document.kms[0].json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "kms" {
  count      = var.create_role ? 1 : 0
  role       = module.this_role.0.iam_role_name
  policy_arn = aws_iam_policy.kms[0].arn
}

resource "kubernetes_service_account" "service-account" {
  count = var.create_service_account ? 1 : 0
  metadata {
    name      = var.service_account
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.service_account
    }
    annotations = {
      "eks.amazonaws.com/role-arn" : module.this_role.0.iam_role_arn
    }
  }
}

resource "helm_release" "sm" {
  count      = var.create_deployment ? 1 : 0
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.chart_version
  namespace  = var.namespace
  depends_on = [
    kubernetes_service_account.service-account
  ]
  set {
    name  = "CreateNamespace"
    value = "false"
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = var.service_account
  }
}
