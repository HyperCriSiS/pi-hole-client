import 'package:flutter/material.dart';
import 'package:pi_hole_client/ui/core/actions/handle_totp_reauth.dart';
import 'package:pi_hole_client/ui/core/view_models/servers_viewmodel.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:provider/provider.dart';

/// Runs a user-initiated screen refresh and recovers an expired TOTP session.
///
/// Explicit refresh gestures are allowed to prompt again even if the user
/// previously cancelled an automatic reauthentication prompt. Automatic loads
/// do not use this helper and continue respecting the declined marker.
Future<void> refreshWithTotpRecovery(
  BuildContext context,
  Future<void> Function() load,
) async {
  final serversViewModel = context.read<ServersViewModel>();
  final address = serversViewModel.selectedServer?.address;
  if (address != null) {
    serversViewModel.clearTotpReauthDeclined(address);
  }

  try {
    await load();
  } on TotpRequiredException {
    if (!context.mounted) return;

    final recovered = await handleTotpReauth(context);
    if (recovered && context.mounted) {
      await load();
    }
  }
}
