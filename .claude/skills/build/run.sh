#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <plan-workspace> [model] [effort]"
  echo ""
  echo "  plan-workspace: path to a Calmecac workspace directory"
  echo "                  (e.g., /Users/you/dev/myapp/calmecac-auth)"
  echo "  model:  sonnet (default), opus, haiku — or full IDs like claude-sonnet-4-6"
  echo "  effort: low, medium, high (default: high)"
  exit 1
fi

WORKSPACE_DIR="$(cd "$1" && pwd)"
PROMPT_FILE="$(dirname "$0")/01-vera.md"

# Project directory is the parent of the workspace
PROJECT_DIR="$(dirname "$WORKSPACE_DIR")"
git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "ERROR: project directory is not a git repo: $PROJECT_DIR"; exit 1; }

# Calmecac workspace convention: files live in phase subdirectories
TASKS_FILE="${WORKSPACE_DIR}/06-alkhwarizmi/tasks.jsonl"
REQUIREMENTS_FILE="${WORKSPACE_DIR}/05-euclid/requirements.md"
TEST_SPECS_FILE="${WORKSPACE_DIR}/05-euclid/test-specs.md"
FINAL_PLAN_FILE="${WORKSPACE_DIR}/04-zhuxi/final-plan.md"
BOUNDARY_CONDITIONS_FILE="${WORKSPACE_DIR}/01-socrates/boundary-conditions.md"

# Model aliases (shorthand) or full IDs both work with `claude --model`:
#
#   Alias    Model               Input/Output (per Mtok)   Notes
#   -----    -----               -----------------------   -----
#   sonnet   Sonnet 4.6          $3 / $15                  default — balanced for iterative loops
#   sonnet   Sonnet 4.6 (1M)     $6 / $22.50              auto-upgrades for long context
#   opus     Opus 4.6            $5 / $25                  strongest reasoning, complex tasks
#   opus     Opus 4.6 (1M)       $10 / $37.50             auto-upgrades for long context
#   haiku    Haiku 4.5           $1 / $5                   fastest & cheapest, lighter tasks
#
# The 1M context tier kicks in automatically when sessions exceed the standard
# window — no separate alias needed. For one-task-per-loop (fresh context each
# run), we stay in the standard tier.
MODEL="${2:-sonnet}"
EFFORT="${3:-high}"
export CLAUDE_CODE_EFFORT_LEVEL="$EFFORT"

[[ -f "$PROMPT_FILE" ]]              || { echo "ERROR: prompt file not found: $PROMPT_FILE"; exit 1; }
[[ -f "$TASKS_FILE" ]]               || { echo "ERROR: tasks file not found: $TASKS_FILE"; exit 1; }
[[ -f "$REQUIREMENTS_FILE" ]]        || { echo "ERROR: requirements file not found: $REQUIREMENTS_FILE"; exit 1; }
[[ -f "$TEST_SPECS_FILE" ]]          || { echo "ERROR: test specs file not found: $TEST_SPECS_FILE"; exit 1; }
[[ -f "$FINAL_PLAN_FILE" ]]          || { echo "ERROR: final plan file not found: $FINAL_PLAN_FILE"; exit 1; }
[[ -f "$BOUNDARY_CONDITIONS_FILE" ]] || { echo "ERROR: boundary conditions file not found: $BOUNDARY_CONDITIONS_FILE"; exit 1; }

MAX_RUNS=$(jq -s 'length' "$TASKS_FILE")
WORKSPACE_NAME=$(basename "$WORKSPACE_DIR")
LOG_DIR="$(dirname "$0")/logs/${WORKSPACE_NAME}"
mkdir -p "$LOG_DIR"
run=1
stall_count=0
prev_pending="$MAX_RUNS"

while (( run <= MAX_RUNS )); do
  current_pending=$(jq -s '[.[] | select((.status | ascii_downcase) == "pending")] | length' "$TASKS_FILE")

  if (( current_pending == 0 )); then
    echo "=== No pending tasks remaining. Done! ==="
    break
  fi

  # Thrash detection: if pending count hasn't decreased in 2 consecutive runs, bail
  if (( current_pending >= prev_pending )); then
    (( stall_count++ ))
  else
    stall_count=0
  fi

  if (( stall_count >= 2 )); then
    echo "ERROR: No progress in 2 consecutive runs ($current_pending tasks still pending). Stopping to avoid thrashing." >&2
    exit 1
  fi

  prev_pending="$current_pending"

  echo "=== Vera run #$run ($current_pending pending, model: $MODEL, effort: $EFFORT) ==="

  # Inject all Calmecac workspace paths into the prompt
  RENDERED_PROMPT=$(sed \
    -e "s|__TASKS_FILE__|${TASKS_FILE}|g" \
    -e "s|__REQUIREMENTS_FILE__|${REQUIREMENTS_FILE}|g" \
    -e "s|__TEST_SPECS_FILE__|${TEST_SPECS_FILE}|g" \
    -e "s|__FINAL_PLAN_FILE__|${FINAL_PLAN_FILE}|g" \
    -e "s|__BOUNDARY_CONDITIONS_FILE__|${BOUNDARY_CONDITIONS_FILE}|g" \
    "$PROMPT_FILE")

  LOG_FILE="${LOG_DIR}/vera_run_${run}.log"
  # Run claude from the project directory so git operations happen in the right repo
  echo "$RENDERED_PROMPT" | (cd "$PROJECT_DIR" && claude -p --model "$MODEL" --dangerously-skip-permissions --verbose) 2>&1 | tee "$LOG_FILE"

  echo "=== Completed run #$run ==="
  (( run++ ))
  sleep 1
done

if (( run > MAX_RUNS )); then
  echo "ERROR: Reached max runs ($MAX_RUNS) without clearing pending tasks" >&2
  exit 1
fi
