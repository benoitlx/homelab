# Homelab

Personnal repository for easy deployment of services running on my homelab.

- A raspberry pi 5 (with latest 64 bit raspbian) running :
    - [Home Assistant](https://www.home-assistant.io/)
- A raspberry pi 4 (with 32bit of raspbian buster) running :
    - [remote-gpio](https://gpiozero.readthedocs.io/en/stable/remote_gpio.html)
    - [Custom](https://github.com/saidijongo/ReSpeaker_Seeed_VoiceCard) kernel headers for Respeaker 4 mic array
- A Fedora 41 server running :
    - [Jellyfin](https://jellyfin.org/)
    - [Jellyseer](https://github.com/Fallenbagel/jellyseerr)
    - The [Arr](https://wiki.servarr.com/) suite
    - [QbitTorrent](https://github.com/qbittorrent/qBittorrent/)
    - [faster-whisper](https://github.com/SYSTRAN/faster-whisper)
    - [llama3](https://ollama.com/library/llama3) with ollama

## Deployment

### Prerequisites

On the computer running the playbooks :
- A python virtualenv with the [requirements](./requirements.txt) installed
- `figlet` and `lolcat` installed, to generate beautiful ASCII art in the MOTD banner
- The [bitwarden client](https://bitwarden.com/help/cli/#download-and-install) for secrets management
    - You will need to connect to your vaultwarden instance and export the session string.
- Recommended: the [`just`][just-manual] command runner

On the managed servers:
- An `ansible` user account with passwordless sudo (`just playbook-create-ansible-user`) use `--ask-become-pass` while running this role for the first time on a fresh fedora 41 install.

### Usage

Create a [`hosts`](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html) file with the target hostnames.

Create a directory `host_vars` for host specific variables. 
For each host create the following file in this directory :

```yaml
compose:
    - homeassistant
    - prowlarr
    - radarr
    - sonarr
```

> [!WARNING]
> Even if you don't want to deploy services on a device you should create this file with `compose:`

Then run `just playbook-deploy-infra`.

## TODO

- [ ] deploy tailscale configuration on hosts (for funnel and serve) (! Home Assistant needs to be run before the serve command is run on 8123 !)
- [ ] solve the issue I opened on ansible-role-tailscale (https://github.com/artis3n/ansible-role-tailscale/issues/517)

## Specific Host Documentation

### SAT

- Additional kernel drivers : https://github.com/Wartem/seeed-voicecard
- J'ai réactivé snc_bcmxxxx dans /etc/modprobe.d/