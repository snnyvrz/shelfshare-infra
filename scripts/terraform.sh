#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-}"
shift || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TF_DIR="${PROJECT_ROOT}/infra/hetzner"
error() {
    echo "Error: $*" >&2
    exit 1
}

# The former helper logic is retained here as comments for reference. It must
# not be re-enabled until a replacement server is provisioned.
# get_my_ip() {
#     curl -4 -s https://ifconfig.me || curl -4 -s https://api.ipify.org
# }
#
# decrypt_tfvars() {
#     (
#         cd "${TF_DIR}"
#         "${PROJECT_ROOT}/scripts/sops.sh" decrypt >&2
#     )
#
#     local path="${TF_DIR}/secrets.sops.tfvars"
#     [[ -f "${path}" ]] || error "Expected decrypted tfvars at '${path}' but it does not exist."
#     echo "${path}"
# }

run_in_tf_dir() {
    (cd "${TF_DIR}" && "$@")
}

case "${COMMAND}" in
    init)
        error "Hetzner infrastructure is retired; Terraform initialization is disabled."
        ;;
    plan|apply)
        error "Hetzner infrastructure is retired; Terraform ${COMMAND} is disabled."
        ;;

    *)
        cat >&2 <<EOF
Usage: $0 <command> [terraform-args...]

Commands:
  init        Disabled; Hetzner infrastructure is retired
  plan        Disabled; Hetzner infrastructure is retired
  apply       Disabled; Hetzner infrastructure is retired

Examples:
  $0 init
  $0 plan
  $0 apply
EOF
        exit 1
        ;;
esac
