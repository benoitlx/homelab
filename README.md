# Homelab

Personnal repository for easy deployment of services running on my homelab.

- A raspberry pi 5 (with latest 64 bit raspbian) running :
    - [Home Assistant](https://www.home-assistant.io/)
    - The [Arr](https://wiki.servarr.com/) suite
- A raspberry pi 4 (with 32bit of raspbian buster) running :
    - [remote-gpio](https://gpiozero.readthedocs.io/en/stable/remote_gpio.html)
    - [Custom](https://github.com/saidijongo/ReSpeaker_Seeed_VoiceCard) kernel headers for Respeaker 4 mic array
- A Fedora 41 server running :
    - [Jellyfin](https://jellyfin.org/)
    - [Jellyseer](https://github.com/Fallenbagel/jellyseerr)
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

Create a [`hosts`](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html) file and adapt the `deploy-server.yml` playbook to choose on which devices to deploy the services.

Then run `just playbook-deploy-infra`.