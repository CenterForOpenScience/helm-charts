#!/usr/bin/env bash

BRANCH='gh-pages'
CHART_REPO_DIR=../${BRANCH}
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Clone the GitHub Pages branch to another directory
git clone ${REPO} --branch ${BRANCH} --single-branch ${CHART_REPO_DIR}

# Package charts
# TODO: sign charts
helm package -d ${CHART_REPO_DIR} */

# Merge chart repo index
cd ${CHART_REPO_DIR}
helm repo index . --merge ./index.yaml

# Check for changes
if [ -z `git diff --exit-code` ]; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi

# Commit and push changes
git add .
git commit -m "Update for ${SHA}"
git push ${SSH_REPO} ${BRANCH}
