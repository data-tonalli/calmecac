# Ralph — Autonomous Task Loop

Ralph is a loop-based autonomous agent that executes Calmecac workspaces. Each invocation picks the highest-impact ready task, implements it, runs tests, commits, and exits. The shell runner (`run.sh`) re-invokes until all tasks are done or progress stalls.

## How It Works

1. `run.sh` reads the tasks file and counts pending tasks
2. It renders `PROMPT.md` with paths to all Calmecac workspace files
3. It pipes the rendered prompt to `claude -p` (headless mode)
4. Ralph (the agent) reads the workspace, selects a task, implements it, tests it, commits
5. `run.sh` checks if progress was made; if yes, loops; if stalled twice, stops

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- `jq` installed (for task counting)
- A completed Calmecac workspace (run `/calmecac` first)

## Directory Layout

```
.claude/ralph/
├── run.sh                 # Loop orchestrator
├── PROMPT.md              # Agent system prompt
├── README.md              # This file
├── CLAUDE.md              # Quick-reference for Claude sessions
└── logs/                  # Auto-created per run
    └── <workspace-name>/ralph_run_N.log
```

## Usage

Via Justfile (recommended):
```bash
just ralph <model> <effort>
```

Or directly:
```bash
.claude/ralph/run.sh path/to/calmecac-workspace <model> <effort>
```

| Arg | Options |
|-----|---------|
| workspace | Path to a Calmecac workspace directory |
| model | `sonnet`, `opus`, `haiku`, or full model ID |
| effort | `low`, `medium`, `high` |

**Example:**

```bash
just ralph sonnet high
.claude/ralph/run.sh /Users/me/dev/myapp/calmecac-auth sonnet high
```

## What Ralph Reads

From the Calmecac workspace:

| File | Purpose |
|------|---------|
| `01-socrates/boundary-conditions.md` | BC-001: where to write code |
| `04-zhuxi/final-plan.md` | Architectural context |
| `05-euclid/requirements.md` | What to build |
| `05-euclid/test-specs.md` | How to verify (TEST-XXX → concrete criteria) |
| `06-alkhwarizmi/tasks.jsonl` | What to do next |

## Task JSONL Schema

Each line in `tasks.jsonl` is a JSON object:

```json
{
  "id": "TASK-001",
  "title": "Define user input schema",
  "requirement": "REQ-001",
  "deps": [],
  "description": "Create the type definition for...",
  "done_when": "Type exists and is importable. TEST-001 passes.",
  "tests": ["TEST-001"],
  "invariants": [],
  "status": "pending"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | TASK-XXX identifier |
| `title` | string | Short descriptive title |
| `requirement` | string | REQ-XXX this task serves |
| `deps` | string[] | TASK-XXX IDs that must complete first |
| `description` | string | What to implement |
| `done_when` | string | Mechanically verifiable completion condition |
| `tests` | string[] | TEST-XXX references (resolved against test-specs.md) |
| `invariants` | string[] | INV-XXX IDs this task protects |
| `status` | string | `pending`, `in_progress`, `completed` |

## Safeguards

- **Anti-thrashing**: Stops if pending count doesn't decrease in 2 consecutive runs
- **Dependency-aware**: Won't start a task if its `deps` aren't all completed
- **Stuck detection**: If pending tasks exist but none are ready, stops immediately
- **Test backpressure**: Must pass all referenced tests before marking a task complete
- **Fresh context**: Each loop invocation reads actual files from disk
- **Atomic commits**: One task = one git commit

## Checking Workspace Status

```bash
# count pending
jq -s '[.[] | select((.status | ascii_downcase) == "pending")] | length' path/to/calmecac-workspace/06-alkhwarizmi/tasks.jsonl

# full summary
jq -s 'group_by(.status) | map({status: .[0].status, count: length})' path/to/calmecac-workspace/06-alkhwarizmi/tasks.jsonl
```
