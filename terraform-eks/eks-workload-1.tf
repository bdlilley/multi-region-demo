locals {
  eks-workload-1-kubernetesClusterName = "workload-1"
  eks-workload-1-nodeGroupConfig = {
    min_size        = 0
    max_size        = 4
    desired_size    = 1
    instance_types  = ["m5.2xlarge"]
    commonClusterSg = module.vpc-us-east-1.commonSecurityGroup.id
  }
  eks-workload-1-subnetIds = [for sn in module.vpc-us-east-1.privateSubnets : sn.id]
  eks-workload-1-securityGroupIds = [
    module.vpc-us-east-1.commonSecurityGroup.id,
    module.vpc-us-east-1.interfaceSecurityGroup.id,
  ]
}

module "eks-workload-1" {
  providers = {
    aws = aws.us-east-1
  }
  source         = "git::https://github.com/bensolo-io/cloud-gitops-examples.git//terraform/_submodules/eks-simple?ref=main"
  resourcePrefix = var.resourcePrefix
  tags           = var.tags

  cluster = {
    name             = local.eks-workload-1-kubernetesClusterName
    version          = var.kubernetesVersion
    securityGroupIds = local.eks-workload-1-securityGroupIds
    subnetIds        = local.eks-workload-1-subnetIds
  }

  nodeGroups = {
    default = local.eks-workload-1-nodeGroupConfig
  }
}
