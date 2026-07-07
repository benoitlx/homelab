venv := ".venv"
venv_path := absolute_path(venv)
venv_bin := venv_path / "bin"
inventory := "hosts"

export VIRTUAL_ENV := absolute_path(venv_path)
export PATH := venv_bin + ":" + env_var('PATH')

[private]
default:
    @just --list --justfile {{justfile()}}

[private]
run_playbook playbook *ARGS:
    {{venv_bin}}/ansible-playbook --inventory {{inventory}} {{playbook}} {{ARGS}}


# Create the ansible user used for all other playbooks
[group('playbooks')]
playbook-create-ansible-user *ARGS: (run_playbook "playbooks/create-ansible-user.yml" ARGS)

# Run the main playbook that configures our infrastructure
[group('playbooks')]
playbook-deploy-services *ARGS: (run_playbook "playbooks/deploy-services.yml" ARGS)

# Provision the control-server (headscale, headplane, caddy, fail2ban)
[group('playbooks')]
playbook-deploy-control-server *ARGS: (run_playbook "playbooks/deploy-control-server.yml" ARGS)


# First-ever deployment sequence, before Vaultwarden exists - see docs/bootstrap.md

# Stage A: bootstrap the control-server, skipping roles needing Headscale-generated secrets, reading user-provided ones (OVH keys, headplane cookie) from a local temp file
[group('bootstrap')]
bootstrap-control-server *ARGS: (run_playbook "playbooks/deploy-control-server.yml" "--skip-tags" "needs-secrets" "--extra-vars" "@.bootstrap-secrets.yml" ARGS)

# Stage B: deploy only Vaultwarden (+ tailscale sidecar) on pi4, reading secrets from the local temp file
[group('bootstrap')]
bootstrap-vaultwarden *ARGS: (run_playbook "playbooks/deploy-services.yml" "--limit" "pi4" "-e" "compose_up_only=vault" "--extra-vars" "@.bootstrap-secrets.yml" ARGS)


# Login to Vault

# Setup a virtualenv and install dependencies
[group('tooling')]
venv:
    #!/usr/bin/env bash
    [[ -d .venv ]] || (python3 -m venv .venv && {{venv_bin}}/pip install -r requirements.txt && {{venv_bin}}/ansible-galaxy install -r galaxy.ansible.yml --force)

# Run ansible-lint
[group('tooling')]
lint *ARGS:
    {{venv_bin}}/ansible-lint {{ARGS}}

# Export information about all hosts, as gathered by Ansible (including variables)
[group('tooling')]
cmdb:
    {{venv_bin}}/ansible --inventory {{inventory}} --module-name ansible.builtin.setup --tree out/ all 2>/dev/null
    {{venv_bin}}/ansible-cmdb --inventory {{inventory}} out/ > overview.html
    @echo "Open overview.html in your browser"

# Find TODOs and comments silencing lints
[group('tooling')]
todo:
    grep --recursive --extended-regexp --ignore-case --line-number --color=always 'noqa|todo' --exclude-dir {{venv}}
