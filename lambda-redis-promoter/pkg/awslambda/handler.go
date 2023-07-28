package awslambda

import (
	"bytes"
	"context"
	"fmt"
	"net"
	"os"
	"regexp"
	"sort"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/elasticache"
	awseltypes "github.com/aws/aws-sdk-go-v2/service/elasticache/types"
	"github.com/aws/aws-sdk-go-v2/service/route53"
	"github.com/bensolo-io/multi-region-demo/lambda-redis-promoter/pkg/awsclient"
	"github.com/bensolo-io/multi-region-demo/lambda-redis-promoter/pkg/config"
	"github.com/bensolo-io/multi-region-demo/lambda-redis-promoter/pkg/dns"
	"github.com/rotisserie/eris"
	"github.com/rs/zerolog/log"
)

var recordSet *dns.FailoverRecordSet
var cfg config.Config
var regionRegexp *regexp.Regexp = regexp.MustCompile(`\.([a-zA-Z0-9\-]+)\.amazonaws.com\.`)
var client *awsclient.AwsClient
var myRegion string = os.Getenv("AWS_REGION")
var currentPrimaryMember, currentSecondaryMember *awseltypes.GlobalReplicationGroupMember

func NewHandlerFunc(envConfig config.Config) (func(event interface{}) error, error) {
	ctx := context.TODO()
	cfg = envConfig
	var err error
	client, err = awsclient.NewAwsClient(ctx, "", "")
	if err != nil {
		return nil, eris.Wrap(err, "failed to create aws client")
	}

	recordSet, err = getRecordSet(ctx)
	if err != nil {
		return nil, eris.Wrapf(err, "failed to fetch recordset for %s (%s)", cfg.HostedZoneID, cfg.DnsName)
	}

	if err = setRSMembers(ctx); err != nil {
		return nil, err
	}

	return HandleLambdaEvent, nil
}

func HandleLambdaEvent(event interface{}) error {
	ctx := context.TODO()

	ips, err := net.LookupIP(cfg.DnsName)
	if err != nil {
		if dErr, ok := err.(*net.DNSError); ok {
			if dErr.IsNotFound {
				log.Debug().Msgf("host %s not found", cfg.DnsName)
			}
		} else {
			return err
		}
	}

	matchedRs := recordSet.FindRecord(ips)
	if matchedRs == nil {
		// try to refresh once when result doens't match any rs
		recordSet, err = getRecordSet(ctx)
		if err != nil {
			return eris.Wrapf(err, "failed to fetch recordset for %s (%s)", cfg.HostedZoneID, cfg.DnsName)
		}
		matchedRs = recordSet.FindRecord(ips)
		if matchedRs == nil {
			log.Debug().Msgf("could not find any matching recordset for domain %s, ip list %v", cfg.DnsName, ips)
			return nil
		}
	}

	log.Debug().Msgf("domain %s resolves to recordset %v", cfg.DnsName, matchedRs)

	if strings.EqualFold(myRegion, matchedRs.Region) {
		log.Debug().Msgf("recordset %v belongs to my region %s", matchedRs, myRegion)
		if err = checkRedis(ctx); err != nil {
			return err
		}
	}

	return nil
}

func checkRedis(ctx context.Context) error {
	if strings.EqualFold(myRegion, *currentPrimaryMember.ReplicationGroupRegion) {
		log.Debug().Msgf("no action required, current primary member %s matches my region %s", *currentPrimaryMember.ReplicationGroupId, myRegion)
		return nil
	}

	log.Debug().Msgf("promotion required; dns name %s resolves to my region %s, but current primary member %s does not belong to this region", cfg.DnsName, myRegion, *currentPrimaryMember.ReplicationGroupId)
	_, err := client.Elasticache().FailoverGlobalReplicationGroup(ctx, &elasticache.FailoverGlobalReplicationGroupInput{
		GlobalReplicationGroupId:  &cfg.GlobalDataStoreId,
		PrimaryRegion:             currentSecondaryMember.ReplicationGroupRegion,
		PrimaryReplicationGroupId: currentSecondaryMember.ReplicationGroupId,
	})
	if err != nil {
		return err
	}
	log.Debug().Msgf("member %s promoted to primary in region %s", *currentSecondaryMember.ReplicationGroupId, *currentSecondaryMember.ReplicationGroupRegion)

	// update the members now that swap has occured
	return setRSMembers(ctx)
}

func setRSMembers(ctx context.Context) error {
	result, err := client.Elasticache().DescribeGlobalReplicationGroups(ctx, &elasticache.DescribeGlobalReplicationGroupsInput{
		GlobalReplicationGroupId: &cfg.GlobalDataStoreId,
		ShowMemberInfo:           aws.Bool(true),
	})
	if err != nil {
		return err
	}

	if len(result.GlobalReplicationGroups) == 0 {
		return fmt.Errorf("could not find global data store with id %s", cfg.GlobalDataStoreId)
	}

	grg := result.GlobalReplicationGroups[0]

	currentPrimaryMember = nil
	currentSecondaryMember = nil
	for _, member := range grg.Members {
		if strings.EqualFold(*member.Role, "PRIMARY") {
			currentPrimaryMember = &member
		}
		if strings.EqualFold(*member.Role, "SECONDARY") {
			currentSecondaryMember = &member
		}
		log.Debug().Msgf("added rg member %s %s %s", *member.ReplicationGroupId, *member.ReplicationGroupRegion, *member.Role)
	}

	if currentPrimaryMember == nil || currentSecondaryMember == nil {
		return fmt.Errorf("could not find secondary or primary member for replication group %s", cfg.GlobalDataStoreId)
	}

	return nil
}

func getRecordSet(ctx context.Context) (*dns.FailoverRecordSet, error) {
	rs := &dns.FailoverRecordSet{}

	pager := route53.NewListResourceRecordSetsPaginator(client.R53(), &route53.ListResourceRecordSetsInput{
		HostedZoneId: &cfg.HostedZoneID,
	})

	for pager.HasMorePages() {
		result, err := pager.NextPage(ctx)
		if err != nil {
			return nil, err
		}
		for _, item := range result.ResourceRecordSets {
			name := strings.TrimRight(*item.Name, ".")
			if strings.EqualFold(cfg.DnsName, name) {
				if item.AliasTarget != nil {
					m := regionRegexp.FindStringSubmatch(*item.AliasTarget.DNSName)
					// not aliased to a regional resource
					if len(m) != 2 {
						log.Debug().Msgf("found record %s in hz %s, but it does not have a regional alias target", *item.Name, cfg.HostedZoneID)
						continue
					}
					log.Debug().Msgf("record %s in hz %s is in region %s aliased to %s", *item.Name, cfg.HostedZoneID, m[1], *item.AliasTarget.DNSName)

					ips, err := net.LookupIP(*item.AliasTarget.DNSName)
					if err != nil {
						if dErr, ok := err.(*net.DNSError); ok {
							if dErr.IsNotFound {
								log.Debug().Msgf("host %s not found", cfg.DnsName)
								// dont add the recordset until it's resolvable
								continue
							}
						} else {
							return nil, err
						}
					}

					sort.Slice(ips, func(i, j int) bool {
						return bytes.Compare(ips[i], ips[j]) < 0
					})

					newRecord := &dns.FailoverRecord{
						Region:             m[1],
						AliasTargetDnsName: *item.AliasTarget.DNSName,
						AliasTargetDnsZone: *item.AliasTarget.HostedZoneId,
						SortedIPs:          ips,
					}

					rs.Records = append(rs.Records, newRecord)
					log.Info().Msgf("added new record %s, %v", newRecord.AliasTargetDnsName, ips)
				}
			}
		}
	}
	return rs, nil
}
