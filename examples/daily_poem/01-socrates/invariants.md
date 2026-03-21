# Invariants

| ID | Scope | Assertion | Violation Consequence |
|---------|---------------|--------------------------------------------------------|---------------------------------|
| INV-001 | system-wide | The tool must never crash or raise an unhandled exception to the user | User loses trust; tool becomes unusable |
| INV-002 | system-wide | If the API is unreachable, a cached poem must always be displayed with a warning | User sees broken tool behavior; no fallback experience |
| INV-003 | cache layer | Cached poems must persist across tool invocations | Fallback mechanism fails; user sees nothing on API failure |
| INV-004 | output layer | Every displayed poem must include author name and poem title (if available in the source) | User cannot attribute or understand the poem |
| INV-005 | output layer | When falling back to a cached poem, a warning message must be visibly displayed to the user | User does not know they are seeing stale data |
| INV-006 | configuration layer | If `~/.config/poem/display.yaml` exists, it must be a valid, readable YAML file or the tool must fail gracefully | Malformed config crashes the tool or produces corrupted output |
| INV-007 | system-wide | The `poem` command must be executable from any terminal working directory | User experience is broken if tool only works in specific directories |
