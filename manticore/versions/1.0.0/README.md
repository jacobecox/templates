# Manticore Search Cluster

Deploys a distributed Manticore Search cluster on Control Plane with:
- **Stateful replicas** with automatic Galera-based clustering and replication
- **Dual-slot import system** (main_a/main_b) for zero-downtime data updates
- **Intelligent cluster orchestration** with automatic initialization, recovery, and repair
- **Multi-table support** with independent schemas and import configurations
- **Web UI** for cluster monitoring and management
- **Load testing** with k6 for performance validation

## Architecture

### Components

| Component | Type | Description |
|-----------|------|-------------|
| **Manticore Workload** | Stateful | Clustered Manticore searchd instances with agent sidecar |
| **Agent** | Sidecar | Per-replica HTTP API for local operations (init, import, health, repair) |
| **Orchestrator API** | Standard | Continuous REST API for cluster-wide coordination |
| **Orchestrator** | Cron | On-demand job execution (imports, maintenance) |
| **UI** | Standard | Web dashboard for cluster monitoring and management |

### How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Orchestrator API                               │
│    (cluster-wide coordination, init decisions, import scheduling)           │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
          ┌───────────────────────────┼───────────────────────────┐
          │                           │                           │
          ▼                           ▼                           ▼
┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
│  Replica-0          │   │  Replica-1          │   │  Replica-N          │
│ ┌─────────────────┐ │   │ ┌─────────────────┐ │   │ ┌─────────────────┐ │
│ │  Agent (8080)   │ │   │ │  Agent (8080)   │ │   │ │  Agent (8080)   │ │
│ └────────┬────────┘ │   │ └────────┬────────┘ │   │ └────────┬────────┘ │
│          │          │   │          │          │   │          │          │
│ ┌────────▼────────┐ │   │ ┌────────▼────────┐ │   │ ┌────────▼────────┐ │
│ │ Manticore (9306)│ │   │ │ Manticore (9306)│ │   │ │ Manticore (9306)│ │
│ └─────────────────┘ │   │ └─────────────────┘ │   │ └─────────────────┘ │
│         │           │   │         │           │   │         │           │
│    ┌────▼────┐      │   │    ┌────▼────┐      │   │    ┌────▼────┐      │
│    │Volumeset│      │   │    │Volumeset│      │   │    │Volumeset│      │
│    └─────────┘      │   │    └─────────┘      │   │    └─────────┘      │
└─────────────────────┘   └─────────────────────┘   └─────────────────────┘
          ▲                         ▲                         ▲
          └─────────────────────────┴─────────────────────────┘
                        Galera Cluster Replication
```

### Table Structure (Per Dataset)

Each table configured in `values.yaml` creates:

| Table | Type | Replicated | Purpose |
|-------|------|------------|---------|
| `{name}_main_a` | Plain | Optional* | Primary data slot (indexed from CSV) |
| `{name}_main_b` | Plain | Optional* | Secondary data slot (for zero-downtime swap) |
| `{name}_delta` | RT | Yes | Real-time updates between imports |
| `{name}` | Distributed | No | Query aggregator across main + delta |

*Main table replication controlled by `config.clusterMain` per table.

### Dual-Slot Import System

The orchestrator uses an A/B slot system for zero-downtime imports:

1. **Identify inactive slot**: If `main_a` is active, target `main_b` (or vice versa)
2. **Import to inactive**: Build new index in the inactive slot
3. **Atomic swap**: Update `{name}` to point to the new slot
4. **Cleanup**: Drop old slot data (optional)

This ensures queries are never interrupted during imports.

## Cluster Initialization

When replicas start, the agent calls the orchestrator API's `/api/init` endpoint. The orchestrator evaluates cluster state and returns one of:

| Action | Condition | What Happens |
|--------|-----------|--------------|
| **bootstrap** | No existing cluster, replica-0 | Creates new cluster |
| **join** | Cluster exists, new replica | Joins existing cluster |
| **rejoin** | Cluster exists, known replica | Rejoins with existing UUID |
| **continue** | Already in cluster | No action needed |

The orchestrator uses `grastate.dat` files (Galera state) to make safe decisions about cluster topology, preventing split-brain scenarios.

## Prerequisites

### 1. S3 Bucket

Create an S3 bucket to store your CSV source files.

### 2. Control Plane Cloud Account

Follow the [Create a Cloud Account](https://docs.controlplane.com/guides/create-cloud-account) guide to establish trust between Control Plane and your AWS account.

## Installation

1. **Configure S3 access** in `values.yaml`:
   ```yaml
   buckets:
     cloudAccountName: your-cloud-account
     awsPolicyRefs:
       - aws::AmazonS3ReadOnlyAccess  # or your custom policy
     sourceBucket: your-bucket-name
   ```

2. **Define your tables**:
   ```yaml
   tables:
     - name: products # table name
       csvPath: imports/products/data.csv
       config:
         haStrategy: noerrors      # HA strategy for distributed table
         agentRetryCount: 3        # Retries for agent connections
         clusterMain: false        # Whether to replicate main tables
         importMethod: indexer     # indexer or sql
       schema:
         columns:
           - name: title
             type: field
           - name: price
             type: attr_float
   ```

3. **Generate an authentication token**:
   ```bash
   openssl rand -base64 32
   ```
   Set this in `orchestrator.agent.token`. This bearer token secures communication between all orchestrator components (see [Authentication](#authentication) below).

**Note:** After installation, Manticore will show as healthy and the cluster will be initialized, but tables will be empty until you run an import job. See [Operations](#operations) below to trigger your first import either manually or via schedule.

## Authentication

All internal API communication is secured with a shared bearer token configured in `orchestrator.agent.token`. This token authenticates:

| Communication Path | Purpose |
|--------------------|---------|
| Orchestrator API → Agent | Coordinated imports, health checks |
| Agent → Orchestrator API | Cluster init requests at startup |
| UI → Orchestrator API | Dashboard operations (import, repair) |

**Token requirements:**
- Must be set before deployment (required field)
- Should be cryptographically random (use `openssl rand -base64 32`)
- Rotating the token requires redeploying all components simultaneously

**How it's used:**
- Stored in the `{release-name}-manticore-agent-token` secret
- Injected into workloads via `cpln://secret/{release-name}-manticore-agent-token.payload`
- Passed in the `Authorization: Bearer {token}` header for API requests

**Security note:** The UI automatically injects this token when communicating with the Orchestrator API. This means anyone with network access to the UI can perform administrative operations (imports, repairs, etc.). Control access to the UI by:
- Setting `orchestrator.ui.allowExternalAccess: false` to restrict to internal GVC access only
- Using a domain with authentication if external access is required
- Limiting network access via firewall rules

## Configuration Reference

### Core Settings

| Path | Description | Default |
|------|-------------|---------|
| `buckets.cloudAccountName` | AWS Cloud Account name | - |
| `buckets.sourceBucket` | S3 bucket with CSV files | - |
| `manticore.clusterName` | Galera cluster name | `manticore` |
| `manticore.autoscaling.minScale` | Minimum replicas | `3` |
| `manticore.autoscaling.maxScale` | Maximum replicas | `4` |

### Table Configuration

Each entry in `tables[]` supports:

| Field | Description |
|-------|-------------|
| `name` | Table name (used for `{name}_main_a`, etc.) |
| `csvPath` | Path to CSV in S3 bucket |
| `config.haStrategy` | HA strategy: `noerrors`, `nodeads`, etc. |
| `config.agentRetryCount` | Retry count for distributed queries |
| `config.clusterMain` | Replicate main tables across cluster |
| `config.importMethod` | Import method: `indexer` or `sql` |
| `schema.columns` | Column definitions for csv-to-manticore |

### Column Types

| Type | Description |
|------|-------------|
| `field` | Full-text searchable field |
| `field_string` | Full-text field (string variant) |
| `attr_uint` | Unsigned integer attribute |
| `attr_bigint` | Big integer attribute |
| `attr_float` | Float attribute |
| `attr_bool` | Boolean attribute |
| `attr_string` | String attribute (not full-text indexed) |
| `attr_timestamp` | Timestamp attribute |
| `attr_multi` | Multi-value integer attribute |
| `attr_multi_64` | Multi-value 64-bit integer attribute |
| `attr_json` | JSON attribute |

**Note**: If column 1 is numeric, it's used as the document ID (don't declare it). If not numeric, an ID is auto-generated.

### Orchestrator Settings

| Path | Description | Default |
|------|-------------|---------|
| `orchestrator.schedule` | Cron schedule for imports | `0 * * * *` |
| `orchestrator.action` | Action: `init`, `import`, `health`, `repair` | `import` |
| `orchestrator.tableName` | Table to import | - |
| `orchestrator.suspend` | Start suspended | `true` |
| `orchestrator.agent.token` | Bearer token for auth | **required** |

## API Endpoints

All API endpoints (except health/ready probes) require authentication via the bearer token configured in `orchestrator.agent.token`:

```
Authorization: Bearer {token}
```

### Orchestrator API (`/api/...`)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/status` | GET | No | Health check (used by readiness probe) |
| `/api/init` | POST | Yes | Initialize/bootstrap cluster |
| `/api/import` | POST | Yes | Trigger coordinated import |
| `/api/repair` | POST | Yes | Repair cluster state |
| `/api/cluster` | GET | Yes | Cluster topology info |
| `/api/tables/status` | GET | Yes | Table status across replicas |

### Agent API (per-replica, port 8080)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/health` | GET | No | Replica health |
| `/api/ready` | GET | No | Readiness probe |
| `/api/tables` | GET | Yes | Local table list |
| `/api/cluster/status` | GET | Yes | Local cluster status |
| `/api/import/{table}` | POST | Yes | Import specific table |

## Operations

### Triggering Operations

Operations can be triggered via the **Orchestrator UI** or the **Control Plane API**.

#### Via Orchestrator UI

The web dashboard provides buttons for common operations:
- **Import**: Select a table and click "Start Import" to trigger a coordinated import
- **Repair**: Click "Repair Cluster" from the Dashboard to recover from split-brain
- **Health Check**: View real-time cluster and replica status

#### Via Control Plane API

Operations are executed by running the orchestrator cron workload with the `runCronWorkload` command. The `ACTION` environment variable determines what operation runs.

**Trigger an import:**
```bash
# Run orchestrator cron with ACTION=import (configured in values.yaml)
cpln workload run-cron {release-name}-orchestrator-job --gvc {gvc-name}
```

**Important:** If you plan to scale Manticore replicas, run imports with the maximum number of replicas active. This ensures all replicas have the imported data when new replicas are added during autoscaling. The orchestrator coordinates imports across all active replicas, so scaling up after an import may leave new replicas without the main table data.

**Trigger a repair:**
First update the orchestrator workload's `ACTION` env var to `repair`, then:
```bash
cpln workload run-cron {release-name}-orchestrator-job --gvc {gvc-name}
```

Or use the REST API directly:
```bash
curl -X POST "https://api.cpln.io/org/{org}/gvc/{gvc}/workload/{release-name}-orchestrator-job/-runCronWorkload" \
  -H "Authorization: Bearer $AUTH_TOKEN"
```

### Cluster Repair

If replicas lose sync (split-brain, network partition):

1. **Via UI**: Navigate to Dashboard and click "Repair Cluster"
2. **Via Control Plane**: Run the orchestrator cron with `ACTION=repair`

The repair process:
1. Identifies all replica states via grastate.dat
2. Selects the best source replica (highest seqno, safe_to_bootstrap)
3. Rebuilds cluster from the source

### Monitoring

**Via Orchestrator UI**:
- **Dashboard**: Cluster health, replica status, split-brain detection
- **Tables**: Per-table status, row counts, slot info across replicas
- **Imports**: Import history and progress

**Via MySQL** (connect to any replica on port 9306):
```sql
-- Cluster status
SHOW STATUS LIKE 'cluster%';

-- Table list
SHOW TABLES;

-- Check specific table
SELECT * FROM products LIMIT 10;
```

## Troubleshooting

### Replica Not Joining Cluster

1. Check agent logs for init action response
2. Verify firewall allows `same-gvc` internal access
3. Review the "Dashboard" page in the UI to check for a split brain scenario. Run a repair operation from the dashbaord if necessary.

### Import Failures

1. Verify CSV exists at configured path in S3
2. Check agent logs for import errors
3. Verify schema columns match CSV structure
4. Check available memory (imports require memory for indexing)

### Split-Brain Recovery

1. Open the Orchestrator UI Dashboard to view cluster state
2. Click "Repair Cluster" or run the orchestrator cron with `ACTION=repair` via Control Plane
3. Monitor the orchestrator logs for source replica selection
4. Verify all replicas rejoin with same cluster UUID in the UI

## Load Testing

Enable k6 load testing to validate search performance:

```yaml
loadTest:
  enabled: true
  vus: 10
  duration: "5m"
  query:
    index: products
    query:
      match:
        "*": "test"
```

**Trigger load tests:**
- **Via Control Plane**: Run the load-test-controller cron workload:
  ```bash
  cpln workload run-cron {release-name}-load-test-controller --gvc {gvc-name}
  ```
- **On a schedule**: Set `loadTest.controller.schedule` to a cron expression (e.g., `"0 2 * * *"` for daily at 2am)

## Backup & Restore

The orchestrator provides cloud storage backup and restore for **delta tables** (real-time data that accumulates between imports).

### How It Works

**Backup:**
1. Triggers a cron workload that connects to a Manticore replica
2. Exports delta table data via `mysqldump` (INSERT statements only)
3. Compresses and uploads to S3 with timestamped filename: `{dataset}_delta-{timestamp}.sql.gz`

**Restore:**
1. Downloads the selected backup file from S3
2. Clears existing delta table data
3. Replays the SQL inserts with cluster prefix for proper replication

> **Note:** Backups only include delta table data. Main table data is re-imported from S3 source files via the import process.

### Prerequisites

#### 1. S3 Bucket for Backups

Create a dedicated S3 bucket (or use a prefix in an existing bucket) for storing backups.

#### 2. IAM Policy

Create a new AWS IAM policy with the following JSON (replace `YOUR_BUCKET_NAME`):

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
                "arn:aws:s3:::YOUR_BUCKET_NAME",
                "arn:aws:s3:::YOUR_BUCKET_NAME/*"
            ]
        }
    ]
}
```

Reference this policy in `orchestrator.backup.s3Policy`.

#### 3. Cloud Account

The backup workload needs a Cloud Account with the above policy attached. This can be the same account used for source data or a separate one.

### Configuration

Enable backups in `values.yaml`:

```yaml
orchestrator:
  backup:
    enabled: true
    cloudAccountName: my-backup-cloud-account  # Cloud Account with S3 write access
    s3Bucket: my-backup-bucket
    s3Policy:
      - my-backup-policy    # IAM policy name from above
    s3Region: us-east-1
    dataSet: products       # Dataset name (table name without _delta suffix)
    prefix: manticore-backups
    schedule: "0 2 * * *"   # Daily at 2am (optional)
    startSuspended: false
```

### Usage

#### Via Orchestrator UI

1. Navigate to the **Dashboard**
2. **Backup**: Click "Backup Table" with a selected table to trigger a backup
3. **Restore**: Click "Restore Table", select a backup file from the list, and confirm

#### Via API

**Trigger a backup:**
```bash
curl -X POST "https://{orchestrator-api-url}/api/backup" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"tableName": "products"}'
```

**List available backups:**
```bash
curl "https://{orchestrator-api-url}/api/backups/files?tableName=products" \
  -H "Authorization: Bearer {token}"
```

**Restore from backup:**
```bash
curl -X POST "https://{orchestrator-api-url}/api/restore" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"tableName": "products", "filename": "products_delta-2024-01-28T22-50-49Z.sql.gz"}'
```

### API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/backups` | Get active backup operations |
| GET | `/api/backups/files?tableName={name}` | List backup files for a table |
| POST | `/api/backup` | Trigger backup for a table's delta |
| POST | `/api/restore` | Restore a table from backup |

### Clustered Table Considerations

Manticore clustered tables require special handling that the backup/restore process manages automatically:

- **Cluster prefix**: All write operations use `cluster:tablename` format for proper replication
- **No DROP/CREATE**: Clustered tables cannot be dropped; backups contain only INSERT statements
- **No TRUNCATE**: Data is cleared via `DELETE FROM table WHERE id > 0`
- **Single-node writes**: Writes target one replica; data replicates automatically to all nodes

## Supported External Services
- [Manticore Search Docs](https://manual.manticoresearch.com/)
- [Orchestrator, Agent, UI and Backup source code](https://github.com/controlplane-com/manticore-orchestrator)