# Local Infrastructure

The application repository owns service development and image builds. This
directory contains only local infrastructure dependencies used by those
services.

Start PostgreSQL and MongoDB with:

```sh
docker compose --env-file .env -f compose/infra.yml up -d
```
