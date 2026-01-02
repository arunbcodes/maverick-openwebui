# ADR-001: Separate Repository for Open WebUI Integration

## Status

Accepted

## Date

2025-01-02

## Context

MaverickMCP provides 80+ stock analysis tools via the Model Context Protocol (MCP). Users need a web-based chat interface to interact with these tools without requiring Claude Desktop or other MCP clients.

[Open WebUI](https://openwebui.com) is a self-hosted ChatGPT-like interface that natively supports MCP via HTTP Streamable transport, making it an ideal frontend for MaverickMCP.

The question was whether to implement Open WebUI integration within the MaverickMCP monorepo or as a separate repository.

## Decision

Maintain Open WebUI integration in this separate repository rather than within the MaverickMCP monorepo.

### Rationale

| Concern | Decision |
|---------|----------|
| Code coupling | Open WebUI config has no Python dependencies on MaverickMCP |
| Release cycle | UI deployment can evolve independently |
| User adoption | Opt-in for users who want a web interface |
| Repository focus | MaverickMCP stays focused on MCP server functionality |
| Maintenance | Docker/deployment config changes don't clutter MCP history |

## Consequences

### Positive

- Clean separation of concerns
- MaverickMCP remains a focused MCP server
- Users can choose their preferred UI (Claude Desktop, Open WebUI, Cursor, etc.)
- Independent versioning and releases
- Simpler CI/CD pipelines for each repo

### Negative

- Users need to clone a second repo for web UI
- Documentation split across repos
- Need to coordinate major version changes

## Implementation

This repository contains:
- Docker Compose configurations (standalone and full-stack)
- Setup scripts for automated deployment
- Custom system prompts for stock analysis personas
- Deployment documentation

### Connection Architecture

```
Open WebUI (port 3001) --[MCP HTTP Streamable]--> MaverickMCP (port 8003)
```

MaverickMCP requires no changes - it already supports HTTP Streamable transport.

## References

- [Open WebUI Documentation](https://docs.openwebui.com/)
- [Open WebUI MCP Guide](https://docs.openwebui.com/features/mcp/)
- [MaverickMCP Repository](https://github.com/wshobson/maverick-mcp)
