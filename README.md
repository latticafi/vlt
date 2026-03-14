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
curl -fsSL https://raw.githubusercontent.com/latticafi/vlt/main/install.sh | bash
```

This installs `vlt` to `/usr/local/bin` and ensures `vault`, `envconsul`, and `jq` are installed via Homebrew.

## Quick start

At the moment, only supporting authentication with Vault's native userpass
method. Once a user has authenticated with Vault, vlt will save a .vault-token
token to their home directory. The security of this token is completely
dependent on how userpass auth has been set up on the Vault host.

This is **NOT** advisable in production. Vault has a number of other
authentication methods, including OIDC. In theory, vlt doesn't care how you
authenticate, so you could bypass `vlt login` entirely if desired.

```bash
# Authenticate (one time, token lasts until it expires)
# There must exist a valid userpass auth on the Vault host already
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

| Command                       | Description                                        |
| ----------------------------- | -------------------------------------------------- |
| `vlt init`                    | Create `.vlt.json` config in the current directory |
| `vlt login`                   | Authenticate to Vault                              |
| `vlt run -- <cmd>`            | Inject secrets as env vars and run a command       |
| `vlt run -e staging -- <cmd>` | Use a specific environment                         |
| `vlt run -q -- <cmd>`         | Suppress warnings                                  |
| `vlt status`                  | Check auth status and config                       |
| `vlt update`                  | Update vlt to the latest version                   |
| `vlt starship`                | Add vlt status to starship prompt                  |

## Config

`vlt init` creates a `.vlt.json` in your project root:

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

## Starship integration

```bash
vlt starship
```

This adds your vault host's status to your [starship](https://starship.rs) prompt. When you're inside a project with `.vlt.json`, your prompt shows:

```
via  rest-api [✓]
```

Status icons: `✓` healthy, `✗` sealed, `?` unreachable.

It disappears when you leave the project directory.

## Migrating from Infisical

Infisical is a popular open-source secret manager.
However it has a fairly limited free tier. It can be self-hosted, however at
that point it might just be more advisable to run a self-hosted enterprise
solution like Vault.
You can use vlt to mimic some of Infisical's pleasant devx features, like command line secret injection.

This is done by wrapping [envconsul](https://github.com/hashicorp/envconsul)
(which itself is a wrapper around Vault and Consul).

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
```
