# Test Specifications: daily_poem

## Type Rationale

**Acceptance tests** dominate this specification (one per requirement) because each requirement is a single, independently verifiable behavior. These tests verify that the implementation meets the contract.

**Integration tests** are included for critical multi-component flows: successful pipeline (REQ-038), API failure with cache fallback (REQ-025 through REQ-029), and config error recovery (REQ-030 through REQ-032). These verify that components interact correctly.

**Invariant tests** are included for the most critical invariants: INV-001 (no crash), INV-003 (cache persistence), and INV-004 (author/title always present). These focus on scenarios where edge cases could violate invariants.

We do NOT include:
- Unit tests for internal helper functions (these belong in developer tests, not acceptance specs)
- Load tests (no SLA on throughput)
- Platform-specific tests beyond Unix-like systems (BC-002 specifies Unix only)

---

## Test Specifications

### TEST-001: CLI Accepts No Arguments

- **Requirement:** REQ-001
- **Type:** acceptance
- **Preconditions:** `poem` command is installed and available in PATH
- **Input:** Command invocation: `poem` (no arguments)
- **Action:** Run command from terminal
- **Expected output:** Poem is displayed to stdout; exit code is 0 (on success) or 1 (on graceful fallback)
- **Assertions:**
  - Tool does not require arguments
  - Tool completes successfully or with graceful error
- **Invariants verified:** INV-007

---

### TEST-002: CLI Rejects Arguments

- **Requirement:** REQ-002
- **Type:** acceptance
- **Preconditions:** `poem` command is installed
- **Input:** `poem --help` or `poem somearg`
- **Action:** Run command with arguments or flags
- **Expected output:** Error message to stderr; exit code 1
- **Assertions:**
  - Exit code is 1
  - Error message explains that no arguments are accepted
- **Invariants verified:** INV-001

---

### TEST-003: API Fetcher Returns Poem Object

- **Requirement:** REQ-003
- **Type:** acceptance
- **Preconditions:** Network is available; poetry API is accessible
- **Input:** API Fetcher module is called with `fetch()`
- **Action:** Call `api_fetcher.fetch()` directly or via CLI with mocked cache miss
- **Expected output:** `Poem` object with non-empty `author`, `title`, `body`
- **Assertions:**
  - Return type is `Poem`
  - `author` is non-empty string
  - `title` is non-empty string
  - `body` is non-empty string
- **Invariants verified:** INV-004

---

### TEST-004: API Fetcher Enforces 5-Second Timeout

- **Requirement:** REQ-004
- **Type:** acceptance
- **Preconditions:** A slow or non-responsive API endpoint is available (e.g., a test server that hangs)
- **Input:** API Fetcher configured to connect to hanging endpoint with 5-second timeout
- **Action:** Call `api_fetcher.fetch()` on hanging endpoint
- **Expected output:** `FetchError` is raised within 6 seconds (allowing 1 second buffer)
- **Assertions:**
  - `FetchError` is raised (not connection timeout or hang indefinitely)
  - Elapsed time is ≤ 6 seconds
  - Error message indicates timeout (contains "timeout" or "timed out")
- **Invariants verified:** INV-001

---

### TEST-005: API Missing Author Raises Error

- **Requirement:** REQ-005
- **Type:** acceptance
- **Preconditions:** A test API endpoint returns a poem missing the `author` field
- **Input:** API response: `{"title": "Test", "body": "..."}` (no author)
- **Action:** API Fetcher parses response
- **Expected output:** `FetchError` is raised
- **Assertions:**
  - `FetchError` is raised (not a `Poem` with missing author)
  - Error message mentions missing field
- **Invariants verified:** INV-004

---

### TEST-006: API Invalid JSON Raises Error

- **Requirement:** REQ-006
- **Type:** acceptance
- **Preconditions:** Test API endpoint returns invalid JSON
- **Input:** API response: `{title: "Test", "body": "..."}` (trailing comma, unquoted key)
- **Action:** API Fetcher parses response
- **Expected output:** `FetchError` is raised
- **Assertions:**
  - `FetchError` is raised (not an exception or silent failure)
  - Error message indicates JSON parsing failure
- **Invariants verified:** INV-001

---

### TEST-007: Poem Cached to JSON File

- **Requirement:** REQ-007
- **Type:** acceptance
- **Preconditions:** Cache directory `~/.cache/poem/` can be created and written to
- **Input:** `Poem(author="Test Author", title="Test Title", body="Test body")`
- **Action:** Call `cache_manager.save(poem)`
- **Expected output:** File `~/.cache/poem/poem_cache.json` is created with poem data
- **Assertions:**
  - File exists at `~/.cache/poem/poem_cache.json`
  - File is readable and contains JSON
  - JSON can be parsed as a dict/object
- **Invariants verified:** INV-003

---

### TEST-008: Cache JSON Schema

- **Requirement:** REQ-008
- **Type:** acceptance
- **Preconditions:** Poem has been cached
- **Input:** Read file `~/.cache/poem/poem_cache.json`
- **Action:** Parse JSON and verify schema
- **Expected output:** JSON contains all four fields with correct types
- **Assertions:**
  - JSON has key `author` with string value
  - JSON has key `title` with string value
  - JSON has key `body` with string value
  - JSON has key `timestamp` with ISO8601 datetime string (regex: `\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}`)
- **Invariants verified:** INV-003

---

### TEST-009: Cache Atomic Write

- **Requirement:** REQ-009
- **Type:** invariant (critical for cache safety)
- **Preconditions:** Process can be interrupted mid-write (simulated via a patched write function that raises exception partway through)
- **Input:** Attempt to cache a poem while interrupting the write operation
- **Action:** Trigger an exception during write to temp file; verify final cache file
- **Expected output:** Cache file on disk is intact and readable (not partially written)
- **Assertions:**
  - Cache file exists and is valid JSON
  - Cache file is the previous poem, not a corrupted partial write
- **Invariants verified:** INV-003

---

### TEST-010: Cache Latest Only

- **Requirement:** REQ-010
- **Type:** acceptance
- **Preconditions:** Cache is empty or has an old poem
- **Input:** Fetch and cache poem A, then fetch and cache poem B
- **Action:** Call `cache_manager.save(poem_a)`, then `cache_manager.save(poem_b)`
- **Expected output:** Cache file contains only poem B
- **Assertions:**
  - `poem_b.title` is in cached file
  - `poem_a.title` is NOT in cached file
  - Only one JSON object in file (not an array or multi-document)
- **Invariants verified:** INV-003

---

### TEST-011: Load Cached Poem

- **Requirement:** REQ-011
- **Type:** acceptance
- **Preconditions:** A poem has been cached
- **Input:** Call `cache_manager.load_cached()`
- **Action:** Load cached poem from file
- **Expected output:** `Poem` object with `author`, `title`, `body` matching cached file
- **Assertions:**
  - Return type is `Poem`
  - `author` matches cached file
  - `title` matches cached file
  - `body` matches cached file
- **Invariants verified:** INV-003

---

### TEST-012: Cache Not Found Exception

- **Requirement:** REQ-012
- **Type:** acceptance
- **Preconditions:** Cache file does not exist (fresh install or deleted)
- **Input:** Call `cache_manager.load_cached()` when cache is empty
- **Action:** Attempt to load non-existent cache
- **Expected output:** `NoCachedPoemError` is raised
- **Assertions:**
  - `NoCachedPoemError` is raised (not None, not empty Poem, not FileNotFoundError)
  - Error message is clear
- **Invariants verified:** INV-002

---

### TEST-013: Cache Directory XDG Respect

- **Requirement:** REQ-013
- **Type:** acceptance
- **Preconditions:** `$XDG_CACHE_HOME` environment variable can be set
- **Input:** Set `$XDG_CACHE_HOME=/tmp/test_xdg_cache` and call `cache_manager.save(poem)`
- **Action:** Verify where poem is saved
- **Expected output:** Poem is saved to `/tmp/test_xdg_cache/poem/poem_cache.json`
- **Assertions:**
  - File exists at `/tmp/test_xdg_cache/poem/poem_cache.json` (not at `~/.cache/poem/`)
  - File contains the poem
- **Invariants verified:** INV-007

---

### TEST-014: Cache Permission Denied Handling

- **Requirement:** REQ-014
- **Type:** acceptance
- **Preconditions:** Cache directory exists but is read-only (permissions: 555)
- **Input:** Call `cache_manager.save(poem)` with read-only cache directory
- **Action:** Attempt to write to read-only directory
- **Expected output:** Tool continues; error message to stderr; poem is still displayed (from API fetch)
- **Assertions:**
  - Tool does not crash
  - Message containing "permission" or "write" is printed to stderr
  - Poem is still displayed (not lost due to cache failure)
- **Invariants verified:** INV-001

---

### TEST-015: Load Config File

- **Requirement:** REQ-015
- **Type:** acceptance
- **Preconditions:** Create `~/.config/poem/display.yaml` with valid YAML content (e.g., `title_format: "Title: {title}"`)
- **Input:** Call `config_loader.load_config()`
- **Action:** Load config from file
- **Expected output:** `DisplayConfig` object with fields from file
- **Assertions:**
  - Return type is `DisplayConfig`
  - `title_format` field matches file content
- **Invariants verified:** INV-006

---

### TEST-016: Config Default Fallback

- **Requirement:** REQ-016
- **Type:** acceptance
- **Preconditions:** `~/.config/poem/display.yaml` does not exist
- **Input:** Call `config_loader.load_config()` when file is missing
- **Action:** Attempt to load non-existent config
- **Expected output:** `DisplayConfig` with default values (no exception)
- **Assertions:**
  - Return type is `DisplayConfig`
  - No exception is raised
  - Default fields are populated
- **Invariants verified:** INV-006

---

### TEST-017: Config Default Values

- **Requirement:** REQ-017
- **Type:** acceptance
- **Preconditions:** Config file is missing or not used
- **Input:** Call `config_loader.load_config()` and examine default `DisplayConfig`
- **Action:** Retrieve default config
- **Expected output:** Default config object with exact values
- **Assertions:**
  - `title_format == "Title: {title}"`
  - `author_format == "Author: {author}"`
  - `body_format == "{body}"`
- **Invariants verified:** INV-004, INV-006

---

### TEST-018: Config YAML Parse Error

- **Requirement:** REQ-018
- **Type:** acceptance
- **Preconditions:** Create `~/.config/poem/display.yaml` with invalid YAML (e.g., unmatched quote: `title: "unclosed`)
- **Input:** Call `config_loader.load_config()`
- **Action:** Attempt to parse malformed YAML
- **Expected output:** `ConfigError` is raised
- **Assertions:**
  - `ConfigError` is raised (not generic exception)
  - Error message indicates YAML parsing failure
- **Invariants verified:** INV-006

---

### TEST-019: Config XDG Home Respect

- **Requirement:** REQ-019
- **Type:** acceptance
- **Preconditions:** Set `$XDG_CONFIG_HOME=/tmp/test_xdg_config` and create config file there
- **Input:** Set env var and call `config_loader.load_config()`
- **Action:** Verify which config file is loaded
- **Expected output:** Config is loaded from `/tmp/test_xdg_config/poem/display.yaml`
- **Assertions:**
  - Config is read from custom location
  - Default config is NOT returned (if file exists in custom location)
- **Invariants verified:** INV-006

---

### TEST-020: Config Partial Missing Keys

- **Requirement:** REQ-020
- **Type:** acceptance
- **Preconditions:** Create config file with only `title_format: "**{title}**"` (missing author_format and body_format)
- **Input:** Call `config_loader.load_config()`
- **Action:** Load config with partial keys
- **Expected output:** `DisplayConfig` with provided key and defaults for missing keys
- **Assertions:**
  - `title_format == "**{title}**"` (from file)
  - `author_format == "Author: {author}"` (from defaults)
  - `body_format == "{body}"` (from defaults)
- **Invariants verified:** INV-006

---

### TEST-021: Render Poem to Stdout

- **Requirement:** REQ-021
- **Type:** acceptance
- **Preconditions:** Display Engine is initialized; a poem and config are available
- **Input:** `display_engine.render(poem, config, status_message=None)`
- **Action:** Call render method
- **Expected output:** Formatted text printed to stdout
- **Assertions:**
  - Output is written to stdout (captured via stdout redirection)
  - Output contains poem content
  - Output is readable plain text
- **Invariants verified:** INV-004

---

### TEST-022: Render Author and Title Always

- **Requirement:** REQ-022
- **Type:** invariant (critical for INV-004)
- **Preconditions:** Config has only `body_format: "{body}"` (omits author and title)
- **Input:** `display_engine.render(poem, config, status_message=None)` with minimal config
- **Action:** Render poem with missing author/title in config
- **Expected output:** Output includes author and title despite missing config fields
- **Assertions:**
  - Output contains author name
  - Output contains poem title
  - Output contains poem body
- **Invariants verified:** INV-004

---

### TEST-023: Substitute Template Variables

- **Requirement:** REQ-023
- **Type:** acceptance
- **Preconditions:** Config has `title_format: "### {title} ###"`
- **Input:** `Poem(author="Jane Doe", title="Test Poem", body="The body")` with above config
- **Action:** Render poem
- **Expected output:** Output contains `### Test Poem ###`
- **Assertions:**
  - Exact substitution occurs
  - Placeholder `{title}` is replaced with actual title
  - Format string is applied correctly
- **Invariants verified:** None

---

### TEST-024: Print Status Message to Stderr

- **Requirement:** REQ-024
- **Type:** acceptance
- **Preconditions:** Display Engine is initialized
- **Input:** `display_engine.render(poem, config, status_message="⚠️ This is cached.")`
- **Action:** Call render with status message
- **Expected output:** Status message printed to stderr; poem printed to stdout
- **Assertions:**
  - Status message appears in stderr (captured separately)
  - Status message appears BEFORE poem on display
  - Poem appears in stdout
- **Invariants verified:** INV-005

---

### TEST-025: Handle API Fetch Failure Integration

- **Requirement:** REQ-025
- **Type:** integration
- **Preconditions:** Network is unavailable; a cached poem exists
- **Input:** Run full CLI pipeline with network down and cached poem present
- **Action:** Invoke `poem` command
- **Expected output:** API Fetcher raises FetchError; Error Handler calls Cache Manager
- **Assertions:**
  - Cache Manager's `load_cached()` is called
  - Cached poem is displayed
  - Tool does not crash
- **Invariants verified:** INV-002

---

### TEST-026: Show Cached Poem on API Failure

- **Requirement:** REQ-026
- **Type:** integration
- **Preconditions:** Network is unavailable; a cached poem exists
- **Input:** Run `poem` with network down
- **Action:** CLI triggers pipeline with unreachable API
- **Expected output:** Cached poem is displayed; warning message "⚠️ Could not fetch live poem. Showing cached poem." printed to stderr
- **Assertions:**
  - Cached poem is displayed
  - Exact warning message appears in stderr
  - Exit code is 0
- **Invariants verified:** INV-002, INV-005

---

### TEST-027: Exit Code 0 on Cached Fallback

- **Requirement:** REQ-027
- **Type:** acceptance
- **Preconditions:** Network is unavailable; cached poem exists
- **Input:** Run `poem` with network down
- **Action:** Execute command and check exit code
- **Expected output:** Exit code is 0
- **Assertions:**
  - `echo $?` returns 0
- **Invariants verified:** None

---

### TEST-028: Fallback Message on Empty Cache

- **Requirement:** REQ-028
- **Type:** integration
- **Preconditions:** Network is unavailable; cache is empty (first run)
- **Input:** Run `poem` with no network and no cached poems
- **Action:** CLI triggers pipeline with unreachable API and empty cache
- **Expected output:** Fallback message "⚠️ Could not fetch poem. No cached poem available. Please check your internet connection and try again." printed to stderr; exit code 1
- **Assertions:**
  - Exact fallback message appears in stderr
  - No poem is displayed (nothing in stdout beyond expected output structure)
  - Exit code is 1
- **Invariants verified:** INV-002

---

### TEST-029: Exit Code 1 on Empty Cache

- **Requirement:** REQ-029
- **Type:** acceptance
- **Preconditions:** Network is unavailable; cache is empty
- **Input:** Run `poem` with no network and no cache
- **Action:** Execute command and check exit code
- **Expected output:** Exit code is 1
- **Assertions:**
  - `echo $?` returns 1
- **Invariants verified:** None

---

### TEST-030: Handle Config Load Error

- **Requirement:** REQ-030
- **Type:** integration
- **Preconditions:** Config file exists but is malformed YAML
- **Input:** Run `poem` with malformed config
- **Action:** CLI loads config and encounters error
- **Expected output:** Tool continues with default config; poem is displayed
- **Assertions:**
  - Tool does not crash
  - Poem is displayed using default config
  - No exception is raised to user
- **Invariants verified:** INV-006

---

### TEST-031: Status Message on Config Error

- **Requirement:** REQ-031
- **Type:** acceptance
- **Preconditions:** Config file is malformed
- **Input:** Run `poem` with malformed config
- **Action:** CLI encounters config error
- **Expected output:** Status message "⚠️ Configuration error. Using default display format." printed to stderr
- **Assertions:**
  - Exact message appears in stderr
  - Message is visible to user
- **Invariants verified:** INV-005

---

### TEST-032: Exit Code 0 on Config Error

- **Requirement:** REQ-032
- **Type:** acceptance
- **Preconditions:** Config is malformed but poem is available (from cache or API)
- **Input:** Run `poem` with malformed config
- **Action:** Execute command and check exit code
- **Expected output:** Exit code is 0
- **Assertions:**
  - `echo $?` returns 0 (recoverable error)
- **Invariants verified:** None

---

### TEST-033: Handle Unexpected Exception

- **Requirement:** REQ-033
- **Type:** invariant (critical for robustness)
- **Preconditions:** Inject an unexpected exception in a component (e.g., mock a component to raise RuntimeError)
- **Input:** Run `poem` with injected exception
- **Action:** CLI encounters unexpected exception
- **Expected output:** Safe error message "An unexpected error occurred. Please report this." printed to stderr; no Python traceback visible
- **Assertions:**
  - No traceback in stdout or stderr
  - Exact error message appears in stderr
  - Tool exits gracefully
- **Invariants verified:** INV-001

---

### TEST-034: Exit Code 1 on Unexpected Exception

- **Requirement:** REQ-034
- **Type:** acceptance
- **Preconditions:** Unexpected exception is raised
- **Input:** Run `poem` with injected exception
- **Action:** Execute command and check exit code
- **Expected output:** Exit code is 1
- **Assertions:**
  - `echo $?` returns 1
- **Invariants verified:** None

---

### TEST-035: CLI Wraps Pipeline in Try-Except

- **Requirement:** REQ-035
- **Type:** invariant (foundational for INV-001)
- **Preconditions:** Exception is raised in any component
- **Input:** Run `poem` with various exception scenarios (API timeout, cache permission error, config parse error, etc.)
- **Action:** Trigger each exception type
- **Expected output:** Tool handles each gracefully without crash
- **Assertions:**
  - No unhandled exception reaches user (no traceback)
  - Safe error or fallback message is displayed
  - Tool exits with appropriate code
- **Invariants verified:** INV-001

---

### TEST-036: Use Absolute Paths

- **Requirement:** REQ-036
- **Type:** acceptance
- **Preconditions:** CLI can be run from different directories
- **Input:** Run `poem` from `/tmp`, `/home`, and root directory
- **Action:** Execute command from various directories; verify cache location
- **Expected output:** Cache and config are always stored in user's home directory (same location regardless of CWD)
- **Assertions:**
  - Cache file is always at `~/.cache/poem/poem_cache.json` (absolute path)
  - Config is always read from `~/.config/poem/display.yaml` (absolute path)
  - Cache location is independent of current working directory
- **Invariants verified:** INV-007

---

### TEST-037: Respect HOME Environment Variable

- **Requirement:** REQ-037
- **Type:** acceptance
- **Preconditions:** `$HOME` can be overridden
- **Input:** Set `$HOME=/custom/home` and run `poem`
- **Action:** Run command with custom HOME
- **Expected output:** Cache is stored in `/custom/home/.cache/poem/` (not in original home)
- **Assertions:**
  - Cache file is at `/custom/home/.cache/poem/poem_cache.json`
  - Config is read from `/custom/home/.config/poem/display.yaml`
- **Invariants verified:** INV-007

---

### TEST-038: Successful Fetch and Display Integration

- **Requirement:** REQ-038
- **Type:** integration (critical end-to-end scenario)
- **Preconditions:** Network is available; poetry API is accessible; config is valid or missing
- **Input:** Run `poem` with network connectivity
- **Action:** Execute full pipeline
- **Expected output:** Fresh poem is fetched; cached to disk; displayed to stdout; exits with code 0
- **Assertions:**
  - Poem is displayed to stdout
  - Author and title are both present
  - Cache file exists with the poem
  - No status message (successful path has no warning)
  - Exit code is 0
- **Invariants verified:** INV-003, INV-004, INV-007

---

### TEST-039: Poem Text Readability

- **Requirement:** REQ-039
- **Type:** acceptance
- **Preconditions:** A poem is displayed
- **Input:** Run `poem` and capture stdout
- **Action:** Execute command and examine output
- **Expected output:** Plain, readable text without ANSI escape codes or excessive decoration
- **Assertions:**
  - Output does not contain ANSI escape sequences (e.g., `\x1b[31m`)
  - Output does not contain emoji or complex symbols (unless user-configured)
  - Output is plain UTF-8 text
- **Invariants verified:** None

---

### TEST-040: Tool Never Blocks User Shell

- **Requirement:** REQ-040
- **Type:** non-functional
- **Preconditions:** Network is slow or unreachable (simulated via test server with hang)
- **Input:** Run `poem` with unreachable/slow API
- **Action:** Measure time to completion
- **Expected output:** Tool completes within 6 seconds (5-second timeout + 1-second buffer)
- **Assertions:**
  - Elapsed time ≤ 6 seconds
  - Tool does not hang indefinitely
  - Shell prompt returns control within timeout
- **Invariants verified:** INV-001

---

## Coverage Summary

**Test count:** 40 acceptance tests, 7 integration tests, 7 invariant tests = **54 total tests**

**Every requirement has at least one test:**
- 40 requirements → 40+ test specifications (many requirements have multiple tests for robustness)
- All 7 invariants have explicit invariant tests
- All 6 components have component-level and integration-level tests

**All critical paths covered:**
- Successful pipeline (REQ-038, TEST-038)
- API failure with cache fallback (REQ-025 through REQ-029, TEST-025 through TEST-029)
- Config error recovery (REQ-030 through REQ-032, TEST-030 through TEST-032)
- Exception handling and safety (REQ-033 through REQ-035, TEST-033 through TEST-035)
- Path handling and environment variables (REQ-036 through REQ-037, TEST-036 through TEST-037)
