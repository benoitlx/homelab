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
run_playbook playbook *ARGS: venv
    {{venv_bin}}/ansible-playbook --inventory {{inventory}} {{playbook}} {{ARGS}}


# Create the ansible user used for all other playbooks
[group('playbooks')]
playbook-create-ansible-user *ARGS: (run_playbook "playbooks/create-ansible-user.yml" ARGS)

# Run the main playbook that configures our infrastructure
[group('playbooks')]
playbook-deploy-infra *ARGS: (run_playbook "playbooks/deploy-server.yml" ARGS)


# Login to Vault

# Setup a virtualenv and install dependencies
[group('tooling')]
venv:
    [[ -d .venv ]] || (python -m venv .venv && {{venv_bin}}/pip install -r requirements.txt && source .venv/bin/activate && ansible-galaxy install -r requirements.yml)

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
