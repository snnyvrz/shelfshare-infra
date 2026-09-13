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

## Operations

The commands below assume that `kubectl`, `flux`, `ansible-playbook`, `sops`,
and `age` are installed. Run Ansible commands from the `ansible/` directory.
Backups and private keys must remain outside this repository.

### Rebuild the cluster

Before rebuilding, make sure the PostgreSQL backup, the SOPS age private key,
and the Ansible inventory variables are available. Confirm that the inventory
contains the intended hosts and that the encrypted variables can be decrypted.

Provision K3s and the host configuration with:

```sh
cd ansible
ansible-playbook -i inventories/hetzner/hosts.ini playbooks/site.yml
```

After the servers are ready, install and bootstrap Flux for production:

```sh
ansible-playbook -i inventories/hetzner/hosts.ini playbooks/flux_install_server.yml
```

Set `KUBECONFIG` to the rebuilt cluster's kubeconfig if it is not already the
default configuration, then verify the cluster and Flux reconciliation:

```sh
kubectl get nodes
flux get all -A
kubectl get pods -A
```

Flux reads `clusters/production` from the `main` branch and recreates the
platform and application resources. Do not manually apply the entire cluster
directory unless recovering from a Flux installation problem.

### Supply the SOPS age key

The encrypted manifests are addressed to the age recipient in `.sops.yaml`,
but decryption requires the corresponding private key. Obtain that key through
the approved secret-management process and write it to a protected file on the
operator machine. Never commit the key or a decrypted `*.sops.*` file.

```sh
install -d -m 700 "$HOME/.config/sops/age"
# Place the private key in this file using your approved secret-management process.
chmod 600 "$HOME/.config/sops/age/keys.txt"
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
```

Test access without decrypting a tracked file in place:

```sh
cd ..
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
./scripts/sops.sh decrypt --output-dir "$tmp_dir" \
  platform/storage/postgres-values.sops.yaml
```

For Ansible, supply the same environment to the command that reads encrypted
inventory variables, or configure the Ansible/SOPS integration used by the
operator environment. The public age recipient is safe to store in Git; the
private key is not.

### Restore PostgreSQL

Restore only after the PostgreSQL HelmRelease is healthy and the persistent
volume is mounted. The release runs in the `shelfshare-localprod` namespace.
Store the dump outside Git and set these shell variables to the credentials and
database name from the approved backup procedure:

```sh
namespace=shelfshare-localprod
pod="$(kubectl get pods -n "$namespace" \
  -l app.kubernetes.io/instance=shelfshare-postgres \
  -o jsonpath='{.items[0].metadata.name}')"
db_name='REPLACE_WITH_DATABASE_NAME'
db_user='REPLACE_WITH_DATABASE_USER'
dump_file='/path/to/backup.dump'
```

Check the target before restoring:

```sh
kubectl get helmrelease shelfshare-postgres -n "$namespace"
kubectl get pod "$pod" -n "$namespace"
```

For a custom-format dump created with `pg_dump -Fc`, stream it into
`pg_restore`:

```sh
kubectl exec -i -n "$namespace" "$pod" -- \
  pg_restore --clean --if-exists --no-owner \
  -U "$db_user" -d "$db_name" < "$dump_file"
```

For a plain SQL dump, use `psql` instead:

```sh
kubectl exec -i -n "$namespace" "$pod" -- \
  psql -v ON_ERROR_STOP=1 -U "$db_user" -d "$db_name" < "$dump_file"
```

If the restore must replace the whole database, stop application writes first,
terminate existing connections, drop and recreate the database, and then run
the appropriate restore command. Use the PostgreSQL administrative user for
those operations. Do not put passwords on the command line; use the prompt,
`PGPASSWORD` only for a short-lived process, or a temporary `PGPASSFILE`.
Verify the restore and application rollout afterward:

```sh
kubectl exec -n "$namespace" "$pod" -- \
  psql -U "$db_user" -d "$db_name" -c '\dt'
kubectl get helmrelease books-service -n "$namespace"
kubectl rollout status deployment/books-service -n "$namespace"
```

### Roll back an application image

Flux image automation updates the `tag` setter in
`apps/books-service/helmrelease.yaml`. Roll back to a known-good tag by editing
that value while preserving the image-policy comment:

```yaml
tag: "0.1.71" # {"$imagepolicy": "flux-system:books-service"}
```

Commit and push the change to `main`, then reconcile the source and release:

```sh
git add apps/books-service/helmrelease.yaml
git commit -m "rollback books service image"
git push origin main

flux reconcile source git flux-system -n flux-system
flux reconcile helmrelease books-service -n shelfshare-localprod
kubectl rollout status deployment/books-service -n shelfshare-localprod
kubectl get deployment books-service -n shelfshare-localprod \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Image automation runs every minute and may replace a manually selected tag if
the tag satisfies the `0.1.x` image policy. If the rollback must remain in
place, suspend the image automation before changing the tag and resume it only
after the incident:

```sh
flux suspend image update shelfshare-images -n flux-system
flux resume image update shelfshare-images -n flux-system
```
