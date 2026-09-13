# Setup

Install the required tooling with `./configure`, then configure SOPS age keys
for encrypted manifests. Local development infrastructure is started with the
Compose files under `compose/`. Production is provisioned with Ansible and
reconciled by Flux on K3s.

## SOPS workflow

Tracked `*.sops.*` files must remain encrypted in the working tree. Normal
validation and tests must not decrypt them in place or decrypt the whole
repository.

To decrypt selected files for a command, create an empty temporary directory
and provide it explicitly:

```sh
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
./scripts/sops.sh decrypt --output-dir "$tmp_dir" \
  apps/books-service/secret.sops.yaml
```

The source file is never modified. The output directory must be temporary and
must be removed after the consuming command finishes. `decrypt` refuses to run
without explicit file paths. Use `encrypt-staged` to protect staged secret
files; do not use in-place decryption as part of tests.

Tests should use the disposable credentials in `compose/.env.test.example`,
copied or generated under a temporary directory and cleaned up on exit.
