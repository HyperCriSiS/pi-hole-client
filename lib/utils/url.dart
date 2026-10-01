/// Builds a server URL from its component parts.
String buildServerUrl({
  required String scheme,
  required String host,
  String port = '',
  String subroute = '',
}) {
  final portSegment = port != '' ? ':$port' : '';
  return '$scheme://$host$portSegment$subroute';
}

/// Resolves [endpoint] below [serverUrl] without discarding an existing
/// server subroute.
///
/// Unlike [Uri.resolve], a leading slash in [endpoint] does not reset the
/// configured base path. Matching path segments at the base/endpoint boundary
/// are de-duplicated, so e.g. `/admin` + `/admin/` stays `/admin/`.
Uri resolveServerUri(String serverUrl, String endpoint) {
  final base = Uri.parse(serverUrl);
  final target = Uri.parse(endpoint);

  final baseSegments = base.pathSegments.where((s) => s.isNotEmpty).toList();
  final targetSegments = target.pathSegments
      .where((s) => s.isNotEmpty)
      .toList();

  var overlap = 0;
  final maxOverlap = baseSegments.length < targetSegments.length
      ? baseSegments.length
      : targetSegments.length;
  for (var size = maxOverlap; size > 0; size--) {
    final baseStart = baseSegments.length - size;
    var matches = true;
    for (var i = 0; i < size; i++) {
      if (baseSegments[baseStart + i] != targetSegments[i]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      overlap = size;
      break;
    }
  }

  final combinedSegments = <String>[
    ...baseSegments,
    ...targetSegments.skip(overlap),
  ];
  if (target.path.endsWith('/') && combinedSegments.isNotEmpty) {
    combinedSegments.add('');
  }

  return base.replace(
    pathSegments: combinedSegments,
    query: target.hasQuery ? target.query : null,
    fragment: target.hasFragment ? target.fragment : null,
  );
}

/// Builds the Pi-hole web-panel URL.
///
/// With a reported [webHome], the web UI is resolved independently from the
/// API subroute stored in [serverUrl]. Pi-hole's [prefix] is the external
/// reverse-proxy prefix and is prepended to [webHome].
///
/// Without that capability, the legacy behavior is preserved by resolving
/// `/admin/` below the configured server address.
String buildWebPanelUrl(
  String serverUrl, {
  String? prefix,
  String? webHome,
}) {
  final normalizedHome = webHome?.trim();
  if (normalizedHome == null || normalizedHome.isEmpty) {
    return resolveServerUri(serverUrl, '/admin/').toString();
  }

  final base = Uri.parse(serverUrl);
  final origin = base.replace(path: '', query: null, fragment: null);
  final webPath = _joinWebPanelPath(prefix, normalizedHome);
  return resolveServerUri(origin.toString(), webPath).toString();
}

String _joinWebPanelPath(String? prefix, String webHome) {
  final prefixSegments = (prefix?.trim() ?? '')
      .split('/')
      .where((segment) => segment.isNotEmpty);
  final homeSegments = webHome.split('/').where(
    (segment) => segment.isNotEmpty,
  );
  final segments = [...prefixSegments, ...homeSegments];

  var path = segments.isEmpty ? '/' : '/${segments.join('/')}';
  if (webHome.endsWith('/') && path != '/') path += '/';
  return path;
}

/// Compares two server URLs ignoring scheme/host case, a trailing slash and a
/// scheme's default port.
///
/// Re-deriving the URL from the form fields lower-cases the host (via
/// [Uri.parse]), so a plain string compare against the stored address would
/// report a false "address changed" for an alias-only edit and wrongly take the
/// destructive replace path. This normalises both sides.
bool isSameEndpoint(String a, String b) {
  String normalize(String url) {
    final uri = Uri.parse(url);
    var path = uri.path == '/' ? '' : uri.path;
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    // [Uri.port] resolves the scheme's default (80/443), so an explicit default
    // port and an omitted one normalise to the same endpoint.
    // (e.g. https://pi.hole == https://pi.hole:443).
    final port = uri.port != 0 ? ':${uri.port}' : '';
    return '${uri.scheme.toLowerCase()}://${uri.host.toLowerCase()}$port$path';
  }

  try {
    return normalize(a) == normalize(b);
  } catch (_) {
    return a == b;
  }
}
