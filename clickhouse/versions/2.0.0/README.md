# ClickHouse

This template deploys a ClickHouse cluster with ClickHouse Keeper for coordination.

ClickHouse is a high-performance column-oriented analytical database designed for real-time querying and data warehousing at scale. Storage includes:

- Primary object storage - long-term scalable storage (AWS S3 or GCS)

- Scratch volume - fast local read cache for performance

- Volumeset - persistent metadata, state, and system files

## Configuration

Before installing, update `values.yaml` with the parameters relevant to your environment:

- **GVC name**: Assign a name for the Global Virtual Cloud.

- **Locations**: Define replica counts per location (affects server workload distribution).

- **Cluster Name**: Assign a cluster name. Used in distributed DDL queries.

- **Storage**: Choose AWS S3 or GCS and fill in configuration values under that section.

**Note on GVC Naming**
  - This template creates a GVC automatically with a name defined in `values.yaml`. If deploying multiple independent ClickHouse clusters, **you must use a unique GVC name** for each deployment.

## Setting Up Storage

### AWS S3

For ClickHouse to have access to a S3 bucket, ensure the following prerequisites are completed in your AWS account before installing:

1. Create your bucket. Update the value `bucket` to include it's name and `region` to include it's region.

2. Run the following CLI command for guidance on setting up required AWS resources.

**Important**: For the steps given from the command, skip step 2 from the generated instructions — this template automatically creates the Cloud Account. In the trust policy (step 4), add your role ARN in addition to the `controlplane-driver` entries. 

```SH
cpln cloudaccount create-aws --org ORG_NAME --how
```


3. Create a new policy with the following JSON and attach it to the role (replace `YOUR_BUCKET_NAME`)

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

4. Update `roleArn` in your values file with the IAM role ARN you created.

5. Set `policyName` to match the policy created in step 3.

### GCS

GCS support will be available in a future release.

## Connecting to ClickHouse

To connect using the ClickHouse client:

```SH
clickhouse-client --host $WORKLOAD_NAME --password $PASSWORD
```

### Supported External Services

[ClickHouse Documentation](https://clickhouse.com/docs/).
[Cloud Accounts Documentation](https://docs.controlplane.com/guides/create-cloud-account#overview)