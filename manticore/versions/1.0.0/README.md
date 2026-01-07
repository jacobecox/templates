# Manticore Search Cluster

Deploys a stateful Manticore Search cluster with:
- Clustered replicas with automatic discovery and replication
- Plain indices imported from S3 on startup and configurable schedule
- Change detection via S3 file modification timestamps
- User-customizable index schema via secrets
- Support for RT (real-time) tables and distributed tables

## Components

| Component | Description |
|-----------|-------------|
| **Search Workload** | Stateful workload running Manticore searchd with clustering |
| **Import Trigger** | Cron workload that checks S3 for changes and triggers imports |
| **Volumeset** | Persistent storage for indices and cluster state |
| **S3 Mount** | Read-only mount of the source S3 bucket |

### Table Types

| Table | Type | Replication | Description |
|-------|------|-------------|-------------|
| `{dataset}_main` | Plain | No | Indexed data from S3 CSV (built by indexer) |
| `{dataset}_delta` | RT | Yes | Real-time table for incremental updates |
| `_import_signals` | RT | Yes | Internal table for coordinating imports |

## Prerequisites

### 1. Create an S3 Bucket

Create an S3 bucket in AWS to store your CSV source files. Note the bucket name - you'll need it for configuration.

### 2. Create a Cloud Account in Control Plane

If you don't have an AWS Cloud Account configured in Control Plane, follow the [Create a Cloud Account](https://docs.controlplane.com/guides/create-cloud-account) guide.

The cloud account establishes trust between Control Plane and your AWS account, allowing workload identities to assume IAM roles.

### 3. Create an IAM Policy in AWS for S3 Access

In the AWS Console, create an IAM policy that grants read access to your S3 bucket:

1. Go to **IAM > Policies > Create Policy**
2. Select **JSON** and paste:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ManticoreS3Read",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::YOUR_BUCKET_NAME",
                "arn:aws:s3:::YOUR_BUCKET_NAME/*"
            ]
        }
    ]
}
```

3. Replace `YOUR_BUCKET_NAME` with your actual bucket name
4. Name the policy (e.g., `manticore-s3-read-policy`)

### 4. Add the IAM Policy to Your Cloud Account

The Manticore workload identity needs permission to use this IAM policy. Add the policy reference to your cloud account:

1. In Control Plane, go to your Cloud Account settings
2. Add the IAM policy name to the allowed policies list
3. The policy name in `values.yaml` (`buckets.policyName`) must match exactly

**Note:** The template creates an identity (`{release-name}-manticore-identity`) that references:
- Your cloud account via `buckets.cloudAccountName`
- The IAM policy via `buckets.policyName`

This identity is used by both the search workload and import trigger to access the S3 bucket.

## Installation

1. Update `values.yaml` with your configuration:
   - Set `buckets.cloudAccountName` to your Cloud Account name
   - Set `buckets.policyName` to the IAM policy name
   - Set `buckets.sourceBucket` to your S3 bucket name
   - Set `import.csvPath` to the path of your CSV file in the bucket
   - Configure `import.schedule` for your desired import frequency

2. Customize `templates/secret-schema.yaml` for your data schema:
   - Update the source definition with your CSV columns
   - Adjust field types (csvpipe_field, csvpipe_attr_uint, etc.)

3. Click the **Install App** button.

## How Import Works

### Initial Import (First Boot)

When the cluster first starts:
1. Replica-0 creates the cluster and `_import_signals` table
2. If no prior imports exist and the S3 file is present, creates import signals
3. Each replica's background watcher picks up the signal and runs the import

### Scheduled Import (Cron)

The import trigger cron workload:
1. Runs on the configured schedule (default: hourly)
2. Checks the S3 file's modification time
3. Compares with the last successful import timestamp
4. If changed, creates one signal row per replica
5. Waits for all replicas to complete and reports success/failure

### Per-Replica Tracking

Each import creates N rows (one per replica) with status tracking:
- `pending` - Signal created, waiting for replica
- `running` - Replica is processing the import
- `success` - Import completed successfully
- `failed` - Import failed (check error_message)

This ensures the cron job's exit code reflects whether ALL replicas succeeded.

## Configuration

### Values Reference

| Value | Description | Default |
|-------|-------------|---------|
| `buckets.cloudAccountName` | AWS Cloud Account name | `my-s3-cloud-account` |
| `buckets.policyName` | IAM policy for S3 access | `manticore-policy` |
| `buckets.sourceBucket` | S3 bucket with CSV files | `address-source-csv` |
| `buckets.dataset` | Dataset name for tables | `addresses` |
| `import.schedule` | Cron schedule for imports | `0 * * * *` |
| `import.csvPath` | Path to CSV in S3 bucket | `data/addresses.csv` |
| `import.pollInterval` | Seconds between status checks | `10` |
| `import.pollTimeout` | Max wait for all replicas | `600` |
| `manticore.clusterName` | Manticore cluster name | `manticore` |
| `manticore.autoscaling.minScale` | Minimum replicas | `2` |
| `manticore.autoscaling.maxScale` | Maximum replicas | `4` |

### Customizing the Schema

Edit `templates/secret-schema.yaml` to define your CSV schema:

```conf
source my_data_source {
    type            = csvpipe
    csvpipe_command = cat /var/lib/manticore/import/data.csv

    # Define your columns (first column is implicit document ID)
    csvpipe_attr_uint  = my_int_field
    csvpipe_field      = my_text_field
    csvpipe_attr_float = my_float_field
}

index my_data_main {
    source     = my_data_source
    path       = /var/lib/manticore/main/my_data_main
    morphology = none
}
```

### Custom DDL

Add custom tables via `values.yaml`:

```yaml
manticore:
  customDDL: |
    -- Create additional RT table
    CREATE TABLE IF NOT EXISTS my_rt_table (
        id BIGINT,
        content TEXT,
        created_at TIMESTAMP
    ) TYPE='rt';
    ALTER CLUSTER manticore ADD my_rt_table;

    -- Create distributed table
    CREATE TABLE IF NOT EXISTS search_all TYPE='distributed'
        LOCAL='addresses_main'
        LOCAL='addresses_delta'
        LOCAL='my_rt_table';
```

## Monitoring

### Check Import Status

Connect to any replica and query the signals table:

```sql
SELECT import_id, replica_id, status, error_message,
       FROM_UNIXTIME(created_at) as created,
       FROM_UNIXTIME(completed_at) as completed
FROM _import_signals
ORDER BY import_id DESC
LIMIT 20;
```

### Check Cluster Status

```sql
SHOW STATUS LIKE 'cluster%';
```

### List Tables

```sql
SHOW TABLES;
```

## Troubleshooting

### Import Not Running

1. Check if the CSV file exists at the expected path in S3
2. Verify the cron workload is running: check job history
3. Check replica logs for import watcher errors

### Replica Not Joining Cluster

1. Verify firewall allows internal communication (`same-gvc`)
2. Check if replica-0 is healthy and cluster is created
3. Look for DNS resolution issues in logs

### Plain Index Not Building

1. Verify the schema in `secret-schema.yaml` matches your CSV
2. Check indexer output in replica logs
3. Ensure the CSV file is valid and accessible
