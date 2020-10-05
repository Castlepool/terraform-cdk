#!/bin/sh
set -e

# Disable spinner even when we have a TTY
export CI='1'

# On main multiple builds might be running and leading to locks - skip always until
# that's fixed
echo "DISABLED - skipping" && exit 0;

# Don't run on external Pull Requests - Will be addressed properly with
# https://github.com/hashicorp/terraform-cdk/issues/200
[ -z "$TERRAFORM_CLOUD_TOKEN" ] && echo "Need to set TERRAFORM_CLOUD_TOKEN - skipping" && exit 0;

scriptdir=$(cd $(dirname $0) && pwd)

cd $(mktemp -d)
mkdir test && cd test

# initialize an empty project
# currently, we initialize this as a local project but we will use stack overrides
# to define remote state backend and test
# the deploy which should call into Terraform
# Cloud for the remote state.
cdktf init --template typescript-minimal --project-name="typescript-test" --project-description="typescript test app" --local

# put some code in it
cp ${scriptdir}/main.ts .

# add null provider
cp ${scriptdir}/cdktf.json .
cdktf get

# destroy
cdktf destroy --auto-approve

# diff
cdktf deploy --auto-approve > output
diff output ${scriptdir}/expected/output

echo "PASS"