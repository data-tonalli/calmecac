# Bring your idea to the calmecac.

CALMECAC is named after the Aztec institution of higher learning. Its philosophy: think slowly and plan deliberately, so that coding can happen fast.

## Why Calmecac?

**The problem with current agentic coding:** Most approaches jump straight into code generation ("YOLO coding"). This leads to messy architectures, unhandled edge cases, missing dependencies, and brittle tests that constantly need fixing.

**The Calmecac approach:** We make human software engineering expertise explicit. Calmecac uses a structured, multi-persona planning phase to catch architectural flaws and missing requirements *before* a single line of code is written. 

### Case Study: A simple API CLI
When asked to build a simple Python CLI to fetch a haiku, `just plan` didn't just write a script. It simulated a rigorous 6-phase planning council:
- **01-socrates:** Defined 10 code invariants and 7 boundary conditions
- **02-khayyam:** Drafted a 5-component architectural plan
- **03-popper:** Refuted vulnerabilities (e.g., endpoint strategy, stderr usage, PyPI package naming collisions)
- **04-zhuxi:** Consolidated the debate into a unified, robust plan
- **05-euclid:** Generated 31 explicit requirements and 33 test specs with full coverage matrices
- **06-alkhwarizmi:** Broke execution down into 21 atomic tasks with zero missing dependencies

*The Result:* When `just build` was run, the autonomous coding agent executed 15+ strict Test-Driven Development (TDD) cycles sequentially. Every test passed. No hallucinations. **Think slowly, code fast.**

The resulting package is live—try it yourself: [calmecac-haiku on PyPI](https://pypi.org/project/calmecac-haiku/) (`uv tool install calmecac-haiku`).

## Two Commands

```bash
just plan <model> <effort>     # Plan what to build (interactive)
just build <model> <effort>    # Build it (autonomous, TDD)
```

**Models:** `sonnet` (balanced), `opus` (strongest), `haiku` (fastest/cheapest)  
**Effort:** `low`, `medium`, `high` — controls how much reasoning Claude applies per step

## Requirements

- [just](https://github.com/casey/just)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## Quick Start

1. Click **"Use this template"** on GitHub and clone your repo
2. Create your project directory: `mkdir -p ~/dev/myproject`
3. Initialize git inside it: `cd ~/dev/myproject && git init`
4. Run `just plan sonnet high`
5. Run `just build sonnet high`

## What's Inside

```
Justfile                           ← your entry point
.claude/
├── skills/plan/                   ← the planning skill (six phases)
└── skills/build/                  ← Vera, the autonomous builder (loop runner)
```

## Docs
- [Personas](docs/personas.md) — the six teachers and Vera Rubin
- [Plan skill](.claude/skills/plan/SKILL.md) — the six-phase planning workflow
- [Build skill](.claude/skills/build/CLAUDE.md) — Vera's loop runner and task schema
