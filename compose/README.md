# Local Infrastructure

The application repository owns service development and image builds. This
directory contains only local infrastructure dependencies used by those
services.

Start PostgreSQL and MongoDB with:

```sh
docker compose --env-file .env -f compose/infra.yml up -d
```

Tests must use disposable credentials. Copy `.env.test.example` to a temporary
directory or generate an equivalent environment file as part of the test
setup; do not use deployment secrets or a checked-in `.env` file.

For example:

```sh
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
cp compose/.env.test.example "$tmp_dir/.env"
docker compose --env-file "$tmp_dir/.env" -f compose/infra.yml up -d
```
