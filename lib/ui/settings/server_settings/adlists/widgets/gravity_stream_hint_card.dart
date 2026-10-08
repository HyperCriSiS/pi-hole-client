import 'package:flutter/material.dart';
import 'package:pi_hole_client/domain/model/gravity/gravity_stream_diagnostics.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';

/// A conditional troubleshooting suggestion, never a confirmed diagnosis.
class GravityStreamHintCard extends StatelessWidget {
  const GravityStreamHintCard({required this.hint, super.key});

  final GravityStreamHint hint;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final (title, detail) = switch (hint) {
      GravityStreamHint.possibleProxyBuffering => (
        locale.gravityProxyTimeoutHintTitle,
        locale.gravityProxyTimeoutHintDetail,
      ),
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
