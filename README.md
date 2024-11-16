# Homelab

Personnal repository for easy deployment of services running on my homelab.

## Prerequisites

On the computer running the playbooks :
- A python virtualenv with the [requirements](./requirements.txt) installed
- `figlet` and `lolcat` installed, to generate beautiful ASCII art in the MOTD banner
- The [bitwarden client](https://bitwarden.com/help/cli/#download-and-install) for secrets management
    - You will need to connect to your vaultwarden instance and export the session string.
- Recommended: the [`just`][just-manual] command runner

On the managed servers:
- An `ansible` user account with passwordless sudo (`just playbook-create-ansible-user`)

## Usage

TODO