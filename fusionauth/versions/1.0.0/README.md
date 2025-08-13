# FusionAuth

## Overview
FusionAuth is a modern, self-hosted identity and access management platform that provides user authentication, authorization, and secure single sign-on. It supports protocols such as OAuth2, OpenID Connect, and SAML.

### Getting Started
1. **Automatic Database Setup**: A PostgreSQL database is automatically created and connected to FusionAuth. No manual database configuration required.

2. **Setup and Integration**: Follow the setup wizard in the FusionAuth admin panel to create your app.

**Note:** For simplified integration, Control Plane offers an [integration file](insert file here) to handle the backend communication to FusionAuth. If using this file, follow the instructions below to properly set up URLs and environment variables.

### Integration Configuration

#### FusionAuth Admin Panel Configuration
In the FusionAuth admin panel, configure your application with these URLs:

**Authorized redirect URLs:**
- `https://YOUR_BACKEND_APP/callback`
- `https://YOUR_BACKEND_APP`

**Authorized request origin URL:**
- `https://YOUR_BACKEND_APP`

**Logout URL:**
- `https://YOUR_BACKEND_APP` (redirect user to home page after login)

#### Backend Application Environment Variables
If using our backend integration file, add the following environment variables to your backend workload:

```yaml
env:
  - name: FUSIONAUTH_URL
    value: YOUR_FUSIONAUTH_URL
  - name: CLIENT_ID
    value: YOUR_FUSIONAUTH_CLIENT_ID
  - name: CLIENT_SECRET
    value: YOUR_FUSIONAUTH_CLIENT_SECRET
  - name: LOGIN_REDIRECT_URI
    value: https://YOUR_BACKEND_APP/callback
  - name: LOGOUT_REDIRECT_URI
    value: https://YOUR_BACKEND_APP
  - name: PORT
    value: YOUR_PORT
```

### Identity Provider (IdP) Configuration
FusionAuth allows easy integration for Identity Providers (IdP) to your login interface. To allow sign in with Google, enable Google OAuth integration by setting

`identityProviders.google.enabled: true`

This will automatically configure the necessary firewall rules for Google OAuth services.

Use the FusionAuth admin panel to configure your IdP.

**Note**: If using any IdP, you must configure a domain name for your FusionAuth workload with the following headers for proper header forwarding to FusionAuth:
- X-Forwarded-Host: YOUR_DOMAIN_NAME
- X-Forwarded-Port: '443'
- X-Forwarded-Proto: https

Be sure to configure your app's tenant to use the proper issuer for issuing tokens (e.g. `https://my-fusionauth-app.io`)

## Access
Once deployed, FusionAuth will be accessible on port 9011 with the following endpoints:
- Health endpoint: `/health`
- Default admin interface: `/admin`

## Additional Resources
- [FusionAuth Documentation](https://fusionauth.io/docs/)
- [FusionAuth GitHub](https://github.com/FusionAuth/fusionauth-containers)