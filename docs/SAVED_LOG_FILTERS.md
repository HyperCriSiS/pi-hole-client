# Saved Query Log filters

Open **Query logs → Filters** and tap the bookmark-plus icon to save the current filter state under a name (1–64 characters). The bookmarks icon lists the saved filters; tap one to restore and refresh, or use the trash icon to delete it. Saving an existing name (case-insensitive) replaces that snapshot for the current server and API version.

A preset contains selected query statuses, request status category, an optional narrowed client list, an exact domain, and explicit start/end timestamps. It does **not** save query data, session IDs, passwords, free-text search or sort order. Exact time ranges are fixed instants, not rolling windows.

Presets are stored locally in SQLite schema version 11 in `saved_log_filters`, scoped by server address and Pi-hole API version. Foreign-key cascading deletes a server's presets when that server is deleted. Server switching does not automatically apply stored presets; the user explicitly selects one. Invalid/obsolete status mappings fail instead of silently broadening queries. Applying uses the existing `LogsViewModel.applyFilterAndLoad` path (including v6 server-side filters and existing v5 behavior).

No network endpoints, generated FTL API code, credentials, automatic session recovery or background jobs are added. Testing covers local JSON serialization, SQLite isolation/cascade/foreign-key behavior, and in-memory ViewModel restoration. Android/desktop manual smoke remains desirable.
