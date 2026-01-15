# PostgreSQL 17 Highly Available with Patroni

This app deploys a highly available PostgreSQL 17 cluster using Patroni for automatic failover and etcd for distributed consensus. The setup provides automatic leader election, health checking, and seamless failover capabilities in a single location with multi zone capability.

## Architecture

- **PostgreSQL with Patroni**: Multi-replica PostgreSQL cluster managed by Patroni
- **etcd**: Distributed key-value store for consensus and configuration allowing high availability
- **HA Proxy** (optional): Leader-routing proxy that directs write traffic to the current primary replica

## Configuration

### PostgreSQL Settings

Configure your PostgreSQL cluster in the values file:

```yaml
replicas: 3  # Number of PostgreSQL replicas (minimum 3 recommended for HA)

resources:
  cpu: 1      # CPU allocation per replica
  memory: 2Gi # Memory allocation per replica

postgres:
  username: username  # PostgreSQL username
  password: password  # PostgreSQL password
  database: test      # Initial database name
```

Configure which workloads can access PostgreSQL:

```yaml
internal_access:
  type: same-gvc  # Options: same-gvc, same-org, workload-list
  workloads:
    # Uncomment and specify workloads if using same-gvc or workload-list
    #- //gvc/GVC_NAME/workload/WORKLOAD_NAME
```

- `same-gvc`: Allow access from all workloads in the same GVC
- `same-org`: Allow access from all workloads in the organization
- `workload-list`: Allow access only from specified workloads

### etcd Configuration

The embedded etcd cluster manages cluster state and consensus:

```yaml
etcd:
  replicas: 3  # Number of etcd replicas (must be odd number, minimum 3 for HA)
  
  resources:
    cpu: 500m
    memory: 512Mi
  
  internal_access:
    type: same-gvc  # Access control for etcd cluster
```

### HA Proxy (Strongly Recommended)

In a Patroni cluster, only the leader replica accepts writes, other replicas are read-only. The HA Proxy provides a stable endpoint that automatically routes traffic to the current leader, ensuring write operations always reach the correct replica.

```yaml
proxy:
  enabled: true  # Enable leader-routing proxy
  resources:
    cpu: 100m
    memory: 128Mi
  minReplicas: 2
  maxReplicas: 2
```

**Required for:**
- **Backup feature**: The proxy must be enabled for backups to function correctly
- **External write access**: External clients must connect through the proxy to perform write operations

When enabled, connect to `{workload-name}-postgres-proxy` on port 5432 for write operations.

## Connecting to PostgreSQL

Connect to the PostgreSQL cluster using the workload name:

```
Host: {workload-name}
Port: 5432
Database: {postgres.database}
Username: {postgres.username}
Password: {postgres.password}
```

### Internal psql Connection

When testing, you can connect internally using `psql`. If doing so, use the replica-specific hostname.

## Important Notes

- **Minimum Replicas**: For production use, maintain at least 3 PostgreSQL replicas and 3 etcd replicas
- **Odd Number for etcd**: Always use an odd number of etcd replicas (3, 5, 7) for proper quorum
- **Resource Allocation**: Ensure adequate CPU and memory resources for both PostgreSQL and etcd workloads
- **Persistent Storage**: Each replica uses dedicated volume storage for data persistence

## Backing Up

**Note:** The HA Proxy must be enabled (`proxy.enabled: true`) for backups to function correctly.

Set your desired backup schedule in the values file and configure your AWS S3 or GCS bucket. You can also set a prefix where your backups will be stored in the bucket.

### AWS S3

For the cron job to have access to a S3 bucket, ensure the following prerequisites are completed in your AWS account before installing:

1. Create your bucket. Update the value `bucket` to include its name and `region` to include its region.

2. If you do not have a Cloud Account set up, refer to the docs to [Create a Cloud Account](https://docs.controlplane.com/guides/create-cloud-account). Update the value `cloudAccountName`.

3. Create a new policy with the following JSON (replace `YOUR_BUCKET_NAME`)

```JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetObjectVersion",
                "s3:DeleteObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::YOUR_BUCKET_NAME",
                "arn:aws:s3:::YOUR_BUCKET_NAME/*"
            ]
        }
    ]
}
```

4. Update `cloudAccountName` in your values file with the name of your Cloud Account.

5. Set `policyName` to match the policy created in step 3.

### GCS

For the cron job to have access to a GCS bucket, ensure the following prerequisites are completed in your GCP account before installing:

1. Create your bucket. Update the value `bucket` to include its name.

2. If you do not have a Cloud Account set up, refer to the docs to [Create a Cloud Account](https://docs.controlplane.com/guides/create-cloud-account). Update the value `cloudAccountName`.

**Important**: You must add the `Storage Admin` role when creating your GCP service account.

## Restoring Backup

Run the following command with password from a client with access to the bucket. Set `WORKLOAD_NAME` to match the proxy workload so restores write to the leader.

S3
```SH
export PGPASSWORD="PASSWORD"

aws s3 cp "s3://BUCKET_NAME/PREFIX/BACKUP_FILE.sql.gz" - \
  | gunzip \
  | psql \
      --host=WORKLOAD_NAME \
      --port=5432 \
      --username=USERNAME \
      --dbname=postgres

unset PGPASSWORD
```

GCS
```SH
export PGPASSWORD="PASSWORD"

gsutil cp "gs://BUCKET_NAME/PREFIX/BACKUP_FILE.sql.gz" - \
  | gunzip \
  | psql \
      --host=WORKLOAD_NAME \
      --port=5432 \
      --username=USERNAME \
      --dbname=postgres

unset PGPASSWORD
```

## Supported External Services

- [Patroni Documentation](https://patroni.readthedocs.io/)
- [Postgres Doccumentation](https://www.postgresql.org/docs/)
- [etcd Documentation](https://etcd.io/docs/v3.6/)