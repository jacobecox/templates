# Control Plane Templates

### Purpose
Templates are used by Control Plane users to quickly deploy applications such as databases, queues, and even stateless apps.

### How templates works
Each template provides a Helm chart that makes deployment quick and easy. Each templates has metadata in its root folder, describing the template. The following are required components within each template folder:

- icon.jpg (512p x 512p)
- config.yaml
- README.md
- versions (folder)
  
### Schema for config.yaml


    slug: name-goes-here
    date-published: YYYY-MM-DD
    description: long description that explains the benefits of the templated artifact.
    latest-stable-version: <name of folder under /versions>
    docs: link to docs

