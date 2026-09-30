# MCP List — Mobile

SwiftUI app for **MCP List** — browse Model Context Protocol servers and copy their client config.

Part of [Chaowalit Greepoke](https://bookchaowalit.com)'s 101 Portfolio Projects.

## Status

This is a Swift package, not yet a shippable app:

- `Sources/McplistCore` — Foundation-only domain logic, unit-tested in
  `Tests/McplistCoreTests` (XCTest).
- `Sources/McplistUI` — SwiftUI tab shell (Home / Explore / Profile). It does not
  use `McplistCore` yet, and there is no Xcode app target (`@main`) yet.

The code has **not been compiled outside CI** (it was written without a Swift
toolchain); the macOS CI job is the first real build. See
[docs/UPGRADE-PLAN.md](docs/UPGRADE-PLAN.md).

## Core features (`McplistCore`)

- Server entries with stdio (command, args, required env keys) or HTTP transport
- Entry validation: kebab-case names, non-empty summary/categories/command, UPPER_SNAKE_CASE env keys, https for remote servers (http only for localhost)
- Search by text and category (official servers first) and category counts
- `mcpServers` config snippet generation with `<PLACEHOLDER>` env values — secrets are never stored or filled in

## Tech Stack

- **UI:** SwiftUI (iOS 17+ / macOS 14+)
- **Language:** Swift 5.10
- **Tests:** XCTest via SwiftPM

## Getting Started

```bash
swift build
swift test          # runs McplistCoreTests
open Package.swift  # opens in Xcode 15+
```

CI (`.github/workflows/build.yml`, macOS 14) runs `swift build` and
`swift test`; failures fail the workflow.

## Related

- **Frontend:** [bookchaowalit-website/mcplist-frontend](https://github.com/bookchaowalit-website/bookchaowalit-mcplist-frontend)
- **Portfolio:** [bookchaowalit.com](https://bookchaowalit.com)

## License

MIT
