#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages (ps: [ ps.feedsearch-crawler ])"

from feedsearch_crawler import search, sort_urls
from feedsearch_crawler.crawler import coerce_url

import json
import sys
url, jsonPath = sys.argv[1:]

url = coerce_url(url, default_scheme="https")
items = search(url)
items = sort_urls(items)

# print all results
serialized = [item.serialize() for item in items]
for item in serialized:
        print(json.dumps(item, sort_keys=True, indent=2))

# save the first result to disk
keep = serialized[0] if serialized else {}
results = json.dumps(keep, sort_keys=True, indent=2)
with open(jsonPath, "w") as out:
        out.write(results)
