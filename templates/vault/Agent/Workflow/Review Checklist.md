---
tags: [{{project}}, agent, workflow]
updated: {{date}}
status: skeleton
---
# Review Checklist

Back: [[00 Home]] · [[Working Agreement]] · [[Session Protocol]]

<!-- For reviewing the maintainer's diffs. Every box comes from a rule (.agents/rules/), a memory note or the cognisphere:reviewer agent; cite it in brackets. Invent none. -->

## Landmines
<!-- The traps the memory notes record, one box each. -->

## Interfaces
<!-- API and contract rules from .agents/rules/. -->

<!-- One group per major area with rules of its own goes here. -->

## Tests
- [ ] The change has a check that fails without it, or the gap is stated. [cognisphere:reviewer]

## Hygiene
- [ ] Only the change's files are staged: no credentials, local config or artifacts. [rules/commit.md]

## Memory drift
- [ ] Each memory note whose `paths:` covers a changed file is in the diff, or still holds. [rules/memory.md]
