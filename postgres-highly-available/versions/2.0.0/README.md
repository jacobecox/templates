# PostgreSQL 17 Highly Available with Patroni

This app deploys a highly available PostgreSQL 17 cluster using Patroni for automatic failover and etcd for distributed consensus. The setup provides automatic leader election, health checking, and seamless failover capabilities.

## Architecture

- **PostgreSQL with Patroni**: Multi-replica PostgreSQL cluster managed by Patroni
- **etcd**: Distributed key-value store for consensus and configuration allowing high availability

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

## Supported External Services

- [Patroni Documentation](https://patroni.readthedocs.io/)
- [Postgres Doccumentation](https://www.postgresql.org/docs/)