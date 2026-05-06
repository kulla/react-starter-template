#!/usr/bin/env bash
set -euo pipefail

ignore_cves=(
  # We do not have user defined CSS and thus are not affected by XSS
  "https://github.com/advisories/GHSA-qx2v-qp2m-jg93"
)

args=(audit)
for cve in "${ignore_cves[@]}"; do
  args+=("--ignore=$cve")
done

exec bun "${args[@]}"
