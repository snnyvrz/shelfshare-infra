#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOPS_SCRIPT="$(cd "$SCRIPT_DIR/.." && pwd)/scripts/sops.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_file_contains() {
    local file="$1"
    local expected="$2"
    grep -Fq "$expected" "$file" || fail "$file does not contain $expected"
}

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/secrets" "$TEST_ROOT/output"
cat > "$TEST_ROOT/bin/sops" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" != "--decrypt" ] || [ "$#" -ne 2 ]; then
    printf 'unexpected sops arguments: %s\n' "$*" >&2
    exit 1
fi
printf 'plaintext generated from %s\n' "$2"
EOF
chmod +x "$TEST_ROOT/bin/sops"

cat > "$TEST_ROOT/secrets/needed.sops.yaml" <<'EOF'
secret: encrypted
sops:
  age: []
EOF
cat > "$TEST_ROOT/secrets/unrelated.sops.yaml" <<'EOF'
secret: unrelated-encrypted
sops:
  age: []
EOF

PATH="$TEST_ROOT/bin:$PATH" "$SOPS_SCRIPT" decrypt \
    --output-dir "$TEST_ROOT/output" "$TEST_ROOT/secrets/needed.sops.yaml"

assert_file_contains "$TEST_ROOT/secrets/needed.sops.yaml" "secret: encrypted"
assert_file_contains "$TEST_ROOT/secrets/unrelated.sops.yaml" "unrelated-encrypted"
assert_file_contains "$TEST_ROOT/output/needed.sops.yaml" "plaintext generated"
[ ! -e "$TEST_ROOT/output/unrelated.sops.yaml" ] || fail "unrelated secret was decrypted"

if PATH="$TEST_ROOT/bin:$PATH" "$SOPS_SCRIPT" decrypt >/dev/null 2>&1; then
    fail "decrypt without an output directory and file succeeded"
fi

printf 'PASS: scoped SOPS decryption preserves tracked sources\n'
