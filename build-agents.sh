#!/usr/bin/env bash
# Generates AGENTS.md by concatenating all rule files in order.
# Strips YAML frontmatter from each file and separates sections with a divider.
# Usage: ./build-agents.sh

set -euo pipefail

SKILL_DIR="$(dirname "$0")/skills/blutui-project-guidelines"
RULES_DIR="$SKILL_DIR/rules"
OUTPUT="$SKILL_DIR/AGENTS.md"

# Ordered list of rule files — matches the Rule Index in SKILL.md
RULE_FILES=(
  "foundation-file-structure.md"
  "foundation-templates-and-layouts.md"
  "foundation-courier-configuration.md"
  "templating-canvas.md"
  "templating-including-templates.md"
  "mcp.md"
  "courier.md"
  "cassettes.md"
  "collections.md"
  "blog.md"
  "forms.md"
  "menus.md"
  "route-patterns.md"
  "canopy.md"
)

# Strip YAML frontmatter (everything between the first pair of --- lines)
strip_frontmatter() {
  local file="$1"
  awk '
    BEGIN { in_front=0; done=0 }
    /^---$/ && !done {
      if (!in_front) { in_front=1; next }
      else { done=1; next }
    }
    done { print }
  ' "$file"
}

{
  echo "<blutui-project-guidelines>"
  echo ""

  for i in "${!RULE_FILES[@]}"; do
    file="${RULES_DIR}/${RULE_FILES[$i]}"

    if [[ ! -f "$file" ]]; then
      echo "Error: required rule file not found: $file" >&2
      exit 1
    fi

    strip_frontmatter "$file"

    # Add a divider between sections (not after the last one)
    if [[ $i -lt $((${#RULE_FILES[@]} - 1)) ]]; then
      echo ""
      echo "---"
      echo ""
    fi
  done

  echo ""
  echo "</blutui-project-guidelines>"
} > "$OUTPUT"

echo "Built $OUTPUT from ${#RULE_FILES[@]} rule files."
