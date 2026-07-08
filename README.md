# Homelab Ansible Playbook

![lint-workflow](https://github.com/benoitlx/homelab/actions/workflows/test.yml/badge.svg)

Personnal repository for easy deployment of services running on my homelab.
This playbook specifically target [raspberry pi][rpi] and machines on [fedora][fedora], but it should works fine for any [debian][debian] based machine.

My homelab heavily rely on [tailscale] with a self-hosted control server (see [headscale]) on a VPS to connect every devices to each other.

## Architecture overview

![](/docs/assets/architecture.svg)

## Deployment

### Prerequisites

On the computer running the playbooks :
- A python virtualenv with the [requirements](./requirements.txt) installed (`just venv`)
- `figlet` and `lolcat` installed, to generate beautiful ASCII art in the MOTD banner
- The [bitwarden client][bw-cli] for secrets management
    - You will need to unlock your vault before running playbooks containing secrets
- Recommended: the [`just`][just-manual] command runner

On the managed servers:
- An `ansible` user account with passwordless sudo (`just playbook-create-ansible-user`) use `--ask-become-pass` while running this role for the first time on a fresh fedora 41 install.
- For backups, necessary [`borg`][borg] repositories need to be present in the right location under `/mnt/tailscale/benoitlx.github/{{ backup_host }}/repo.borg/`

To develop on your computer :
  - A Python virtualenv with the [requirements](./requirements.txt) installed (`just venv`)
  - Recommended: Visual Studio Code with the [`Ansible` extension][ansible-vscode-extension] (you should be prompted to install it when opening the project)

### Usage

Create a [`hosts`][inventory] file with the target hostnames.

Create a directory `host_vars` (like the directory [`host_vars_example`](host_vars_example/)) for host specific variables.
For each host create a yaml file in `host_vars` indicating which service to run on the host.

Here is an example of what should be inside these files for running the [homeassistant](/roles/compose_up/templates/homeassistant/homeassistant.yml.j2) service using the specified compose file.

```yaml
# yaml-language-server: $schema=../host_vars_example/schema.json

services:
  - name: home
    file: homeassistant
    public: true
    port: 8123
```

A full example is available [here](/host_vars_example/example.com.yml), as well as a [json-schema](/host_vars_example/schema.json).

> [!WARNING]
> Even if you don't want to deploy services on a device you should create this file with `services:`

The control-server (Headscale, Caddy, fail2ban) and the rest of the machines are deployed by two separate playbooks:

- `just playbook-deploy-control-server` provisions the control-server
- `just playbook-deploy-services` provisions every other machine, compose services included

> [!NOTE]
> Deploying for the very first time ? All secrets live in a self-hosted Vaultwarden vault, which is itself one of the services deployed by these playbooks, so there's a specific order to follow, see [docs/bootstrap.md](docs/bootstrap.md).

## TODO

- [ ] solve the issue I opened on ansible-role-tailscale (https://github.com/artis3n/ansible-role-tailscale/issues/517)
- [ ] role for installing seeed-voicecard driver
    - forked driver (working on pi4 with bookworm) : https://github.com/Wartem/seeed-voicecard
    - The forked driver remove the headphone drive. To reanable it search for snc_bcmxxxx in `/etc/modprobe.d/`
- [ ] watchtower
- [ ] move from bw cli to rbw cli
- [ ] borgmatic config template
    - add a `backup: true or false` in the host yaml
    - get the backup `ping_url` from vaultwarden (in order to get notification in case of backup failing from uptime kuma)
- [ ] automatic mount of tailscale share under `/mnt/tailscale` (for backups)
    - need to install `davfs2` and specify the good entry in `/etc/fstab`
- [ ] update json-schema with the `no_backup` option
- [ ] better explain the backup process in the readme

## Acknowledgements and Inspirations

- [Rezoleo's playbook](https://github.com/rezoleo/ansible-playbooks/)
- [tailscale ansible role](https://github.com/artis3n/ansible-role-tailscale)

[just-manual]: https://just.systems/man/en/
[bw-cli]: https://bitwarden.com/help/cli/#download-and-install
[ansible-vscode-extension]: https://marketplace.visualstudio.com/items?itemName=redhat.ansible
[inventory]: https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html
[homeassistant]: https://www.home-assistant.io/
[remote-gpio]: https://gpiozero.readthedocs.io/en/stable/remote_gpio.html
[jellyfin]: https://jellyfin.org/
[jellyseer]: https://github.com/Fallenbagel/jellyseerr
[arr]: https://wiki.servarr.com/
[qbittorrent]: https://github.com/qbittorrent/qBittorrent/
[faster-whisper]: https://github.com/SYSTRAN/faster-whisper
[ollama]: https://ollama.com/
[debian]: https://www.debian.org/
[fedora]: https://fedoraproject.org/
[rpi]: https://www.raspberrypi.org/
[wizarr]: https://github.com/Wizarrrr/wizarr
[open-webui]: https://github.com/open-webui/open-webui
[piper]: https://github.com/rhasspy/piper
[borg]: https://www.borgbackup.org/
[tailscale]: https://tailscale.com/
[headscale]: https://headscale.net/stable/
