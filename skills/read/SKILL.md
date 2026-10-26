---
name: read
description: Reads a note from this project's vault given its path as Obsidian copies it - relative to the vault (Human/draft.md, or <project>/Human/draft.md when ~/Cognisphere is the open vault) - checks it against the code, and then does what the rest of the argument asks, or asks what to do.
argument-hint: "<note path> [what to do with it]"
disable-model-invocation: true
---

# read

Argument: `$ARGUMENTS` — a vault-relative note path, then optionally a request.

1. **Find the note.** The vault is the path `AGENTS.local.md` § Agent workspace names.
   No such section, or no `AGENTS.local.md` → no vault is set up for this repo: say
   so, point at `/cognisphere:vault`, and stop. Drop a leading
   `<project>/` (the maintainer opened `~/Cognisphere` itself in Obsidian), join the rest
   to the vault and Read it, adding `.md` if the path has no extension. The path may
   hold spaces: the request is what follows the `.md`, or what is left once the longest
   path that exists is taken. No such note → say so and stop. A path that leaves the
   vault (`..`, another project's folder) → say so and stop.
2. **Read** it whole, plus its embeds (`![[…]]`) and the links its content depends on,
   one level deep.
3. **Check** what it says about the code against the code: code > `AGENTS.md` >
   `.agents/memory/` > the vault.
4. **Act.** A request → do it, with the note as the brief, leading with any
   contradiction from step 3 that changes the work. No request → one line naming what
   was read and what the code contradicts, then ask what to do. Don't summarise the
   note unasked.

Never write the note: `Human/` is the maintainer's, and `Agent/` changes only through
the Session Protocol.
