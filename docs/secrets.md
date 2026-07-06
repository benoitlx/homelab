# Secrets

All secrets are stored as items in the `ansible` Vaultwarden vault and fetched at deploy time via:

```
lookup('community.general.bitwarden', '<item name>', field='notes')[0]
```

The secret value goes in the item's **notes** field (not password), matching the convention already used for `tailscale_auth_key` / `headscale_api_key` in this repo.

## Items to create

| Vaultwarden item name | Value | File | Role |
|---|---|---|---|
| `tailscale_auth_key` | A **reusable** Headscale pre-auth key, no tags (`headscale preauthkeys create --user ansible-managed --reusable --expiration <long>`) | `playbooks/deploy-server.yml` (`Servers` play) | `artis3n.tailscale.machine` |
| `tailscale_auth_key` | (same value as above) | `roles/compose_up/templates/ts-service/ts-service.yml.j2` | `compose_up` |
| `headscale_api_key` | Headscale API key, used by Headplane's admin UI | `roles/headplane/templates/config.yaml.j2` | `headplane` |
| `caddy_ovh_application_key` | OVH API application key (https://api.ovh.com/createToken/) | `group_vars/all.yml` | `caddy`, `compose_up` |
| `caddy_ovh_application_secret` | OVH API application secret | `group_vars/all.yml` | `caddy`, `compose_up` |
| `caddy_ovh_consumer_key` | OVH API consumer key | `group_vars/all.yml` | `caddy`, `compose_up` |
| `headplane_cookie_secret` | 32-char random string for Headplane's session cookie signing | `group_vars/control_server.yml` | `headplane` |

## Per-service tags: fetched from the Headscale API, not Vaultwarden

Headscale fixes tags at pre-auth-key creation time — a node authenticated via a given key can only ever carry the tags that key was created with (tags-as-identity model, headscale PR #2931). A single static key can't serve every service, since each one needs a different tag combination (`semi-private`+`pi4`, `public`+`fedora-fixe`, etc.).

Rather than pre-creating and storing one Vaultwarden item per tag combination, the plan is to call the **Headscale API** directly at deploy time (authenticated with `headscale_api_key`) to create a pre-auth key on demand with exactly the tags a given service's `host_vars` entry declares (`item.tags`), and use that key as `TS_AUTHKEY` for that service's sidecar. This keeps tag combinations defined in one place (`host_vars`) instead of duplicated as separate Vaultwarden entries, and avoids managing a growing set of static keys as new tag combinations appear.
