import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/utils/url.dart';

void main() {
  group('buildServerUrl', () {
    test('builds a bare scheme://host when port and subroute are empty', () {
      expect(buildServerUrl(scheme: 'http', host: 'pi.hole'), 'http://pi.hole');
    });

    test('includes the port with a colon when provided', () {
      expect(
        buildServerUrl(scheme: 'http', host: 'pi.hole', port: '8080'),
        'http://pi.hole:8080',
      );
    });

    test('omits the colon entirely for an empty port', () {
      expect(
        buildServerUrl(scheme: 'https', host: 'pi.hole', port: ''),
        'https://pi.hole',
      );
    });

    test('appends the subroute as-is', () {
      expect(
        buildServerUrl(scheme: 'https', host: 'pi.hole', subroute: '/admin'),
        'https://pi.hole/admin',
      );
    });

    test('combines scheme, host, port and subroute', () {
      expect(
        buildServerUrl(
          scheme: 'https',
          host: 'pi.hole',
          port: '443',
          subroute: '/api/v1',
        ),
        'https://pi.hole:443/api/v1',
      );
    });
  });

  group('isSameEndpoint', () {
    test('returns true for identical URLs', () {
      expect(isSameEndpoint('https://pi.hole', 'https://pi.hole'), isTrue);
    });

    test('ignores host case differences', () {
      expect(isSameEndpoint('https://Pi.Hole', 'https://pi.hole'), isTrue);
    });

    test('ignores scheme case differences', () {
      expect(isSameEndpoint('HTTPS://pi.hole', 'https://pi.hole'), isTrue);
    });

    test('ignores a trailing slash', () {
      expect(isSameEndpoint('https://pi.hole/', 'https://pi.hole'), isTrue);
    });

    test('treats a bare slash and empty path as equal', () {
      expect(isSameEndpoint('https://pi.hole/', 'https://pi.hole'), isTrue);
    });

    test('keeps subroute path case-sensitive', () {
      expect(
        isSameEndpoint('https://pi.hole/API', 'https://pi.hole/api'),
        isFalse,
      );
    });

    test('matches subroutes that only differ by a trailing slash', () {
      expect(
        isSameEndpoint('https://pi.hole/api/v1/', 'https://pi.hole/api/v1'),
        isTrue,
      );
    });

    test('distinguishes different schemes', () {
      expect(isSameEndpoint('http://pi.hole', 'https://pi.hole'), isFalse);
    });

    test('distinguishes different hosts', () {
      expect(isSameEndpoint('https://pi.hole', 'https://example.com'), isFalse);
    });

    test('distinguishes different ports', () {
      expect(
        isSameEndpoint('https://pi.hole:8080', 'https://pi.hole:9090'),
        isFalse,
      );
    });

    test('treats the default https port as equal to an omitted port', () {
      expect(isSameEndpoint('https://pi.hole', 'https://pi.hole:443'), isTrue);
    });

    test('treats the default http port as equal to an omitted port', () {
      expect(isSameEndpoint('http://pi.hole', 'http://pi.hole:80'), isTrue);
    });

    test('normalises the default port alongside a subroute', () {
      expect(
        isSameEndpoint('https://pi.hole/admin', 'https://pi.hole:443/admin'),
        isTrue,
      );
    });

    test('does not equate an explicit non-default port with the default', () {
      expect(
        isSameEndpoint('https://pi.hole', 'https://pi.hole:8080'),
        isFalse,
      );
    });

    test('does not equate a default port across different schemes', () {
      // http default (80) and https default (443) must stay distinct.
      expect(
        isSameEndpoint('http://pi.hole:80', 'https://pi.hole:443'),
        isFalse,
      );
    });

    test('distinguishes different subroutes', () {
      expect(
        isSameEndpoint('https://pi.hole/api', 'https://pi.hole/admin'),
        isFalse,
      );
    });

    test('falls back to string equality when a URL is unparseable', () {
      expect(isSameEndpoint('::: not a url', '::: not a url'), isTrue);
      expect(isSameEndpoint('::: not a url', 'https://pi.hole'), isFalse);
    });
  });

  group('resolveServerUri', () {
    test('keeps root-server behavior unchanged', () {
      expect(
        resolveServerUri('https://pi.hole', '/api/auth').toString(),
        'https://pi.hole/api/auth',
      );
    });

    test('preserves a configured server subroute', () {
      expect(
        resolveServerUri('https://pi.hole/pihole', '/api/auth').toString(),
        'https://pi.hole/pihole/api/auth',
      );
    });

    test('deduplicates overlapping boundary segments', () {
      expect(
        resolveServerUri('https://pi.hole/pihole/api', '/api/auth').toString(),
        'https://pi.hole/pihole/api/auth',
      );
    });

    test('preserves endpoint query parameters', () {
      expect(
        resolveServerUri(
          'https://pi.hole/pihole',
          '/api/queries?limit=10',
        ).toString(),
        'https://pi.hole/pihole/api/queries?limit=10',
      );
    });
  });

  group('buildWebPanelUrl', () {
    test('adds admin below a custom subroute', () {
      expect(
        buildWebPanelUrl('https://pi.hole/pihole'),
        'https://pi.hole/pihole/admin/',
      );
    });

    test('does not duplicate an existing admin path', () {
      expect(
        buildWebPanelUrl('https://pi.hole/admin'),
        'https://pi.hole/admin/',
      );
    });

    test('uses reported webhome independently from the API subroute', () {
      expect(
        buildWebPanelUrl(
          'https://pi.hole/api-proxy',
          webHome: '/admin2/',
        ),
        'https://pi.hole/admin2/',
      );
    });

    test('prepends the reported reverse-proxy prefix to webhome', () {
      expect(
        buildWebPanelUrl(
          'https://pi.hole/api-proxy',
          prefix: '/pihole',
          webHome: '/admin2/',
        ),
        'https://pi.hole/pihole/admin2/',
      );
    });

    test('supports a root webhome below a reported prefix', () {
      expect(
        buildWebPanelUrl(
          'https://pi.hole/api-proxy',
          prefix: '/pihole',
          webHome: '/',
        ),
        'https://pi.hole/pihole/',
      );
    });
  });
}
