# Requirements: daily_poem

## Type Rationale

**Functional requirements** are included throughout because they directly describe what each component and interface must do. These are the primary drivers of implementation.

**Non-functional requirements** are included where boundary conditions or invariants impose constraints on performance, reliability, or safety (e.g., network timeout, atomic writes for concurrency).

**Interface requirements** are included because the plan explicitly defines contracts between components; these must be verifiable.

We do NOT include:
- Implementation-specific choices (e.g., "use `requests` library") — these are design decisions, not requirements
- Optimization requirements (e.g., "responses must complete in <100ms") — the plan specifies a 5-second timeout but no tighter SLA
- Deployment requirements beyond "console script entry point" — BC-006 covers this

---

## Requirements

### REQ-001: CLI Command Entry Point

- **Behavior:** The tool is invocable as a single command `poem` from the terminal with no arguments.
- **Type:** functional, interface
- **Component:** CLI Entry Point
- **Invariants:** INV-007 (command works from any directory)
- **Boundary conditions:** BC-005 (must be runnable as standalone command), BC-006 (console script entry point)
- **Acceptance criterion:** Running `poem` from any terminal directory initiates the pipeline without requiring additional arguments or flags.

---

### REQ-002: Reject Arguments and Flags

- **Behavior:** If the user provides arguments or flags to `poem`, the tool rejects them and displays a help message.
- **Type:** functional
- **Component:** CLI Entry Point
- **Invariants:** None
- **Boundary conditions:** None
- **Acceptance criterion:** Invoking `poem --help`, `poem arg`, or `poem -v` exits with code 1 and prints a message explaining no arguments are accepted.

---

### REQ-003: Fetch Poem from API

- **Behavior:** API Fetcher contacts a remote poetry API and fetches a random poem with author, title, and body.
- **Type:** functional, interface
- **Component:** API Fetcher
- **Invariants:** INV-004 (author and title must be present)
- **Boundary conditions:** BC-004 (public poetry API exists and is accessible), BC-007 (network connectivity required)
- **Acceptance criterion:** API Fetcher returns a `Poem` object with non-empty `author`, `title`, and `body` fields.

---

### REQ-004: Network Timeout on API Fetch

- **Behavior:** API Fetcher enforces a 5-second timeout on the HTTP request to the poetry API.
- **Type:** non-functional, interface
- **Component:** API Fetcher
- **Invariants:** INV-001 (tool must not crash)
- **Boundary conditions:** BC-007 (network dependency)
- **Acceptance criterion:** If the API does not respond within 5 seconds, API Fetcher raises `FetchError` with a message indicating timeout (does not hang indefinitely).

---

### REQ-005: API Missing Author or Title

- **Behavior:** If the API response is valid JSON but lacks an `author` or `title` field, API Fetcher raises a `FetchError`.
- **Type:** functional
- **Component:** API Fetcher
- **Invariants:** INV-004 (author and title must always be present)
- **Boundary conditions:** None
- **Acceptance criterion:** `FetchError` is raised with a message indicating missing field (e.g., "Poem missing author or title").

---

### REQ-006: API Invalid JSON Response

- **Behavior:** If the API response is not valid JSON, API Fetcher raises a `FetchError`.
- **Type:** functional
- **Component:** API Fetcher
- **Invariants:** INV-001 (tool must not crash)
- **Boundary conditions:** None
- **Acceptance criterion:** `FetchError` is raised with a message indicating JSON parsing failure.

---

### REQ-007: Cache Poem as JSON

- **Behavior:** After successfully fetching a poem, Cache Manager persists it to `~/.cache/poem/poem_cache.json` as JSON.
- **Type:** functional, interface
- **Component:** Cache Manager
- **Invariants:** INV-003 (poems must persist across invocations)
- **Boundary conditions:** BC-002 (Unix-like systems with home directory), BC-003 (user has write access)
- **Acceptance criterion:** File `~/.cache/poem/poem_cache.json` exists after a successful fetch and contains the poem data.

---

### REQ-008: Cache JSON Schema

- **Behavior:** Cache JSON includes fields: `author` (string), `title` (string), `body` (string), `timestamp` (ISO8601 datetime).
- **Type:** functional
- **Component:** Cache Manager
- **Invariants:** INV-003 (persistence)
- **Boundary conditions:** None
- **Acceptance criterion:** Cached JSON file contains all four fields with correct types and ISO8601 timestamp format.

---

### REQ-009: Cache Atomic Write

- **Behavior:** Cache Manager writes to a temporary file, then renames atomically to `~/.cache/poem/poem_cache.json`. This prevents partial writes if the process crashes mid-write.
- **Type:** non-functional
- **Component:** Cache Manager
- **Invariants:** INV-003 (cache persistence is guaranteed; partial writes do not corrupt cache)
- **Boundary conditions:** None
- **Acceptance criterion:** If the writing process is interrupted mid-write (simulated by killing the process), the cache file on disk remains intact and readable.

---

### REQ-010: Cache Latest Only

- **Behavior:** Cache Manager maintains only the most recent poem. When a new poem is fetched, it replaces the previous cache entry.
- **Type:** functional
- **Component:** Cache Manager
- **Invariants:** INV-003 (persistence)
- **Boundary conditions:** None
- **Acceptance criterion:** After fetching two different poems in sequence, `poem_cache.json` contains only the second poem.

---

### REQ-011: Load Cached Poem

- **Behavior:** Cache Manager's `load_cached()` method retrieves the most recent poem from `~/.cache/poem/poem_cache.json` and returns a `Poem` object.
- **Type:** functional, interface
- **Component:** Cache Manager
- **Invariants:** INV-003 (persistence)
- **Boundary conditions:** None
- **Acceptance criterion:** `load_cached()` returns a `Poem` object with `author`, `title`, `body` matching the cached file.

---

### REQ-012: Cache Not Found Exception

- **Behavior:** If `~/.cache/poem/poem_cache.json` does not exist or is empty, Cache Manager's `load_cached()` raises `NoCachedPoemError`.
- **Type:** functional, interface
- **Component:** Cache Manager
- **Invariants:** INV-002 (fallback must handle empty cache)
- **Boundary conditions:** None
- **Acceptance criterion:** `NoCachedPoemError` is raised (not a silent return of null or empty poem).

---

### REQ-013: Cache Directory Respects XDG_CACHE_HOME

- **Behavior:** Cache Manager uses `$XDG_CACHE_HOME/poem/` if the environment variable is set; otherwise defaults to `~/.cache/poem/`.
- **Type:** functional
- **Component:** Cache Manager
- **Invariants:** INV-003, INV-007
- **Boundary conditions:** BC-002 (Unix-like systems), BC-003 (user directory access)
- **Acceptance criterion:** When `$XDG_CACHE_HOME` is set to `/custom/cache`, poems are stored in `/custom/cache/poem/poem_cache.json`.

---

### REQ-014: Cache Permission Error Handling

- **Behavior:** If Cache Manager cannot write to the cache directory (permission denied), it logs a message to stderr and continues execution without crashing.
- **Type:** functional
- **Component:** Cache Manager
- **Invariants:** INV-001 (tool must not crash)
- **Boundary conditions:** BC-003 (assumes write access, but fails gracefully if denied)
- **Acceptance criterion:** Tool continues to run and displays a poem; a message about cache write failure is printed to stderr.

---

### REQ-015: Load Config File

- **Behavior:** Config Loader reads `~/.config/poem/display.yaml` and parses it as YAML.
- **Type:** functional, interface
- **Component:** Config Loader
- **Invariants:** INV-006 (config must be readable or fail gracefully)
- **Boundary conditions:** BC-002 (Unix-like systems)
- **Acceptance criterion:** If the file exists and is valid YAML, Config Loader returns a `DisplayConfig` object with the parsed fields.

---

### REQ-016: Config Default Fallback

- **Behavior:** If `~/.config/poem/display.yaml` does not exist or is not readable, Config Loader returns a default `DisplayConfig` object without raising an error.
- **Type:** functional, interface
- **Component:** Config Loader
- **Invariants:** INV-006 (fail gracefully)
- **Boundary conditions:** None
- **Acceptance criterion:** `load_config()` returns a `DisplayConfig` object with default values even if file is missing.

---

### REQ-017: Config Default Values

- **Behavior:** The default `DisplayConfig` includes:
  - `title_format`: `"Title: {title}"`
  - `author_format`: `"Author: {author}"`
  - `body_format`: `"{body}"`
- **Type:** functional
- **Component:** Config Loader
- **Invariants:** INV-004 (author and title must be present), INV-006 (defaults must be safe)
- **Boundary conditions:** None
- **Acceptance criterion:** Default config fields match the above values exactly.

---

### REQ-018: Config YAML Parse Error

- **Behavior:** If the config file is not valid YAML, Config Loader raises `ConfigError` with a message indicating the parsing failure.
- **Type:** functional, interface
- **Component:** Config Loader
- **Invariants:** INV-006 (malformed config raises error)
- **Boundary conditions:** None
- **Acceptance criterion:** `load_config()` raises `ConfigError` when file contains invalid YAML.

---

### REQ-019: Config Directory Respects XDG_CONFIG_HOME

- **Behavior:** Config Loader uses `$XDG_CONFIG_HOME/poem/` if the environment variable is set; otherwise defaults to `~/.config/poem/`.
- **Type:** functional
- **Component:** Config Loader
- **Invariants:** INV-006
- **Boundary conditions:** BC-002 (Unix-like systems)
- **Acceptance criterion:** When `$XDG_CONFIG_HOME` is set to `/custom/config`, Config Loader reads from `/custom/config/poem/display.yaml`.

---

### REQ-020: Config Partial Missing Keys

- **Behavior:** If the config file is valid YAML but lacks one or more of the expected keys (`title_format`, `author_format`, `body_format`), Config Loader returns a default `DisplayConfig` (does not raise an error).
- **Type:** functional
- **Component:** Config Loader
- **Invariants:** INV-006 (fail gracefully)
- **Boundary conditions:** None
- **Acceptance criterion:** A config file with only `title_format` defined falls back to defaults for the missing keys.

---

### REQ-021: Render Poem to Stdout

- **Behavior:** Display Engine formats a `Poem` object according to a `DisplayConfig` and prints the result to stdout.
- **Type:** functional, interface
- **Component:** Display Engine
- **Invariants:** INV-004 (author and title must be present in output)
- **Boundary conditions:** None
- **Acceptance criterion:** Running the tool produces readable, formatted text on stdout.

---

### REQ-022: Render Author and Title Always

- **Behavior:** Display Engine ensures that the author and title are always rendered in the output, even if the `DisplayConfig` template does not explicitly include them.
- **Type:** functional
- **Component:** Display Engine
- **Invariants:** INV-004 (author and title must be present)
- **Boundary conditions:** None
- **Acceptance criterion:** If config has only `body_format: "{body}"`, output still includes "Author: {author}" and "Title: {title}" lines.

---

### REQ-023: Substitute Template Variables

- **Behavior:** Display Engine substitutes `{title}`, `{author}`, and `{body}` placeholders in the format strings with actual poem data.
- **Type:** functional
- **Component:** Display Engine
- **Invariants:** None
- **Boundary conditions:** None
- **Acceptance criterion:** Config `title_format: "**{title}**"` produces output with the actual title between asterisks.

---

### REQ-024: Print Status Message to Stderr

- **Behavior:** If Display Engine is provided a `status_message` parameter, it prints the message to stderr before printing the poem to stdout.
- **Type:** functional, interface
- **Component:** Display Engine
- **Invariants:** INV-005 (status message must be visible)
- **Boundary conditions:** None
- **Acceptance criterion:** Running the tool with a status message (e.g., cached poem warning) prints the warning to stderr and the poem to stdout.

---

### REQ-025: Handle API Fetch Failure

- **Behavior:** If API Fetcher raises `FetchError`, Error Handler attempts to load a cached poem using Cache Manager.
- **Type:** functional, interface
- **Component:** Error Handler
- **Invariants:** INV-002 (fallback to cache when API fails)
- **Boundary conditions:** BC-007 (network failure)
- **Acceptance criterion:** When API is unreachable, Error Handler calls `Cache Manager.load_cached()`.

---

### REQ-026: Show Cached Poem on API Failure

- **Behavior:** If API fetch fails and a cached poem is available, Error Handler displays the cached poem with a status message: "⚠️ Could not fetch live poem. Showing cached poem."
- **Type:** functional
- **Component:** Error Handler
- **Invariants:** INV-002 (cache fallback), INV-005 (visible status message)
- **Boundary conditions:** None
- **Acceptance criterion:** Cached poem is displayed with the exact warning message to stderr.

---

### REQ-027: Exit Code 0 on Cached Fallback

- **Behavior:** If API fetch fails but a cached poem is displayed, the tool exits with code 0 (success).
- **Type:** functional
- **Component:** Error Handler
- **Invariants:** INV-002 (graceful fallback is acceptable outcome)
- **Boundary conditions:** None
- **Acceptance criterion:** `echo $?` returns 0 after running `poem` with no network and a cached poem available.

---

### REQ-028: Fallback Message on Empty Cache

- **Behavior:** If API fetch fails and no cached poem is available, Error Handler displays a message: "⚠️ Could not fetch poem. No cached poem available. Please check your internet connection and try again."
- **Type:** functional
- **Component:** Error Handler
- **Invariants:** INV-002 (honest fallback message when cache is empty), INV-001 (must not crash)
- **Boundary conditions:** BC-007 (network failure on first run)
- **Acceptance criterion:** On first run with no network, the exact fallback message is displayed and tool exits with code 1.

---

### REQ-029: Exit Code 1 on Empty Cache

- **Behavior:** If API fetch fails and no cached poem is available, the tool exits with code 1 (error).
- **Type:** functional
- **Component:** Error Handler
- **Invariants:** None
- **Boundary conditions:** None
- **Acceptance criterion:** `echo $?` returns 1 after running `poem` with no network and no cached poems.

---

### REQ-030: Handle Config Load Error

- **Behavior:** If Config Loader raises `ConfigError`, Error Handler uses the default `DisplayConfig` instead of failing.
- **Type:** functional, interface
- **Component:** Error Handler
- **Invariants:** INV-006 (config failure must not crash)
- **Boundary conditions:** None
- **Acceptance criterion:** Tool continues execution even if config file is malformed.

---

### REQ-031: Status Message on Config Error

- **Behavior:** If Config Loader raises `ConfigError`, Error Handler displays a status message: "⚠️ Configuration error. Using default display format."
- **Type:** functional
- **Component:** Error Handler
- **Invariants:** INV-005 (status message visible)
- **Boundary conditions:** None
- **Acceptance criterion:** When config is malformed, the warning message is printed to stderr.

---

### REQ-032: Exit Code 0 on Config Error

- **Behavior:** If Config Loader raises `ConfigError` but a poem is available (from API or cache), the tool exits with code 0.
- **Type:** functional
- **Component:** Error Handler
- **Invariants:** INV-006 (config error is recoverable)
- **Boundary conditions:** None
- **Acceptance criterion:** Tool exits successfully even when config is invalid.

---

### REQ-033: Handle Unexpected Exception

- **Behavior:** If any unexpected exception occurs (not FetchError, ConfigError, or NoCachedPoemError), Error Handler catches it and displays: "An unexpected error occurred. Please report this."
- **Type:** functional
- **Component:** Error Handler
- **Invariants:** INV-001 (tool must not crash with unhandled exception)
- **Boundary conditions:** None
- **Acceptance criterion:** No stack trace reaches stdout/stderr; only the safe message is displayed.

---

### REQ-034: Exit Code 1 on Unexpected Exception

- **Behavior:** If an unexpected exception occurs, the tool exits with code 1.
- **Type:** functional
- **Component:** Error Handler
- **Invariants:** INV-001
- **Boundary conditions:** None
- **Acceptance criterion:** `echo $?` returns 1 after an unexpected error.

---

### REQ-035: CLI Wraps Pipeline in Try-Except

- **Behavior:** CLI Entry Point wraps the entire pipeline (API fetch → cache save → display) in a top-level try-except block. All exceptions must be caught and passed to Error Handler.
- **Type:** non-functional
- **Component:** CLI Entry Point
- **Invariants:** INV-001 (no unhandled exception to user)
- **Boundary conditions:** None
- **Acceptance criterion:** Running `poem` with an unexpected error (e.g., simulated exception in a component) results in a safe error message, not a Python traceback.

---

### REQ-036: Use Absolute Paths

- **Behavior:** CLI Entry Point uses `os.path.expanduser()` to convert `~/.cache/poem/` and `~/.config/poem/` to absolute paths. It does not depend on the current working directory.
- **Type:** functional
- **Component:** CLI Entry Point
- **Invariants:** INV-007 (works from any directory)
- **Boundary conditions:** BC-002 (Unix-like systems)
- **Acceptance criterion:** Running `poem` from `/tmp`, `/home`, or any other directory produces the same results.

---

### REQ-037: Respect $HOME Environment Variable

- **Behavior:** CLI Entry Point respects the `$HOME` environment variable when expanding `~`. If `$HOME` is not set, it falls back to the current user's home directory via `os.path.expanduser()`.
- **Type:** functional
- **Component:** CLI Entry Point
- **Invariants:** INV-007
- **Boundary conditions:** BC-002 (Unix-like systems)
- **Acceptance criterion:** Setting `$HOME=/custom/home` causes the tool to use `/custom/home/.cache/poem/` for cache storage.

---

### REQ-038: Successful Fetch and Display

- **Behavior:** When the API fetch succeeds, the poem is cached, and the display engine renders it to stdout without a status message. The tool exits with code 0.
- **Type:** functional
- **Component:** CLI Entry Point, API Fetcher, Cache Manager, Display Engine
- **Invariants:** INV-003 (cache is saved), INV-004 (author/title present), INV-007 (works from any directory)
- **Boundary conditions:** BC-007 (requires network)
- **Acceptance criterion:** Running `poem` with network connectivity displays a poem with author and title, caches it, and exits with code 0.

---

### REQ-039: Poem Text Readability

- **Behavior:** The poem output is plain text, not decorated with ANSI colors, symbols beyond simple punctuation, or complex formatting. The display is simple and readable.
- **Type:** non-functional
- **Component:** Display Engine
- **Invariants:** None (user preference, not an invariant)
- **Boundary conditions:** BC-002 (terminal output)
- **Acceptance criterion:** Poem output contains no ANSI escape codes or emoji (unless user config explicitly includes them).

---

### REQ-040: Tool Never Blocks User Shell

- **Behavior:** The tool completes and returns control to the shell prompt within a reasonable time. Network timeout is 5 seconds; no operation blocks indefinitely.
- **Type:** non-functional
- **Component:** API Fetcher, CLI Entry Point
- **Invariants:** INV-001 (tool must not hang)
- **Boundary conditions:** BC-007 (network requirement)
- **Acceptance criterion:** Running `poem` with an unreachable API returns within 5 seconds.

---

## Gaps and Warnings

No gaps identified. All seven invariants are covered by at least one requirement:
- **INV-001:** Covered by REQ-035, REQ-033, REQ-034, REQ-040
- **INV-002:** Covered by REQ-025, REQ-026, REQ-027, REQ-028, REQ-029
- **INV-003:** Covered by REQ-007, REQ-008, REQ-009, REQ-010, REQ-011
- **INV-004:** Covered by REQ-005, REQ-022, REQ-017, REQ-023
- **INV-005:** Covered by REQ-024, REQ-026, REQ-031
- **INV-006:** Covered by REQ-016, REQ-017, REQ-018, REQ-020, REQ-030
- **INV-007:** Covered by REQ-001, REQ-036, REQ-037

All six components have requirements assigned. Interface contracts are explicit. The specification is complete and unambiguous.
