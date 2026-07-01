# Control Server

The control server is an OVH VPS running three services:

| Service | Role |
|---|---|
| **Headscale** | Self-hosted Tailscale control plane |
| **Caddy** | TLS termination + public reverse proxy |
| **fail2ban** | SSH brute-force protection |

Deployed via the `control_server` play in `playbooks/deploy-server.yml`.

```bash
ansible-playbook playbooks/deploy-server.yml --limit control_server
```

Real values (domain, IP, SSH port) are in `group_vars/control_server.yml` which is gitignored.
Copy [`group_vars_example/control_server.yml`](../group_vars_example/control_server.yml) as a starting point and fill in your values.

---

## Headscale

- **Version**: see `roles/headscale/defaults/main.yml`
- **Control plane URL**: `https://headscale.<YOUR_DOMAIN>`
- **MagicDNS base domain**: `ts.<YOUR_DOMAIN>` — nodes appear as `<name>.ts.<YOUR_DOMAIN>`
- **Config**: `/etc/headscale/config.yaml` (templated from `roles/headscale/templates/config.yaml.j2`)
- **Database**: `/var/lib/headscale/db.sqlite`
- **Listens on**: `127.0.0.1:8080` — not exposed publicly, Caddy is in front

### Common commands

All commands require `sudo`.

```bash
# Validate config
sudo headscale configtest

# List users
sudo headscale users list

# Create a user
sudo headscale users create homelab

# List nodes
sudo headscale nodes list

# Register a node manually
sudo headscale nodes register --user homelab --key <mkey:...>

# Create a reusable pre-auth key (for Ansible automation)
sudo headscale preauthkeys create --user homelab --reusable --expiration 24h

# List pre-auth keys
sudo headscale preauthkeys list --user homelab
```

### Upgrading

Bump `headscale_version` in `roles/headscale/defaults/main.yml` and re-run the playbook.

---

## Caddy

- **Config**: `/etc/caddy/Caddyfile` (templated from `roles/caddy/templates/Caddyfile.j2`)
- Handles TLS automatically via Let's Encrypt (HTTP-01 challenge on port 80)
- Forwards client IP to Headscale via `True-Client-IP` / `X-Real-IP` headers
- Handles the Tailscale captive portal check (`/generate_204`)

### Adding a public service

When a homelab service needs to be reachable from the internet (e.g. Vaultwarden), add a block to `roles/caddy/templates/Caddyfile.j2`:

```caddyfile
vault.<YOUR_DOMAIN> {
    reverse_proxy vault.ts.<YOUR_DOMAIN>:80 {
        header_up True-Client-IP {remote_host}
        header_up X-Real-IP {remote_host}
    }
}
```

The VPS resolves `vault.ts.<YOUR_DOMAIN>` via MagicDNS because it is itself a node in the VPN. Add the corresponding DNS A record at the registrar pointing to the VPS IP.

### Common commands

```bash
# Validate config
sudo caddy validate --config /etc/caddy/Caddyfile

# Reload after manual edit
sudo systemctl reload caddy

# Check TLS certificate status
sudo caddy list-certs
```

---

## fail2ban

Protects SSH. Bans IPs after 5 failed attempts within 10 minutes for 1 hour.

Defaults in `roles/fail2ban/defaults/main.yml` — all values are overridable via `group_vars/control_server.yml`.

```bash
# Check banned IPs
sudo fail2ban-client status sshd

# Unban an IP
sudo fail2ban-client set sshd unbanip <IP>
```

---

## DNS records

| Record | Target |
|---|---|
| `A headscale.<YOUR_DOMAIN>` | `<VPS_IP>` |
| `A <service>.<YOUR_DOMAIN>` | `<VPS_IP>` (one per public service) |

MagicDNS names (`*.ts.<YOUR_DOMAIN>`) are resolved inside the VPN — no public DNS records needed for those.

---

## Backup

Critical files to back up on the VPS:

- `/var/lib/headscale/db.sqlite` — all nodes, users, pre-auth keys
- `/var/lib/headscale/noise_private.key` — re-registration of all nodes required if lost
