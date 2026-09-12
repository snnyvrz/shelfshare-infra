# Agent Instructions

This is the ShelfShare infrastructure repository. Application source code,
tests, Dockerfiles, image builds, and application CI live in
`snnyvrz/shelfshare`.

## Repository Shape

- `ansible/` provisions hosts, WireGuard, K3s, and Flux bootstrap.
- `apps/` contains application deployment manifests only.
- `charts/` contains reusable Helm charts.
- `clusters/` contains Flux entry points for local and production.
- `compose/` contains local infrastructure dependencies only.
- `platform/` contains shared controllers, networking, storage, and sources.

Do not add application source or image-building workflows here.

## Secrets

Files matching `*.sops.*` are encrypted repository secrets. Never commit
decrypted secrets. Use the repository's configured SOPS workflow when editing
encrypted manifests.

## Validation

Validate Helm charts with `helm lint`, render clusters with
`kustomize build clusters/local` and `kustomize build clusters/production`,
and run Ansible syntax checks before deployment changes.
