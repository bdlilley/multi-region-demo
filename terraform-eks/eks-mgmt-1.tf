locals {
  eks-mgmt-1-kubernetesClusterName = "mgmt-1"
  eks-mgmt-1-nodeGroupConfig = {
    min_size        = 0
    max_size        = 4
    desired_size    = 1
    instance_types  = ["m5.2xlarge"]
    commonClusterSg = aws_security_group.common-us-east-1.id
  }
  eks-mgmt-1-subnetIds        = [for sn in module.vpc-us-east-1.privateSubnets : sn.id]
  eks-mgmt-1-securityGroupIds = [aws_security_group.common-us-east-1.id]
}

module "eks-mgmt-1" {
  providers = {
    aws = aws.us-east-1
  }
  source         = "git::https://github.com/bdlilley/cloud-gitops-examples.git//terraform-modules/eks-simple?ref=main"
  resourcePrefix = var.resourcePrefix
  tags           = var.tags

  cluster = {
    name             = local.eks-mgmt-1-kubernetesClusterName
    version          = var.kubernetesVersion
    securityGroupIds = local.eks-mgmt-1-securityGroupIds
    subnetIds        = local.eks-mgmt-1-subnetIds
  }

  nodeGroups = {
    default = local.eks-mgmt-1-nodeGroupConfig
  }
}
