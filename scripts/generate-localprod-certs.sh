#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CERT_DIR="$PROJECT_ROOT/infra/certs"

if ! command -v openssl >/dev/null 2>&1; then
    printf 'openssl is required to generate local-production certificates.\n' >&2
    exit 1
fi

mkdir -p "$CERT_DIR"

if [[ -f "$CERT_DIR/ca.crt" && -f "$CERT_DIR/postgres-envoy.crt" && -f "$CERT_DIR/postgres-envoy.key" ]]; then
    printf 'Local-production certificates already exist in %s\n' "$CERT_DIR"
    exit 0
fi

umask 077
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

openssl req -x509 -newkey rsa:4096 -sha256 -nodes -days 365 \
    -subj "/CN=ShelfShare local-production CA" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -keyout "$TEMP_DIR/ca.key" \
    -out "$TEMP_DIR/ca.crt"

openssl req -newkey rsa:2048 -nodes -sha256 \
    -subj "/CN=envoy" \
    -addext "subjectAltName=DNS:envoy,DNS:localhost,IP:127.0.0.1" \
    -keyout "$TEMP_DIR/postgres-envoy.key" \
    -out "$TEMP_DIR/postgres-envoy.csr"

openssl x509 -req -sha256 -days 365 \
    -in "$TEMP_DIR/postgres-envoy.csr" \
    -CA "$TEMP_DIR/ca.crt" \
    -CAkey "$TEMP_DIR/ca.key" \
    -CAcreateserial \
    -copy_extensions copyall \
    -out "$TEMP_DIR/postgres-envoy.crt"

install -m 0644 "$TEMP_DIR/ca.crt" "$CERT_DIR/ca.crt"
install -m 0644 "$TEMP_DIR/postgres-envoy.crt" "$CERT_DIR/postgres-envoy.crt"
# Envoy runs unprivileged, so the bind-mounted key must be readable in the container.
install -m 0644 "$TEMP_DIR/postgres-envoy.key" "$CERT_DIR/postgres-envoy.key"

printf 'Generated local-production certificates in %s\n' "$CERT_DIR"
