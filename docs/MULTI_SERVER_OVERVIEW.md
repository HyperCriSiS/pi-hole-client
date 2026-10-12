# Multi-Pi-hole overview (initial, read-only slice)

From **Settings → App → Servers**, use the new dashboard icon in the title bar to open the overview. All configured Pi-hole v5 and v6 servers are listed with their address and alias.

Opening this dialog does not contact any server. Use the refresh icon on a server card to read only that server, or **Refresh all servers** for sequential per-server snapshots. Queries use existing authenticated repository calls: Pi-hole v5 realtime status summary and Pi-hole v6 metrics stats summary. The overview shows daily query counts, blocked query counts, and blocking percentage **for each server separately**.

Safety/limitations:
- No automatic/background polling, writes, blocking toggles, server selection changes, credential copying, or interactive TOTP prompts. The underlying authenticated client can attempt its existing noninteractive session renewal for an explicitly requested read; failures show a generic error on only the affected card.
- Each successful card shows the **local device date and time of that individual read's completion** so the freshness of a snapshot is explicit. This is not the Pi-hole server's time and does not prove DNS service availability. A failed read has no snapshot timestamp or metrics.
- Successful reads do not prove DNS service uptime, and different servers can have different local "today" windows. There is no aggregate total or cross-server ranking.
- The overview starts with no cached results on each opening. Failed refreshes remove old statistics instead of presenting them as fresh.
- Closing the overview discards the local snapshots. An already-started network request cannot be cancelled by the dialog; its completion is ignored and the next server is not contacted after disposal.
- Device-level connectivity, TLS, session and UX smoke tests remain pending.
