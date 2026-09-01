import 'package:flutter/material.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';

class CnameEditorDialog extends StatefulWidget {
  const CnameEditorDialog({
    required this.onSave,
    this.record,
    this.onDelete,
    super.key,
  });

  final CnameRecord? record;
  final Future<bool> Function(CnameRecord record) onSave;
  final Future<bool> Function(CnameRecord record)? onDelete;

  @override
  State<CnameEditorDialog> createState() => _CnameEditorDialogState();
}

class _CnameEditorDialogState extends State<CnameEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _aliasController;
  late final TextEditingController _targetController;
  late final TextEditingController _ttlController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(text: widget.record?.alias ?? '');
    _targetController = TextEditingController(text: widget.record?.target ?? '');
    _ttlController = TextEditingController(
      text: widget.record?.ttl?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _targetController.dispose();
    _ttlController.dispose();
    super.dispose();
  }

  String? _validateHost(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.contains(',') || trimmed.contains(' ')) {
      return AppLocalizations.of(context)!.invalidHostname;
    }
    return null;
  }

  String? _validateTtl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final ttl = int.tryParse(trimmed);
    if (ttl == null || ttl <= 0) {
      return AppLocalizations.of(context)!.invalid;
    }
    return null;
  }

  CnameRecord _buildRecord() {
    final ttlText = _ttlController.text.trim();
    return CnameRecord(
      alias: _aliasController.text.trim(),
      target: _targetController.text.trim(),
      ttl: ttlText.isEmpty ? null : int.parse(ttlText),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final success = await widget.onSave(_buildRecord());
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final record = widget.record;
    final onDelete = widget.onDelete;
    if (record == null || onDelete == null) return;

    final locale = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${locale.delete} CNAME?'),
        content: Text('${record.alias} → ${record.target}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(locale.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(locale.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    final success = await onDelete(record);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final editing = widget.record != null;

    return AlertDialog(
      title: Text('${editing ? locale.edit : locale.add} CNAME'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _aliasController,
                enabled: !_submitting,
                decoration: InputDecoration(labelText: locale.alias),
                validator: _validateHost,
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                enabled: !_submitting,
                decoration: InputDecoration(labelText: locale.host),
                validator: _validateHost,
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ttlController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'TTL'),
                validator: _validateTtl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (editing && widget.onDelete != null)
          TextButton(
            onPressed: _submitting ? null : _delete,
            child: Text(locale.delete),
          ),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(locale.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _save,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(locale.save),
        ),
      ],
    );
  }
}
