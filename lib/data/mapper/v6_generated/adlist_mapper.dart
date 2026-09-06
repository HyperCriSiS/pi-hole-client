import 'package:pi_hole_client/domain/model/enum_converters.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/list/adlist.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

/// Maps [Get4ListsInner] (OpenAPI-generated) to [Adlist] (domain model).
extension Get4ListsInnerMapper on Get4ListsInner {
  Adlist toDomain() {
    return Adlist(
      id: id ?? 0,
      address: address ?? '',
      type: type.toListType(),
      groups: groups ?? [0],
      enabled: enabled ?? true,
      dateAdded: DateTime.fromMillisecondsSinceEpoch((dateAdded ?? 0) * 1000),
      dateModified: DateTime.fromMillisecondsSinceEpoch(
        (dateModified ?? 0) * 1000,
      ),
      dateUpdated: DateTime.fromMillisecondsSinceEpoch(
        (dateUpdated ?? 0) * 1000,
      ),
      number: number ?? 0,
      invalidDomains: invalidDomains ?? 0,
      abpEntries: abpEntries ?? 0,
      status: (status ?? 0).toListsStatus(),
      comment: comment,
    );
  }
}

/// Maps [GetLists200Response] (OpenAPI-generated) to domain model list.
extension GetLists200ResponseMapper on GetLists200Response {
  List<Adlist> toDomainList() {
    return (lists ?? []).map((l) => l.toDomain()).toList();
  }
}

/// Converts [Get4ListsInnerTypeEnum] to [ListType].
extension Get4ListsInnerTypeEnumMapper on Get4ListsInnerTypeEnum? {
  ListType toListType() {
    return switch (this) {
      Get4ListsInnerTypeEnum.allow => ListType.allow,
      Get4ListsInnerTypeEnum.block => ListType.block,
      null => ListType.unknown,
    };
  }
}
