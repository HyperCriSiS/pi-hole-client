import 'package:flutter/material.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';

/// Nonblocking status for a statistics view that already has real cached data.
///
/// Never show this in place of a first-load indicator or error. The caller
/// decides whether a usable snapshot exists for its own statistics section.
class StatisticsRevalidationStatus extends StatelessWidget {
  const StatisticsRevalidationStatus({required this.status, super.key});

  final LoadStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.loaded:
        return const SizedBox.shrink();
      case LoadStatus.loading:
        return const LinearProgressIndicator(minHeight: 2);
      case LoadStatus.error:
        return Padding(
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
                  AppLocalizations.of(context)!.statsNotLoaded,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
