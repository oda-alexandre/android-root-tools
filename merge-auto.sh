#!/usr/bin/env bash

# Provides:          merge-auto
# Authors:           https://www.oda-alexandre.com/
# Short-Description: Merge Auto GitLab Pipeline
# Description: merge auto when pipeline succeeds

set -e

# Check if the GitLab Private Token exist  
if [ -z "$GITLAB_PRIVATE_TOKEN" ]; then
  echo -e '\033[36;1m PRIVATE_TOKEN not set \033[0m'
  echo -e '\033[36;1m Please set the GitLab Private Token as PRIVATE_TOKEN \033[0m'
  exit 1
fi

# Extract the host where the server is running, and add the URL to the APIs
[[ $HOST =~ ^https?://[^/]+ ]] && HOST="${BASH_REMATCH[0]}/api/v4/projects/"

# Look which is the default branch
TARGET_BRANCH=`curl --silent "${HOST}${CI_PROJECT_ID}" --header "PRIVATE-TOKEN:${PRIVATE_TOKEN}" | python3 -c "import sys, json; print(json.load(sys.stdin)['default_branch'])"`;

# The description of our new MR, we want to remove the branch after the MR has
# been closed
BODY="{
    \"id\": ${CI_PROJECT_ID},
    \"source_branch\": \"${CI_COMMIT_REF_NAME}\",
    \"target_branch\": \"${TARGET_BRANCH}\",
    \"remove_source_branch\": true,
    \"title\": \"WIP: ${CI_COMMIT_REF_NAME}\",
    \"assignee_id\":\"${GITLAB_USER_ID}\"
}";

# Require a list of all the merge request and take a look if there is already
# one with the same source branch
LISTMR=`curl --silent "${HOST}${CI_PROJECT_ID}/merge_requests?state=opened" --header "PRIVATE-TOKEN:${PRIVATE_TOKEN}"`;
COUNTBRANCHES=`echo ${LISTMR} | grep -o "\"source_branch\":\"${CI_COMMIT_REF_NAME}\"" | wc -l`;

# No MR found, let's create a new one
if [ ${COUNTBRANCHES} -eq "0" ]; then
    curl -X POST "${HOST}${CI_PROJECT_ID}/merge_requests" \
        --header "PRIVATE-TOKEN:${PRIVATE_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "${BODY}";

    echo -e '\033[36;1m Opened a new merge request: WIP: ${CI_COMMIT_REF_NAME} and assigned to you \033[0m';
    exit;
fi

echo -e '\033[36;1m No new merge request opened \033[0m';