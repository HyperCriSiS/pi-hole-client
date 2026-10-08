import 'package:flutter/material.dart';
import 'package:pi_hole_client/domain/model/server/endpoint_diagnostics.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/core/ui/components/section_label.dart';

/// Explicit, read-only endpoint checks, not a network-only connectivity test.
class EndpointDiagnosticsPanel extends StatelessWidget {
  const EndpointDiagnosticsPanel({
    required this.running,
    required this.checks,
    required this.onRun,
    super.key,
  });

  final bool running;
  final List<EndpointCheckResult> checks;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    String outcomeLabel(EndpointOutcome outcome) => switch (outcome) {
      EndpointOutcome.success => locale.valid,
      EndpointOutcome.authentication => locale.authentication,
      EndpointOutcome.tls => locale.tlsStatus,
      EndpointOutcome.timeout => locale.connectionTimeout,
      EndpointOutcome.connection => locale.notConnected,
      EndpointOutcome.notFound => locale.notApplicable,
      EndpointOutcome.server => locale.error,
      EndpointOutcome.unknown => locale.unknown,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: locale.endpointDiagnosticsTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            locale.endpointDiagnosticsNote,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: running ? null : onRun,
            icon: running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(locale.endpointDiagnosticsRun),
          ),
        ),
        for (final check in checks)
          ListTile(
            dense: true,
            title: Text(check.endpoint.path),
            trailing: Text(
              '${outcomeLabel(check.outcome)} '
              '(${check.elapsed.inMilliseconds} ms)',
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
