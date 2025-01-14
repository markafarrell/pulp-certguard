#!/bin/bash

# WARNING: DO NOT EDIT!
#
# This file was generated by plugin_template, and is managed by it. Please use
# './plugin-template --github pulp_certguard' to update this file.
#
# For more info visit https://github.com/pulp/plugin_template

set -euv

# make sure this script runs at the repo root
cd "$(dirname "$(realpath -e "$0")")/../../.."

mkdir ~/.ssh
touch ~/.ssh/pulp-infra
chmod 600 ~/.ssh/pulp-infra
echo "$PULP_DOCS_KEY" > ~/.ssh/pulp-infra

echo "docs.pulpproject.org,8.43.85.236 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGXG+8vjSQvnAkq33i0XWgpSrbco3rRqNZr0SfVeiqFI7RN/VznwXMioDDhc+hQtgVhd6TYBOrV07IMcKj+FAzg=" >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts

export PYTHONUNBUFFERED=1
export DJANGO_SETTINGS_MODULE=pulpcore.app.settings
export PULP_SETTINGS=$PWD/.ci/ansible/settings/settings.py
export WORKSPACE=$PWD

# start the ssh agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/pulp-infra

python3 .github/workflows/scripts/docs-publisher.py --build-type "$1" --branch "$2"

if [[ "$GITHUB_WORKFLOW" == "Certguard changelog update" ]]; then
  # Do not build bindings docs on changelog update
  exit
fi

mkdir -p ../certguard-bindings
tar -xvf certguard-python-client-docs.tar --directory ../certguard-bindings
pushd ../certguard-bindings

# publish to docs.pulpproject.org/pulp_certguard_client
rsync -avzh site/ doc_builder_pulp_certguard@docs.pulpproject.org:/var/www/docs.pulpproject.org/pulp_certguard_client/

# publish to docs.pulpproject.org/pulp_certguard_client/en/{release}
rsync -avzh site/ doc_builder_pulp_certguard@docs.pulpproject.org:/var/www/docs.pulpproject.org/pulp_certguard_client/en/"$2"
popd
