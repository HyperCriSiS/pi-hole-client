import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/server/api_versions.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/core/ui/components/error_message.dart';
import 'package:pi_hole_client/ui/core/view_models/servers_viewmodel.dart';
import 'package:pi_hole_client/ui/core/view_models/status_viewmodel.dart';
import 'package:pi_hole_client/ui/statistics/widgets/dns_tab.dart';
import 'package:pi_hole_client/ui/statistics/widgets/statistics_list.dart';
import 'package:pi_hole_client/ui/statistics/widgets/statistics_queries_servers_tab.dart';
import 'package:pi_hole_client/ui/statistics/widgets/statistics_revalidation_status.dart';
import 'package:provider/provider.dart';

class StatisticsTripleColumn extends StatefulWidget {
  const StatisticsTripleColumn({super.key});

  @override
  State<StatisticsTripleColumn> createState() => _StatisticsTripleColumnState();
}

class _StatisticsTripleColumnState extends State<StatisticsTripleColumn> {
  final PageController _controller = PageController(viewportFraction: 1 / 3);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusLoading = context.select<StatusViewModel, LoadStatus>(
      (vm) => vm.getStatusLoading,
    );
    final apiVersion =
        context.select<ServersViewModel, String?>(
          (vm) => vm.selectedServer?.apiVersion,
        ) ??
        SupportedApiVersions.v5;

    final hasCachedData = context.select<StatusViewModel, bool>(
      (vm) => vm.getRealtimeStatus != null ||
          (apiVersion == SupportedApiVersions.v6 &&
              vm.getFtlDnsMetrics != null),
    );

    final columns = <Widget>[
      _buildColumn(
        context: context,
        title: AppLocalizations.of(context)!.queriesServers,
        content: const QueriesServersTabContent(),
      ),
      _buildColumn(
        context: context,
        title: AppLocalizations.of(context)!.domains,
        content: StatisticsListContent(
          type: 'domains',
          countLabel: AppLocalizations.of(context)!.hits,
          pieChartRadiusScale: 6.0,
        ),
      ),
      _buildColumn(
        context: context,
        title: AppLocalizations.of(context)!.clients,
        content: StatisticsListContent(
          type: 'clients',
          countLabel: AppLocalizations.of(context)!.requests,
          pieChartRadiusScale: 6.0,
        ),
      ),
    ];

    if (apiVersion == SupportedApiVersions.v6) {
      columns.add(
        _buildColumn(
          context: context,
          title: AppLocalizations.of(context)!.dns,
          content: const DnsTabContent(),
        ),
      );
    }

    // A previously successful snapshot is usable even when its revalidation
    // is pending or fails. Only the first request can replace the page.
    final Widget body;
    if (!hasCachedData && statusLoading == LoadStatus.loading) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.loadingStats,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 20,
              ),
            ),
          ],
        ),
      );
    } else if (!hasCachedData && statusLoading == LoadStatus.error) {
      body = Center(
        child: ErrorMessage(
          message: AppLocalizations.of(context)!.statsNotLoaded,
        ),
      );
    } else {
      body = Column(
        children: [
          if (hasCachedData)
            StatisticsRevalidationStatus(status: statusLoading),
          Expanded(
            child: Stack(
              children: [
                ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: apiVersion == SupportedApiVersions.v6 ? 32 : 0,
                    ),
                    child: PageView.builder(
                      controller: _controller,
                      physics: const PageScrollPhysics(),
                      padEnds: false,
                      itemCount: columns.length,
                      itemBuilder: (context, index) => columns[index],
                    ),
                  ),
                ),
                if (apiVersion == SupportedApiVersions.v6)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.chevron_left,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                if (apiVersion == SupportedApiVersions.v6)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.chevron_right,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.statistics)),
      body: body,
    );
  }

  Widget _buildColumn({
    required BuildContext context,
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: ListView(children: [content])),
      ],
    );
  }
}
