import 'package:flutter/material.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/ui/core/themes/theme.dart';

class CnameListView extends StatelessWidget {
  const CnameListView({
    required this.records,
    required this.onRecordTap,
    super.key,
  });

  final List<CnameRecord> records;
  final void Function(CnameRecord record) onRecordTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppColors>()!;

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final ttl = record.ttl;
        return ListTile(
          leading: Icon(
            Icons.alt_route_rounded,
            color: theme.queryGreen ?? Colors.green,
          ),
          title: Text(record.alias),
          subtitle: Text(
            ttl == null ? record.target : '${record.target}  •  TTL $ttl',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onRecordTap(record),
        );
      },
    );
  }
}
