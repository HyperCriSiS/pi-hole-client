import 'package:flutter/material.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/servers/view_models/multi_server_overview_controller.dart';

/// Manual refresh only: opening this dialog makes no network request.
class MultiServerOverviewDialog extends StatefulWidget {
  const MultiServerOverviewDialog({required this.servers, required this.reader, super.key});
  final List<Server> servers;
  final ServerOverviewReader reader;
  @override
  State<MultiServerOverviewDialog> createState() => _MultiServerOverviewDialogState();
}

class _MultiServerOverviewDialogState extends State<MultiServerOverviewDialog> {
  late final MultiServerOverviewController controller;
  @override
  void initState() {
    super.initState();
    controller = MultiServerOverviewController(servers: widget.servers, reader: widget.reader);
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      child: SizedBox(
        width: 660,
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Column(
            children: [
              ListTile(
                title: Text(loc.multiServerOverview),
                subtitle: Text(loc.multiServerOverviewManual),
                trailing: IconButton(
                  tooltip: loc.close, icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: controller.servers.isEmpty
                    ? Center(child: Text(loc.noSavedConnections))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        itemCount: controller.servers.length,
                        itemBuilder: (context, index) {
                          final server = controller.servers[index];
                          return _OverviewTile(
                            key: ValueKey(server.address),
                            server: server,
                            entry: controller.entryFor(server),
                            enabled: !controller.busy,
                            onRefresh: () => controller.refreshOne(server),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: controller.busy || controller.servers.isEmpty
                          ? null : controller.refreshAll,
                      icon: controller.busy
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(loc.multiServerRefreshAll),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({required this.server, required this.entry, required this.enabled, required this.onRefresh, super.key});
  final Server server;
  final ServerOverviewEntry entry;
  final bool enabled;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final metrics = entry.metrics;
    final updatedAt = entry.updatedAt?.toLocal();
    final materialLoc = MaterialLocalizations.of(context);
    final status = switch (entry.state) {
      ServerOverviewLoadState.notRequested => loc.multiServerNotRequested,
      ServerOverviewLoadState.loading => loc.loading,
      ServerOverviewLoadState.loaded => loc.multiServerLastFetched,
      ServerOverviewLoadState.failed => loc.multiServerFetchFailed,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(server.alias, style: Theme.of(context).textTheme.titleMedium),
                      Text(server.address, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      Text(server.apiVersion, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: loc.refresh, onPressed: enabled ? onRefresh : null,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(status, style: Theme.of(context).textTheme.bodySmall),
            ),
            if (entry.state == ServerOverviewLoadState.loaded &&
                updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${loc.multiServerSnapshotAt}: '
                  '${materialLoc.formatMediumDate(updatedAt)} '
                  '${materialLoc.formatTimeOfDay(
                    TimeOfDay.fromDateTime(updatedAt),
                    alwaysUse24HourFormat:
                        MediaQuery.alwaysUse24HourFormatOf(context),
                  )}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (metrics != null && entry.state == ServerOverviewLoadState.loaded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 20, runSpacing: 8,
                  children: [
                    Text('${loc.totalQueries}: ${metrics.queries}'),
                    Text('${loc.blocked}: ${metrics.blocked}'),
                    Text('${loc.multiServerBlockedPercent}: ${metrics.blockedPercentage.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
