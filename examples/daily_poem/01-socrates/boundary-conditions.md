# Boundary Conditions

| ID | Category | Condition | Source/Reason |
|--------|----------------|--------------------------------------------------------|----------------------------------|
| BC-001 | language | Implementation must be in Python | User requirement: "Create a Python API" |
| BC-002 | environment | Running on Unix-like systems (macOS, Linux) with home directory support (~/.cache, ~/.config) | User's expected environment; Windows support not mentioned |
| BC-003 | filesystem | User has read/write access to `~/.cache/` and `~/.config/` directories | Required for cache and config storage; standard user environment assumption |
| BC-004 | API source | A public poetry API exists and is accessible over HTTP/HTTPS | Required for poem fetching; specific API not yet identified |
| BC-005 | CLI integration | The tool must be runnable as a standalone command from the terminal | User requirement: single command `poem` from command line |
| BC-006 | distribution | The tool must be installable and executable as a CLI command (executable script or installed package) | User wants "proper RAS command" behavior; implies installation/setup phase |
| BC-007 | network | The tool requires internet connectivity to fetch poems from the remote API | Core feature dependency; graceful fallback handles loss of connectivity |
| BC-008 | tooling | UV is the standard tool for Python venv and dependency management | Project standard; all development uses `uv run`, `uv add`, etc. |
| BC-009 | project structure | Implementation code lives at `/Users/tonalli/dev/ollin/calmecac/poem/` | User confirmed; required for consistent tooling, uv, and console script setup |
