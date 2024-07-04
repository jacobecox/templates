# Control Plane Templates

### Purpose

Templates are used by Control Plane users to quickly deploy applications such as databases, queues, and even stateless apps.

### How templates works

Each template provides a Helm chart that makes deployment quick and easy. Each templates has metadata in its root folder, describing the template. The following are required components within each template folder:

- icon.png

No resolution restriction, it will always be rendered in a square space
Make sure that the background is not filled with a color, should be transparent.

- config.yaml
- README.md
- versions

A parent folder that contains all versions with each having it's own folder

### Schema for config.yaml

    name: unique-name-goes-here
    date-published: YYYY-MM-DD
    description: long description that explains the benefits of the templated artifact.
    latest: <name of folder under /versions>

Visit [Control Plane](https://controlplane.com) to learn about the platform.
