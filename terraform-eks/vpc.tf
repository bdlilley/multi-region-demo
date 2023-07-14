

module "vpc-us-east-1" {
  source           = "git::https://github.com/bensolo-io/cloud-gitops-examples.git//terraform/_submodules/vpc-simple?ref=main"
  vpcConfig        = var.vpcConfigs["us-east-1"]
  resourcePrefix   = var.resourcePrefix
  tags             = var.tags
  commonVpcConfigs = var.commonVpcConfigs
  region           = "us-east-1"
  providers = {
    aws = aws.us-east-1
  }
}

module "vpc-us-east-2" {
  source           = "git::https://github.com/bensolo-io/cloud-gitops-examples.git//terraform/_submodules/vpc-simple?ref=main"
  vpcConfig        = var.vpcConfigs["us-east-2"]
  resourcePrefix   = var.resourcePrefix
  tags             = var.tags
  commonVpcConfigs = var.commonVpcConfigs
  region           = "us-east-2"
  providers = {
    aws = aws.us-east-2
  }
}

######################################################################
# peering - requesting VPC (us-east-2)
resource "aws_vpc_peering_connection" "requester" {
  provider    = aws.us-east-2
  peer_vpc_id = module.vpc-us-east-1.vpc.id
  peer_region = "us-east-1"
  vpc_id      = module.vpc-us-east-2.vpc.id
  auto_accept = false
  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_options" "requester" {
  provider                  = aws.us-east-2
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id
  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

######################################################################
# peering - requesting VPC (us-east-1)
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.us-east-1
  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  auto_accept               = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  tags = {
    Side = "Accepter"
  }
}


######################################################################
# peering - route tables

# this seems wonky, but it's the only way to get a value unknown at plan time 
# into a for_each loop
locals {
  peerRtsRequester = {
    private = module.vpc-us-east-2.routeTable.private
    public  = module.vpc-us-east-2.routeTable.public
  }
  peerRtsAccepter = {
    private = module.vpc-us-east-1.routeTable.private
    public  = module.vpc-us-east-1.routeTable.public
  }
}

resource "aws_route" "requester" {
  for_each                  = local.peerRtsRequester
  route_table_id            = each.value.id
  destination_cidr_block    = module.vpc-us-east-1.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  provider                  = aws.us-east-2
}

resource "aws_route" "accepter" {
  for_each                  = local.peerRtsAccepter
  route_table_id            = each.value.id
  destination_cidr_block    = module.vpc-us-east-2.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  provider                  = aws.us-east-1
}

# data "aws_route_tables" "accepter" {
#   vpc_id   = module.vpc-us-east-1.vpc.id
#   provider = aws.us-east-1
# }

# data "aws_route_tables" "requester" {
#   vpc_id   = module.vpc-us-east-2.vpc.id
#   provider = aws.us-east-2
# }

# output "rt_ids" {
#   value = {
#     requester_route_tables_ids = data.aws_route_tables.requester.ids
#     accepter_route_tables_ids  = data.aws_route_tables.accepter.ids
#   }
# }
