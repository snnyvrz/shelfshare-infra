# Agent Instructions

## Repository Shape

- This is a mixed infrastructure and application repository. The two Nx projects are `apps/books-service` (Go/Gin/Postgres) and `apps/auth-service` (Bun/TypeScript/Express/Mongo).
- `nx.json` uses Bun as the package manager; use `bun`, not npm or yarn. Keep the root `bun.lock` and `uv.lock` authoritative.
- Infrastructure lives under `ansible/`, `k8s/`, `clusters/`, `infra/`, and Docker Compose files at the root. Do not assume application-only changes are isolated from deployment configuration.

## Setup And Commands

- Before local Make targets, run `chmod +x ./configure && ./configure`. This validates or installs the required Go, air, shfmt, Bun, Docker, and SOPS versions, installs JS dependencies, configures Git, and creates `.configured`.
- The dev script expects `.env.dev` (copy `.env.dev.example`); the Makefile's standalone infra targets default to `.env`, so check the env file used by the command. `make dev books` starts Postgres and the books service through Nx/air; `make dev auth` starts Mongo and the auth service through Nx/Bun. `make books-infra-up`, `make infra-down`, and `make logs` manage the development infrastructure separately.
- `make dev` currently has a misspelled `deecrypt-secrets` prerequisite in the Makefile; invoke the relevant `bun x nx run ...:serve` target or fix that prerequisite before relying on the Make shortcut.
- `make test books` runs the books-service unit tests with coverage via Nx, but `scripts/test.sh` currently appends `|| true`, so verify the test output and use `bun x nx run books-service:test` when the exit status must be trusted. The underlying target is `go test -coverprofile=coverage/coverage.out ./...` in `apps/books-service`.
- `make books-integration-test` starts the Docker Postgres service, loads `.env.test`, creates the test database if needed, and runs `go test -tags=integration ./...` through Nx. Docker must be running; the suite migrates and truncates its test database.
- Focused Nx commands use project targets, for example `bun x nx run books-service:test`, `bun x nx run books-service:integration-test`, `bun x nx run books-service:swagger`, and `bun x nx run books-service:coverage`. `bun x nx affected --target=test` is the pre-push check.
- Swagger output under `apps/books-service/internal/docs` is generated. The `serve`, CI, and deploy flows regenerate it with `bun x nx run books-service:swagger` or the equivalent `swag init` command; do not hand-edit generated docs.

## Secrets And Hooks

- Files matching `*.sops.*` are encrypted repository secrets. Use `make decrypt-secrets` only when local plaintext is required and `make encrypt-secrets` before returning them to encrypted form; do not commit plaintext secrets.
- The pre-commit hook runs SOPS encryption for staged secret files and then `bun x lint-staged`; the pre-push hook runs `bun x nx affected --target=test`.
- `.env.dev`, `.env.localprod`, `.env.prod`, `.configured`, coverage, and Terraform state are ignored. Use `.env.dev.example` as the local environment template; integration tests use the checked-in `.env.test` values with Docker Postgres.

## Verification And Formatting

- CI installs with `bun install --frozen-lockfile`, regenerates Swagger, runs affected coverage, then runs `make books-integration-test`; match that order when validating books-service changes.
- Staged files are auto-formatted by `lint-staged`: ESLint/Prettier for JS/TS, `go fix`/`gofmt`/`go vet` for Go, `shfmt` for shell, Prettier for JSON/Markdown/YAML, and `scripts/lint-helm.sh` for `charts/**`.
- Follow `.editorconfig`: four-space indentation except two-space YAML and tab-indented Makefiles. Prettier uses semicolons, ES5 trailing commas, and a 120-column width.
