class CnameRecord {
  const CnameRecord({required this.alias, required this.target, this.ttl});

  final String alias;
  final String target;
  final int? ttl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CnameRecord &&
          other.alias == alias &&
          other.target == target &&
          other.ttl == ttl;

  @override
  int get hashCode => Object.hash(alias, target, ttl);
}
