
## required vpc values
locals {
  redisVpcLocals = {
    "us-east-1" : {
      subnetIds : [for sn in module.vpc-us-east-1.privateSubnets : sn.id]
      securityGroupIds : [
        module.vpc-us-east-1.commonSecurityGroup.id,
        module.vpc-us-east-1.interfaceSecurityGroup.id,
      ]
    }
    "us-east-2" : {
      subnetIds : [for sn in module.vpc-us-east-2.privateSubnets : sn.id]
      securityGroupIds : [
        module.vpc-us-east-2.commonSecurityGroup.id,
        module.vpc-us-east-2.interfaceSecurityGroup.id,
      ]
    }
  }
}

## primary us-east-1

resource "aws_elasticache_global_replication_group" "redis-global" {
  provider                           = aws.us-east-1
  global_replication_group_id_suffix = "${local.resourcePrefix}-global"
  primary_replication_group_id       = aws_elasticache_replication_group.redis-primary-us-east-1.id
}

# primary replication group - this is a depdency to create the global datastore (aws_elasticache_global_replication_group)
resource "aws_elasticache_replication_group" "redis-primary-us-east-1" {
  provider                   = aws.us-east-1
  automatic_failover_enabled = false
  # this must be unique per replication group
  replication_group_id = "${local.resourcePrefix}-primary"
  description          = "${local.resourcePrefix}-primary"
  node_type            = "cache.m5.large"
  num_cache_clusters   = 1
  parameter_group_name = "default.redis7"
  engine               = "redis"
  engine_version       = "7.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis-primary-us-east-1.name
  security_group_ids   = local.redisVpcLocals["us-east-1"].securityGroupIds

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth
  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "aws_elasticache_subnet_group" "redis-primary-us-east-1" {
  provider   = aws.us-east-1
  name       = "${local.resourcePrefix}-primary"
  subnet_ids = local.redisVpcLocals["us-east-1"].subnetIds
}

output "redis-primary-us-east-1" {
  value = {
    address = "${aws_elasticache_replication_group.redis-primary-us-east-1.primary_endpoint_address}:${aws_elasticache_replication_group.redis-primary-us-east-1.port}"
    host    = aws_elasticache_replication_group.redis-primary-us-east-1.primary_endpoint_address
    port    = aws_elasticache_replication_group.redis-primary-us-east-1.port
  }
}

## secondary us-east-2

# secondary replication group - this must refer to the global datastore
resource "aws_elasticache_replication_group" "redis-secondary-us-east-2" {
  provider = aws.us-east-2
  # this must be unique per replication group
  replication_group_id = "${local.resourcePrefix}-secondary"
  # this is required to join the global group
  global_replication_group_id = aws_elasticache_global_replication_group.redis-global.global_replication_group_id
  description                 = "${local.resourcePrefix}-secondary"
  num_cache_clusters          = 1
  # automatic_failover_enabled = false

  port               = 6379
  subnet_group_name  = aws_elasticache_subnet_group.redis-secondary-us-east-2.name
  security_group_ids = local.redisVpcLocals["us-east-2"].securityGroupIds

  auth_token = var.redis_auth
  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "aws_elasticache_subnet_group" "redis-secondary-us-east-2" {
  provider   = aws.us-east-2
  name       = "${local.resourcePrefix}-secondary"
  subnet_ids = local.redisVpcLocals["us-east-2"].subnetIds
}

output "redis-secondary-us-east-2" {
  value = {
    address = "${aws_elasticache_replication_group.redis-secondary-us-east-2.primary_endpoint_address}:${aws_elasticache_replication_group.redis-secondary-us-east-2.port}"
    host    = aws_elasticache_replication_group.redis-secondary-us-east-2.primary_endpoint_address
    port    = aws_elasticache_replication_group.redis-secondary-us-east-2.port
  }
}
