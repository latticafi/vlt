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

This installs `vlt` to `~/.local/bin` and ensures `vault`, `envconsul`, `jq`, and `gh` are installed via Homebrew.

## Quick start

```bash
# Authenticate via GitHub (recommended)
vlt login --gh

# Set up a project
cd ~/example-app
vlt init
# Vault address: https://vault.example.com
# Project name: example-app

# Run your app with secrets injected
vlt run -- bun run ...
```

## Usage

| Command                       | Description                                        |
| ----------------------------- | -------------------------------------------------- |
| `vlt init`                    | Create `.vlt.json` config in the current directory |
| `vlt login [--gh]`            | Authenticate via GitHub (default)                  |
| `vlt login --userpass`        | Authenticate via username/password                 |
| `vlt login --token`           | Authenticate via Vault token                       |
| `vlt run -- <cmd>`            | Inject secrets as env vars and run a command       |
| `vlt run -e staging -- <cmd>` | Use a specific environment                         |
| `vlt run -q -- <cmd>`         | Suppress warnings                                  |
| `vlt status`                  | Check auth status and config                       |
| `vlt update`                  | Update vlt to the latest version                   |
| `vlt starship`                | Add vlt status to starship prompt                  |

## Authentication

vlt supports multiple auth methods. Your choice is remembered so subsequent
`vlt login` calls use the same method automatically.

**GitHub (recommended):** Requires the [GitHub CLI](https://cli.github.com/).
If you're already logged into `gh`, authentication is automatic — no tokens
to copy. Your Vault host must have GitHub auth enabled and your GitHub org
configured.

```bash
vlt login --gh
```

**Userpass:** Username and password, prompted interactively. Your Vault host
must have userpass auth enabled.

```bash
vlt login --userpass
```

**Token:** Direct Vault token, prompted interactively. Works with any Vault
setup.

```bash
vlt login --token
```

## Config

`vlt init` creates a `.vlt.json` in your project root:

```json
{
  "addr": "https://vault.example.com",
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

## Starship integration

```bash
vlt starship
```

This adds your vault host's status to your [starship](https://starship.rs) prompt. When you're inside a project with `.vlt.json`, your prompt shows:

```
via  rest-api [✓]
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

## Onboarding

1. Run the install one-liner (or clone + `./install.sh`)
2. `vlt login --gh` — they need to be in the GitHub org
3. `cd` into any project with a `.vlt.json` and they're ready to go

## Uninstall

```bash
./uninstall.sh
```
