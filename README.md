# Welcome to the Calmecac. Bring your idea. The teachers are waiting.

## Two Commands

```bash
just calmecac <model> <effort>    # Plan what to build (interactive)
just ralph <model> <effort>       # Build it (autonomous)
```

**Models:** `sonnet` (balanced), `opus` (strongest), `haiku` (fastest/cheapest)
**Effort:** `low`, `medium`, `high`

## What Happens

### `just calmecac` — Plan

An interactive session where six teachers — drawn from six civilizations — guide you through structured thinking:

1. **Socrates** asks questions to clarify what you want to build
2. **Khayyam** designs the architecture
3. **Popper** attacks the plan to find weaknesses
4. **Zhu Xi** rebuilds the plan stronger
5. **Euclid** writes precise requirements and test specs
6. **Al-Khwarizmi** breaks everything into atomic tasks

You review and approve each phase. The output is a complete workspace with specs, requirements, tests, and an ordered task list.

### `just ralph` — Build

Ralph reads the workspace Calmecac produced and builds the project autonomously. One task at a time, tested, committed. It loops until everything is done or it gets stuck.

## Getting Started

1. Click **"Use this template"** on GitHub
2. Clone your new repo
3. Install [just](https://github.com/casey/just) and [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
4. Create your project directory and initialize git (or have an existing one):
   ```bash
   mkdir -p ~/dev/myproject && cd ~/dev/myproject && git init
   ```
5. Run `just calmecac sonnet high` — Calmecac will ask for the project location
6. When planning is done, run `just ralph sonnet high`

**Note:** The project location must be a separate directory with a git repository. Calmecac will verify this and offer to set it up if needed.

## What's Inside

```
Justfile                           ← your entry point
.claude/
├── skills/calmecac/               ← the planning skill (six phases)
└── ralph/                         ← the autonomous builder (loop runner)
examples/daily_poem/               ← a complete example workspace
```

## Example

See [examples/daily_poem/](examples/daily_poem/) for a complete Calmecac workspace produced from the idea: "a simple CLI tool that fetches a random poem."

## About

CALMECAC is named after the Aztec institution of higher learning where future leaders learned to think systematically. Its philosophy: think slowly and plan deliberately, so that coding can happen fast.

![calmecac](.claude/skills/calmecac/calmecac.png)
