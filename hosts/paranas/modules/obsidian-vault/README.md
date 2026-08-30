# Obsidian starter vault

This directory is the versioned source for the vault's folders and templates.
The running Markdown mirror is `/var/lib/obsidian-vault`; do not point
Obsidian at this Git checkout.

After the LiveSync bridge has completed its first CouchDB-to-filesystem sync,
copy missing starter files into the mirror with:

```console
sudo systemctl start obsidian-vault-seed
```

The copy is non-destructive: an existing note with the same path is retained.
LiveSync Bridge then sends the new starter notes to Obsidian clients.

Recommended community plugins:

- Tasks for vault-wide task queries.
- QuickAdd for one-key meeting and inbox capture.
- Either Text Generator or Copilot for processing raw meeting notes.

Keep generated content in `Briefings/`; all other folders are human-owned.
