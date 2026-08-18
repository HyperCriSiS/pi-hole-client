/// Server-side filters supported by Pi-hole v6 `/api/queries`.
///
/// Pi-hole v5 intentionally keeps using client-side filtering. This value
/// object is v6-specific so filter transport can be added without leaking v6
/// API details into the shared log UI model.
class V6QueryFilter {
  const V6QueryFilter({
    this.domain,
    this.clientIp,
    this.status,
    this.type,
    this.reply,
  });

  /// Exact domain filter accepted by Pi-hole FTL.
  final String? domain;

  /// Exact client IP filter accepted by Pi-hole FTL as `client_ip`.
  final String? clientIp;

  /// Pi-hole v6 query status name, for example `GRAVITY` or `FORWARDED`.
  final String? status;

  /// DNS record type name, for example `A` or `AAAA`.
  final String? type;

  /// Pi-hole v6 reply type name.
  final String? reply;

  /// Returns only parameters that should be sent to `/api/queries`.
  ///
  /// Empty strings are deliberately omitted so clearing a UI filter restores
  /// the server default instead of sending an empty filter value.
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};

    void add(String key, String? value) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        params[key] = normalized;
      }
    }

    add('domain', domain);
    add('client_ip', clientIp);
    add('status', status);
    add('type', type);
    add('reply', reply);

    return params;
  }

  bool get isEmpty => toQueryParameters().isEmpty;
}
