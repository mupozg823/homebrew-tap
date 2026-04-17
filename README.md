# mupozg823/homebrew-tap

Homebrew tap for [CodeLens MCP](https://github.com/mupozg823/codelens-mcp-plugin).

CodeLens is a harness-native, pure-Rust MCP server for multi-agent coding
workflows. It indexes a codebase once and exposes bounded, role-scoped
tools so agents like Claude Code, Codex, Cursor, and Continue can answer
"where is X / what calls X / what breaks if I change X" in compressed,
token-efficient form — typically **6-170× fewer tokens** than a
`rg + cat` loop on the same question.

## What's in this tap

| Formula        | Upstream                                                                | What it is                                                                        |
| -------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `codelens-mcp` | [codelens-mcp-plugin](https://github.com/mupozg823/codelens-mcp-plugin) | MCP server binary. 107 tools, 25 languages, tree-sitter + hybrid semantic search. |

The formula installs a single self-contained binary (`codelens-mcp`).
The binary statically links SQLite, sqlite-vec, and the ONNX runtime
used for semantic search — no other Homebrew dependencies are required.

## Install

```bash
brew tap mupozg823/tap
brew install codelens-mcp
```

Verify:

```bash
codelens-mcp --version
codelens-mcp --cmd get_capabilities --args '{}' .
```

## Configure an MCP client

### Claude Code / Cursor (stdio)

Add to `~/.claude.json` (or the Cursor equivalent):

```json
{
  "mcpServers": {
    "codelens": {
      "command": "codelens-mcp",
      "args": []
    }
  }
}
```

### Shared HTTP daemon (multi-agent)

Running one stdio subprocess per agent duplicates 200-300 MB of index
state. Instead, start one shared daemon and attach every agent by URL:

```bash
# read-only daemon for planners/reviewers
codelens-mcp /path/to/project --transport http --profile reviewer-graph --daemon-mode read-only     --port 7837 &

# mutation-enabled daemon for refactor agents
codelens-mcp /path/to/project --transport http --profile refactor-full  --daemon-mode mutation-enabled --port 7838 &
```

```json
{
  "mcpServers": {
    "codelens": { "type": "http", "url": "http://127.0.0.1:7837/mcp" }
  }
}
```

See `docs/multi-agent-integration.md` upstream for the preflight /
coordination protocol.

## Why CodeLens

- **Bounded answers, not raw files.** Every tool has a response cap.
  `get_ranked_context` returns a ranked-and-trimmed symbol set within
  the token budget; `impact_report` returns a summarised blast radius
  rather than unbounded adjacency lists.
- **Role-scoped surfaces.** Planners see read-only tools, refactor
  agents see mutation tools behind a preflight gate, CI audit runs
  see a deterministic machine-schema subset.
- **Mutation is gated.** `verify_change_readiness` must be called
  before `rename_symbol` / `replace_symbol_body` / `refactor_*`, and
  the gate checks freshness + overlapping agent claims recorded in
  `coordination.db`.
- **Durable analysis handles.** Heavy analyses (`impact_report`,
  `dead_code_report`, `refactor_safety_report`, `semantic_code_review`)
  run as async jobs that return a handle; clients can poll, cancel,
  and fetch one section at a time rather than waiting on a single
  blocking call.

## Upstream architecture (summary)

```text
MCP client ──JSON-RPC──▶ codelens-mcp (control plane: surfaces, gates,
                                       transport, analysis queue)
                         │
                         ▼
                         codelens-engine (data plane: tree-sitter parser,
                                          import/call graph, SQLite +
                                          sqlite-vec, optional ONNX
                                          embedding store, optional LSP)
                         │
                         ▼
                         .codelens/ under each project root
                           ├── symbols.db     (SQLite + FTS5)
                           ├── vec.db         (sqlite-vec index)
                           ├── graph.cache
                           ├── bridges.json
                           ├── memories/
                           └── audit/
```

`codelens-mcp` and `codelens-engine` are separately published on
[crates.io](https://crates.io); the same binary is also shipped as OCI
image `ghcr.io/mupozg823/codelens-mcp-plugin:<tag>` and as signed
tar.gz archives in the upstream GitHub Releases. This tap just wraps
the prebuilt release binary; it has no custom build step.

## Channels

| Channel    | Install                                                               |
| ---------- | --------------------------------------------------------------------- |
| Homebrew   | `brew tap mupozg823/tap && brew install codelens-mcp`                 |
| crates.io  | `cargo install codelens-mcp` (build from source, semantic feature on) |
| Docker/OCI | `docker pull ghcr.io/mupozg823/codelens-mcp-plugin:<tag>`             |
| Tar.gz     | `gh release download <tag> -R mupozg823/codelens-mcp-plugin`          |

All four channels ship the same underlying binary on every tagged
release. Homebrew and tar.gz are the fastest install; crates.io
compiles from source (the semantic feature pulls in `ort` and
`fastembed`, so expect a few minutes on first build).

## License

Upstream CodeLens is licensed under Apache-2.0. See
[LICENSE](https://github.com/mupozg823/codelens-mcp-plugin/blob/main/LICENSE).
This tap itself carries no additional restrictions — the formula is a
thin wrapper around the upstream release artifact.
