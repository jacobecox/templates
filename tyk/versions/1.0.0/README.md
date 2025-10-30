## Coraza WAF with Tyk API Gateway

Creates a Coraza Web Application Firewall (WAF) with OWASP Core Rule Set (CRS) integration that proxies traffic to a target workload, providing comprehensive security filtering and protection. This template also includes a fully configured Tyk API Gateway for path-based API routing. Incoming traffic flows through Coraza first (WAF), then to the Tyk Gateway, and finally to your target workloads.

### Configuration

The following values can be configured in your values file:

- `endpoints`: A list of API routes for Tyk to proxy
  - `name`: Unique endpoint name
  - `workload`: Target workload DNS (`WORKLOAD_NAME.GVC_NAME.cpln.local`)
  - `port`: Target workload port
  - `path`: Public listen path (e.g., `/app1`)
- `WAFPort`: The port on the WAF workload to expose to the internet
- `resources`: Reserved resources for the workload
- `multiZone`: Deploys replicas across multiple zones
  
Redis and Sentinel (required; defaults provided):
- `redis.redis`: Internal Redis for Tyk state (resources, auth, persistence)
- `redis.sentinel`: Internal Redis Sentinel (resources, auth, persistence)

**Important**: You must set strong passwords for both Redis and Sentinel:

### Logging

All Coraza logging is currently sent to `/dev/stdout` to be readable in the Control Plane built-in logging interface. Logging can be redirected by using the existing environment variables in the workload configuration.

### Advanced Configuration

Coraza configuration is largely specified through environment variables and can be customized by the user once installed. You can modify these environment variables in the workload configuration to adjust Coraza's behavior, logging levels, and security policies according to your specific requirements. For details on the environment variables, see the resources below.

### Usage

The Coraza WAF will act as a reverse proxy, filtering incoming requests before forwarding them to the Tyk Gateway, which routes to your target workloads. Configure `endpoints` to define path-based routes that map to your internal workloads. The WAF will be accessible on the specified `WAFPort`.

**Important**: The target workloads must be configured with internal firewall access set to `same-gvc`, `same-org`, or specifically allow this workload in order for the WAF to reach it.

### Security Features

Coraza provides web application firewall capabilities including:
- Automatic integration of OWASP Core Rule Set (CRS) for comprehensive protection
- Request filtering and validation
- Protection against common web attacks
- Custom rule configuration
- Traffic monitoring and logging

### Custom Rules

After installation, you can add custom rules by editing the created secret with the suffix `coraza-custom-rules`. The secret contains an example rule that blocks requests containing "attack" in the URI:

```
SecRule REQUEST_URI "@rx attack" "id:1001,phase:1,deny,msg:'Blocked attack attempt'"
```

**Note**: After modifying the custom rules secret, you must restart the workload replicas for the changes to take effect. See the Coraza and CRS documentation below for instructions on creating custom rules.

## Additional Resources

- [OWASP Coraza Docs](https://coraza.io/docs/tutorials/introduction/)
- [OWASP CRS Docs](https://coreruleset.org/docs/)
- [Coraza Caddy README](https://github.com/coreruleset/coraza-crs-docker#)
- [Tyk Docs](https://tyk.io/docs)