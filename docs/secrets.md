# Secrets

> [!NOTE]
> Deploying for the very first time? Vaultwarden itself is one of the services
> deployed by these playbooks, so it can't hold any secrets yet on a fresh
> infra. See [bootstrap.md](bootstrap.md) for the chicken-and-egg procedure.

All secrets are stored as items in the `ansible` Vaultwarden vault (self-hosted, no cloud fallback) and fetched at deploy time via:

```
lookup('community.general.bitwarden', '<item name>', field='notes')[0]
```

The secret value goes in the item's **notes** field (not password), matching the convention already used for `headscale_api_key` in this repo.

## Items to create

| Vaultwarden item name | Value | File | Role |
|---|---|---|---|
| `headscale_api_key` | Headscale API key (`headscale apikeys create`), used by Headplane's admin UI and to mint pre-auth keys on demand for every Tailscale node (hosts and compose services alike) | `roles/headplane/templates/config.yaml.j2`, `roles/headscale_preauthkey/tasks/main.yml` | `headplane`, `headscale_preauthkey` |
| `caddy_ovh_application_key` | OVH API application key (https://api.ovh.com/createToken/) | `group_vars/all.yml` | `caddy`, `compose_up` |
| `caddy_ovh_application_secret` | OVH API application secret | `group_vars/all.yml` | `caddy`, `compose_up` |
| `caddy_ovh_consumer_key` | OVH API consumer key | `group_vars/all.yml` | `caddy`, `compose_up` |
| `headplane_cookie_secret` | 32-char random string for Headplane's session cookie signing | `group_vars/control_server.yml` | `headplane` |

## Every node identity: minted from the Headscale API, not Vaultwarden

Headscale fixes tags at pre-auth-key creation time — a node authenticated via a given key can only ever carry the tags that key was created with (tags-as-identity model, headscale PR #2931). A single static key can't serve every service, since each one needs a different tag combination (`semi-private`+`pi4`, `public`+`fedora-fixe`, etc.), and reusing one static key everywhere is also just a wider blast radius if it ever leaks.

So instead of a static key shared by every node, both `compose_up` and the host-level `artis3n.tailscale.machine` join call the shared **`roles/headscale_preauthkey`** role, authenticated with `headscale_api_key`, to mint a fresh, single-use (`reusable: false`) pre-auth key for that specific node right before it registers:

- **Per-service** (`roles/compose_up/tasks/headscale_preauthkey.yml`): tags come from the service's `host_vars` entry (`item.tags`) plus the host's own name (`inventory_hostname`, e.g. `tag:pi4`), used as `TS_AUTHKEY` for that service's sidecar.
- **Per-host** (`playbooks/tasks/mint_tailscale_authkey.yml`): tagged with just the host's own name (e.g. `tag:vps`, `tag:pi4`), used as `tailscale_authkey` for the host's own `artis3n.tailscale.machine` join.

Both derive the host tag the same way (`inventory_hostname.split('.')[0]`), so it needs a matching entry in `roles/headscale/templates/acl-policy.hujson.j2`'s `tagOwners` (one per host in the inventory). The Headscale user id lookup inside `headscale_preauthkey` is cached in a fact for the whole run, so it only happens once per host even though both callers may hit it (e.g. the host's own join and every one of its compose services).

This keeps tag combinations defined in one place (`host_vars`) instead of duplicated as separate Vaultwarden entries, and avoids managing a growing set of static keys as new tag combinations appear.

A key is only minted for nodes that aren't registered yet: `compose_up` checks for persisted Tailscale state on disk (`ts/state/tailscaled.state`), while the host-level join reuses the play's existing `tailscale_installed` check. An already-registered node ignores whatever key it's handed on restart, so re-running the playbook never needlessly mints (or wastes) a new one.
