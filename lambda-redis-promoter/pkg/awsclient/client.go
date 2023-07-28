package awsclient

import (
	"context"
	"fmt"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials/stscreds"
	"github.com/aws/aws-sdk-go-v2/service/cloudcontrol"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/ec2/types"
	"github.com/aws/aws-sdk-go-v2/service/eks"
	"github.com/aws/aws-sdk-go-v2/service/elasticache"
	"github.com/aws/aws-sdk-go-v2/service/resourcegroupstaggingapi"
	"github.com/aws/aws-sdk-go-v2/service/route53"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"github.com/aws/aws-sdk-go/aws/arn"
	"github.com/rotisserie/eris"
)

const (
	stsService         = "sts"
	iamService         = "iam"
	roleResourcePrefix = "role"
)

func NewAwsClient(ctx context.Context, region string, roleToAssume string) (*AwsClient, error) {
	cfg, err := awsconfig.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, eris.Wrap(err, "failed to load default aws config from environment")
	}

	if region != "" {
		cfg.Region = region
	}

	c := &AwsClient{
		cfg:                      cfg,
		sts:                      sts.NewFromConfig(cfg),
		resourcegroupstaggingapi: resourcegroupstaggingapi.NewFromConfig(cfg),
		regionName:               cfg.Region,
	}

	currentIdentity, err := c.sts.GetCallerIdentity(context.TODO(), &sts.GetCallerIdentityInput{})
	if err != nil {
		return nil, fmt.Errorf("failed to get current aws identity: %s", err)
	}

	if !strings.EqualFold(roleToAssume, "") {
		shouldAssumeRole := true
		if currentIdentity.Arn != nil {
			currentRole, err := assumedRoleToRole(*currentIdentity.Arn)
			if err != nil {
				return nil, eris.Wrapf(err, "failed to parse role arn for '%s'", *currentIdentity.Arn)
			}

			if strings.EqualFold(currentRole, roleToAssume) {
				shouldAssumeRole = false
			}
		}
		if shouldAssumeRole {
			creds := stscreds.NewAssumeRoleProvider(c.sts, roleToAssume)
			cfg.Credentials = aws.NewCredentialsCache(creds)
		}
	}

	return c, nil
}

func (c *AwsClient) Elasticache() *elasticache.Client {
	if c.elasti == nil {
		c.elasti = elasticache.NewFromConfig(c.cfg)
	}
	return c.elasti
}

func (c *AwsClient) EC2() *ec2.Client {
	if c.ec2 == nil {
		c.ec2 = ec2.NewFromConfig(c.cfg)
	}
	return c.ec2
}

func (c *AwsClient) R53() *route53.Client {
	if c.r53 == nil {
		c.r53 = route53.NewFromConfig(c.cfg)
	}
	return c.r53
}

func (c *AwsClient) EKS() *eks.Client {
	if c.eks == nil {
		c.eks = eks.NewFromConfig(c.cfg)
	}
	return c.eks
}

func (c *AwsClient) CloudControl() *cloudcontrol.Client {
	if c.cc == nil {
		c.cc = cloudcontrol.NewFromConfig(c.cfg)
	}
	return c.cc
}

func (c *AwsClient) GetRegions(ctx context.Context) ([]types.Region, error) {
	result, err := c.EC2().DescribeRegions(ctx, &ec2.DescribeRegionsInput{})
	if err != nil {
		return nil, err
	}
	return result.Regions, nil
}

func assumedRoleToRole(assumedRole string) (string, error) {
	roleArn, err := arn.Parse(assumedRole)
	if err != nil {
		return "", err
	}

	if roleArn.Service == stsService {
		roleArn.Service = "iam"
	}

	if roleArn.Service != iamService {
		return "", fmt.Errorf("invalid service for role: %s", roleArn.Service)
	}

	role, err := resourceToRole(roleArn.Resource)
	if err != nil {
		return "", eris.Wrap(err, "could not parse role from resource")
	}
	roleArn.Resource = role

	return roleArn.String(), nil
}

func resourceToRole(resource string) (string, error) {
	resourceArr := strings.Split(resource, "/")
	if len(resourceArr) < 2 {
		return "", fmt.Errorf("invalid resource format for role: %s", resource)
	}

	if resourceArr[0] == "assumed-role" {
		resourceArr[0] = "role"
	}

	if resourceArr[0] != roleResourcePrefix {
		return "", fmt.Errorf("invalid resource type for role: %s", resourceArr[0])
	}

	return strings.Join(resourceArr[:2], "/"), nil
}
