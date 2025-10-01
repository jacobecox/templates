## etcd App

etcd is a distributed, reliable key-value store for the most critical data of a distributed system. It provides a reliable way to store data that needs to be accessed by a distributed system or cluster of machines. etcd is essential for maintaining cluster health by providing consistent coordination, service discovery, and configuration management across distributed systems.

### Key Features

- **Distributed**: etcd is designed to be distributed across multiple nodes for high availability
- **Consistent**: Provides strong consistency guarantees for all operations
- **Reliable**: Built-in leader election and automatic failover capabilities

### Accessing etcd

Workloads are allowed to access etcd based on the `internal-access` you specify in `values.yaml`. You can learn more about it in our [documentation](https://docs.controlplane.com/reference/workload#internal).

### Supported External Services
- [etcd Docs](https://etcd.io/docs/v3.6/)