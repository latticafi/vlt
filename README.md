# vlt

Secret injection CLI for [HashiCorp Vault](https://www.vaultproject.io/).

## Install

**From the repo:**

```bash
git clone git@github.com:lattica/vlt.git
cd vlt
./install.sh
```

**Or one-liner (without cloning):**

```bash
curl -fsSL https://raw.githubusercontent.com/lattica/vlt/main/install.sh | bash
```

This installs `vlt` to `/usr/local/bin` and ensures `vault`, `envconsul`, and `jq` are installed via Homebrew.

## Quick start

```bash
# Authenticate (one time, token lasts until it expires)
vlt login

# Set up a project
cd ~/example-app
vlt init
# Vault address [https://vault.example.com]: <enter>
# Project name: example-app

# Run your app with secrets injected
vlt run -- bun run ...
```

## Usage

| Command                       | Description                                             |
| ----------------------------- | ------------------------------------------------------- |
| `vlt init`                    | Create `.vault.json` config in the current directory    |
| `vlt login`                   | Authenticate to Vault (saves token to `~/.vault-token`) |
| `vlt run -- <cmd>`            | Inject secrets as env vars and run a command            |
| `vlt run -e staging -- <cmd>` | Use a specific environment                              |
| `vlt status`                  | Check auth status and config                            |

## Config

`vlt init` creates a `.vault.json` in your project root:

```json
{
  "addr": "https://vault.lattica.xyz",
  "project": "rest-api",
  "environments": {
    "dev": "secret/data/dev/rest-api",
    "staging": "secret/data/staging/rest-api",
    "prod": "secret/data/prod/rest-api"
  },
  "default_env": "dev"
}
```

**Commit this to git** so your team shares the same config.

## Migrating from Infisical

Infisical is a popular open-source secret manager.
However it has a fairly strict free tier.
Instead, you can setup a self-hosted Vault cluster (or instance) and use vlt
to mimic some of the functionality of Infisical, like secret injection.

This is done by wrapping [envconsul](https://github.com/hashicorp/envconsul)
(which itself is a wrapper around HashiCorp Vault and Consul).

Replace `infisical run --` with `vlt run --` in your `package.json`:

```diff
  "scripts": {
-   "dev": "infisical run -- bun run --hot src/index.ts",
-   "db:migrate": "infisical run -- drizzle-kit migrate"
+   "dev": "vlt run -- bun run --hot src/index.ts",
+   "db:migrate": "vlt run -- drizzle-kit migrate"
  }
```

## Uninstall

```bash
./uninstall.sh
# or just: rm /usr/local/bin/vlt
```
