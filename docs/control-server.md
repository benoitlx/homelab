# Control Server

The control server is an OVH VPS running three services:

| Service | Role |
|---|---|
| **Headscale** | Self-hosted Tailscale control plane |
| **Caddy** | TLS termination + public reverse proxy |
| **fail2ban** | SSH brute-force protection |

Deployed via `playbooks/deploy-control-server.yml`. See [bootstrap.md](bootstrap.md) for the first-ever deployment sequence.

```bash
ansible-playbook playbooks/deploy-control-server.yml
```

Real values (domain, IP, SSH port) are in `group_vars/control_server.yml` which is gitignored.
Copy [`group_vars_example/control_server.yml`](../group_vars_example/control_server.yml) as a starting point and fill in your values.

---

## Headscale

- **Config files**: `/etc/headscale/config.yaml` and `/etc/headscale/acl-policy.hujson` 
- **Database**: `/var/lib/headscale/db.sqlite`

The `systemctl` service is named `headscale`.
To upgrade Headscale, bump `headscale_version` in `roles/headscale/defaults/main.yml` and re-run the playbook.

---

## Caddy

- **Config files**: `/etc/caddy/Caddyfile` and `/etc/caddy/sites/*`

Caddy run as a `systemctl` service named `caddy`.

### Adding a public service

When a homelab service needs to be reachable from the internet, add a block to `roles/caddy/templates/Caddyfile.j2`:

```caddyfile
service.<YOUR_DOMAIN> {
    reverse_proxy service.ts.<YOUR_DOMAIN>:80 {
        header_up True-Client-IP {remote_host}
        header_up X-Real-IP {remote_host}
    }
}
```

The VPS resolves `service.ts.<YOUR_DOMAIN>` via MagicDNS because it is itself a headscale node. Then, add the corresponding DNS A record at the registrar pointing to the VPS IP.

You can manually inspect tls certificates with `caddy list-certs`.

---

## fail2ban

Protects SSH. Bans IPs after 5 failed attempts within 10 minutes for 1 hour.

Some usefull commands:
```bash
# Check banned IPs
sudo fail2ban-client status sshd

# Unban an IP
sudo fail2ban-client set sshd unbanip <IP>
```

---

## Backup

Critical files to back up on the VPS:

- `/var/lib/headscale/db.sqlite`: all nodes, users, pre-auth keys
- `/var/lib/headscale/noise_private.key`: re-registration of all nodes required if lost
