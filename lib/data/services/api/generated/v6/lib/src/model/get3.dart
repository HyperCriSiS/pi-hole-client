//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:pihole_v6_api/src/model/get3_clients_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get3.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Get3 {
  /// Returns a new [Get3] instance.
  Get3({this.clients});

  /// Array of clients
  @JsonKey(name: r'clients', required: false, includeIfNull: false)
  final List<Get3ClientsInner>? clients;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Get3 && other.clients == clients;

  @override
  int get hashCode => clients.hashCode;

  factory Get3.fromJson(Map<String, dynamic> json) => _$Get3FromJson(json);

  Map<String, dynamic> toJson() => _$Get3ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
