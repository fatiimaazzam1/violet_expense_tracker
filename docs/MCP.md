# Violet Expense Tracker — MCP Evidence

**Status:** Configuration observed; one source snapshot was user-provided; complete resource access is not verified in this record
**Project scope:** Figma Make Expense Tracker design inspection only

## Configuration evidence

The workspace-root `.mcp.json` contains a `figma` server entry using HTTP at `https://mcp.figma.com/mcp`. This confirms the configured endpoint and transport only; it does not by itself prove authentication, successful calls, resource listing, resource-template support, or access to a particular Figma Make project.

The user supplied the complete contents of `src/main.tsx` and identified them as retrieved through the VS Code Figma MCP Resources interface. This is evidence for one user-reported source-resource read, not an independently captured MCP result or a complete project-resource inventory. The source snapshot is not stored in this repository.

## Verification status

- Figma tool definitions are available in the Copilot session. No direct MCP call transcript is stored in this repository.
- No complete Figma Resource or Resource Template listing, nor a set of project-file payloads, is stored in this repository.
- `DESIGN.md` describes prior browser-preview observations; it explicitly does not claim that those observations came from MCP resource reads.
- No Figma screenshots, source snapshots, or resource payloads are stored here.

Do not treat the single user-provided source snapshot as a complete project export or as proof that all Resources are listable/readable. Record a capability as verified only after the operation and result are captured. Do not include authentication tokens or other secrets in this document.

QR Menu design work and any non-Expense-Tracker Figma project are outside this project's scope.