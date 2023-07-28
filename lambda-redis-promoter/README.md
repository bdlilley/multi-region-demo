# lambba redis promoter

Manages promotion of Global Elasticache datastores from secondary to primary based on route53 failover recordset status.  This lambda is intended to be run on a CloudWatch event.

### Design

The lambda should be deployed to each region that has a datastore member.  Global Elasticache is limited to 2 regions, so for example if you deployed the primary member to us-east-1 and the secondary member to us-east-2, you would deploy this lambda to us-east-1 and us-east-2.  The lambda must exist in both regions to protect against entire region failure.

Each lambda will attempt to modify the current primary member only if the supplied DNS name resolves to a resource in the same region as the lambda, and that member is not the current primary.

The lambda is configured with a DNS name it should check for changes.  Recordsets for the DNS name are cached in global memory along with the region of each aliased target.  Data store members are also stored in global memory.

**Global memory cache refresh**

To prevent rate limits of the AWS api, the recordsets and data store members are only updated in two cases after the lambda starts:

* the IP addresss returned from a DNS query for the supplied domain do not match either target from the failover recordset
* the primary or secondary member of the global data store cannot be found

Global memory is safe to be used in this way; once initialized, the lamba code will only be executed in serial.