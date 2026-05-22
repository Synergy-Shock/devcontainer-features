#!/usr/bin/env bash
#
# Detect upstream major-version bumps for every feature listed in
# upstream-versions.json. Logs to stderr; emits a compact JSON array of
# detected bumps to stdout for the calling workflow to capture into
# $GITHUB_OUTPUT.
#
set -euo pipefail

STATE_FILE="${STATE_FILE:-upstream-versions.json}"

log() { printf '%s\n' "$*" >&2; }

resolve_latest() {
  local source="$1" ref="$2"
  case "$source" in
    npm)
      curl -fsSL "https://registry.npmjs.org/${ref}/latest" | jq -r '.version'
      ;;
    github)
      curl -fsSL "https://api.github.com/repos/${ref}/releases/latest" \
        | jq -r '.tag_name | sub("^v"; "")'
      ;;
    gitbutler-api)
      curl -fsSL "https://app.gitbutler.com/api/downloads?channel=${ref}&limit=1" \
        | jq -r '.[0].build_version'
      ;;
    *)
      log "unknown source: $source"
      return 1
      ;;
  esac
}

major_of() { printf '%s\n' "$1" | sed -E 's/^v?([0-9]+).*/\1/'; }

bumps='[]'

while read -r feature; do
  source=$(jq -r ".features.\"$feature\".source" "$STATE_FILE")
  ref=$(jq -r    ".features.\"$feature\".ref"    "$STATE_FILE")
  baseline_major=$(jq -r ".features.\"$feature\".major" "$STATE_FILE")

  latest_version=$(resolve_latest "$source" "$ref")
  latest_major=$(major_of "$latest_version")

  log "::group::$feature"
  log "baseline_major=$baseline_major  latest=$latest_version  latest_major=$latest_major"

  if [[ "$baseline_major" == "null" ]]; then
    log "Unseeded — recording current major without alerting."
    tmp=$(mktemp)
    jq --arg f "$feature" --argjson m "$latest_major" \
      '.features[$f].major = $m' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  elif (( latest_major > baseline_major )); then
    log "Major bump detected: ${baseline_major} → ${latest_major}"
    bumps=$(jq --arg feature "$feature" \
               --arg source "$source" \
               --arg ref "$ref" \
               --argjson baseline_major "$baseline_major" \
               --argjson latest_major "$latest_major" \
               --arg latest_version "$latest_version" \
               '. + [{
                  feature: $feature, source: $source, ref: $ref,
                  baseline_major: $baseline_major,
                  latest_major: $latest_major,
                  latest_version: $latest_version
                }]' <<<"$bumps")
  fi
  log "::endgroup::"
done < <(jq -r '.features | keys[]' "$STATE_FILE")

# Surface any self-seeded baseline diff. The workflow token is read-only by
# design, so the maintainer commits the seed manually after the first run.
if ! git diff --quiet -- "$STATE_FILE" 2>/dev/null; then
  log "::warning::$STATE_FILE was self-seeded this run but cannot be committed (read-only token). Commit the diff below manually:"
  git --no-pager diff -- "$STATE_FILE" >&2 || true
fi

jq -c . <<<"$bumps"
