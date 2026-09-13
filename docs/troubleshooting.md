# Troubleshooting

Inspect Flux resources with `flux get all -A`, verify Kustomization paths, and
check SOPS decryption errors before investigating individual HelmReleases.
Host and WireGuard issues should be checked through the Ansible inventory and
systemd logs on the affected node.
