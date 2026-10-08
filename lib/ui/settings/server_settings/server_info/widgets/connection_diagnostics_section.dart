import 'package:flutter/material.dart';
import 'package:pi_hole_client/domain/model/server/connection_diagnostics.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/core/ui/components/list_tile_title.dart';
import 'package:pi_hole_client/ui/core/ui/components/section_label.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ConnectionDiagnosticsSection extends StatelessWidget {
  const ConnectionDiagnosticsSection({
    required this.diagnostics,
    super.key,
  });

  final ConnectionDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton.keep(child: SectionLabel(label: locale.connectionStatus)),
        _diagnosticTile(
          context,
          icon: Icons.api_rounded,
          title: 'API ${locale.version}',
          value: diagnostics.apiVersion.toUpperCase(),
        ),
        _diagnosticTile(
          context,
          icon: Icons.memory_rounded,
          title: 'FTL ${locale.version}',
          value: diagnostics.ftlVersion ?? '-',
        ),
        _diagnosticTile(
          context,
          icon: Icons.route_rounded,
          title: 'API ${locale.subrouteField}',
          value: diagnostics.apiBasePath,
        ),
        _diagnosticTile(
          context,
          icon: Icons.web_rounded,
          title: 'Web ${locale.subrouteField}',
          value: diagnostics.webPanelPath,
        ),
        _diagnosticTile(
          context,
          icon: Icons.key_rounded,
          title: locale.sessionStatus,
          value: _sessionLabel(locale),
        ),
        _diagnosticTile(
          context,
          icon: Icons.security_rounded,
          title: locale.tlsStatus,
          value: _tlsLabel(locale),
        ),
      ],
    );
  }

  Widget _diagnosticTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: Skeleton.keep(child: Icon(icon)),
      title: Skeleton.keep(
        child: listTileTitleNoPadding(title, colorScheme: colorScheme),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Tooltip(
          message: value,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  String _sessionLabel(AppLocalizations locale) {
    return switch (diagnostics.sessionState) {
      ConnectionSessionState.active => locale.valid,
      ConnectionSessionState.noAuthenticationRequired => locale.notApplicable,
      ConnectionSessionState.interactiveReauthRequired => locale.authentication,
      ConnectionSessionState.notApplicable => locale.notApplicable,
      ConnectionSessionState.unknown => locale.unknown,
    };
  }

  String _tlsLabel(AppLocalizations locale) {
    return switch (diagnostics.tlsPolicy) {
      ConnectionTlsPolicy.http => locale.serverSecurityHttp,
      ConnectionTlsPolicy.httpsVerified => locale.serverSecurityHttpsVerified,
      ConnectionTlsPolicy.httpsPinned => locale.serverSecurityHttpsPinned,
      ConnectionTlsPolicy.httpsUntrustedAllowed =>
        locale.serverSecurityHttpsUntrustedAllowed,
      ConnectionTlsPolicy.httpsCertificateChecksDisabled =>
        locale.dontCheckCertificate,
      ConnectionTlsPolicy.unknown => locale.serverSecurityHttpsUnknown,
    };
  }
}
