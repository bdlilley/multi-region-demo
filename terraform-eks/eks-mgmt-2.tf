locals {
  eks-mgmt-2-kubernetesClusterName = "mgmt-2"
  eks-mgmt-2-nodeGroupConfig = {
    min_size        = 0
    max_size        = 4
    desired_size    = 1
    instance_types  = ["m5.2xlarge"]
    commonClusterSg = aws_security_group.common-us-east-2.id
  }
  eks-mgmt-2-subnetIds        = [for sn in module.vpc-us-east-2.privateSubnets : sn.id]
  eks-mgmt-2-securityGroupIds = [aws_security_group.common-us-east-2.id]
}

module "eks-mgmt-2" {
  providers = {
    aws = aws.us-east-2
  }
  source         = "git::https://github.com/bdlilley/cloud-gitops-examples.git//terraform-modules/eks-simple?ref=main"
  resourcePrefix = var.resourcePrefix
  tags           = var.tags

  cluster = {
    name             = local.eks-mgmt-2-kubernetesClusterName
    version          = var.kubernetesVersion
    securityGroupIds = local.eks-mgmt-2-securityGroupIds
    subnetIds        = local.eks-mgmt-2-subnetIds
  }

  nodeGroups = {
    default = local.eks-mgmt-2-nodeGroupConfig
  }
}
