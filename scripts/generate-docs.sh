#!/usr/bin/env bash
# Local port of generateFeaturesDocumentation from devcontainers/action.
# Source: https://github.com/devcontainers/action/blob/main/src/generateDocs.ts
#
# Usage: generate-docs.sh [BASE_PATH] [OCI_REGISTRY] [NAMESPACE]
# Defaults: ./src  ghcr.io  <owner>/<repo> (lowercased, from `git remote get-url origin`)

set -euo pipefail

BASE_PATH="${1:-${BASE_PATH:-./src}}"
OCI_REGISTRY="${2:-${OCI_REGISTRY:-ghcr.io}}"
NAMESPACE="${3:-${NAMESPACE:-}}"

remote_url="$(git remote get-url origin 2>/dev/null || true)"
owner=""
repo=""
if [[ "$remote_url" =~ github\.com[:/]([^/]+)/(.+) ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]%.git}"
fi

if [[ -z "$NAMESPACE" && -n "$owner" && -n "$repo" ]]; then
    NAMESPACE="$(printf '%s/%s' "$owner" "$repo" | tr '[:upper:]' '[:lower:]')"
fi

base_path_trimmed="${BASE_PATH#./}"

generate_one() {
    local dir="$1"
    local feature
    feature="$(basename "$dir")"
    [[ "$feature" == .* ]] && return 0

    local json="${dir}/devcontainer-feature.json"
    if [[ ! -f "$json" ]]; then
        echo "(!) Warning: devcontainer-feature.json not found at path '${json}'. Skipping..." >&2
        return 0
    fi

    local id name desc version_full version
    id="$(jq -r '.id // ""' "$json")"
    if [[ -z "$id" ]]; then
        echo "ERROR: devcontainer-feature.json for '${feature}' does not contain an 'id'" >&2
        return 0
    fi
    name="$(jq -r '.name // ""' "$json")"
    desc="$(jq -r '.description // ""' "$json")"
    version_full="$(jq -r '.version // ""' "$json")"
    if [[ -n "$version_full" ]]; then
        version="${version_full%%.*}"
    else
        version="latest"
    fi

    local title_name
    if [[ -n "$name" ]]; then
        title_name="${name} (${id})"
    else
        title_name="${id}"
    fi

    local options_table=""
    if [[ "$(jq -r '.options | type' "$json")" == "object" ]]; then
        local rows
        rows="$(jq -r '
            .options | to_entries[] |
            "| \(.key) | \(.value.description // "-") | \(.value.type // "-") | \(if .value.default == "" then "-" else (.value.default | tostring) end) |"
        ' "$json")"
        if [[ -n "$rows" ]]; then
            options_table=$'## Options\n\n| Options Id | Description | Type | Default Value |\n|-----|-----|-----|-----|\n'"$rows"
        fi
    fi

    local customizations=""
    if [[ "$(jq -r '(.customizations.vscode.extensions // []) | length' "$json")" -gt 0 ]]; then
        local ext_list
        ext_list="$(jq -r '.customizations.vscode.extensions[] | "- `\(.)`"' "$json")"
        customizations=$'\n## Customizations\n\n### VS Code Extensions\n\n'"${ext_list}"$'\n'
    fi

    local notes=""
    if [[ -f "${dir}/NOTES.md" ]]; then
        notes="$(cat "${dir}/NOTES.md")"
    fi

    local url_to_config="devcontainer-feature.json"
    if [[ -n "$owner" && -n "$repo" ]]; then
        url_to_config="https://github.com/${owner}/${repo}/blob/main/${base_path_trimmed}/${feature}/devcontainer-feature.json"
    fi

    local header=""
    local is_deprecated legacy_count
    is_deprecated="$(jq -r '.deprecated // false' "$json")"
    legacy_count="$(jq -r '(.legacyIds // []) | length' "$json")"
    if [[ "$is_deprecated" == "true" || "$legacy_count" -gt 0 ]]; then
        header="### **IMPORTANT NOTE**"$'\n'
        if [[ "$is_deprecated" == "true" ]]; then
            header+="- **This Feature is deprecated, and will no longer receive any further updates/support.**"$'\n'
        fi
        if [[ "$legacy_count" -gt 0 ]]; then
            local formatted_legacy
            formatted_legacy="$(jq -r '[.legacyIds[] | "'\''" + . + "'\''"] | join(", ")' "$json")"
            header+="- **Ids used to publish this Feature in the past - ${formatted_legacy}**"$'\n'
        fi
    fi

    local readme_path="${dir}/README.md"
    [[ -f "$readme_path" ]] && rm -f "$readme_path"

    {
        [[ -n "$header" ]] && printf '%s' "$header"
        cat <<EOF

# ${title_name}

${desc}

## Example Usage

\`\`\`json
"features": {
    "${OCI_REGISTRY}/${NAMESPACE}/${id}:${version}": {}
}
\`\`\`

${options_table}
${customizations}
${notes}

---

_Note: This file was auto-generated from the [devcontainer-feature.json](${url_to_config}).  Add additional notes to a \`NOTES.md\`._
EOF
    } > "$readme_path"

    echo "wrote ${readme_path}"
}

shopt -s nullglob
for dir in "$BASE_PATH"/*/; do
    generate_one "${dir%/}"
done
