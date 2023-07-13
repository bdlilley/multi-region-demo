vpcConfigs = {
  "default" = {
    # cidr of the entire VPC
    cidr = "10.20.0.0/16"
    # cidr used for client VPN connections; cannot overlap
    # with VPC side above
    vpnCidr = "10.0.0.0/22"
    # "private" just means no placement of IGW
    privateNets = [
      { cidr : "10.20.0.0/18", zoneId : "use2-az1" },
      { cidr : "10.20.64.0/18", zoneId : "use2-az2" }
    ]
    # "public" just means where the IGW will live
    publicNets = [
      { cidr : "10.20.128.0/24", zoneId : "use2-az1" },
      { cidr : "10.20.129.0/24", zoneId : "use2-az2" }
    ]
  }

  "us-east-1" = {
    # cidr of the entire VPC
    cidr = "10.20.0.0/16"
    # cidr used for client VPN connections; cannot overlap
    # with VPC side above
    vpnCidr = "10.0.0.0/22"
    # "private" just means no placement of IGW
    privateNets = [
      { cidr : "10.20.0.0/18", zoneId : "use1-az1" },
      { cidr : "10.20.64.0/18", zoneId : "use1-az2" }
    ]
    # "public" just means where the IGW will live
    publicNets = [
      { cidr : "10.20.128.0/24", zoneId : "use1-az1" },
      { cidr : "10.20.129.0/24", zoneId : "use1-az2" }
    ]
  }

  "us-east-2" = {
    # cidr of the entire VPC
    cidr = "10.10.0.0/16"
    # cidr used for client VPN connections; cannot overlap
    # with VPC side above
    vpnCidr = "10.0.0.0/22"
    # "private" just means no placement of IGW
    privateNets = [
      { cidr : "10.10.0.0/18", zoneId : "use2-az1" },
      { cidr : "10.10.64.0/18", zoneId : "use2-az2" }
    ]
    # "public" just means where the IGW will live
    publicNets = [
      { cidr : "10.10.128.0/24", zoneId : "use2-az1" },
      { cidr : "10.10.129.0/24", zoneId : "use2-az2" }
    ]
  }

  "eu-central-1" = {
    # cidr of the entire VPC
    cidr = "10.10.0.0/16"
    # cidr used for client VPN connections; cannot overlap
    # with VPC side above
    vpnCidr = "10.0.0.0/22"
    # "private" just means no placement of IGW
    privateNets = [
      { cidr : "10.10.0.0/18", zoneId : "euc1-az1" },
      { cidr : "10.10.64.0/18", zoneId : "euc1-az3" }
    ]
    # "public" just means where the IGW will live
    publicNets = [
      { cidr : "10.10.128.0/24", zoneId : "euc1-az1" },
      { cidr : "10.10.129.0/24", zoneId : "euc1-az3" }
    ]
  }
}

commonVpcConfigs = {
  interfaceEndpoints = [
    "elasticache",
    "ec2",
    "ec2messages",
    "ecr.api",
    "ecr.dkr",
    "autoscaling",
    "sts",
    "logs",
    "lambda",
    "ssm",
    "ssmmessages"
  ]
  gatewayEndpoints = [
    "s3"
  ]
}