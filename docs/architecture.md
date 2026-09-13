# Architecture

`shelfshare-infra` is the deployment and operations repository for ShelfShare.
Application source, tests, Dockerfiles, and image builds live in
`snnyvrz/shelfshare`.

- `ansible/` provisions hosts, WireGuard, K3s, and Flux bootstrap.
- `clusters/` contains Flux entry points for each environment.
- `platform/` contains shared cluster resources and chart sources.
- `apps/` contains application HelmReleases and encrypted runtime secrets.
- `charts/` contains reusable Helm charts.
- `terraform/` contains cloud provisioning when a provider is active.
