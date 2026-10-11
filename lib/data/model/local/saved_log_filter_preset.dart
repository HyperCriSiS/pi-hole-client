import 'dart:convert';

/// A named, locally persisted query-log filter belonging to one API version.
///
/// Server ownership is enforced by the repository's address-scoped queries.
/// No SID, password, session token, or log entry is serialized.
class SavedLogFilterPreset {
  const SavedLogFilterPreset({
    required this.name,
    required this.apiVersion,
    required this.statusKeys,
    required this.requestStatus,
    required this.selectedClients,
    this.domain,
    this.startTime,
    this.endTime,
  });

  final String name;
  final String apiVersion;
  final List<String> statusKeys;
  final String requestStatus;

  /// Null means "all clients"; an explicit list means a narrowed selection.
  final List<String>? selectedClients;
  final String? domain;
  final DateTime? startTime;
  final DateTime? endTime;

  String encode() => jsonEncode({
    'version': 1,
    'statusKeys': statusKeys,
    'requestStatus': requestStatus,
    'selectedClients': selectedClients,
    'domain': domain,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
  });

  factory SavedLogFilterPreset.decode({
    required String name,
    required String apiVersion,
    required String json,
  }) {
    final data = jsonDecode(json);
    if (data is! Map<String, dynamic> || data['version'] != 1) {
      throw const FormatException('Unsupported saved log filter format');
    }
    final statuses = data['statusKeys'];
    final clients = data['selectedClients'];
    if (statuses is! List || statuses.any((e) => e is! String) ||
        (clients != null &&
            (clients is! List || clients.any((e) => e is! String))) ||
        data['requestStatus'] is! String ||
        (data['domain'] != null && data['domain'] is! String)) {
      throw const FormatException('Invalid saved log filter');
    }
    DateTime? date(dynamic value) {
      if (value == null) return null;
      if (value is! String) {
        throw const FormatException('Invalid saved log filter date');
      }
      return DateTime.parse(value);
    }

    return SavedLogFilterPreset(
      name: name,
      apiVersion: apiVersion,
      statusKeys: List<String>.from(statuses),
      requestStatus: data['requestStatus'] as String,
      selectedClients: clients == null ? null : List<String>.from(clients as List),
      domain: data['domain'] as String?,
      startTime: date(data['startTime']),
      endTime: date(data['endTime']),
    );
  }
}
