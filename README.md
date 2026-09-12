# ShelfShare – Setup Instructions

Before using the project, make the configure script executable:

```sh
chmod +x ./configure
```

Then run the configure script:

```sh
./configure
```

## Local Production Compose

Local production runs Postgres behind an Envoy TCP proxy. Envoy terminates TLS
on port `15432` and forwards traffic to Postgres on the private Compose
network. The books service connects to the `envoy` service using the
`POSTGRES_PORT_TLS` value from `.env.localprod`.

Create the ignored environment file from the example and generate the local
certificate material before starting the stack:

```sh
cp .env.localprod.example .env.localprod
./scripts/generate-localprod-certs.sh
make books-localprod
```

The certificate generator creates a local CA and an Envoy certificate for
`envoy`, `localhost`, and `127.0.0.1` under `infra/certs/`. The generated files
are ignored by Git and expire after one year. Run the generator again after
removing that directory's generated files when certificates need to be
renewed. These certificates are for local use only and must not be used in
production.

To start the stack without Make, use:

```sh
docker compose --env-file .env.localprod -f docker-compose.localprod.yml up --build
```
