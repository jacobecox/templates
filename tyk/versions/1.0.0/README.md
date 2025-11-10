# Tyk API Gateway

This template creates a Tyk API Gateway for centralized API configuration. It also provisions Redis with Redis Sentinel to store gateway state, rate limits, and analytics with high availability.

## Important
Please read the instructions below carefully before configuring and installing.

## How This Template Works

Tyk stores APIs and policies as JSON files, so you must create the secrets that hold those files before or shortly after installation.

When you provide both `apiSecretName` and `policySecretName`, the template mounts those secrets into the workload and updates the identity policy accordingly. You can then manage the secrets independently, as long as the names stay consistent. If you omit either value, the associated configuration is skipped.

## Configuration

The following values should be configured in your values file:

Tyk Gateway
- `listenPort`: Port exposed on the workload
- `apiSecretName`: Secret name containing your API JSON files
- `policySecretName`: Secret name containing your policy JSON files
- `adminSecret`: Admin API Key for management of Tyk
- `resources`: Reserved resources for the workload
- `multiZone`: Deploys replicas across multiple zones (confirm availability in your location)
- `externalAccess`: Set to `true` to expose the workload to the internet; set to `false` for internal-only access
- `internalAccess`: Sets the internal firewall scope
  
Redis and Sentinel (defaults provided):
- `redis.redis`: Internal Redis for Tyk state (resources, auth, persistence)
- `redis.sentinel`: Internal Redis Sentinel (resources, auth, persistence)

**Important**: You must set strong passwords for both Redis and Sentinel

## Creating the Secrets

Follow these steps to create a secret for both the APIs and policies. This can be done after the template is installed, but it is preferred the secrets already exist when the template is installed.

### API Secret

1. Using the console, navigate to Secrets and create a new secret.

2. Name this secret the exact name you will give to the `apiSecretName` value.

3. Select type `Dictionary`.

4. For the `Key` be sure the name you give it ends with `.json` so Tyk will pick it up

5. For the `Value` insert your JSON object for your desired API.

    **Note**: For more help on creating the API JSON object, see the [Tyk API JSON Object](https://tyk.io/docs/5.0/tyk-gateway-api/api-definition-objects/) page.

6. Enter as many key/values for each API and click save.

**Note**: If the template was installed before the secrets existed, redeploy the workload after creating them.

### Policy Secret

1. Using the console, navigate to Secrets and create a new secret.

2. Name this secret the exact name you will give to the `policySecretName` value.

3. Select type `Opaque`.

4. Insert your JSON object for your desired policies.

    **Note**: For more help on creating the Policies JSON object, see the [Tyk Policy Guide](https://tyk.io/docs/5.1/basic-config-and-security/security/security-policies/policies-guide/) page.

6. Click save.

    **Note**: If the template was installed before the secrets existed, redeploy the workload after creating them.

Once the secrets are in place, Tyk automatically loads the files as APIs and policies. Restart the workload whenever you update, remove, or add API or policy definitions.

## Additional Resources

- [Tyk Docs](https://tyk.io/docs)
- [Tyk API JSON Object](https://tyk.io/docs/5.0/tyk-gateway-api/api-definition-objects/)
- [Tyk Policy Guide](https://tyk.io/docs/5.1/basic-config-and-security/security/security-policies/policies-guide/)