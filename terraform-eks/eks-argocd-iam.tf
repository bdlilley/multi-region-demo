data "aws_caller_identity" "current" {}

# argocd controller role - allows assume role to the deployer roles
module "irsa-argocd-mgmt-1-controller" {
  source                       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  create_role                  = true
  role_name                    = "${var.resourcePrefix}-mgmt-1-argocd-controller"
  provider_url                 = replace(module.eks-mgmt-1.eks.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns             = [aws_iam_policy.mgmt-1-argocd-controller.arn]
  oidc_subjects_with_wildcards = ["system:serviceaccount:argocd:argocd-*"]
}

output "irsa_argocd_controller" {
  value = module.irsa-argocd-mgmt-1-controller.iam_role_arn
}

resource "aws_iam_policy" "mgmt-1-argocd-controller" {
  name        = "${var.resourcePrefix}-mgmt-1-argocd-controller"
  path        = "/"
  description = "manage kubernetes resources"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sts:AssumeRole"
          ],
          "Resource" : [
            "${aws_iam_role.argocd-mgmt-2.arn}",
            "${aws_iam_role.argocd-workload-1.arn}",
            "${aws_iam_role.argocd-workload-2.arn}"
          ]
        }
      ]
  })
}

resource "local_file" "install-argocd" {
  content = templatefile("${path.module}/templates/install-argocd.yaml", {
    argocd-controller-arn = module.irsa-argocd-mgmt-1-controller.iam_role_arn
  })
  filename = "${path.module}/../argocd/${var.resourcePrefix}/_install_argocd/kustomization.yaml"
}

# deployer roles for each cluster
resource "aws_iam_role" "argocd-mgmt-2" {
  name = "${var.resourcePrefix}-mgmt-2-argocd"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.irsa-argocd-mgmt-1-controller.iam_role_arn}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOF
}

resource "aws_iam_role" "argocd-workload-1" {
  name = "${var.resourcePrefix}-workload-1-argocd"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.irsa-argocd-mgmt-1-controller.iam_role_arn}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOF
}


resource "aws_iam_role" "argocd-workload-2" {
  name = "${var.resourcePrefix}-workload-2-argocd"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.irsa-argocd-mgmt-1-controller.iam_role_arn}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOF
}

output "iam_argocd" {
  value = {
    "mgmt-2"     = aws_iam_role.argocd-mgmt-2.arn
    "workload-1" = aws_iam_role.argocd-workload-1.arn
    "workload-2" = aws_iam_role.argocd-workload-2.arn
  }
}
