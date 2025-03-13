## External Secret Syncer (ESS)

### Overview
Creates an application that continuously syncs secrets/parameters from external apps into Control Plane secrets. If you store your secrets externally, you can use this app to automatically keep Control Plane configuration options up to date. 


### Supported External Services
- <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html" target="_blank">AWS Systems Manager Parameter Store</a>
- <a href="https://aws.amazon.com/secrets-manager/" target="_blank">AWS Secrets Manager</a>
- <a href="https://www.hashicorp.com/en/products/vault" target="_blank">Vault</a>