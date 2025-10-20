# Airflow App
Deploys Apache Airflow with CeleryExecutor using Redis as the broker and PostgreSQL database, with optional integration of KEDA for autoscaling Celery workers.

**Note on GVC Naming**

- This template creates a GVC with a default name defined in the `values.yaml`. If you plan to deploy multiple instances of this template, you **must assign a unique GVC name** for each deployment.