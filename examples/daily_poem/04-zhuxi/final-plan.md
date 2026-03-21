# Final Plan: daily_poem

## Executive Summary

The `poem` CLI tool fetches random poems from a public poetry API and displays them to the terminal with grace, simplicity, and resilience. The plan integrates Khayyam's component-based architecture with Popper's refutations, strengthening it through five explicit mitigations:

1. A defined cache format (JSON) and retention policy (latest only)
2. A specified default display configuration that guarantees author/title visibility
3. A decision tree for Error Handler that covers all failure modes, including first-run with no cache
4. Atomic writes to prevent cache corruption under concurrent access
5. A pre-implementation research task to validate a working poetry API

The result is a robust, failure-resilient pipeline that always delivers a poem—either fresh or cached—or provides a clear, honest error message.

---

## Consolidated Invariants

| ID | Scope | Assertion | Violation Consequence | Origin |
|---------|---------------|--------------------------------------------------------|---------------------------------|-----------|
| INV-001 | system-wide | The tool must never crash or raise an unhandled exception to the user | User loses trust; tool becomes unusable | Socrates |
| INV-002 | system-wide | If the API is unreachable, a cached poem must be displayed with a warning, or a fallback message shown | User sees broken tool behavior; no fallback experience | Socrates |
| INV-003 | cache layer | Cached poems must persist across tool invocations | Fallback mechanism fails; user sees nothing on API failure | Socrates |
| INV-004 | output layer | Every displayed poem must include author name and poem title (if available in the source) | User cannot attribute or understand the poem | Socrates |
| INV-005 | output layer | When displaying a cached or fallback poem, a clear status message must be visibly displayed to the user | User does not know they are seeing stale or fallback data | Socrates |
| INV-006 | configuration layer | If `~/.config/poem/display.yaml` exists, it must be a valid, readable YAML file or the tool must fail gracefully | Malformed config crashes the tool or produces corrupted output | Socrates |
| INV-007 | system-wide | The `poem` command must be executable from any terminal working directory | User experience is broken if tool only works in specific directories | Socrates |

---

## Boundary Conditions

| ID | Category | Condition | Source/Reason |
|--------|----------------|--------------------------------------------------------|----------------------------------|
| BC-001 | language | Implementation must be in Python | User requirement: "Create a Python API" |
| BC-002 | environment | Running on Unix-like systems (macOS, Linux) with home directory support (~/.cache, ~/.config) | User's expected environment; Windows support not mentioned |
| BC-003 | filesystem | User has read/write access to `~/.cache/` and `~/.config/` directories | Required for cache and config storage; standard user environment assumption |
| BC-004 | API source | A public poetry API exists and is accessible over HTTP/HTTPS that provides random poems with author and title | Required for poem fetching; must be validated before implementation begins |
| BC-005 | CLI integration | The tool must be runnable as a standalone command from the terminal | User requirement: single command `poem` from command line |
| BC-006 | distribution | The tool must be installable and executable as a CLI command (console script entry point) | User wants "proper CLI command" behavior; implies installation/setup phase |
| BC-007 | network | The tool requires internet connectivity to fetch poems from the remote API | Core feature dependency; graceful fallback handles loss of connectivity |
| BC-008 | tooling | UV is the standard tool for Python venv and dependency management | Project standard; all development uses `uv run`, `uv add`, etc. |
| BC-009 | project structure | Implementation code lives at `/Users/tonalli/dev/ollin/calmecac/poem/` | User confirmed; required for consistent tooling, uv, and console script setup |

---

## Architecture

### Component: CLI Entry Point (`poem_cli.py`)

- **Purpose:** Serve as the single executable entry point. Accept the `poem` command with no arguments, validate runtime environment (Python version, directory access), initialize the application, and orchestrate the pipeline. Guarantee that all exceptions are caught and no unhandled exception reaches the user.
- **Interfaces:**
  - **Input:** Command-line invocation (no arguments expected)
  - **Output:** Rendered poem to stdout with optional status message to stderr; exit code 0 on success, 1 on fallback or graceful error
  - **Calls:** API Fetcher, Error Handler, Display Engine
- **Invariant coverage:**
  - **INV-001:** Wrapped in try-except at the highest level; all exceptions caught and converted to user-friendly messages or graceful fallback
  - **INV-007:** Uses absolute paths (via `os.path.expanduser()`) and does not depend on current working directory
- **Boundary condition compliance:**
  - **BC-001:** Written in Python
  - **BC-005:** Designed as a terminal-callable command
  - **BC-006:** Will be installed as a console script via setuptools or similar
  - **BC-002:** Uses `os.path.expanduser()` for Unix-like path handling
- **Dependencies:** API Fetcher, Cache Manager, Config Loader, Display Engine, Error Handler
- **Refutation responses:**
  - **First-Run Failure:** Error Handler now has a decision tree that handles empty cache by showing an honest error message. See Refutation #5 response.
  - **Error Handler Decision Logic:** CLI orchestrates Error Handler's decision tree. See Refutation #5 response.

---

### Component: API Fetcher (`api_fetcher.py`)

- **Purpose:** Encapsulate all network I/O. Contact the remote poetry API, parse the JSON response, and extract author, title, and poem body. Return a `Poem` object or raise a `FetchError` on any failure (timeout, connection error, invalid response).
- **Interfaces:**
  - **Input:** None (stateless)
  - **Output:** `Poem(author: str, title: str, body: str)` or raises `FetchError(reason: str)`
  - **External dependency:** HTTP(S) request library (e.g., `requests` or `urllib3`); configured with a 5-second timeout
- **Invariant coverage:**
  - **INV-004:** Always attempts to extract author and title from API response; raises `FetchError` if missing (never returns incomplete poem)
- **Boundary condition compliance:**
  - **BC-004:** Will target a specific public poetry API (to be determined by pre-implementation research; candidate APIs include PoetryDB, Poetry API, or similar)
  - **BC-007:** Designed to fail fast on network unavailability; network timeout set to 5 seconds; no retry logic at this layer
- **Dependencies:** None (isolated from other components)
- **Refutation responses:**
  - **API Selection Deferred:** Added to Open Questions (below); research task required before implementation.

---

### Component: Cache Manager (`cache_manager.py`)

- **Purpose:** Manage the local poem cache at `~/.cache/poem/`. Write fetched poems to disk, retrieve the most recent cached poem on demand, and handle filesystem errors gracefully.
- **Interfaces:**
  - **Input (save):** `Poem` object
  - **Output (save):** None (side effect: writes to `~/.cache/poem/poem_cache.json`)
  - **Input (load):** None
  - **Output (load):** `Poem` object or raises `NoCachedPoemError` if cache is empty
  - **Calls:** None
- **Invariant coverage:**
  - **INV-003:** Poems are written to disk with atomic write semantics (write to temp file, then rename); retrieval is guaranteed to succeed if any prior poem was cached
  - **INV-002:** Fallback to cached poem is possible if cache is populated; empty cache raises `NoCachedPoemError` (handled by Error Handler with fallback message)
- **Boundary condition compliance:**
  - **BC-002:** Uses `~/.cache/poem/` on Unix-like systems; respects `$XDG_CACHE_HOME` if set
  - **BC-003:** Assumes user has read/write access; fails gracefully if permissions are denied
- **Dependencies:** None
- **Refutation responses:**
  - **Cache Storage Format:** Cache stores poems as JSON in `~/.cache/poem/poem_cache.json` with schema: `{"author": str, "title": str, "body": str, "timestamp": ISO8601 datetime}`. Retention policy: keep latest only (replace on each new successful fetch).
  - **Concurrency:** Uses atomic writes (write to `~/.cache/poem/poem_cache.tmp`, then rename to `~/.cache/poem/poem_cache.json`). This is sufficient for the low-concurrency scenario of a CLI tool.

---

### Component: Config Loader (`config_loader.py`)

- **Purpose:** Read and validate the display configuration at `~/.config/poem/display.yaml`. Parse the YAML, extract formatting directives, and return a `DisplayConfig` object. If the file is missing, return sensible defaults. If the file is malformed, raise `ConfigError`.
- **Interfaces:**
  - **Input:** None (reads from filesystem)
  - **Output:** `DisplayConfig` with schema: `{title_format: str, author_format: str, body_format: str}` or raises `ConfigError(reason: str)`
  - **External dependency:** YAML parser (e.g., `pyyaml`)
- **Default DisplayConfig** (when config file is missing or file operations fail):
  ```
  {
    "title_format": "Title: {title}",
    "author_format": "Author: {author}",
    "body_format": "{body}"
  }
  ```
- **Invariant coverage:**
  - **INV-006:** Validates YAML syntax before returning; raises `ConfigError` on parse failure. Graceful fallback to defaults (above) if file missing or unreadable. Defaults guarantee author/title visibility (protecting INV-004).
- **Boundary condition compliance:**
  - **BC-002:** Uses `~/.config/poem/` on Unix-like systems; respects `$XDG_CONFIG_HOME` if set
  - **BC-003:** Assumes user has read access; falls back to defaults if permissions are denied
- **Dependencies:** None
- **Refutation responses:**
  - **Config Loader Defaults:** Defaults are now explicitly defined (above). Display Engine will always render author and title using these defaults, even if user config is missing.

---

### Component: Display Engine (`display_engine.py`)

- **Purpose:** Format and render a `Poem` object to stdout according to a `DisplayConfig`. Apply the user's template (title format, author format, body layout) to produce human-readable output. Always include author and title in the output, even if the config template omits them.
- **Interfaces:**
  - **Input:** `Poem` object, `DisplayConfig` object, optional `status_message: str` (e.g., warning about cached/fallback poem)
  - **Output:** Rendered text to stdout; status message (if provided) to stderr
  - **Calls:** None directly; receives DisplayConfig from CLI orchestration
- **Invariant coverage:**
  - **INV-004:** Always renders author and title, enforced at the engine level. If config omits fields, engine still includes them with sensible defaults (e.g., "Title: {title}" if config doesn't specify title_format).
  - **INV-005:** If `status_message` is provided (e.g., "⚠️ Could not fetch live poem. Showing cached poem."), prints it to stderr before the poem.
- **Boundary condition compliance:**
  - **BC-002:** Uses `stdout` and `stderr` for terminal output
- **Dependencies:** None
- **Refutation responses:**
  - **Config Loader Defaults:** Works in tandem with Config Loader. If config is missing or invalid, Config Loader provides defaults, which Display Engine applies. INV-004 is protected by both components.

---

### Component: Error Handler (`error_handler.py`)

- **Purpose:** Centralized error recovery logic. When any component fails, decide whether to gracefully degrade to a cached poem, show a fallback message, or exit with an error. Formulate appropriate user-facing messages.
- **Interfaces:**
  - **Input:** Exception type, original error message, context (e.g., source: API fetch, cache load, config load)
  - **Output:** `ErrorRecoveryDecision(action: 'show_poem' | 'show_error', poem: Poem | None, status_message: str, exit_code: int)`
  - **Calls:** Cache Manager (to attempt fallback retrieval)
- **Error Handler Decision Tree:**
  - **API Fetcher raises `FetchError`:** Attempt to load cached poem. If successful, show cached poem with status message "⚠️ Could not fetch live poem. Showing cached poem." (exit code 0). If cache is empty, show fallback message "⚠️ Could not fetch poem. No cached poem available. Please check your internet connection and try again." (exit code 1).
  - **Config Loader raises `ConfigError`:** Use defaults and show status message "⚠️ Configuration error. Using default display format." (exit code 0). Continue and show poem using default config.
  - **Cache Manager raises `NoCachedPoemError` during fallback:** Handled above (show fallback message, exit code 1).
  - **Any other unexpected exception:** Catch and show generic error message "An unexpected error occurred. Please report this." (exit code 1).
- **Invariant coverage:**
  - **INV-001:** All exceptions are caught here; no unhandled exception propagates to CLI
  - **INV-002:** If API fetch fails and cache exists, immediately shows cached poem. If cache is empty, shows honest fallback message (does not pretend a poem is available).
  - **INV-005:** Formulates all status messages and ensures they are displayed to stderr
- **Boundary condition compliance:**
  - **BC-007:** Handles network errors gracefully with multi-tier fallback
- **Dependencies:** Cache Manager
- **Refutation responses:**
  - **First-Run Failure:** Error Handler now explicitly handles empty cache on first run with a fallback message. User always sees either a poem (fresh or cached) or a clear explanation of why no poem is available.
  - **Error Handler Decision Logic:** Decision tree is now fully specified (above).

---

## Interfaces Between Components

| Interface | From | To | Contract |
|-----------|------|----|----|
| **fetch()** | CLI Entry Point | API Fetcher | Fetches a poem from the API. Returns `Poem(author, title, body)` or raises `FetchError`. No retry logic. 5-second timeout. |
| **save(poem)** | API Fetcher success path | Cache Manager | Persists a poem to `~/.cache/poem/poem_cache.json` using atomic write (temp file + rename). Fire-and-forget; failures logged to stderr but non-fatal. |
| **load_cached()** | Error Handler | Cache Manager | Retrieves the most recent cached poem. Returns `Poem` or raises `NoCachedPoemError` if cache file does not exist or is empty. |
| **load_config()** | CLI Entry Point or Display Engine | Config Loader | Loads `~/.config/poem/display.yaml` and returns `DisplayConfig`. Returns sensible defaults if file missing or unreadable. Raises `ConfigError` if YAML parsing fails. |
| **render(poem, config, status_message)** | CLI Entry Point | Display Engine | Formats `Poem` according to `DisplayConfig` and prints to stdout. Prints `status_message` to stderr if provided. Always includes author and title. |
| **handle_error(exception, context)** | CLI Entry Point (in except block) | Error Handler | Decides recovery action using decision tree (above). Returns `ErrorRecoveryDecision(action, poem, status_message, exit_code)`. |

---

## Implementation Order

1. **API Fetcher** (first)
   - Why first: Validates that a public poetry API meeting requirements exists and is accessible. Pre-implementation research required (see Open Questions).

2. **Cache Manager** (second)
   - Why second: Depends only on the `Poem` data structure. Tested with atomic write semantics. Unblocks Error Handler and fallback logic.

3. **Config Loader** (third)
   - Why third: Reads from filesystem; should be validated early. Unblocks Display Engine. Tested with default fallback.

4. **Display Engine** (fourth)
   - Why fourth: Depends on Config Loader. Tested to ensure author/title always rendered, even with missing config.

5. **Error Handler** (fifth)
   - Why fifth: Orchestrates Cache Manager and applies decision tree. Ready once both Cache Manager and Config Loader are stable.

6. **CLI Entry Point** (sixth)
   - Why last: Depends on all other components. Integrated last. Top-level try-except orchestrates entire pipeline.

---

## Invariant Coverage Matrix

| Invariant | Protected By | Mechanism |
|-----------|------------------------|----------------------------------------------|
| INV-001 | CLI Entry Point, Error Handler | CLI wraps entire pipeline in try-except at highest level. Error Handler catches all component failures and converts to safe states (poem display or error message). No code path raises unhandled exception. |
| INV-002 | Error Handler, Cache Manager | When API Fetcher fails, Error Handler attempts Cache Manager load. If cache exists, shows cached poem. If cache is empty on first run, Error Handler shows honest fallback message (does not crash or hide failure). |
| INV-003 | Cache Manager | Uses atomic writes (temp file + rename) to ensure partial writes don't corrupt cache. Persistence guaranteed even under concurrent access. Schema versioned for forward compatibility. |
| INV-004 | API Fetcher, Config Loader, Display Engine | API Fetcher validates presence of author/title in API response. Config Loader ensures default display config includes both fields. Display Engine enforces minimum render of author and title regardless of config. Triple protection. |
| INV-005 | Error Handler, Display Engine | Error Handler formulates all status messages (cached warning, fallback message, config error message). Display Engine prints status message to stderr before the poem. User always sees status clearly. |
| INV-006 | Config Loader | Validates YAML syntax and raises `ConfigError` if malformed. Graceful fallback to defaults (above) if file missing or unreadable. Defaults guarantee safety and readability. |
| INV-007 | CLI Entry Point | Uses `os.path.expanduser()` and `$XDG_CACHE_HOME`/`$XDG_CONFIG_HOME` environment variables. All paths are absolute. Does not depend on current working directory. Verified to work from any terminal location. |

---

## Refutation Disposition

| Refutation | Disposition | Explanation |
|-----------------------------|--------------------------|----------------------------------------------|
| First-Run Failure | Plan changed | Added Error Handler decision tree that handles empty cache on first run. Shows fallback message "Could not fetch poem. No cached poem available..." (exit code 1) instead of crashing. INV-002 reworded to reflect this two-tier fallback (cached poem if available, else message). |
| Cache Storage Format | Plan changed | Specified cache format: JSON file at `~/.cache/poem/poem_cache.json` with schema `{author, title, body, timestamp}`. Retention policy: latest only (replace on each successful fetch). Atomic writes (temp + rename) added to Cache Manager. |
| Config Loader Defaults | Plan changed | Specified exact default DisplayConfig object (above). Defaults ensure author/title are always rendered. Config Loader falls back to defaults if file missing or parsing fails. Display Engine enforces author/title even if config omits them. |
| API Selection Deferred | Open Question | BC-004 remains conditional. Pre-implementation research required to identify and validate a working public poetry API. Recommend PoetryDB or similar. If no suitable API found, project cannot proceed (environmental blocker, not architectural flaw). |
| Error Handler Logic | Plan changed | Specified complete decision tree (above): API failure → attempt cache → show cached or fallback message. Config failure → use defaults and continue. Other failures → show error. Exit codes defined (0 for graceful fallback, 1 for hard error). |
| Concurrency | Plan changed | Cache Manager uses atomic writes (temp file + rename). This is sufficient for low-concurrency CLI tool. No lock file needed (over-engineering for this use case). |

---

## Open Questions

1. **Poetry API Selection (Pre-implementation):** Which public poetry API should be used? Candidates:
   - **PoetryDB** (https://poetrydb.org): No auth required, provides free poems with author and title, random endpoint available. **Recommended.**
   - **Poetry API** (various providers): Some deprecated, some require keys. Verify availability.
   - **Custom fallback:** If no public API works, consider bundling a small set of poems.
   - **Action:** Research and validate at least one API before implementation begins. Update BC-004 with confirmed API details.

2. **Python Version and Dependency Management:** What is the minimum Python version? (Assumed 3.9+ for f-strings and type hints.) What dependencies are acceptable?
   - **Current plan:** `requests` (or `urllib3`) for HTTP, `pyyaml` for config parsing.
   - **Action:** Verify version constraints and finalize `pyproject.toml` dependencies during API Fetcher implementation.

3. **Installation Method:** How should the tool be packaged and distributed?
   - **Current plan:** Python package with setuptools console script entry point, installable via `uv install` or `pip install` from a local directory.
   - **Action:** Define packaging strategy (PyPI vs. local wheel vs. source install).

---

## Synthesis Note

This plan represents a genuine synthesis of Khayyam's architecture with Popper's critiques. Popper found no structural flaws, only specification gaps. Each gap has been addressed:

- **First-Run Failure:** Resolved by adding a decision tree and fallback message.
- **Cache Format:** Resolved by specifying JSON schema and atomic writes.
- **Config Defaults:** Resolved by defining exact defaults and triple-enforcing author/title visibility.
- **API Selection:** Remains an open question because it is environmental, not architectural.
- **Error Handler Logic:** Resolved by detailing a complete decision tree.
- **Concurrency:** Resolved by specifying atomic writes.

The result is a **self-contained, specification-complete plan** that is ready for the Specification phase (Euclid) and ultimately for implementation.
