import 'package:flutter/material.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/repository_bundle.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/view_models/server_info_viewmodel.dart';
import 'package:pi_hole_client/ui/settings/server_settings/server_info/widgets/server_info_screen.dart';

Widget createServerInfoScreen({
  required RepositoryBundle bundle,
  required Server server,
}) {
  return ServerInfoScreen(
    viewModel: ServerInfoViewModel(
      ftlRepository: bundle.ftl,
      authRepository: bundle.auth,
      configRepository: bundle.config,
      server: server,
      connectionSessionStateProvider: () => bundle.connectionSessionState,
    )..loadServerInfo.run(),
    serverAlias: server.alias,
    serverAddress: server.address,
  );
}
