#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

set -xeu -o pipefail

url="$1"
jsonPath="$2"

apiQuery="https://feedsearch.dev/api/v1/search?url=$url"
curl -X GET "$apiQuery" | jq '.[0]' > "$jsonPath"
