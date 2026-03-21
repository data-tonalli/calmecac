# Specification — daily_poem

## Overview

`poem` is a command-line tool that retrieves and displays a random poem from a public poetry API each time it is invoked.

## Functional Behavior

### Primary Path: Successful Fetch
1. User runs `poem` in the terminal
2. The tool contacts a remote poetry API and requests a random poem
3. The poem (with author and title) is cached locally to `~/.cache/poem/`
4. The poem is displayed in the terminal according to a display format template

### Fallback Path: API Unreachable
1. If the API is unreachable, times out, or returns an error, the tool does not crash
2. The tool retrieves any previously cached poem from `~/.cache/poem/`
3. A warning message is displayed to the user: "⚠️ Could not fetch live poem. Showing cached poem."
4. The cached poem is displayed in the same format as a live poem

### Display Format
The poem is displayed as plain, well-organized text. The display layout is configurable via a human-readable configuration file at `~/.config/poem/display.yaml`. This file defines:
- How the title is labeled/formatted
- How the author is labeled/formatted
- How the poem body is presented (spacing, indentation, etc.)
- Any separators or dividers between sections

The configuration file is not hardcoded; it is read and applied at runtime.

## Non-Functional Requirements

- **Simplicity:** No decorative elements, animations, or CLI framework bloat. Straightforward text output.
- **Robustness:** The tool must never crash; if something fails, it gracefully shows a cached poem and warns the user.
- **Configurability:** Display format is user-controllable via YAML without editing Python code.
- **Persistence:** Cached poems are stored persistently so fallback works across sessions.

## Success Criteria

- Command `poem` works from any terminal directory
- Live poems are fetched and displayed with author and title
- API failures trigger graceful fallback with warning message
- Display format is configurable via `~/.config/poem/display.yaml`
- Tool exits cleanly with appropriate messages (success or warning)
