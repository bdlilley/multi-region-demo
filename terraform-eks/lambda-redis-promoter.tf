resource "aws_lambda_function" "redis-promoter-us-east-1" {
  provider = aws.us-east-1

  function_name = "aws-global-elasticache-promoter"

  # source can be found here https://github.com/bdlilley/aws-global-elasticache-promoter
  filename         = "${path.module}/lambda/aws-global-elasticache-promoter.zip"
  runtime          = "go1.x"
  handler          = "aws-global-elasticache-promoter"
  role             = aws_iam_role.redis-promoter-us-east-1.arn
  source_code_hash = filebase64sha256("${path.module}/lambda/aws-global-elasticache-promoter.zip")

  vpc_config {
    subnet_ids = [for sn in module.vpc-us-east-1.privateSubnets : sn.id]
    security_group_ids = [
      module.vpc-us-east-1.commonSecurityGroup.id,
      module.vpc-us-east-1.interfaceSecurityGroup.id,
    ]
  }

  environment {
    variables = {
      HOSTED_ZONE_ID = aws_route53_zone.private.id
      # this name is set in kubernetes service annoations for the mgmt plane
      DNS_NAME            = "mgmt.ha-demo.vpc"
      GLOBAL_DATASTORE_ID = aws_elasticache_global_replication_group.redis-global.id
    }
  }
}

resource "aws_iam_role" "redis-promoter-us-east-1" {
  provider = aws.us-east-1

  name = "redis-promoter-us-east-1"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "redis-promoter-us-east-1" {
  name = "redis-promoter-us-east-1"
  role = aws_iam_role.redis-promoter-us-east-1.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "route53:List*",
          "elasticache:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}


resource "aws_iam_role_policy_attachment" "redis-promoter-us-east-1" {
  role       = aws_iam_role.redis-promoter-us-east-1.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_cloudwatch_event_rule" "redis-promoter-us-east-1" {
  provider            = aws.us-east-1
  name                = "every-one-minutes"
  description         = "Fires every one minutes"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "redis-promoter-us-east-1" {
  provider  = aws.us-east-1
  rule      = aws_cloudwatch_event_rule.redis-promoter-us-east-1.name
  target_id = "redis-promoter-us-east-1"
  arn       = aws_lambda_function.redis-promoter-us-east-1.arn
}

resource "aws_lambda_permission" "redis-promoter-us-east-1" {
  provider      = aws.us-east-1
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redis-promoter-us-east-1.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.redis-promoter-us-east-1.arn
}

## region 2

resource "aws_lambda_function" "redis-promoter-us-east-2" {
  provider = aws.us-east-2

  function_name = "aws-global-elasticache-promoter"

  # source can be found here https://github.com/bdlilley/aws-global-elasticache-promoter
  filename         = "${path.module}/lambda/aws-global-elasticache-promoter.zip"
  runtime          = "go1.x"
  handler          = "aws-global-elasticache-promoter"
  role             = aws_iam_role.redis-promoter-us-east-2.arn
  source_code_hash = filebase64sha256("${path.module}/lambda/aws-global-elasticache-promoter.zip")

  vpc_config {
    subnet_ids = [for sn in module.vpc-us-east-2.privateSubnets : sn.id]
    security_group_ids = [
      module.vpc-us-east-2.commonSecurityGroup.id,
      module.vpc-us-east-2.interfaceSecurityGroup.id,
    ]
  }

  environment {
    variables = {
      HOSTED_ZONE_ID = aws_route53_zone.private.id
      # this name is set in kubernetes service annoations for the mgmt plane
      DNS_NAME            = "mgmt.ha-demo.vpc"
      GLOBAL_DATASTORE_ID = aws_elasticache_global_replication_group.redis-global.id
    }
  }
}

resource "aws_iam_role" "redis-promoter-us-east-2" {
  provider = aws.us-east-2

  name = "redis-promoter-us-east-2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "redis-promoter-us-east-2" {
  name = "redis-promoter-us-east-2"
  role = aws_iam_role.redis-promoter-us-east-2.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "route53:List*",
          "elasticache:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}


resource "aws_iam_role_policy_attachment" "redis-promoter-us-east-2" {
  role       = aws_iam_role.redis-promoter-us-east-2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_cloudwatch_event_rule" "redis-promoter-us-east-2" {
  provider            = aws.us-east-2
  name                = "every-one-minutes"
  description         = "Fires every one minutes"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "redis-promoter-us-east-2" {
  provider  = aws.us-east-2
  rule      = aws_cloudwatch_event_rule.redis-promoter-us-east-2.name
  target_id = "redis-promoter-us-east-2"
  arn       = aws_lambda_function.redis-promoter-us-east-2.arn
}

resource "aws_lambda_permission" "redis-promoter-us-east-2" {
  provider      = aws.us-east-2
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redis-promoter-us-east-2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.redis-promoter-us-east-2.arn
}
