# Calmecac: plan, then build.
#
# Models:  sonnet (default, balanced), opus (strongest), haiku (fastest/cheapest)
# Effort:  low, medium, high
#
# Examples:
#   just plan sonnet high
#   just build sonnet high
#   just build opus high /Users/me/dev/myapp/calmecac-auth

# Plan a new project with Calmecac
plan model effort:
    CLAUDE_CODE_EFFORT_LEVEL={{effort}} claude --model {{model}} "/plan"

# Build the project with Vera
build model effort workspace="":
    #!/usr/bin/env bash
    set -euo pipefail
    ws="{{workspace}}"
    if [[ -z "$ws" && -f .plan-last ]]; then
        ws=$(cat .plan-last)
    fi
    if [[ -z "$ws" ]]; then
        echo "No workspace found. Run 'just plan' first, or specify:"
        echo "  just build {{model}} {{effort}} /path/to/calmecac-workspace"
        exit 1
    fi
    .claude/skills/build/run.sh "$ws" "{{model}}" "{{effort}}"
