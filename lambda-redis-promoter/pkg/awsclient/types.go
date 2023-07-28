package awsclient

import (
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/cloudcontrol"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/eks"
	"github.com/aws/aws-sdk-go-v2/service/elasticache"
	"github.com/aws/aws-sdk-go-v2/service/resourcegroupstaggingapi"
	"github.com/aws/aws-sdk-go-v2/service/route53"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

type AwsClient struct {
	cfg                      aws.Config
	ec2                      *ec2.Client
	eks                      *eks.Client
	sts                      *sts.Client
	r53                      *route53.Client
	elasti                   *elasticache.Client
	resourcegroupstaggingapi *resourcegroupstaggingapi.Client
	cc                       *cloudcontrol.Client
	regionName               string
}
