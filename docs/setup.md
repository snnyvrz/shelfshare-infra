# Setup

Install the required tooling with `./configure`, then configure SOPS age keys
for encrypted manifests. Local development infrastructure is started with the
Compose files under `compose/`. Production is provisioned with Ansible and
reconciled by Flux on K3s.
