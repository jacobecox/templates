# Release Notes - Version 1.0.1

## What's New

- **Extra Arguments Support**: Added `extraArgs` configuration for both Redis and Sentinel, allowing custom command-line arguments to be passed at startup
  - Redis example: `extraArgs: "--maxclients 20000 --maxmemory 200mb --maxmemory-policy allkeys-lru"`
  - Sentinel example: `extraArgs: "--sentinel down-after-milliseconds mymaster 5000 --sentinel failover-timeout mymaster 10000"`
- **Customizable Server Command**: Added `serverCommand` option for Redis to override the startup command (default: `redis-server`)
- **Configurable Images**: Added `image` configuration for both Redis and Sentinel to specify custom container images (default: `redis:7.2`)