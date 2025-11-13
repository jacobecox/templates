# Tyk API Gateway

Tyk API Gateway is an open-source API management platform that controls, secures, and monitors API traffic.

This template creates a Tyk API Gateway workload, the entry point that routes and manages API traffic. It also provisions Redis which operates as the backing store for tokens, analytics, rate-limits, and state, and Redis Sentinel which provides automatic Redis failover and high availability.

## Important
Please read the instructions below carefully before configuring and installing.

## How This Template Works

Tyk organizes configuration into two key components:

**API Definitions** - describe individual APIs, including routes, rate limits, authentication, and upstream targets

**Policies** - define higher-level access rules and rate limits that can apply across multiple APIs

Both of these are provided to Tyk as JSON files, which this template expects to be mounted from Control Plane secrets.

You must pre-configure each of these and store them as Control Plane secrets (see directions below).

When you provide both `apiSecretName` and `policySecretName` (the names of your pre-configured Control Plane secrets) in the values file, the template mounts those secrets into the workload and updates the workload identity's policy. You can then manage the secrets independently, as long as the names stay consistent. If you use the default values, be sure the secrets you create use the same name.

## Configuration

The following values should be configured in your values file:

### Tyk Gateway:
- `listenPort`: The port exposed on the Tyk workload
- `apiSecretName`: The name of the Control Plane secret containing your API definitions
- `policySecretName`: The name of the Control Plane secret containing your policies
- `adminSecret`: The value you set to be the admin API key for management of Tyk
- `resources`: Desired CPU and memory reserved for the workload
- `multiZone`: Deploys replicas across multiple zones (confirm availability in your location)
- `externalAccess`: Set to `true` to expose the workload to the internet; set to `false` for internal-only access
- `internalAccess`: Sets the internal firewall scope
  
### Redis and Sentinel:
- `redis.redis`: Configuration for the Redis workload including resources (CPU and memory), replica count, password, and firewall settings
- `redis.sentinel`: Configuration for the Sentinel workload including resources (CPU and memory), replica count, password, and firewall settings
**Note**: The defaults provided for both Redis and Sentinel are sufficient for this template's purpose.

## Creating the Secrets

### API Secret

1. Using the console, navigate to Secrets and create a new secret.

2. Name this secret the exact name you will give to the `apiSecretName` value.

3. Select type `Dictionary`.

4. For the `Key` be sure the name you give it ends with `.json` so Tyk will pick it up

5. For the `Value` insert your JSON object for your desired API.

    **Note**: For more help on creating the API JSON object, see the [Tyk API JSON Object](https://tyk.io/docs/5.0/tyk-gateway-api/api-definition-objects/) page.

6. Repeat for each API and click save.

Example secret:

<img src="https://github.com/jacobecox/images/raw/13ccbab70f0abfc795b097fa25c40fac95b92bd6/tyk-api-example.png" alt="tyk-api-secret-example" width="400"/>

**Note**: If the template was installed before the secrets existed, redeploy the workload after creating them.

### Policy Secret

1. Using the console, navigate to Secrets and create a new secret.

2. Name this secret the exact name you will give to the `policySecretName` value.

3. Select type `Opaque`.

4. Insert your JSON object for your desired policies.

    **Note**: For more help on creating the Policies JSON object, see the [Tyk Policy Guide](https://tyk.io/docs/5.1/basic-config-and-security/security/security-policies/policies-guide/) page.

6. Click save.

    **Note**: If the template was installed before the secrets existed, redeploy the workload after creating them.

Once the secrets are in place, Tyk automatically loads the files as APIs and policies. Restart the workload whenever you update, remove, or add API definitions or policies.

## Additional Resources

- [Tyk Docs](https://tyk.io/docs)
- [Tyk API JSON Object](https://tyk.io/docs/5.0/tyk-gateway-api/api-definition-objects/)
- [Tyk Policy Guide](https://tyk.io/docs/5.1/basic-config-and-security/security/security-policies/policies-guide/)