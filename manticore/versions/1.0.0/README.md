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
| **Agent** | Sidecar | Per-replica HTTP API for local operations (init, import, health) |
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

### 3. IAM Policy for S3 Access

Create an IAM policy granting read access to your bucket:

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

### 4. Add Policy to Cloud Account

Add the IAM policy to your Control Plane Cloud Account's allowed policies list.

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
     - name: products
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

4. **Click Install App**.

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
- Stored in the `{release-name}-agent-token` secret
- Injected into workloads via `cpln://secret/{release-name}-agent-token.payload`
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
| `config.haStrategy` | HA strategy: `noerrors`, `nodeadlines`, etc. |
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
| `attr_json` | JSON attribute |

**Note**: If column 1 is numeric, it's used as the document ID (don't declare it). If not numeric, an ID is auto-generated.

### Orchestrator Settings

| Path | Description | Default |
|------|-------------|---------|
| `orchestrator.schedule` | Cron schedule for imports | `0 * * * *` |
| `orchestrator.action` | Action: `init`, `import`, `health` | `import` |
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
cpln workload run-cron {release-name}-orchestrator --gvc {gvc-name}
```

**Trigger a repair:**
First update the orchestrator workload's `ACTION` env var to `repair`, then:
```bash
cpln workload run-cron {release-name}-orchestrator --gvc {gvc-name}
```

Or use the REST API directly:
```bash
curl -X POST "https://api.cpln.io/org/{org}/gvc/{gvc}/workload/{release-name}-orchestrator/-runCronWorkload" \
  -H "Authorization: Bearer $CPLN_TOKEN"
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
