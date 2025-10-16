## etcd

etcd is a distributed, reliable key-value store for the most critical data of a distributed system. It provides a reliable way to store data that needs to be accessed by a distributed system or cluster of machines. etcd is essential for maintaining cluster health by providing consistent coordination, service discovery, and configuration management across distributed systems.

### Configuring etcd

Update the `values.yaml` file with your settings:

- **`replicas`**: Number of etcd instances (default: 3, must be odd)
- **`resources.cpu`**: CPU per instance (default: 1 vCPU)
- **`resources.memory`**: Memory per instance (default: 2 GB RAM)
- **`internal_access.type`**: Internal firewall access (`same-gvc`, `same-org`, or `workload-list`)
- **`internal_access.workloads`**: Specific workloads (when using `workload-list` or `same-gvc`)
- **`multiZone`**: Distributes replicas equally across available zones

### Supported External Services
- [etcd docs](https://etcd.io/docs/v3.6/)