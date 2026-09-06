import 'package:pi_hole_client/config/enums.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/actions_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/adlist_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/auth_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/client_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/cname_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/config_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/dhcp_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/domain_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/ftl_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/group_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/metrics_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/network_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/realtime_status_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/actions_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/adlist_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/auth_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/client_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/config_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/dhcp_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/domain_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/ftl_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/group_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/metrics_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/network_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v5/realtime_status_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/actions_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/adlist_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/auth_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/client_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/config_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/dhcp_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/domain_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/ftl_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/group_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/metrics_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/network_repository.dart';
import 'package:pi_hole_client/data/repositories/api/v6/realtime_status_repository.dart'
    as v6;
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache.dart';
import 'package:pi_hole_client/data/services/api/generated/v6/pihole_v6_api/lib/pihole_v6_api.dart';
import 'package:pi_hole_client/data/services/api/pihole_v5_api_client.dart';
import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';
import 'package:pi_hole_client/data/services/api/wrappers/pihole_v6_service.dart';
import 'package:pi_hole_client/data/services/local/session_credential_service.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';

class RepositoryBundle {
  const RepositoryBundle({
    required this.actions,
    required this.adlist,
    required this.auth,
    required this.client,
    required this.config,
    required this.dhcp,
    required this.dns,
    required this.domain,
    required this.ftl,
    required this.group,
    required this.localDns,
    required this.metrics,
    required this.network,
    required this.realtimeStatus,
    required this.serverAddress,
    required this.apiVersion,
    required this.allowUntrustedCert,
    required this.ignoreCertificateErrors,
    required this.pinnedCertificateSha256,
  });

  final ActionsRepository actions;
  final AdlistRepository adlist;
  final AuthRepository auth;
  final ClientRepository client;
  final ConfigRepository config;
  final DhcpRepository dhcp;
  final DnsRepository dns;
  final DomainRepository domain;
  final FtlRepository ftl;
  final GroupRepository group;
  final LocalDnsRepository localDns;
  final MetricsRepository metrics;
  final NetworkRepository network;
  final RealtimeStatusRepository realtimeStatus;
  final String serverAddress;
  final String? apiVersion;
  final bool allowUntrustedCert;
  final bool ignoreCertificateErrors;
  final String? pinnedCertificateSha256;

  CnameRepository? get cname => localDns is CnameRepository
      ? localDns as CnameRepository
      : null;
}

class RepositoryBundleFactory {
  RepositoryBundleFactory({required SessionCredentialService creds})
    : _creds = creds;

  final SessionCredentialService _creds;

  RepositoryBundle create(Server server) {
    final creds = _creds;
    switch (server.apiVersion) {
      case ApiVersion.v6:
        final client = PiholeV6ApiClient(
          url: server.address,
          allowUntrustedCert: server.allowUntrustedCert,
          ignoreCertificateErrors: server.ignoreCertificateErrors,
          pinnedCertificateSha256: server.pinnedCertificateSha256,
        );
        final generatedApi = PiholeV6Api(
          basePathOverride: '${server.address}/api',
          interceptors: client.sharedInterceptors,
        );
        final generatedService = PiholeV6Service(api: generatedApi);
        final sessionCache = V6SessionCache(creds: creds, client: client);
        return RepositoryBundle(
          actions: ActionsRepositoryV6(
            client: client,
            service: generatedService,
            sessionCache: sessionCache,
          ),
          adlist: AdlistRepositoryV6(
            service: generatedService,
            sessionCache: sessionCache,
          ),
          auth: AuthRepositoryV6(
            client: client,
            service: generatedService,
            sessionCache: sessionCache,
          ),
          client: ClientRepositoryV6(
            service: generatedService,
            sessionCache: sessionCache,
          ),
          config: ConfigRepositoryV6(
            service: generatedService,
            sessionCache: sessionCache,
          ),
          dhcp: DhcpRepositoryV6(
            service: generatedService,
            sessionCache: sessionCache,
          ),
          dns: DnsRepositoryV6(
            service: generatedService,
            sessionCache: sessionCache,
          ),
          domain: DomainRepositoryV6(
            service: generatedService,
            sessionCache: sessionCache,
          ),
          ftl: FtlRepositoryV6(
            client: client,
            service: generatedService,
            sessionCache: sessionCache,
          ),
          group: GroupRepositoryV6(
            service: generatedService,
            sessionCache: sessionCache,
          ),
          localDns: LocalDnsRepositoryV6(
            client: client,
            service: generatedService,
            sessionCache: sessionCache,
          ),
          metrics: MetricsRepositoryV6(
            client: client,
            service: generatedService,
            sessionCache: sessionCache,
          ),
          network: NetworkRepositoryV6(
            client: client,
            service: generatedService,
            sessionCache: sessionCache,
          ),
          realtimeStatus: v6.RealtimeStatusRepositoryV6(
            client: client,
            sessionCache: sessionCache,
          ),
          serverAddress: server.address,
          apiVersion: server.apiVersion,
          allowUntrustedCert: server.allowUntrustedCert,
          ignoreCertificateErrors: server.ignoreCertificateErrors,
          pinnedCertificateSha256: server.pinnedCertificateSha256,
        );
      default:
        final client = PiholeV5ApiClient(
          url: server.address,
          allowUntrustedCert: server.allowUntrustedCert,
          ignoreCertificateErrors: server.ignoreCertificateErrors,
          pinnedCertificateSha256: server.pinnedCertificateSha256,
        );
        return RepositoryBundle(
          actions: ActionsRepositoryV5(client: client, creds: creds),
          adlist: AdlistRepositoryV5(client: client, creds: creds),
          auth: AuthRepositoryV5(client: client, creds: creds),
          client: ClientRepositoryV5(client: client, creds: creds),
          config: ConfigRepositoryV5(client: client, creds: creds),
          dhcp: DhcpRepositoryV5(client: client, creds: creds),
          dns: DnsRepositoryV5(client: client, creds: creds),
          domain: DomainRepositoryV5(client: client, creds: creds),
          ftl: FtlRepositoryV5(client: client, creds: creds),
          group: GroupRepositoryV5(client: client, creds: creds),
          localDns: LocalDnsRepositoryV5(client: client, creds: creds),
          metrics: MetricsRepositoryV5(client: client, creds: creds),
          network: NetworkRepositoryV5(client: client, creds: creds),
          realtimeStatus: RealTimeStatusRepositoryV5(
            client: client,
            creds: creds,
          ),
          serverAddress: server.address,
          apiVersion: server.apiVersion,
          allowUntrustedCert: server.allowUntrustedCert,
          ignoreCertificateErrors: server.ignoreCertificateErrors,
          pinnedCertificateSha256: server.pinnedCertificateSha256,
        );
    }
  }
}
