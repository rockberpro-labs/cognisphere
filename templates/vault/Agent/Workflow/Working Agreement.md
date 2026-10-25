---
tags: [{{project}}, agent, workflow]
updated: {{date}}
status: skeleton
---
# Working Agreement

Back: [[00 Home]] · [[Session Protocol]] · [[Review Checklist]]

## Roles
{{working_style}}
<!-- Mirrors AGENTS.local.md § Working style; change both together. -->

## Git
<!-- Condense .agents/rules/commit.md and point to it; never restate it differently. -->

## Tests
<!-- How changes are tested here, from AGENTS.md and the memory notes. No real test net → say so. -->

## Guardrails
- Guards (cognisphere plugin): `master-guard`, `secret-guard`, `memory-drift-guard`.
- Vault: `Agent/` writable, `Human/` denied (`.agents/settings.local.json`).
<!-- Add the deny list from .agents/settings.json and any hooks in .agents/hooks/. -->

## Subagents and commands
- `cognisphere:explorer`, `cognisphere:planner`, `cognisphere:implementer`, `cognisphere:test-runner`, `cognisphere:reviewer`.
- `/cognisphere:install`, `/cognisphere:update [area]`.
<!-- Add the project's own .agents/agents/ and .agents/skills/, if any. -->

## Memory graph
- Index: `.agents/memory/MEMORY.md`. Read an area's note before changing its code; fix a note in the same task that made it wrong (`.agents/rules/memory.md`).
