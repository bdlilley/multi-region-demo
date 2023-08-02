resource "aws_security_group" "common-us-east-1" {
  provider = aws.us-east-1

  name        = "${var.resourcePrefix}-common"
  description = "common sg"
  vpc_id      = module.vpc-us-east-1.vpc.id

  ingress {
    description = "all from vpc"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc-us-east-1.vpc.cidr_block, module.vpc-us-east-2.vpc.cidr_block]
  }

  egress {
    description = "all to vpc"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc-us-east-1.vpc.cidr_block, module.vpc-us-east-2.vpc.cidr_block]
  }

  egress {
    description = "https to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resourcePrefix}-common"
  }
}

resource "aws_security_group" "common-us-east-2" {
  provider = aws.us-east-2

  name        = "${var.resourcePrefix}-common"
  description = "common sg"
  vpc_id      = module.vpc-us-east-2.vpc.id

  ingress {
    description = "all from vpc"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc-us-east-1.vpc.cidr_block, module.vpc-us-east-2.vpc.cidr_block]
  }

  egress {
    description = "all to vpc"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc-us-east-1.vpc.cidr_block, module.vpc-us-east-2.vpc.cidr_block]
  }

  egress {
    description = "https to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resourcePrefix}-common"
  }
}