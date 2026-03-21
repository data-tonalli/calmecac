# Welcome to the Calmecac. Bring your idea. The teachers are waiting.

## Two Commands

```bash
just plan <model> <effort>     # Plan what to build (interactive)
just build <model> <effort>    # Build it (autonomous)
```

**Models:** `sonnet` (balanced), `opus` (strongest), `haiku` (fastest/cheapest)
**Effort:** `low`, `medium`, `high`

## What Happens

### `just plan` — Plan

An interactive session where six teachers — drawn from six civilizations — guide you through structured thinking:

1. **Socrates** asks questions to clarify what you want to build
2. **Khayyam** designs the architecture
3. **Popper** attacks the plan to find weaknesses
4. **Zhu Xi** rebuilds the plan stronger
5. **Euclid** writes precise requirements and test specs
6. **Al-Khwarizmi** breaks everything into atomic tasks

You review and approve each phase. The output is a complete workspace with specs, requirements, tests, and an ordered task list.

### `just build` — Build

Vera reads the workspace the plan produced and builds the project autonomously. One task at a time, tested, committed. It loops until everything is done or it gets stuck.

## Getting Started

1. Click **"Use this template"** on GitHub
2. Clone your new repo
3. Install [just](https://github.com/casey/just) and [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
4. Create your project directory and initialize git (or have an existing one):
   ```bash
   mkdir -p ~/dev/myproject && cd ~/dev/myproject && git init
   ```
5. Run `just plan sonnet high` — the plan skill will ask for the project location
6. When planning is done, run `just build sonnet high`

**Note:** The project location must be a separate directory with a git repository. The plan skill will verify this and offer to set it up if needed.

## What's Inside

```
Justfile                           ← your entry point
.claude/
├── skills/plan/                   ← the planning skill (six phases)
└── skills/build/                  ← Vera, the autonomous builder (loop runner)
examples/daily_poem/               ← a complete example workspace
```

## The Teachers

Six teachers from six civilizations guide the planning phases:

| Phase | Teacher | Tradition | Role |
|-------|---------|-----------|------|
| 1 | Socrates | Ancient Greece | Dialectical inquiry |
| 2 | Khayyam | Medieval Persia | Systematic decomposition |
| 3 | Popper | 20th-century Vienna | Falsificationism |
| 4 | Zhu Xi | Song Dynasty China | Synthesis |
| 5 | Euclid | Ancient Alexandria | Axiomatization |
| 6 | Al-Khwarizmi | Abbasid Baghdad | Algorithmic sequencing |

## The Builder

**Vera Rubin** (1928–2016) executes the plan.

Vera Rubin was an American astronomer whose meticulous observation of galaxy rotation curves provided the strongest evidence that the universe is dominated by dark matter — mass that is real but invisible. Despite facing systemic barriers throughout her career (she was denied access to observatories, excluded from talks, told astronomy wasn't for women), she kept observing, kept measuring, and kept following the evidence wherever it led. She is named a builder here because she embodies what it means to do the work: systematic, evidence-driven, thorough, and relentless.

## Example

See [examples/daily_poem/](examples/daily_poem/) for a complete workspace produced from the idea: "a simple CLI tool that fetches a random poem."

## About

CALMECAC is named after the Aztec institution of higher learning where future leaders learned to think systematically. Its philosophy: think slowly and plan deliberately, so that coding can happen fast.

![calmecac](.claude/skills/plan/calmecac.png)
