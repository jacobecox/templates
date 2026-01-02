## Manticore Search

Deploys Manticore Search with a query workload and two ingester cron jobs (main and delta) for building and updating search indexes from CSV data stored in S3.

## Architecture

- **Query Workload**: A scalable workload that serves search queries, pulling index artifacts from S3.
- **Main Ingester**: Cron job that builds the full index from a main CSV file (runs monthly by default).
- **Delta Ingester**: Cron job that builds incremental index updates from a delta CSV file (runs hourly by default).

## Prerequisites

### 1. Create Two S3 Buckets

You need two S3 buckets in AWS:

| Bucket | Purpose |
|--------|---------|
| **Source Bucket** | Stores the CSV files to be indexed (e.g., `main/addresses_main.csv`, `delta/addresses_delta.csv`) |
| **Artifact Bucket** | Stores the generated index artifacts that the query workload fetches |

### 2. Configure a Cloud Account

If you don't have an AWS Cloud Account configured, refer to the docs to [Create a Cloud Account](https://docs.controlplane.com/guides/create-cloud-account).

### 3. Create a Custom IAM Policy in AWS

Create a new IAM policy with the following JSON (replace `SOURCE_BUCKET_NAME` and `ARTIFACT_BUCKET_NAME` with your bucket names):

```json
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
                "arn:aws:s3:::SOURCE_BUCKET_NAME",
                "arn:aws:s3:::SOURCE_BUCKET_NAME/*",
                "arn:aws:s3:::ARTIFACT_BUCKET_NAME",
                "arn:aws:s3:::ARTIFACT_BUCKET_NAME/*"
            ]
        }
    ]
}
```

## Installation

1. Update `values.yaml` with your configuration:
   - Set `buckets.cloudAccountName` to your Cloud Account name
   - Set `buckets.policyName` to the IAM policy name created above
   - Set `buckets.awsRegion` to your S3 bucket region
   - Set `buckets.sourceBucket` and `buckets.artifactBucket` to your bucket names
   - Configure CSV paths and schedules for the ingesters

2. Click the **Install App** button.

## Initial Setup

**Important**: After installation, both ingester cron jobs must be triggered manually to build the initial index files before the query workload can serve search requests.

1. Navigate to the **main ingester** workload and trigger the cron job manually.
2. Navigate to the **delta ingester** workload and trigger the cron job manually.

Once the initial indexes are built and uploaded to the artifact bucket, the query workload will automatically pull them. After this initial setup, the cron jobs will run according to their configured schedules.

## Configuration

| Value | Description |
|-------|-------------|
| `buckets.cloudAccountName` | Name of your AWS Cloud Account |
| `buckets.policyName` | Name of the IAM policy with S3 access |
| `buckets.awsRegion` | AWS region of your S3 buckets |
| `buckets.dataset` | Dataset name for the index |
| `buckets.sourceBucket` | S3 bucket containing CSV source files |
| `buckets.artifactBucket` | S3 bucket for storing index artifacts |
| `ingester.main.csvPath` | Path to the main CSV file in the source bucket |
| `ingester.main.jobSchedule` | Cron schedule for main index builds |
| `ingester.delta.csvPath` | Path to the delta CSV file in the source bucket |
| `ingester.delta.jobSchedule` | Cron schedule for delta index builds |
| `query.autoscaling.*` | Autoscaling settings for the query workload |

