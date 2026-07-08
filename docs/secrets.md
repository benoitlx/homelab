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
