# Calmecac + Ralph: plan, then build.
#
# Models:  sonnet (default, balanced), opus (strongest), haiku (fastest/cheapest)
# Effort:  low, medium, high
#
# Examples:
#   just calmecac sonnet high
#   just ralph sonnet high
#   just ralph opus high /Users/me/dev/myapp/calmecac-auth

# Plan a new project with Calmecac
calmecac model effort:
    CLAUDE_CODE_EFFORT_LEVEL={{effort}} claude --model {{model}} "/calmecac"

# Build the project with Ralph
ralph model effort workspace="":
    #!/usr/bin/env bash
    set -euo pipefail
    ws="{{workspace}}"
    if [[ -z "$ws" && -f .calmecac-last ]]; then
        ws=$(cat .calmecac-last)
    fi
    if [[ -z "$ws" ]]; then
        echo "No workspace found. Run 'just calmecac' first, or specify:"
        echo "  just ralph {{model}} {{effort}} /path/to/calmecac-workspace"
        exit 1
    fi
    .claude/ralph/run.sh "$ws" "{{model}}" "{{effort}}"
