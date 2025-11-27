# FusionAuth

## Overview
FusionAuth is a modern, self-hosted identity and access management platform that provides user authentication, authorization, and secure single sign-on. It supports protocols such as OAuth2, OpenID Connect, and SAML.

### Getting Started
1. **Automatic Database Setup**: A PostgreSQL database is automatically created and connected to FusionAuth. No manual database configuration required.

2. **Identity Provider Configuration**: FusionAuth allows easy integration for Identity Providers (IdP) to your login interface. To allow sign in with Google, enable Google OAuth integration by setting `identityProviders.google.enabled: true`

    - This will automatically configure the necessary firewall rules for Google OAuth services. Use the FusionAuth admin panel to configure your IdP.

3. **Setup and Integration**: Follow the setup wizard in the FusionAuth admin panel to create your app.
    - Configure your application with the corresponding `origin`, `redirect`, and `logout` URLs to your code
    - Be sure to configure your app's tenant to use the proper issuer for issuing tokens (e.g. `my-fusionauth-app.io`)

## Additional Resources
- [FusionAuth Documentation](https://fusionauth.io/docs/)
- [FusionAuth GitHub](https://github.com/FusionAuth/fusionauth-containers)