
locals {
  irsaOutputs = {
    "mgmt-1" : module.eks-mgmt-1.irsa
    "mgmt-2" : module.eks-mgmt-2.irsa
    "workload-1" : module.eks-workload-1.irsa
    "workload-2" : module.eks-workload-2.irsa
  }
  eksOutputs = {
    "mgmt-1" : module.eks-mgmt-1
    "mgmt-2" : module.eks-mgmt-2
    "workload-1" : module.eks-workload-1
    "workload-2" : module.eks-workload-2
  }
}

output "irsa" {
  value = local.irsaOutputs
}

output "eks" {
  value = local.eksOutputs
}

output "update-kubeconfig" {
  value = {
    "cmd" = <<EOT
aws eks update-kubeconfig --name ${module.eks-mgmt-1.eks.name} --region us-east-1
kubectl config rename-context ${module.eks-mgmt-1.eks.arn} mgmt-1
aws eks update-kubeconfig --name ${module.eks-mgmt-2.eks.name} --region us-east-2
kubectl config rename-context ${module.eks-mgmt-2.eks.arn} mgmt-2
aws eks update-kubeconfig --name ${module.eks-workload-1.eks.name} --region us-east-1
kubectl config rename-context ${module.eks-workload-1.eks.arn} workload-1
aws eks update-kubeconfig --name ${module.eks-workload-2.eks.name} --region us-east-2
kubectl config rename-context ${module.eks-workload-2.eks.arn} workload-2
    EOT
  }
}