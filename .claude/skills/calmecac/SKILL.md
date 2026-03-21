---
name: calmecac
description: >
  Use this skill for planning and decomposing complex coding tasks — greenfield
  or brownfield — that need structured thinking before implementation. Triggers
  include: requests to plan a feature, design a system, think through an
  architecture, identify requirements, prepare implementation specs, create tasks,
  or decompose work into implementable steps. Also use when the user says things
  like "help me think through", "let's plan", "I need to figure out how to build",
  "what are the requirements for", "break this into tasks", or mentions invariants,
  constraints, or boundary conditions. This skill takes a raw idea through six
  phases — discovery, construction, destruction, reconciliation, specification,
  and decomposition — producing an ordered task list ready for a coding loop.
  Use it whenever the task is complex enough that jumping straight to code would
  be risky.
---

# CALMECAC

A six-phase thinking workflow that transforms a raw idea into an ordered, atomic task list ready for a coding loop. No code is produced — only structured plans, requirements, test specifications, and tasks with full traceability.

## The Six Phases

| Phase | Teacher | Role |
|-------|---------|------|
| 1. Discovery | Socrates | Dialectical inquiry — question the idea to its core |
| 2. Construction | Khayyam | Systematic decomposition — produce an architectural plan |
| 3. Destruction | Popper | Falsificationism — attack the plan's assumptions |
| 4. Reconciliation | Zhuxi | Unifying frameworks — synthesize a stronger plan |
| 5. Specification | Euclid | Axiomatization — extract requirements and test specs |
| 6. Decomposition | Al-Khwarizmi | Algorithmic sequencing — produce atomic tasks |

Each phase has a human checkpoint. The human reviews, gives feedback or approves, and only then does the next phase begin.

---

## Initialization

On first invocation:

1. Greet the human briefly. Explain that CALMECAC will guide them through six phases of structured thinking to produce a ready-to-execute task list.
2. Ask for a short task name (used for the workspace folder). Examples: "auth-redesign", "data-pipeline", "hipaa-logging".
3. Create the workspace directory at `calmecac-{task-name}` in the current working directory with this structure:

```
calmecac-{task-name}/
├── context/
│   └── user-input.md
├── 01-socrates/
├── 02-khayyam/
├── 03-popper/
├── 04-zhuxi/
├── 05-euclid/
└── 06-alkhwarizmi/
```

4. Capture the user's initial idea/context and write it to `context/user-input.md`.
5. Read `agents/01-socrates.md` and begin Phase 1.

---

## Phase Definitions

### Phase 1 — Socrates (Discovery)

- Read `agents/01-socrates.md` and adopt the Socrates persona.
- Input context: The user's idea (from conversation and `context/user-input.md`).
- Interaction mode: **Conversational dialogue** with the human. Socrates is the ONLY teacher that engages in dialogue.
- Writes to: `01-socrates/spec.md`, `01-socrates/invariants.md`, `01-socrates/boundary-conditions.md`.
- Human checkpoint: Present all three files. Wait for approval or feedback.
- On approval: Read `agents/02-khayyam.md` and begin Phase 2.

### Phase 2 — Khayyam (Construction)

- Read `agents/02-khayyam.md` and adopt the Khayyam persona.
- Input context: Read ALL files from `01-socrates/`.
- Interaction mode: **Autonomous** — produce complete output without asking questions.
- Writes to: `02-khayyam/plan.md`, and optionally `02-khayyam/proposed-invariants.md`.
- Human checkpoint: Present outputs. Wait for approval or feedback.
- On approval: Read `agents/03-popper.md` and begin Phase 3.

### Phase 3 — Popper (Destruction)

- Read `agents/03-popper.md` and adopt the Popper persona.
- Input context: Read ALL files from `01-socrates/` AND `02-khayyam/`.
- Interaction mode: **Autonomous**.
- Writes to: `03-popper/refutations.md`, and optionally `03-popper/proposed-invariants.md`.
- Human checkpoint: Present outputs. Wait for approval or feedback.
- On approval: Read `agents/04-zhuxi.md` and begin Phase 4.

### Phase 4 — Zhuxi (Reconciliation)

- Read `agents/04-zhuxi.md` and adopt the Zhuxi persona.
- Input context: Read ALL files from `01-socrates/`, `02-khayyam/`, AND `03-popper/`.
- Interaction mode: **Autonomous**.
- Writes to: `04-zhuxi/final-plan.md`.
- Human checkpoint: Present output. Wait for approval or feedback.
- On approval: Read `agents/05-euclid.md` and begin Phase 5.

### Phase 5 — Euclid (Specification)

- Read `agents/05-euclid.md` and adopt the Euclid persona.
- Input context: Read `04-zhuxi/final-plan.md`.
- Interaction mode: **Autonomous**.
- Writes to: `05-euclid/requirements.md`, `05-euclid/test-specs.md`, `05-euclid/coverage-matrix.md`.
- Human checkpoint: Present all three files. Wait for approval or feedback.
- On approval: Read `agents/06-alkhwarizmi.md` and begin Phase 6.

### Phase 6 — Al-Khwarizmi (Decomposition)

- Read `agents/06-alkhwarizmi.md` and adopt the Al-Khwarizmi persona.
- Input context: Read ALL files from `05-euclid/`.
- Interaction mode: **Autonomous**.
- Writes to: `06-alkhwarizmi/tasks.jsonl`.
- Human checkpoint: Present the task file. Wait for approval or feedback.
- On approval: Announce that the Calmecac is complete and provide the path to `06-alkhwarizmi/tasks.jsonl`.

---

## Context Threading

Each teacher reads specific files from prior phases. This is the authoritative reference:

| Teacher | Reads from |
|---------|-----------|
| Socrates | User's idea (conversation + `context/user-input.md`) |
| Khayyam | `01-socrates/spec.md`, `invariants.md`, `boundary-conditions.md` |
| Popper | `01-socrates/spec.md`, `invariants.md`, `boundary-conditions.md` AND `02-khayyam/plan.md`, `proposed-invariants.md` (if exists) |
| Zhuxi | All files from `01-socrates/`, `02-khayyam/`, `03-popper/` |
| Euclid | `04-zhuxi/final-plan.md` |
| Al-Khwarizmi | `05-euclid/requirements.md`, `test-specs.md`, `coverage-matrix.md` |

Popper reads `01-socrates/invariants.md` as a separate input — not only through Khayyam's coverage matrix — so it can verify whether Khayyam missed or mischaracterized any invariants.

Euclid reads only Zhuxi's final plan because it is self-contained and already incorporates everything from prior phases.

Al-Khwarizmi reads only Euclid's outputs because the requirements, test specs, and coverage matrix contain everything needed to produce tasks.

---

## Feedback Handling

When the human provides feedback on any phase's output:

1. Remain in the current teacher's persona.
2. Incorporate the feedback.
3. **Overwrite** the relevant files (full overwrite, not append).
4. Re-present the updated outputs.
5. Wait for approval again.

This cycle repeats until the human approves. There is no limit on feedback rounds.

---

## Invariant Threading

Invariants are the thread that holds the entire Calmecac together:

1. **Born in Socrates** — IDs (INV-XXX), scope, assertion, violation consequence.
2. **Proposed by Khayyam** — if architecture implies new ones. IDs continue sequence.
3. **Proposed by Popper** — if critique reveals new ones. IDs continue sequence.
4. **Consolidated by Zhuxi** — single canonical list in final plan. Origin tracked.
5. **Traced by Euclid** — coverage matrix maps every invariant to requirements and tests.
6. **Carried by Al-Khwarizmi** — each task that protects an invariant references it.

Boundary conditions are FROZEN after Socrates. They describe the world as it is, not the plan.

---

## Completion

When the human approves Phase 6, the Calmecac is complete. Announce completion and provide the path to the task file:

> The Calmecac is complete. Your task list is ready at `calmecac-{task-name}/06-alkhwarizmi/tasks.jsonl`. Execute the tasks top to bottom — dependencies are satisfied by linear order.
