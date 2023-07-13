locals {
  irsaOutputs = {
    "mgmt-1" : module.eks-mgmt-1.irsa
    "mgmt-2" : module.eks-mgmt-2.irsa
    "workload-1" : module.eks-workload-1.irsa
    "workload-2" : module.eks-workload-2.irsa
  }
}

output "irsa" {
  value = local.irsaOutputs
}

output "update-kubeconfig" {
  value = {
    "cmd" = <<EOT
aws eks update-kubeconfig --name ${module.eks-mgmt-1.eks.name} --region us-east-1
aws eks update-kubeconfig --name ${module.eks-mgmt-2.eks.name} --region us-east-2
aws eks update-kubeconfig --name ${module.eks-workload-1.eks.name} --region us-east-1
aws eks update-kubeconfig --name ${module.eks-workload-2.eks.name} --region us-east-2
    EOT
  }
}