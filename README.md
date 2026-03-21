# Welcome to the Calmecac. Bring your idea. The teachers are waiting.

## Calmecac

CALMECAC is a structured, six-phase thinking workflow that systematically plans and decomposes complex coding tasks before any code is written.

Named after the Aztec institution of higher learning where future leaders learned to think systematically, CALMECAC does not produce code. Instead, it takes a raw, half-baked idea and processes it to output a complete, battle-tested, and traceable list of atomic tasks that are ready for a coding loop to execute.

Its core philosophy is to think slowly and plan deliberately, so that coding can happen fast. The system avoids using a multi-agent swarm; instead, a single AI sequentially adopts the personas of six historical thinkers. A crucial feature of this workflow is the human-in-the-loop requirement: the human must review, give feedback, and approve the outputs at the end of every single phase before the AI moves on.

### The Six Phases

1. **Discovery (Socrates):** The only phase with conversational dialogue. Socrates asks focused questions to refine the project specification, establish boundary conditions (unchangeable facts about the environment), and define invariants (absolute rules the system must never violate).

2. **Construction (Omar Khayyam):** Working autonomously from Socrates's notes, Khayyam creates an architectural plan detailing what to build, how components will interact, and how they will protect the established invariants.

3. **Destruction (Karl Popper):** Popper actively attempts to break the architectural plan by attacking its assumptions and finding refutations or vulnerabilities.

4. **Reconciliation (Zhu Xi):** Zhu Xi reviews the original architecture and Popper's critiques to forge a unified, strengthened final plan that mitigates the discovered weaknesses.

5. **Specification (Euclid):** Euclid translates the final plan into strict, verifiable behavioral requirements, structured test specifications, and a coverage matrix proving all requirements and invariants are accounted for.

6. **Decomposition (Al-Khwarizmi):** The requirements and tests are broken down into the most atomic, unambiguous steps possible. The output is a JSONL file of tasks with explicit dependencies, ready for a coding loop to execute.

![calmecac](.claude/skills/calmecac/calmecac.png)

## Ralph — The Coding Loop

Ralph is the autonomous agent that executes Calmecac's output. It picks the highest-impact ready task, implements it, runs tests, commits, and exits. The shell runner re-invokes until all tasks are done or progress stalls.

See [ralph/README.md](ralph/README.md) for details.

## The Full Workflow

```
1. User has an idea
2. Run /calmecac                    → six phases of structured planning
3. Calmecac produces workspace      → {project}/calmecac-{name}/
4. Run ralph/run.sh on workspace    → code is built, tested, committed
```

### Step 1: Plan with Calmecac

In a Claude Code session, invoke the skill:

```
/calmecac
```

Calmecac will ask for:
- **Project location** — absolute path where implementation code will live
- **Task name** — short name for the planning workspace

Then guide you through six phases of structured thinking, producing a workspace at `{project-location}/calmecac-{task-name}/`.

### Step 2: Build with Ralph

```bash
./ralph/run.sh {project-location}/calmecac-{task-name} [model] [effort]
```

Ralph reads the workspace and builds the project, one task at a time.

## Usage

Click **"Use this template"** on GitHub to create a new repository from this template.

## Example

See [examples/daily_poem/](examples/daily_poem/) for a complete Calmecac workspace produced from the idea: "a simple CLI tool that fetches a random poem."
