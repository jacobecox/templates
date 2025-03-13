## External Secret Syncer (ESS)

### Overview
Creates an application that continuously syncs secrets/parameters from external apps into Control Plane secrets. If you store your secrets externally, you can use this app to automatically keep Control Plane configuration options up to date. 


### Supported External Services
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Vault](https://www.hashicorp.com/en/products/vault)