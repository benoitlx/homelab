# Bootstrap: deploying from zero

All secrets in this repo are read from a self-hosted **Vaultwarden** vault via
`lookup('community.general.bitwarden', ...)` (see [secrets.md](secrets.md)).
That creates a circular dependency the very first time you deploy: Vaultwarden
itself is deployed by the same playbooks, so it can't be up yet when its own
`tailscale_auth_key` is looked up. There is no Bitwarden cloud fallback in this
setup — the sequence below breaks the cycle with a small local, gitignored
file instead.

## Before anything is deployed

```bash
cp bootstrap-secrets.yml.example .bootstrap-secrets.yml
```

Fill in the values that don't depend on any infra existing yet:

- `caddy_ovh_application_key` / `caddy_ovh_application_secret` / `caddy_ovh_consumer_key`: from the [OVH API token page](https://api.ovh.com/createToken/)
- `headplane_cookie_secret`: any random 32-char string

Leave `tailscale_authkey` and `headscale_api_key` empty for now because they don't exist yet.

## Bootstrap the control-server

```bash
just bootstrap-control-server
```

This deploys `common`, `headscale`, `caddy`, and `fail2ban` on the control-server,
skipping the two roles (`artis3n.tailscale.machine`, `headplane`) that need
secrets Headscale hasn't generated yet. `caddy` resolves its OVH keys from
`.bootstrap-secrets.yml` instead of Vaultwarden.

Once it's done, SSH into the control-server and generate the two
Headscale-backed secrets:

```bash
sudo headscale users create ansible-managed
sudo headscale preauthkeys create --user ansible-managed --reusable --expiration <long>
sudo headscale apikeys create
```

Add both values to `.bootstrap-secrets.yml`:

```yaml
tailscale_authkey: "<preauth key output above>"
headscale_api_key: "<api key output above>"
```

## Deploy Vaultwarden only

```bash
just bootstrap-vaultwarden
```

This installs Docker, joins `pi4` to the tailnet, and deploys **only** the
`vault` compose service (via `-e compose_up_only=vault`). It still reads `tailscale_authkey` from
`.bootstrap-secrets.yml`, since Vaultwarden doesn't exist until this step
finishes.

## Move secrets into Vaultwarden

Open the Vaultwarden instance you just deployed, create the `ansible`
vault/collection, and add every item listed in [secrets.md](secrets.md),
using the values currently sitting in `.bootstrap-secrets.yml`.

Then point the local `bw` CLI at it and log in:

```bash
bw config server https://vault.<your-domain>
bw login
bw unlock
```

Once every item is confirmed present in Vaultwarden, delete the temp file:

```bash
rm .bootstrap-secrets.yml
```

## Deploy everything else

```bash
just playbook-deploy-control-server
just playbook-deploy-services
```

No flags, no extra-vars, every `bw` lookup now resolves against Vaultwarden,
including the rest of `pi4`'s services and every other host.
