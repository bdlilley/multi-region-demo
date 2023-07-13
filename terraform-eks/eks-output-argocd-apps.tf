locals {
  allClusters = {
    "mgmt-1" : "us-east-1"
    "mgmt-2" : "us-east-2"
    "workload-1" : "us-east-1"
    "workload-2" : "us-east-2"
  }
}

resource "local_file" "argocd-app-yaml" {
  for_each = local.allClusters

  content = templatefile("${path.module}/templates/apps.yaml", {
    ext-secrets-role-arn       = local.irsaOutputs[each.key].ext-secrets
    ext-dns-role-arn           = local.irsaOutputs[each.key].ext-dns
    aws-lb-controller-role-arn = local.irsaOutputs[each.key].aws-lb-controller
    cluster-name               = each.key
  })
  filename = "${path.module}/../argocd/${var.resourcePrefix}/${each.key}/generated-apps.yaml"
}

resource "local_file" "argocd-ext-dns-yaml" {
  for_each = local.allClusters

  content = templatefile("${path.module}/templates/ext-dns.yaml", {
    region           = each.value
    ext-dns-role-arn = local.irsaOutputs[each.key].ext-dns
    cluster-name     = each.key
    domain           = var.privateHzName
  })
  filename = "${path.module}/../argocd/${var.resourcePrefix}/${each.key}/generated-ext-dns.yaml"
}
