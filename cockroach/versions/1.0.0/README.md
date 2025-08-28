# CockroachDB

CockroachDB is a distributed SQL database built on a transactional and strongly-consistent key-value store. It provides automatic replication, distribution, and survivability across multiple locations with minimal latency and maximum throughput. CockroachDB offers ACID transactions, horizontal scalability, and built-in fault tolerance, making it ideal for applications requiring global data distribution and high availability.

## Configuration

To configure your CockroachDB cluster across multiple locations, update the `gvc.locations` section in the `values.yaml` file:

### Database Initialization

To create a database with a user on initialization, configure the `database` section in your `values.yaml` file:

```yaml
database:
  name: mydb
  user: myuser
```

This will automatically create the specified database and user when the CockroachDB cluster is first deployed.

**Note**: Password creation is not required as CockroachDB grants access to users based on firewall restrictions. Other workloads given internal access can connect without authentication. It is important not to expose this workload externally.

### Internal Access Configuration

To specify which workloads can access this CockroachDB cluster internally, configure the `internal_access` section in your `values.yaml` file:

```yaml
internal_access:
  type: same-gvc
  workloads:
    - //gvc/my-gvc/workload/my-app-backend
    - //gvc/my-gvc/workload/my-api-service
```

**Access Types:**
- `same-gvc`: Allow access from all workloads in the same GVC
- `same-org`: Allow access from all workloads in the same organization
- `workload-list`: Allow access only from specific workloads listed in `outside_workloads` and can be used in conjunction with `same-gvc`


Once deployed, CockroachDB will be available on Port 26257 (default)

The cluster automatically handles data distribution and replication across your configured locations.

### Supported External Services
- [CockroachDB Documentation](https://www.cockroachlabs.com/docs/stable/)