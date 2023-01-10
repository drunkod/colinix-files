{ lib
, curl
, jq
, runtimeShell
, writeScript
# feed-specific args
, jsonPath
, url
}:

let
  apiQuery = "https://feedsearch.dev/api/v1/search?url=${url}";
in
writeScript "update-feed" ''
  #!${runtimeShell}
  PATH=${lib.makeBinPath [ curl jq  ]}
  curl -X GET '${apiQuery}' | jq '.[-1]' > '${jsonPath}'
''
