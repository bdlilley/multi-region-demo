resource "aws_route53_zone" "private" {
  name = var.privateHzName

  vpc {
    vpc_id     = module.vpc-us-east-1.vpc.id
    vpc_region = "us-east-1"
  }

  vpc {
    vpc_id     = module.vpc-us-east-2.vpc.id
    vpc_region = "us-east-2"
  }
}