# ShelfShare Infrastructure

Deployment and operations configuration for ShelfShare. Application source,
tests, Dockerfiles, image builds, and application CI live in
[`snnyvrz/shelfshare`](https://github.com/snnyvrz/shelfshare).

## Layout

- `ansible/`: host configuration, WireGuard, K3s, and Flux bootstrap
- `apps/`: application HelmReleases and encrypted runtime secrets
- `charts/`: reusable Helm charts
- `clusters/`: Flux entry points for local and production
- `compose/`: local infrastructure dependencies
- `platform/`: shared controllers, networking, storage, and chart sources
- `docs/`: setup, architecture, backup, restore, and troubleshooting

Production uses K3s and Flux. Compose is for local infrastructure only.
