# Ralph — Autonomous Task Loop

Ralph is a loop-based autonomous agent that executes task lists produced by Calmecac. The shell runner (`run.sh`) re-invokes until all tasks are done or no progress is detected.

## Pipeline

```
/calmecac (skill)           →  ralph run.sh
 six-phase planning             executes tasks via loop
 produces workspace              one task per invocation
```

| Step | What | Produces |
|------|------|----------|
| 1 | `just calmecac <model> <effort>` | `{project}/calmecac-{name}/` workspace with specs, requirements, tests, tasks |
| 2 | `just ralph <model> <effort>` | Implementation code at `{project}/`, one git commit per task |

## Calmecac workspace structure (Ralph's input)

```
{project}/calmecac-{name}/
├── context/user-input.md
├── 01-socrates/
│   ├── spec.md
│   ├── invariants.md
│   └── boundary-conditions.md    ← BC-001 = project location
├── 02-khayyam/plan.md
├── 03-popper/refutations.md
├── 04-zhuxi/final-plan.md        ← architecture
├── 05-euclid/
│   ├── requirements.md            ← specs
│   ├── test-specs.md              ← verification criteria
│   └── coverage-matrix.md
└── 06-alkhwarizmi/tasks.jsonl     ← task list
```

## Invocation

```bash
just ralph <model> <effort>
```

Or directly:
```bash
.claude/ralph/run.sh {project}/calmecac-{name} <model> <effort>
```

- **model**: `sonnet`, `opus`, `haiku`, or full model ID
- **effort**: `low`, `medium`, `high`

## Task JSONL schema

```json
{"id": "TASK-001", "title": "...", "requirement": "REQ-001", "deps": [], "description": "...", "done_when": "...", "tests": ["TEST-001"], "invariants": ["INV-001"], "status": "pending"}
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

## Checking workspace status

```bash
# count pending
jq -s '[.[] | select((.status | ascii_downcase) == "pending")] | length' {workspace}/06-alkhwarizmi/tasks.jsonl

# full summary
jq -s 'group_by(.status) | map({status: .[0].status, count: length})' {workspace}/06-alkhwarizmi/tasks.jsonl
```
