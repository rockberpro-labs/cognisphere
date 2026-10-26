---
name: read
description: Reads a note from this project's vault or from ~/Cognisphere/Shared given its path as Obsidian copies it - relative to the open vault (Human/draft.md, or the same path under Projects and the project's folder, or Shared/conventions.md, when ~/Cognisphere is the open vault) - checks it against the code, and then does what the rest of the argument asks, or asks what to do.
argument-hint: "<note path> [what to do with it]"
disable-model-invocation: true
---

# read

Argument: `$ARGUMENTS` — a note path as Obsidian copies it, then optionally a request.

1. **Find the note.** The vault is the path `AGENTS.local.md` § Agent workspace names;
   the root is the folder two levels up (`~/Cognisphere`), and `Shared/` sits in it.
   No such section, or no `AGENTS.local.md` → no vault is set up for this repo: say
   so, point at `/cognisphere:vault`, and stop. Obsidian copies the path relative to
   whichever folder is open, so resolve it by its first segments:
   - `Projects/<project>/…` (the root is open) or `<project>/…` (`Projects/` is open) →
     drop that prefix and join the rest to the vault.
   - `Shared/…` → join it to the root.
   - Anything else (the project's folder or `Shared/` itself is open) → join it to the
     vault; nothing there → join it to `Shared/`. Both exist → the vault's, and say so.

   Add `.md` if the path has no extension. The path may hold spaces: the request is what
   follows the `.md`, or what is left once the longest path that exists is taken. No such
   note → say so and stop. A path that lands outside the vault and `Shared/` (`..`,
   another project's folder, another folder of the root) → say so and stop: the agent
   has no access there.
2. **Read** it whole, plus its embeds (`![[…]]`) and the links its content depends on,
   one level deep.
3. **Check** what it says about the code against the code: code > `AGENTS.md` >
   `.agents/memory/` > the vault.
4. **Act.** A request → do it, with the note as the brief, leading with any
   contradiction from step 3 that changes the work. No request → one line naming what
   was read and what the code contradicts, then ask what to do. Don't summarise the
   note unasked.

Never write the note: `Human/` and `Shared/` are the maintainer's, and `Agent/` changes
only through the Session Protocol.
