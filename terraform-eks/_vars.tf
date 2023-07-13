variable "tags" {
  # default = {
  #   "created-by" = "benji_lilley"
  #   "team"       = "product"
  #   "purpose"    = "product-development"
  # }
}

variable "privateHzName" {
  description = "a unique name for a private route53 hosted zone to use for load balancers"
}

variable "resourcePrefix" {
  description = "provide a short unique string to prefix all your resources in AWS to avoid conflicts"
}

variable "commonVpcConfigs" {

}

variable "vpcConfigs" {

}

variable "kubernetesVersion" {

}

variable "redis_auth" {
  description = "a redis auth password to use for elasticache"
}