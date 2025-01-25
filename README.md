# Homelab Ansible Playbook

![lint-workflow](https://github.com/benoitlx/homelab/actions/workflows/test.yml/badge.svg)

Personnal repository for easy deployment of services running on my homelab.
This playbook specifically target [raspberry pi][rpi] and machines on [fedora][fedora], but it should works fine for any [debian][debian] based machine.

## What's currently running

- A Fedora 41 server running :
    - [Jellyfin][jellyfin]
    - [Jellyseer][jellyseer]
    - The [Arr][arr] suite
    - [QbitTorrent][qbittorrent]
    - [faster-whisper][faster-whisper]
    - [piper][piper]
    - [ollama][ollama] and with a [Web UI][open-webui]
- A raspberry pi 5 running :
    - [Home Assistant][homeassistant]
    - [Wizarr][wizarr]

## Deployment

### Prerequisites

On the computer running the playbooks :
- A python virtualenv with the [requirements](./requirements.txt) installed
- `figlet` and `lolcat` installed, to generate beautiful ASCII art in the MOTD banner
- The [bitwarden client][bw-cli] for secrets management
    - You will need to unlock your vault before running playbooks containing secrets 
- Recommended: the [`just`][just-manual] command runner

On the managed servers:
- An `ansible` user account with passwordless sudo (`just playbook-create-ansible-user`) use `--ask-become-pass` while running this role for the first time on a fresh fedora 41 install.

To develop on your computer :
  - A Python virtualenv with the [requirements](./requirements.txt) installed
  - Recommended: Visual Studio Code with the [`Ansible` extension][ansible-vscode-extension] (you should be prompted to install it when opening the project)

### Usage

Create a [`hosts`][inventory] file with the target hostnames.

Create a directory `host_vars` (like the directory [`host_var_examples`][host_var_examples/]) for host specific variables. 
For each host create a yaml file in `host_vars` indicating which service to run on the host.

Here is an example of what should be inside these files for running the [homeassistant][/roles/compose_up/templates/homeassistant.yml.j2] service using the specified compose file.

```yaml
# yaml-language-server: $schema=../host_var_examples/schema.json

compose:
  - file: homeassistant
    name: home
    serve: 
      - 8123
```

A full example is available [here][/host_var_examples/example.com.yml], as well as a [json-schema][/host_var_examples/schema.json].

> [!WARNING]
> Even if you don't want to deploy services on a device you should create this file with `compose:`

Then run `just playbook-deploy-infra` and your services should be deployed on your machines.

## TODO

- [ ] solve the issue I opened on ansible-role-tailscale (https://github.com/artis3n/ansible-role-tailscale/issues/517)
- [ ] role for installing seeed-voicecard driver
    - forked driver (working on pi4 with bookworm) : https://github.com/Wartem/seeed-voicecard
    - The forked driver remove the headphone drive. To reanable it search for snc_bcmxxxx in `/etc/modprobe.d/`
- [ ] watchtower
- [ ] move from bw cli to rbw cli

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