# ClickHouse

This template creates a ClickHouse cluster with ClickHouse Keeper coordination.

ClickHouse is a columnar database management system designed for real-time analytical data processing and data warehousing. This deployment includes both ClickHouse Server and ClickHouse Keeper components for distributed coordination.

## Configuration

Before installing, update the values file with your desired configuration:

- **Database settings**: Configure database name and password in the `database` section
- **Resources**: Adjust CPU and memory for both server and keeper workloads
- **Locations**: Configure replica counts per location (affects server workload only)
- **GVC name**: Set your desired GVC name

**Note on GVC Naming**
  - This template creates a GVC with a default name defined in the `values.yaml`. If you plan to deploy multiple instances of this template, you **must assign a unique GVC name** for each deployment.

## Important Notes

- **Keeper Replicas**: ClickHouse Keeper always runs with 3 total replicas (1 per location) for proper raft coordination, use minimum 3 locations for high availability between Keeper nodes.
- **Multi-location**: This deployment supports multiple locations for high availability
- **Ports**: 
  - ClickHouse Server: 8123 (HTTP for client), 9000 (TCP), 9009 (HTTP between server nodes)
  - ClickHouse Keeper: 9181 (TCP for servers), 9234 (TCP between keeper nodes)

## Connecting to Clickhouse Client

If connecting via `clickhouse-client`, use the following command:

`clickhouse-client --host $WORKLOAD_NAME --user $USERNAME$ --password $PASSWORD`

## Creating a Table

- To create a table that supports replication and sharding, use a command similar to this one

```SQL
CREATE TABLE <table_name> (
    <columns>
)
ENGINE = ReplicatedMergeTree('<keeper_path>/<shard>', '<replica_name>')
ORDER BY <primary_key>;
```

**Note**: Creating a table across all replicas using distributed DDL is not supported. Once a table is created across each replica, sharding and replication of data will be automatic.

### Supported External Services

[ClickHouse Documentation](https://clickhouse.com/docs/).