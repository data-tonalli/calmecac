# Refutations

## Overall Assessment

I have identified **5 refutations**, of which **2 are Critical** and **3 are High**. None of these are plan-blocking, but they represent genuine gaps in the architecture that must be addressed before implementation. The plan's invariant coverage is sound in principle, but the mechanisms rely on unspecified behavior (e.g., API selection, cache format, config schema).

---

## Refutation 1: First-Run Failure Leaves User with No Output

- **Target:** Error Handler, Cache Manager interaction in fallback path
- **Assumption attacked:** The plan assumes that if API fetch fails, a cached poem will always be available. This is false on first run: if the API fails before any poem is ever cached, Error Handler will call Cache Manager to load a poem, but no cache exists.
- **Breaking scenario:** User runs `poem` for the first time. Internet is down (or API is unreachable). API Fetcher raises `FetchError`. Error Handler calls Cache Manager's `load_cached()`. Cache Manager raises `NoCachedPoemError` because `~/.cache/poem/` is empty. Error Handler is now stuck: it cannot show a cached poem, and the primary path failed. What does the user see?
- **Severity:** Critical
- **Invariants at risk:** INV-001 (tool must not crash; unclear what happens when both primary and fallback fail), INV-002 (fallback promise is broken on first run)
- **Boundary conditions at risk:** None directly, but BC-007 (network requirement) is not addressed
- **Suggested mitigation:** Error Handler must have a tertiary fallback: if both API and cache fail, display a hardcoded "demo poem" or a clear error message ("No poems available. Please check your internet and try again."). Define this behavior explicitly in the spec.

---

## Refutation 2: Cache Storage Format and Schema Are Unspecified

- **Target:** Cache Manager (save and load operations)
- **Assumption attacked:** The plan says Cache Manager "writes fetched poems to disk" but does not specify the file format, naming, or structure. If the format is undefined, then "persistent cache" is undefined.
- **Breaking scenario:** Cache Manager writes a poem as JSON to `~/.cache/poem/poem.json`. If the schema changes in a future version (e.g., adding a "source" field), old cached poems won't load. Or: what if there are multiple cached poems? Does Cache Manager keep all of them, or only the latest? The plan says "any cached poem" on retrieval, implying there could be multiple, but the write interface only takes one `Poem` object.
- **Severity:** High
- **Invariants at risk:** INV-003 (persistence is only as good as the format; if the format changes, old caches become unreadable)
- **Boundary conditions at risk:** None
- **Suggested mitigation:** Specify the cache file format (JSON with a schema), file naming convention, and retention policy (latest only, or all with timestamps?). Define this before Cache Manager is implemented.

---

## Refutation 3: Config Loader Defaults Are Not Defined

- **Target:** Config Loader, Display Engine interaction
- **Assumption attacked:** Config Loader returns "sensible defaults" if `~/.config/poem/display.yaml` is missing, but the plan does not define what those defaults are. Display Engine then applies them, but it's unclear what the output will be.
- **Breaking scenario:** User runs `poem` without ever creating a config file. Config Loader returns default `DisplayConfig`. Display Engine renders the poem using those defaults. But what are the defaults? If Display Engine expects keys like `title_prefix`, `author_prefix`, `body_indent`, and Config Loader returns an empty or differently-keyed config, Display Engine will either crash or produce nonsensical output (e.g., no title label, jumbled author line).
- **Severity:** High
- **Invariants at risk:** INV-006 (config must be readable and valid; default behavior is unspecified), INV-004 (author and title must be present; if defaults omit them, invariant is broken)
- **Boundary conditions at risk:** None
- **Suggested mitigation:** Define the complete default schema and example `DisplayConfig` object in the spec or in Config Loader's docstring. Example: `{title_format: "Title: {title}", author_format: "Author: {author}", body_indent: 0, separator: ""}`.

---

## Refutation 4: API Selection Is Deferred; No Validation That a Suitable API Exists

- **Target:** API Fetcher component and boundary condition BC-004
- **Assumption attacked:** BC-004 states "A public poetry API exists and is accessible," but the plan defers the choice of which API to use. It's possible that no publicly available poetry API meets the requirements (returns random poems, includes author and title, is free and reliable).
- **Breaking scenario:** During implementation, the team searches for a public poetry API and finds that Poetry API is deprecated, PoetryDB requires authentication, and other options are geographically restricted or require rate-limit keys. No API provides reliable random poem access with author and title. Implementation stalls.
- **Severity:** High
- **Invariants at risk:** None (this is an environmental risk, not a system invariant risk)
- **Boundary conditions at risk:** BC-004 may be false
- **Suggested mitigation:** Before moving to implementation, research and identify at least one confirmed public poetry API that provides random poems with author and title. Validate that it is accessible, reliable, and free. Document the chosen API in the spec.

---

## Refutation 5: Error Handler Decision Logic Is Underspecified

- **Target:** Error Handler component
- **Assumption attacked:** The plan says Error Handler "decides whether to use cached poem or exit with error," but the decision logic is not defined. Under what conditions should Error Handler choose to exit vs. fall back?
- **Breaking scenario:** API Fetcher raises a `FetchError("API returned invalid JSON")`. Error Handler must decide: is this a transient network issue (retry or use cache) or a permanent API problem (exit with error)? Similarly, if Config Loader raises `ConfigError("YAML parsing failed")`, should Error Handler fall back to default config and show a poem, or exit and tell the user to fix their config?
- **Severity:** High
- **Invariants at risk:** INV-001 (unclear error handling strategy could lead to inconsistent behavior or missed crashes), INV-005 (warning message is shown, but when?)
- **Boundary conditions at risk:** None
- **Suggested mitigation:** Define Error Handler's decision tree explicitly: e.g., "On API fetch failure: always attempt to use cached poem. On config parse failure: use defaults and show warning. On cache write failure: log to stderr but continue. On cache read failure (empty cache on first run): show hardcoded fallback poem or error message."

---

## Refutation 6: No Concurrency or Multi-Instance Handling

- **Target:** Cache Manager (write path)
- **Assumption attacked:** The plan assumes that only one instance of `poem` will write to the cache at a time. If two users (or two invocations of `poem` in rapid succession) call the tool simultaneously, they will both write to `~/.cache/poem/`, potentially causing race conditions or file corruption.
- **Breaking scenario:** User's shell runs two instances of `poem` in parallel (e.g., in a subshell or background process). Both fetch a poem from the API simultaneously. Both reach Cache Manager and attempt to write their poem to `~/.cache/poem/`. If the write is not atomic, the final cached file could be corrupted (partial write, interleaved data).
- **Severity:** Medium (unlikely in normal use, but possible in scripting scenarios)
- **Invariants at risk:** INV-003 (cache persistence is compromised if writes are non-atomic)
- **Boundary conditions at risk:** None
- **Suggested mitigation:** Cache Manager should use atomic writes (write to a temporary file, then rename). Optionally add a lock file to prevent concurrent writes, though for a simple tool this may be over-engineering.

---

## No Further Refutations Found

I have checked the following assumptions and found them sound:

- **INV-001 coverage:** CLI Entry Point wrapping in try-except and Error Handler fallback are legitimate mechanisms. I verified that all code paths (primary, fallback, error) lead to safe states.
- **INV-007 coverage:** CLI Entry Point uses absolute paths (expanduser). This is correct for Unix-like systems as defined in BC-002.
- **Invariant coverage matrix:** Every invariant is assigned to a responsible component. The mappings are precise and traceable.
- **BC-001 through BC-003, BC-005 through BC-006:** All are respected by the component design.
- **Display Engine's rendering logic:** I checked whether author/title could be omitted despite INV-004. The plan correctly states that Display Engine "always renders both fields, even if config omits them," enforcing the invariant at the engine level.

The plan is architecturally sound. The refutations above are gaps in specification, not flaws in the component structure itself.
