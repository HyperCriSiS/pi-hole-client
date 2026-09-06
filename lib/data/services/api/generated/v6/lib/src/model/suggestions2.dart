//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/suggestions2_clients_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggestions2.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Suggestions2 {
  /// Returns a new [Suggestions2] instance.
  Suggestions2({this.clients});

  @JsonKey(name: r'clients', required: false, includeIfNull: false)
  final List<Suggestions2ClientsInner>? clients;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestions2 && other.clients == clients;

  @override
  int get hashCode => clients.hashCode;

  factory Suggestions2.fromJson(Map<String, dynamic> json) =>
      _$Suggestions2FromJson(json);

  Map<String, dynamic> toJson() => _$Suggestions2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
