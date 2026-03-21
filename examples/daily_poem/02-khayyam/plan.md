# Architectural Plan: daily_poem

## Summary

This plan decomposes the `poem` CLI tool into five autonomous, single-purpose components: a CLI entry point that is never vulnerable to crashes, an API fetcher that is tested for network resilience, a cache manager that guarantees persistence, a configuration loader that validates and defaults safely, and a display engine that renders poems according to user-defined templates. Together, they form a robust, stateless pipeline that always delivers a poem to the user—either fresh or cached—without exception. The approach prioritizes failure resilience, configurability, and simplicity: each component has one job, knows its boundaries, and handles its own errors before passing control onward.

---

## Components

### Component: CLI Entry Point (`poem_cli.py`)

- **Purpose:** Serve as the single executable entry point. Accept the `poem` command with no arguments, validate runtime environment (Python version, directory access), initialize the application, and orchestrate the pipeline. Guarantee that all exceptions are caught and no unhandled exception reaches the user.
- **Interfaces:**
  - **Input:** Command-line invocation (no arguments expected)
  - **Output:** Rendered poem or error message to stdout/stderr; exit code 0 on success, 1 on graceful fallback/warning
  - **Calls:** API Fetcher, Error Handler, Display Engine
- **Invariant coverage:**
  - **INV-001:** Wrapped in try-except at the highest level; all exceptions caught and converted to user-friendly messages or graceful fallback
  - **INV-007:** Implements entry point that works from any directory (uses absolute paths for home directories, respects $HOME or pwd.getpwall)
- **Boundary condition compliance:**
  - **BC-001:** Written in Python
  - **BC-005:** Designed as a terminal-callable command
  - **BC-006:** Will be installed as a console script via setuptools or similar
  - **BC-002:** Uses `os.path.expanduser()` for Unix-like path handling
- **Dependencies:** API Fetcher, Cache Manager, Config Loader, Display Engine, Error Handler

---

### Component: API Fetcher (`api_fetcher.py`)

- **Purpose:** Encapsulate all network I/O. Contact the remote poetry API, parse the JSON response, and extract author, title, and poem body. Return a `Poem` object or raise a `FetchError` on any failure (timeout, connection error, invalid response).
- **Interfaces:**
  - **Input:** None (stateless)
  - **Output:** `Poem(author: str, title: str, body: str)` or raises `FetchError(reason: str)`
  - **External dependency:** HTTP(S) request library (e.g., `requests` or `urllib3`)
- **Invariant coverage:**
  - **INV-004:** Always attempts to extract author and title from API response; raises `FetchError` if missing (never returns incomplete poem)
- **Boundary condition compliance:**
  - **BC-004:** Targets a specific public poetry API (TBD: PoetryDB, Poetry API, or similar—will be researched during implementation)
  - **BC-007:** Designed to fail fast on network unavailability; no retry logic at this layer
- **Dependencies:** None (isolated from other components)

---

### Component: Cache Manager (`cache_manager.py`)

- **Purpose:** Manage the local poem cache at `~/.cache/poem/`. Write fetched poems to disk, retrieve the most recent cached poem on demand, and handle filesystem errors gracefully.
- **Interfaces:**
  - **Input (save):** `Poem` object
  - **Output (save):** None (side effect: writes to `~/.cache/poem/`)
  - **Input (load):** None
  - **Output (load):** `Poem` object (any cached poem) or raises `NoCachedPoemError` if cache is empty
  - **Calls:** None
- **Invariant coverage:**
  - **INV-003:** Poems are written to disk with write-through semantics; retrieval is guaranteed to succeed if any prior poem was cached
  - **INV-002:** Fallback to cached poem is always possible (unless cache is empty on first run)
- **Boundary condition compliance:**
  - **BC-002:** Uses `~/.cache/poem/` on Unix-like systems; respects `$XDG_CACHE_HOME` if set
  - **BC-003:** Assumes user has read/write access; fails gracefully if permissions are denied
- **Dependencies:** None

---

### Component: Config Loader (`config_loader.py`)

- **Purpose:** Read and validate the display configuration at `~/.config/poem/display.yaml`. Parse the YAML, extract formatting directives (title format, author format, body spacing, separators), and return a `DisplayConfig` object. If the file is missing, return sensible defaults. If the file is malformed, raise `ConfigError`.
- **Interfaces:**
  - **Input:** None (reads from filesystem)
  - **Output:** `DisplayConfig(title_format: str, author_format: str, body_format: str, separators: dict)` or raises `ConfigError(reason: str)`
  - **External dependency:** YAML parser (e.g., `pyyaml`)
- **Invariant coverage:**
  - **INV-006:** Validates YAML syntax before returning; raises `ConfigError` on parse failure or missing required keys; defaults are safe and sensible
- **Boundary condition compliance:**
  - **BC-002:** Uses `~/.config/poem/` on Unix-like systems; respects `$XDG_CONFIG_HOME` if set
  - **BC-003:** Assumes user has read access; fails gracefully if permissions are denied
- **Dependencies:** None

---

### Component: Display Engine (`display_engine.py`)

- **Purpose:** Format and render a `Poem` object to stdout according to a `DisplayConfig`. Apply the user's template (title format, author format, body layout) to produce human-readable output. Always include author and title in the output.
- **Interfaces:**
  - **Input:** `Poem` object, `DisplayConfig` object, optional `warning_message: str`
  - **Output:** Rendered text to stdout
  - **Calls:** Config Loader (to get default config if none provided)
- **Invariant coverage:**
  - **INV-004:** Always renders author and title, even if the template doesn't explicitly request them (minimum fields guaranteed)
  - **INV-005:** If `warning_message` is provided, prints it to stderr before the poem
- **Boundary condition compliance:**
  - **BC-002:** Uses `stdout` and `stderr` for terminal output
- **Dependencies:** Config Loader

---

### Component: Error Handler (`error_handler.py`)

- **Purpose:** Centralized error recovery logic. When any component fails (API Fetcher, Cache Manager, Config Loader), decide whether to gracefully degrade to a cached poem or exit with an error. Formulate appropriate user-facing messages.
- **Interfaces:**
  - **Input:** Exception type, original error message, context (e.g., was API fetch or cache load?)
  - **Output:** `ErrorRecoveryDecision(action: 'use_cached_poem' | 'exit_with_error', message: str, exit_code: int)`
  - **Calls:** Cache Manager (to attempt fallback retrieval)
- **Invariant coverage:**
  - **INV-001:** All exceptions are caught here; no unhandled exception propagates to CLI
  - **INV-002:** If API fetch fails, immediately attempts to load cached poem; user always sees either fresh or cached poem
  - **INV-005:** Formulates the warning message "Could not fetch live poem. Showing cached poem."
- **Boundary condition compliance:**
  - **BC-007:** Handles network errors gracefully; assumes fallback is possible if cache exists
- **Dependencies:** Cache Manager

---

## Interfaces Between Components

| Interface | From | To | Contract |
|-----------|------|----|----|
| **fetch()** | CLI Entry Point | API Fetcher | Fetches a poem from the API. Returns `Poem(author, title, body)` or raises `FetchError`. No retry logic. |
| **save(poem)** | API Fetcher result handler | Cache Manager | Persists a poem to `~/.cache/poem/`. Fire-and-forget; failures are logged but non-fatal. |
| **load_cached()** | Error Handler, CLI fallback | Cache Manager | Retrieves any cached poem. Returns `Poem` or raises `NoCachedPoemError` if cache is empty. |
| **load_config()** | Display Engine | Config Loader | Loads `~/.config/poem/display.yaml` and returns `DisplayConfig`. Returns sensible defaults if file missing. Raises `ConfigError` if malformed. |
| **render(poem, config, warning)** | CLI Entry Point | Display Engine | Formats `Poem` according to `DisplayConfig` and prints to stdout. Prints warning to stderr if provided. |
| **handle_error(exception, context)** | CLI Entry Point (in except block) | Error Handler | Decides recovery action: use cached poem or exit. Returns `ErrorRecoveryDecision`. |

---

## Implementation Order

1. **API Fetcher** (first)
   - Why first: Identifies which public poetry API to use and validates that fetching works before building other components. Unblocks Cache Manager and Display Engine.

2. **Cache Manager** (second)
   - Why second: Depends only on the `Poem` data structure; unblocks Error Handler and fallback logic.

3. **Config Loader** (third)
   - Why third: Reads from filesystem; should be validated early. Unblocks Display Engine.

4. **Display Engine** (fourth)
   - Why fourth: Depends on both Cache Manager and Config Loader. Ready once both are tested.

5. **Error Handler** (fifth)
   - Why fifth: Orchestrates Cache Manager and formulates messages. Ready once both Cache Manager and Config Loader are stable.

6. **CLI Entry Point** (sixth)
   - Why last: Depends on all other components. Integrated last so that unit tests of individual components can run first.

---

## Invariant Coverage Matrix

| Invariant | Protected By | Mechanism |
|-----------|------------------------|----------------------------------------------|
| INV-001 | CLI Entry Point, Error Handler | CLI wraps entire pipeline in try-except; Error Handler converts all exceptions to graceful fallback or safe error message. |
| INV-002 | Error Handler, Cache Manager | When API Fetcher fails, Error Handler immediately calls Cache Manager to load cached poem; always delivers a poem. |
| INV-003 | Cache Manager | Cache Manager writes to disk with OS-level atomicity (write to temp file, rename). Persistence guaranteed across invocations. |
| INV-004 | API Fetcher, Display Engine | API Fetcher validates that author and title are present in API response; Display Engine always renders both fields, even if config omits them. |
| INV-005 | Error Handler, Display Engine | Error Handler formulates warning message; Display Engine prints it to stderr before the poem. |
| INV-006 | Config Loader | Config Loader parses YAML with validation; raises `ConfigError` if malformed. Graceful fallback to sensible defaults if file missing. |
| INV-007 | CLI Entry Point | Entry point uses `os.path.expanduser()` and absolute paths; does not depend on current working directory. |
