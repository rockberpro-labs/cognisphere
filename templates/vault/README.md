# Cognisphere

One folder per project, written by the [cognisphere](https://github.com/rockberpro/cognisphere) plugin for Claude Code. Each one can be opened as an Obsidian vault.

- `<project>/Agent/` is the agent's workspace: state, log, knowledge, scratch. The agent is its only writer.
- `<project>/Human/` is yours. Agents read it and cannot write there.

## Backups are yours

Nothing here is in git, and cognisphere never syncs or backs it up. Lose this folder and the agent's state, history and your own notes are gone.

Pick one:

- Add `~/Cognisphere` to a sync client: Google Drive for desktop, Dropbox, OneDrive, iCloud Drive.
- Use Obsidian Sync or Syncthing.
- Schedule a copy, e.g. `rsync -a ~/Cognisphere/ /backup/Cognisphere/` from cron, or a `restic` snapshot.

Then:

- **Test a restore** once: copy a project folder back and open it.
- Sync clients may create conflict copies (`… (conflicted copy).md`) when two machines write at once. Merge them by hand and delete the copy.

A restored or lost folder is not recreated behind your back: `/cognisphere:update` reports a missing vault, and `/cognisphere:vault` re-seeds only the notes that are missing.
