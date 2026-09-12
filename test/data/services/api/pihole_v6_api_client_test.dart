import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pi_hole_client/data/model/v6/network/gateway.dart';
import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../testing/helper/test_helper.dart';
import '../utils/mocks.mocks.dart';

void main() {
  const baseUrl = 'http://localhost:8080';
  const sid = 'sid12345';

  late PiholeV6ApiClient apiClient;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    apiClient = PiholeV6ApiClient(url: baseUrl, client: mockClient);
  });

  // ==========================================================================
  // Authentication
  // ==========================================================================
  group('postAuth', () {
    final url = Uri.parse('$baseUrl/api/auth');

    test('returns Session on successful authentication', () async {
      final respJson = {
        'session': {
          'valid': true,
          'totp': false,
          'sid': 'n9n9f6c3umrumfq2ese1lvu2pg',
          'csrf': 'Ux87YTIiMOf/GKCefVIOMw=',
          'validity': 300,
          'message': 'correct password',
        },
        'took': 0.03,
      };
      final response = http.Response(jsonEncode(respJson), 200);

      mockPost(mockClient, url, response);

      final result = await apiClient.postAuth(password: 'pass123');

      expectSuccess(result, respJson);
    });

    test('parses no-password response (valid, null sid/csrf)', () async {
      final respJson = {
        'session': {
          'valid': true,
          'totp': false,
          'sid': null,
          'csrf': null,
          'validity': -1,
          'message': 'no password set',
        },
        'took': 0.03,
      };
      final response = http.Response(jsonEncode(respJson), 200);

      mockPost(mockClient, url, response);

      final result = await apiClient.postAuth(password: '');

      expect(result.isSuccess(), isTrue);
      final session = result.getOrNull()!;
      expect(session.session.valid, isTrue);
      expect(session.session.sid, isNull);
      expect(session.session.csrf, isNull);
    });

    test('returns error when password is incorrect (401)', () async {
      final response = http.Response(
        jsonEncode({
          'session': {
            'valid': false,
            'totp': false,
            'sid': null,
            'validity': -1,
            'message': 'password incorrect',
          },
          'took': 0.03,
        }),
        401,
      );

      mockPost(mockClient, url, response);

      final result = await apiClient.postAuth(password: 'wrongpass');

      expectHttpError(
        result,
        statusCode: 401,
        messageContains: 'password incorrect',
      );
    });

    test(
      'returns TotpRequiredException when 2FA is required (400 bad_request)',
      () async {
        final response = http.Response(
          jsonEncode({
            'error': {
              'key': 'bad_request',
              'message': 'No 2FA token found in JSON payload',
              'hint': null,
            },
            'took': 0.03,
          }),
          400,
        );

        mockPost(mockClient, url, response);

        final result = await apiClient.postAuth(password: 'correct');

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), isA<TotpRequiredException>());
      },
    );

    test(
      'returns TotpInvalidException when the TOTP code is rejected (401)',
      () async {
        final response = http.Response(
          jsonEncode({
            'error': {
              'key': 'unauthorized',
              'message': 'Invalid 2FA token',
              'hint': null,
            },
            'took': 0.03,
          }),
          401,
        );

        mockPost(mockClient, url, response);

        final result = await apiClient.postAuth(password: 'correct', totp: 0);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), isA<TotpInvalidException>());
      },
    );

    test(
      'returns TotpReusedException when the TOTP code is reused (401)',
      () async {
        final response = http.Response(
          jsonEncode({
            'error': {
              'key': 'unauthorized',
              'message': 'Reused 2FA token',
              'hint': 'wait for new token',
            },
            'took': 0.03,
          }),
          401,
        );

        mockPost(mockClient, url, response);

        final result = await apiClient.postAuth(password: 'correct', totp: 0);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), isA<TotpReusedException>());
      },
    );

    test(
      'returns TotpRateLimitException when 2FA is rate limited (429)',
      () async {
        final response = http.Response(
          jsonEncode({
            'error': {
              'key': 'rate_limiting',
              'message': 'Rate-limiting 2FA token requests, try again later',
              'hint': null,
            },
            'took': 0.03,
          }),
          429,
        );

        mockPost(mockClient, url, response);

        final result = await apiClient.postAuth(password: 'correct', totp: 0);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), isA<TotpRateLimitException>());
      },
    );

    test('a generic login rate-limit (429) is a plain HTTP error', () async {
      final response = http.Response(
        jsonEncode({
          'error': {
            'key': 'rate_limiting',
            'message': 'Rate-limiting login attempts',
            'hint': null,
          },
          'took': 0.03,
        }),
        429,
      );

      mockPost(mockClient, url, response);

      final result = await apiClient.postAuth(password: 'wrong');

      expectHttpError(
        result,
        statusCode: 429,
        messageContains: 'Rate-limiting',
      );
    });
  });

  // ==========================================================================
  // Metrics
  // ==========================================================================
  // ==========================================================================
  // DNS control
  // ==========================================================================
  // ==========================================================================
  // Group management
  // ==========================================================================
  // ==========================================================================
  // Domain management
  // ==========================================================================
  // ==========================================================================
  // List management
  // ==========================================================================
  // ==========================================================================
  // FTL information
  // ==========================================================================
  group('getInfoFtl', () {
    final url = Uri.parse('$baseUrl/api/info/ftl');

    test('returns FTL information with FTL < 6.2', () async {
      final data = {
        'ftl': {
          'database': {
            'gravity': 67906,
            'groups': 6,
            'lists': 1,
            'clients': 5,
            'domains': {
              'allowed': {'total': 10, 'enabled': 10},
              'denied': {'total': 3, 'enabled': 3},
            },
            'regex': {
              'allowed': {'total': 2, 'enabled': 2},
              'denied': {'total': 1, 'enabled': 1},
            },
          },
          'privacy_level': 0,
          'clients': {'total': 10, 'active': 8},
          'pid': 1234,
          'uptime': 123456789,
          '%mem': 0.1,
          '%cpu': 1.2,
          'allow_destructive': true,
          'dnsmasq': {
            'dns_cache_inserted': 8,
            'dns_cache_live_freed': 0,
            'dns_queries_forwarded': 2,
            'dns_auth_answered': 0,
            'dns_local_answered': 74,
            'dns_stale_answered': 0,
            'dns_unanswered': 0,
            'bootp': 0,
            'pxe': 0,
            'dhcp_ack': 0,
            'dhcp_decline': 0,
            'dhcp_discover': 0,
            'dhcp_inform': 0,
            'dhcp_nak': 0,
            'dhcp_offer': 0,
            'dhcp_release': 0,
            'dhcp_request': 0,
            'noanswer': 0,
            'leases_allocated_4': 0,
            'leases_pruned_4': 0,
            'leases_allocated_6': 0,
            'leases_pruned_6': 0,
            'tcp_connections': 0,
            'dnssec_max_crypto_use': 0,
            'dnssec_max_sig_fail': 0,
            'dnssec_max_work': 0,
          },
        },
        'took': 0.003,
      };
      final response = http.Response(jsonEncode(data), 200);
      mockGet(mockClient, url, response);

      final result = await apiClient.getInfoFtl(sid);

      expectSuccess(result, data);
    });

    test('returns FTL information with FTL >= 6.3', () async {
      final data = {
        'ftl': {
          'database': {
            'gravity': 67906,
            'groups': 6,
            'lists': 1,
            'clients': 5,
            'domains': {
              'allowed': {'total': 40, 'enabled': 10},
              'denied': {'total': 30, 'enabled': 3},
            },
            'regex': {
              'allowed': {'total': 20, 'enabled': 2},
              'denied': {'total': 10, 'enabled': 1},
            },
          },
          'privacy_level': 0,
          'clients': {'total': 10, 'active': 8},
          'pid': 1234,
          'uptime': 123456789,
          '%mem': 0.1,
          '%cpu': 1.2,
          'allow_destructive': true,
          'dnsmasq': {
            'dns_cache_inserted': 8,
            'dns_cache_live_freed': 0,
            'dns_queries_forwarded': 2,
            'dns_auth_answered': 0,
            'dns_local_answered': 74,
            'dns_stale_answered': 0,
            'dns_unanswered': 0,
            'bootp': 0,
            'pxe': 0,
            'dhcp_ack': 0,
            'dhcp_decline': 0,
            'dhcp_discover': 0,
            'dhcp_inform': 0,
            'dhcp_nak': 0,
            'dhcp_offer': 0,
            'dhcp_release': 0,
            'dhcp_request': 0,
            'noanswer': 0,
            'leases_allocated_4': 0,
            'leases_pruned_4': 0,
            'leases_allocated_6': 0,
            'leases_pruned_6': 0,
            'tcp_connections': 0,
            'dnssec_max_crypto_use': 0,
            'dnssec_max_sig_fail': 0,
            'dnssec_max_work': 0,
          },
        },
        'took': 0.003,
      };
      final response = http.Response(jsonEncode(data), 200);
      mockGet(mockClient, url, response);

      final result = await apiClient.getInfoFtl(sid);

      expectSuccess(result, data);
    });

    test('returns error when unauthorized (401)', () async {
      const data = {
        'error': {
          'key': 'unauthorized',
          'message': 'Unauthorized',
          'hint': null,
        },
        'took': 0.003,
      };
      final response = http.Response(jsonEncode(data), 401);
      mockGet(mockClient, url, response);

      final result = await apiClient.getInfoFtl(sid);

      expectHttpError(result, statusCode: 401, messageContains: 'Unauthorized');
    });
  });

  // ==========================================================================
  // Network information
  // ==========================================================================
  group('getNetworkGateway', () {
    final url = Uri.parse('$baseUrl/api/network/gateway');

    test('get network gateway information', () async {
      final data = {
        'gateway': [
          {
            'family': 'inet',
            'interface': 'eth0',
            'address': '192.168.0.1',
            'local': ['192.168.0.22'],
          },
          {
            'family': 'inet6',
            'interface': 'eth0',
            'address': 'fe80::3587:2fff:f11a:1',
            'local': ['fe80::3587:2fff:f11a:4321'],
          },
        ],
        'took': 0.003,
        'interfaces': null,
        'routes': null,
      };
      final response = http.Response(jsonEncode(data), 200);
      mockGet(mockClient, url, response);

      final result = await apiClient.getNetworkGateway(sid);

      expectSuccess(result, data);
    });

    test('get newtork gateway information when isDetailed is true', () async {
      final data = {
        'gateway': [
          {
            'family': 'inet',
            'interface': 'eth0',
            'address': '192.168.0.1',
            'local': ['192.168.0.22'],
          },
        ],
        'routes': [
          {
            'table': 254,
            'family': 'inet',
            'protocol': 'boot',
            'scope': 'universe',
            'type': 'unicast',
            'flags': ['onlink'],
            'iflags': 4,
            'gateway': '192.168.0.1',
            'oif': 'eth0',
            'dst': 'default',
          },
          {
            'table': 254,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'link',
            'type': 'unicast',
            'flags': ['linkdown'],
            'iflags': 16,
            'dst': '172.17.0.0',
            'prefsrc': '172.17.0.1',
            'oif': 'docker0',
          },
          {
            'table': 254,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'link',
            'type': 'unicast',
            'flags': ['linkdown'],
            'iflags': 16,
            'dst': '172.18.0.0',
            'prefsrc': '172.18.0.1',
            'oif': 'br-123456abcdef',
          },
          {
            'table': 254,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'link',
            'type': 'unicast',
            'flags': [],
            'iflags': 0,
            'dst': '192.168.0.0',
            'prefsrc': '192.168.0.22',
            'oif': 'eth0',
          },
          {
            'table': 255,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'host',
            'type': 'local',
            'flags': [],
            'iflags': 0,
            'dst': '127.0.0.0',
            'prefsrc': '127.0.0.1',
            'oif': 'lo',
          },
          {
            'table': 255,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'host',
            'type': 'local',
            'flags': [],
            'iflags': 0,
            'dst': '127.0.0.1',
            'prefsrc': '127.0.0.1',
            'oif': 'lo',
          },
          {
            'table': 255,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'link',
            'type': 'broadcast',
            'flags': [],
            'iflags': 0,
            'dst': '127.255.255.255',
            'prefsrc': '127.0.0.1',
            'oif': 'lo',
          },
          {
            'table': 255,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'host',
            'type': 'local',
            'flags': [],
            'iflags': 0,
            'dst': '172.17.0.1',
            'prefsrc': '172.17.0.1',
            'oif': 'docker0',
          },
          {
            'table': 255,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'link',
            'type': 'broadcast',
            'flags': ['linkdown'],
            'iflags': 16,
            'dst': '172.17.255.255',
            'prefsrc': '172.17.0.1',
            'oif': 'docker0',
          },
          {
            'table': 255,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'host',
            'type': 'local',
            'flags': [],
            'iflags': 0,
            'dst': '172.18.0.1',
            'prefsrc': '172.18.0.1',
            'oif': 'br-123456abcdef',
          },
          {
            'table': 255,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'link',
            'type': 'broadcast',
            'flags': ['linkdown'],
            'iflags': 16,
            'dst': '172.18.255.255',
            'prefsrc': '172.18.0.1',
            'oif': 'br-123456abcdef',
          },
          {
            'table': 255,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'host',
            'type': 'local',
            'flags': [],
            'iflags': 0,
            'dst': '192.168.0.22',
            'prefsrc': '192.168.0.22',
            'oif': 'eth0',
          },
          {
            'table': 255,
            'family': 'inet',
            'protocol': 'kernel',
            'scope': 'link',
            'type': 'broadcast',
            'flags': [],
            'iflags': 0,
            'dst': '192.168.0.255',
            'prefsrc': '192.168.0.22',
            'oif': 'eth0',
          },
          {
            'table': 254,
            'family': 'inet6',
            'protocol': 'kernel',
            'scope': 'universe',
            'type': 'unicast',
            'flags': [],
            'iflags': 0,
            'dst': 'fe80::',
            'priority': 256,
            'oif': 'eth0',
            'cstamp': 1745897374,
            'tstamp': 1745897374,
            'expires': 0,
            'error': 0,
            'used': 0,
            'pref': 0,
          },
          {
            'table': 254,
            'family': 'inet6',
            'protocol': 'kernel',
            'scope': 'universe',
            'type': 'unicast',
            'flags': ['linkdown'],
            'iflags': 16,
            'dst': 'fe80::',
            'priority': 256,
            'oif': 'br-123456abcdef',
            'cstamp': 1745897374,
            'tstamp': 1745897374,
            'expires': 0,
            'error': 0,
            'used': 0,
            'pref': 0,
          },
          {
            'table': 255,
            'family': 'inet6',
            'protocol': 'kernel',
            'scope': 'universe',
            'type': 'local',
            'flags': [],
            'iflags': 0,
            'dst': '::1',
            'priority': 0,
            'oif': 'lo',
            'cstamp': 1745897374,
            'tstamp': 1745897374,
            'expires': 0,
            'error': 0,
            'used': 0,
            'pref': 0,
          },
          {
            'table': 255,
            'family': 'inet6',
            'protocol': 'kernel',
            'scope': 'universe',
            'type': 'local',
            'flags': [],
            'iflags': 0,
            'dst': 'fe80::50d8:b7ee:fe99:e19d',
            'priority': 0,
            'oif': 'br-123456abcdef',
            'cstamp': 1745897374,
            'tstamp': 1745897374,
            'expires': 0,
            'error': 0,
            'used': 0,
            'pref': 0,
          },
          {
            'table': 255,
            'family': 'inet6',
            'protocol': 'kernel',
            'scope': 'universe',
            'type': 'local',
            'flags': [],
            'iflags': 0,
            'dst': 'fex0::e13f:1ef:f1ba:3ede',
            'priority': 0,
            'oif': 'eth0',
            'cstamp': 1745897374,
            'tstamp': 1745897374,
            'expires': 0,
            'error': 0,
            'used': 0,
            'pref': 0,
          },
          {
            'table': 255,
            'family': 'inet6',
            'protocol': 'kernel',
            'scope': 'universe',
            'type': 'multicast',
            'flags': [],
            'iflags': 0,
            'dst': 'ff00::',
            'priority': 256,
            'oif': 'eth0',
            'cstamp': 1745897374,
            'tstamp': 1745897374,
            'expires': 0,
            'error': 0,
            'used': 0,
            'pref': 0,
          },
          {
            'table': 255,
            'family': 'inet6',
            'protocol': 'kernel',
            'scope': 'universe',
            'type': 'multicast',
            'flags': ['linkdown'],
            'iflags': 16,
            'dst': 'ff00::',
            'priority': 256,
            'oif': 'br-123456abcdef',
            'cstamp': 1745897374,
            'tstamp': 1745897374,
            'expires': 0,
            'error': 0,
            'used': 0,
            'pref': 0,
          },
        ],
        'interfaces': [
          {
            'name': 'lo',
            'index': 1,
            'family': 'unspec',
            'speed': null,
            'type': 'loopback',
            'flags': ['up', 'loopback', 'running', 'lower_up'],
            'ifname': 'lo',
            'txqlen': 1000,
            'state': 'unknown',
            'linkmode': 0,
            'mtu': 65536,
            'min_mtu': 0,
            'max_mtu': 0,
            'group': 0,
            'promiscuity': 0,
            'unknown': [61, 58, 63, 64, 59, 60, 32830, 32833],
            'num_tx_queues': 1,
            'gso_max_segs': 65535,
            'gso_max_size': 65536,
            'num_rx_queues': 1,
            'carrier': true,
            'carrier_changes': 0,
            'carrier_up_count': 0,
            'carrier_down_count': 0,
            'proto_down': false,
            'address': '00:00:00:00:00:00',
            'broadcast': '00:00:00:00:00:00',
            'qdisc': 'noqueue',
            'map': 0,
            'stats': {
              'rx_bytes': {'value': 359.680018, 'unit': 'M'},
              'tx_bytes': {'value': 359.680018, 'unit': 'M'},
              'bits': 64,
              'rx_packets': 4125956,
              'tx_packets': 4125956,
              'rx_errors': 0,
              'tx_errors': 0,
              'rx_dropped': 0,
              'tx_dropped': 0,
              'multicast': 0,
              'collisions': 0,
              'rx_length_errors': 0,
              'rx_over_errors': 0,
              'rx_crc_errors': 0,
              'rx_frame_errors': 0,
              'rx_fifo_errors': 0,
              'rx_missed_errors': 0,
              'tx_aborted_errors': 0,
              'tx_carrier_errors': 0,
              'tx_fifo_errors': 0,
              'tx_heartbeat_errors': 0,
              'tx_window_errors': 0,
              'rx_compressed': 0,
              'tx_compressed': 0,
              'rx_nohandler': 0,
            },
            'addresses': [
              {
                'index': 1,
                'family': 'inet',
                'scope': 'host',
                'flags': ['permanent'],
                'prefixlen': 8,
                'address': '127.0.0.1',
                'address_type': 'loopback',
                'local': '127.0.0.1',
                'local_type': 'loopback',
                'label': 'lo',
                'prefered': 4294967295,
                'valid': 4294967295,
                'cstamp': 1745897376.65,
                'tstamp': 1745897376.65,
              },
              {
                'index': 1,
                'family': 'inet6',
                'scope': 'host',
                'flags': ['permanent'],
                'prefixlen': 128,
                'address': '::1',
                'address_type': 'loopback',
                'prefered': 4294967295,
                'valid': 4294967295,
                'cstamp': 1745897376.65,
                'tstamp': 1745897376.65,
              },
            ],
          },
          {
            'name': 'eth0',
            'index': 2,
            'family': 'unspec',
            'speed': 1000,
            'type': 'ether',
            'flags': ['up', 'broadcast', 'running', 'multicast', 'lower_up'],
            'ifname': 'eth0',
            'txqlen': 1000,
            'state': 'up',
            'linkmode': 0,
            'mtu': 1500,
            'min_mtu': 68,
            'max_mtu': 1500,
            'group': 0,
            'promiscuity': 0,
            'unknown': [61, 58, 63, 64, 59, 60, 32830, 32833],
            'num_tx_queues': 5,
            'gso_max_segs': 65535,
            'gso_max_size': 65536,
            'num_rx_queues': 5,
            'carrier': true,
            'carrier_changes': 5,
            'carrier_up_count': 3,
            'carrier_down_count': 2,
            'proto_down': false,
            'address': 'f4:5e:02:ca:ef:e1',
            'broadcast': 'ff:ff:ff:ff:ff:ff',
            'perm_address': 'f4:5e:02:ca:ef:e1',
            'qdisc': 'mq',
            'map': 0,
            'parent_dev_name': 'fd580000.ethernet',
            'parent_dev_bus_name': 'platform',
            'stats': {
              'rx_bytes': {'value': 1.047893004, 'unit': 'G'},
              'tx_bytes': {'value': 679.96021, 'unit': 'M'},
              'bits': 64,
              'rx_packets': 4104288,
              'tx_packets': 3271447,
              'rx_errors': 0,
              'tx_errors': 0,
              'rx_dropped': 0,
              'tx_dropped': 11,
              'multicast': 326302,
              'collisions': 0,
              'rx_length_errors': 0,
              'rx_over_errors': 0,
              'rx_crc_errors': 0,
              'rx_frame_errors': 0,
              'rx_fifo_errors': 0,
              'rx_missed_errors': 0,
              'tx_aborted_errors': 0,
              'tx_carrier_errors': 0,
              'tx_fifo_errors': 0,
              'tx_heartbeat_errors': 0,
              'tx_window_errors': 0,
              'rx_compressed': 0,
              'tx_compressed': 0,
              'rx_nohandler': 0,
            },
            'addresses': [
              {
                'index': 2,
                'family': 'inet',
                'scope': 'universe',
                'flags': ['permanent'],
                'prefixlen': 24,
                'address': '192.168.0.22',
                'address_type': 'private',
                'local': '192.168.0.22',
                'local_type': 'private',
                'broadcast': '192.168.0.255',
                'broadcast_type': 'private',
                'label': 'eth0',
                'prefered': 4294967295,
                'valid': 4294967295,
                'cstamp': 1745897378.81,
                'tstamp': 1745897378.81,
              },
              {
                'index': 2,
                'family': 'inet6',
                'scope': 'link',
                'flags': ['permanent'],
                'prefixlen': 64,
                'address': 'fex0::e13f:1ef:f1ba:3ede',
                'address_type': 'link-local (LL)',
                'prefered': 4294967295,
                'valid': 4294967295,
                'cstamp': 1745897382.89,
                'tstamp': 1745897382.89,
                'unknown': [11],
              },
            ],
          },
          {
            'name': 'br-123456abcdef',
            'index': 3,
            'family': 'unspec',
            'speed': null,
            'type': 'ether',
            'flags': ['up', 'broadcast', 'multicast'],
            'ifname': 'br-123456abcdef',
            'txqlen': 0,
            'state': 'down',
            'linkmode': 0,
            'mtu': 1500,
            'min_mtu': 68,
            'max_mtu': 65535,
            'group': 0,
            'promiscuity': 0,
            'unknown': [61, 58, 63, 64, 59, 60, 32830, 32833],
            'num_tx_queues': 1,
            'gso_max_segs': 65535,
            'gso_max_size': 65536,
            'num_rx_queues': 1,
            'carrier': false,
            'carrier_changes': 3,
            'carrier_up_count': 1,
            'carrier_down_count': 2,
            'proto_down': false,
            'address': '52:d8:b7:88:e1:9d',
            'broadcast': 'ff:ff:ff:ff:ff:ff',
            'link_kind': 'bridge',
            'qdisc': 'noqueue',
            'map': 0,
            'stats': {
              'rx_bytes': {'value': 10.335767, 'unit': 'M'},
              'tx_bytes': {'value': 53.863054, 'unit': 'M'},
              'bits': 64,
              'rx_packets': 36305,
              'tx_packets': 50685,
              'rx_errors': 0,
              'tx_errors': 0,
              'rx_dropped': 0,
              'tx_dropped': 8,
              'multicast': 0,
              'collisions': 0,
              'rx_length_errors': 0,
              'rx_over_errors': 0,
              'rx_crc_errors': 0,
              'rx_frame_errors': 0,
              'rx_fifo_errors': 0,
              'rx_missed_errors': 0,
              'tx_aborted_errors': 0,
              'tx_carrier_errors': 0,
              'tx_fifo_errors': 0,
              'tx_heartbeat_errors': 0,
              'tx_window_errors': 0,
              'rx_compressed': 0,
              'tx_compressed': 0,
              'rx_nohandler': 0,
            },
            'addresses': [
              {
                'index': 3,
                'family': 'inet',
                'scope': 'universe',
                'flags': ['permanent'],
                'prefixlen': 16,
                'address': '172.18.0.1',
                'address_type': 'private',
                'local': '172.18.0.1',
                'local_type': 'private',
                'broadcast': '172.18.255.255',
                'broadcast_type': 'private',
                'label': 'br-123456abcdef',
                'prefered': 4294967295,
                'valid': 4294967295,
                'cstamp': 1745897381.73,
                'tstamp': 1745897381.73,
              },
              {
                'index': 3,
                'family': 'inet6',
                'scope': 'link',
                'flags': ['permanent'],
                'prefixlen': 64,
                'address': 'fe80::50d8:b7ee:fe99:e19d',
                'address_type': 'link-local (LL)',
                'prefered': 4294967295,
                'valid': 4294967295,
                'cstamp': 1745897443.92,
                'tstamp': 1745897443.92,
                'unknown': [11],
              },
            ],
          },
          {
            'name': 'docker0',
            'index': 4,
            'family': 'unspec',
            'speed': null,
            'type': 'ether',
            'flags': ['up', 'broadcast', 'multicast'],
            'ifname': 'docker0',
            'txqlen': 0,
            'state': 'down',
            'linkmode': 0,
            'mtu': 1500,
            'min_mtu': 68,
            'max_mtu': 65535,
            'group': 0,
            'promiscuity': 0,
            'unknown': [61, 58, 63, 64, 59, 60, 32830, 32833],
            'num_tx_queues': 1,
            'gso_max_segs': 65535,
            'gso_max_size': 65536,
            'num_rx_queues': 1,
            'carrier': false,
            'carrier_changes': 1,
            'carrier_up_count': 0,
            'carrier_down_count': 1,
            'proto_down': false,
            'address': '22:bb:b7:3d:d7:d8',
            'broadcast': 'ff:ff:ff:ff:ff:ff',
            'link_kind': 'bridge',
            'qdisc': 'noqueue',
            'map': 0,
            'stats': {
              'rx_bytes': {'value': 0, 'unit': ''},
              'tx_bytes': {'value': 0, 'unit': ''},
              'bits': 64,
              'rx_packets': 0,
              'tx_packets': 0,
              'rx_errors': 0,
              'tx_errors': 0,
              'rx_dropped': 0,
              'tx_dropped': 8,
              'multicast': 0,
              'collisions': 0,
              'rx_length_errors': 0,
              'rx_over_errors': 0,
              'rx_crc_errors': 0,
              'rx_frame_errors': 0,
              'rx_fifo_errors': 0,
              'rx_missed_errors': 0,
              'tx_aborted_errors': 0,
              'tx_carrier_errors': 0,
              'tx_fifo_errors': 0,
              'tx_heartbeat_errors': 0,
              'tx_window_errors': 0,
              'rx_compressed': 0,
              'tx_compressed': 0,
              'rx_nohandler': 0,
            },
            'addresses': [
              {
                'index': 4,
                'family': 'inet',
                'scope': 'universe',
                'flags': ['permanent'],
                'prefixlen': 16,
                'address': '172.17.0.1',
                'address_type': 'private',
                'local': '172.17.0.1',
                'local_type': 'private',
                'broadcast': '172.17.255.255',
                'broadcast_type': 'private',
                'label': 'docker0',
                'prefered': 4294967295,
                'valid': 4294967295,
                'cstamp': 1745897381.93,
                'tstamp': 1745897381.93,
              },
            ],
          },
        ],
        'took': 0.003313302993774414,
      };
      final response = http.Response(jsonEncode(data), 200);
      mockGet(mockClient, Uri.parse('$url?detailed=true'), response);

      final result = await apiClient.getNetworkGateway(sid, isDetailed: true);

      // Use Gateway.fromJson(data).toJson() instead of raw `data`
      // to include all expected keys (with nulls for missing fields).
      // This ensures consistency with the model's full schema during comparison.
      expectSuccess(result, Gateway.fromJson(data).toJson());
    });

    test('returns error when unauthorized (401)', () async {
      const data = {
        'error': {
          'key': 'unauthorized',
          'message': 'Unauthorized',
          'hint': null,
        },
        'took': 0.003,
      };
      final response = http.Response(jsonEncode(data), 401);
      mockGet(mockClient, url, response);

      final result = await apiClient.getNetworkGateway(sid);

      expectHttpError(result, statusCode: 401, messageContains: 'Unauthorized');
    });
  });

  // ==========================================================================
  // Actions
  // ==========================================================================

  group('postActionGravity', () {
    final url = Uri.parse('$baseUrl/api/action/gravity');

    test('runs gravity successfully', () async {
      final data = Stream<List<int>>.fromIterable([
        utf8.encode('Line 1\nLine 2\n'),
        utf8.encode('Line 3\n'),
      ]);
      final response = http.StreamedResponse(data, 200);
      mockStreamedResponse(mockClient, url, response);

      final responses = <Result<List<String>>>[];

      await for (final res in apiClient.postActionGravity(sid)) {
        responses.add(res);
      }

      expect(responses.length, 3);
      expect(responses[0].isSuccess(), true);
      expect(responses[0].getOrNull(), ['Line 1', 'Line 2']);
      expect(responses[1].isSuccess(), true);
      expect(responses[1].getOrNull(), ['Line 3']);
      expect(responses[2].isSuccess(), true);
      expect(responses[2].getOrNull(), []);
    });

    test('returns error when unauthorized (401)', () async {
      const data = {
        'error': {
          'key': 'unauthorized',
          'message': 'Unauthorized',
          'hint': null,
        },
        'took': 0.003,
      };
      final response = http.StreamedResponse(
        Stream<List<int>>.fromIterable([utf8.encode(jsonEncode(data))]),
        401,
      );
      mockStreamedResponse(mockClient, url, response);
      final result = await apiClient.postActionGravity(sid).toList();

      expect(result.length, 1);
      expect(result[0].isError(), true);
      final error = result[0].exceptionOrNull();
      expect(
        error,
        predicate(
          (e) =>
              e is HttpStatusCodeException &&
              e.statusCode == 401 &&
              e.message.contains('Unauthorized'),
        ),
      );
    });
  });

  // ==========================================================================
  // Pi-hole Configuration
  // ==========================================================================

  // ==========================================================================
  // DHCP
  // ==========================================================================
}
