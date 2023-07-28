package dns

import (
	"bytes"
	"net"
	"sort"
	"time"
)

type FailoverRecordSet struct {
	DnsName     string
	Records     []*FailoverRecord
	LastUpdated *time.Time
}

type FailoverRecord struct {
	Region             string
	AliasTargetDnsName string
	AliasTargetDnsZone string
	SortedIPs          []net.IP
}

func (f *FailoverRecordSet) FindRecord(ips []net.IP) *FailoverRecord {
	sort.Slice(ips, func(i, j int) bool {
		return bytes.Compare(ips[i], ips[j]) < 0
	})
	for _, rs := range f.Records {
		if areSortedEqual(rs.SortedIPs, ips) {
			return rs
		}
	}
	return nil
}

func areSortedEqual(a []net.IP, b []net.IP) bool {
	if len(a) != len(b) {
		return false
	}

	for i := 0; i < len(a); i++ {
		if !a[i].Equal(b[i]) {
			return false
		}
	}
	return true
}
