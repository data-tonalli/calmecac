# Welcome to the Calmecac. Bring your idea. The teachers are waiting.
## Calmecac
CALMECAC is a structured, six-phase "thinking workflow" designed to systematically plan and decompose complex coding tasks before any code is written
.
Named after the Aztec institution of higher learning where future leaders learned to think systematically, CALMECAC does not produce code. Instead, it takes a raw, half-baked idea and processes it to output a complete, battle-tested, and traceable list of atomic tasks that are ready for a separate coding loop to execute
.
Its core philosophy is to think slowly and plan deliberately, so that coding can happen fast
. The system avoids using a multi-agent swarm; instead, a single AI sequentially adopts the personas of six historical thinkers
. A crucial feature of this workflow is the human-in-the-loop requirement: the human must review, give feedback, and approve the outputs at the end of every single phase before the AI moves on
.
The workflow is divided into the following six phases:
1. Discovery (Socrates): This is the only phase that engages in conversational dialogue with the user. Socrates asks focused questions to refine the project specifications, establish "boundary conditions" (unchangeable facts about the environment, like the existing database), and define "invariants" (absolute rules the system must never violate)
.
2. Construction (Omar Khayyam): Working autonomously from Socrates's notes, Khayyam creates an architectural plan detailing what to build, how components will interact, and how they will protect the established invariants
.
3. Destruction (Karl Popper): This phase acts as a stress test. Popper actively attempts to break the architectural plan by attacking its assumptions and finding refutations or vulnerabilities
.
4. Reconciliation (Zhu Xi): Zhu Xi reviews the original architecture and Popper's critiques to forge a unified, strengthened final plan that mitigates the discovered weaknesses
.
5. Specification (Euclid): Euclid translates the final plan into strict, verifiable behavioral requirements. This phase also generates structured test specifications and a coverage matrix to prove that all requirements and invariants are accounted for
.
6. Decomposition (Al-Khwarizmi): In the final phase, the requirements and tests are broken down into the most atomic, unambiguous steps possible. The output is a highly ordered JSONL file of tasks designed so that a coding agent can execute them top-to-bottom without ever hitting a missing dependency

![calmecac](".claude/skills/calmecac/calmecac.png")


## Usage
Click **"Use this template"** on GitHub to create a new repository from this template.
