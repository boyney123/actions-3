#!/bin/bash

set -e

# skip if no /clojure
echo "Checking if contains '/clojure' command..."
(jq -r ".comment.body" "$GITHUB_EVENT_PATH" | grep -E "/clojure") || exit 78

if [[ "$(jq -r ".action" "$GITHUB_EVENT_PATH")" != "created" ]]; then
	echo "This is not a new comment event!"
	exit 78
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
	echo "Set the GITHUB_TOKEN env variable."
	exit 1
fi

comment_body=$(jq -r ".comment.body" "$GITHUB_EVENT_PATH")

# Evaluate comment and capture output
echo "Evaluate comment and capture output:"
clojure_code=$(sed "s/\/clojure //g" <<< $comment_body)
echo "$clojure_code"
output=$(clojure --eval "$clojure_code")

# Write output to STDOUT
echo "$output"

ISSUE_NUMBER=$(jq -r ".issue.number" "$GITHUB_EVENT_PATH")
REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")
echo "Creating new comment #$ISSUE_NUMBER of $REPO_FULLNAME..."

COMMENTS_URI=$(jq -r ".issue.comments_url" "$GITHUB_EVENT_PATH")
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token $GITHUB_TOKEN"

new_comment_resp=$(curl --data "{\"body\": \"\`\`\`clojure\\n$clojure_code\\n\`\`\`\\n\`\`\`\\n$output\\n\`\`\`\"}" -X POST -s -H "${AUTH_HEADER}" -H "${API_HEADER}" ${COMMENTS_URI})

echo "$new_comment_resp"
echo "created comment"