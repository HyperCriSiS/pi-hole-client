import 'package:flutter/material.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/cname_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/repository_bundle.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/local_dns/view_models/local_dns_viewmodel.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/local_dns/widgets/local_dns_screen.dart';

Widget createLocalDnsScreen(RepositoryBundle bundle) {
  final localDnsRepository = bundle.localDns;
  return LocalDnsScreen(
    viewModel: LocalDnsViewModel(
      localDnsRepository: localDnsRepository,
      networkRepository: bundle.network,
      cnameRepository: localDnsRepository is CnameRepository
          ? localDnsRepository
          : null,
    )..loadRecords.run(),
  );
}
