import 'package:flutter/material.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';

/// Keeps cached chart content visible while it is revalidated. Only the
/// absence of cached data should switch a chart to a loading/error screen.
class CachedChartStatus extends StatelessWidget {
  const CachedChartStatus({
    required this.status,
    required this.child,
    super.key,
  });

  final LoadStatus status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (status == LoadStatus.loaded) return child;

    return Column(
      children: [
        if (status == LoadStatus.loading)
          const LinearProgressIndicator(minHeight: 2),
        if (status == LoadStatus.error)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.chartsNotLoaded,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        child,
      ],
    );
  }
}
