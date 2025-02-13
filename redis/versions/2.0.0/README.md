## Redis Sentinel App

This app creates a Redis sentinel cluster on Control Plane Platform.

### Accessing redis

Workloads are allowed to access Redis based on the `firewallConfig` you specify. You can learn more about in our [documentation](https://docs.controlplane.com/reference/workload#internal).

#### Option 1:

Syntax: <WORKLOAD_NAME>
```
redis-cli -c -h {workload-name} -p 6379 set mykey "test"
redis-cli -c -h {workload-name} -p 6379 get mykey
```
#### Option 2: (By replica)

Syntax: <REPLICA_NAME>.<WORKLOAD_NAME>
```
redis-cli -c -h {workload-name}-0.{workload-name} -p 6379 set mykey "test"
redis-cli -c -h {workload-name}-1.{workload-name} -p 6379 get mykey
```
