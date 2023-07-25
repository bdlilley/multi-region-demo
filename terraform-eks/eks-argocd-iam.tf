# these roles have no AWS policies; they only exist for mapping into kubernetes rbac
# to support argocd managing clusters remotely
# each role name must be unique, but they all trust only the mgmt-1 cluster b/c that is our single argocd isntance
# ; argocd can be HA, but is not configured that way for this demo
module "irsa-argocd-mgmt-1" {
  source                       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  create_role                  = true
  role_name                    = "${var.resourcePrefix}-mgmt-1-argocd"
  provider_url                 = replace(module.eks-mgmt-1.eks.identity[0].oidc[0].issuer, "https://", "")
  oidc_subjects_with_wildcards = ["system:serviceaccount:argocd:argocd-*"]
}

module "irsa-argocd-mgmt-2" {
  source                       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  create_role                  = true
  role_name                    = "${var.resourcePrefix}-mgmt-2-argocd"
  provider_url                 = replace(module.eks-mgmt-1.eks.identity[0].oidc[0].issuer, "https://", "")
  oidc_subjects_with_wildcards = ["system:serviceaccount:argocd:argocd-*"]
}

module "irsa-argocd-workload-1" {
  source                       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  create_role                  = true
  role_name                    = "${var.resourcePrefix}-workload-1-argocd"
  provider_url                 = replace(module.eks-mgmt-1.eks.identity[0].oidc[0].issuer, "https://", "")
  oidc_subjects_with_wildcards = ["system:serviceaccount:argocd:argocd-*"]
}

module "irsa-argocd-workload-2" {
  source                       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  create_role                  = true
  role_name                    = "${var.resourcePrefix}-workload-2-argocd"
  provider_url                 = replace(module.eks-mgmt-1.eks.identity[0].oidc[0].issuer, "https://", "")
  oidc_subjects_with_wildcards = ["system:serviceaccount:argocd:argocd-*"]
}

output "irsa_argocd" {
  value = {
    "mgmt-1"     = module.irsa-argocd-mgmt-1.iam_role_arn
    "mgmt-2"     = module.irsa-argocd-mgmt-2.iam_role_arn
    "workload-1" = module.irsa-argocd-workload-1.iam_role_arn
    "workload-2" = module.irsa-argocd-workload-2.iam_role_arn
  }
}
