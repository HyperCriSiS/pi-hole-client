import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/domain/model/local_dns/local_dns.dart';
import 'package:pi_hole_client/routing/route_extra.dart';
import 'package:pi_hole_client/routing/routes.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/core/ui/behavior/custom_scroll_behavior.dart';
import 'package:pi_hole_client/ui/core/ui/components/empty_data_screen.dart';
import 'package:pi_hole_client/ui/core/ui/components/error_message.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/responsive.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/snackbar.dart';
import 'package:pi_hole_client/ui/core/ui/modals/process_modal.dart';
import 'package:pi_hole_client/ui/core/view_models/app_config_viewmodel.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/local_dns/view_models/local_dns_viewmodel.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/local_dns/widgets/add_local_dns_modal.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/local_dns/widgets/cname_editor_dialog.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/local_dns/widgets/cname_list_view.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/local_dns/widgets/local_dns_list_view.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _fakeLocalDnsInfo = [
  LocalDns(ip: '192.168.2.111', name: 'raspberrypi'),
  LocalDns(ip: '192.168.2.112', name: 'printer'),
  LocalDns(ip: '192.168.2.113', name: 'laptop'),
];

const _fakeCnameInfo = [
  CnameRecord(alias: 'printer.home.arpa', target: 'printer'),
  CnameRecord(alias: 'nas.home.arpa', target: 'server', ttl: 300),
];

enum _LocalDnsMode { hosts, cname }

class LocalDnsScreen extends StatefulWidget {
  const LocalDnsScreen({required this.viewModel, super.key});

  final LocalDnsViewModel viewModel;

  @override
  State<LocalDnsScreen> createState() => _LocalDnsScreenState();
}

class _LocalDnsScreenState extends State<LocalDnsScreen> {
  _LocalDnsMode _mode = _LocalDnsMode.hosts;

  Future<bool> _onAddLocalDns(Map<String, dynamic> value) async {
    final locale = AppLocalizations.of(context)!;
    final appConfigViewModel = context.read<AppConfigViewModel>();
    final process = ProcessModal(context: context)..open(locale.localDnsAdding);

    try {
      await widget.viewModel.addRecord.runAsync(
        LocalDns(ip: value['ip'], name: value['name']),
      );
      if (!mounted) return false;
      process.close();
      showSuccessSnackBar(
        context: context,
        appConfigViewModel: appConfigViewModel,
        label: locale.localDnsAddSuccess,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      process.close();
      showErrorSnackBar(
        context: context,
        appConfigViewModel: appConfigViewModel,
        label: locale.localDnsAddFailed,
      );
      return false;
    }
  }

  Future<bool> _onUpdateLocalDns(LocalDns updated, String oldIp) async {
    final locale = AppLocalizations.of(context)!;
    final appConfigViewModel = context.read<AppConfigViewModel>();
    final process = ProcessModal(context: context)..open(locale.updating);

    try {
      await widget.viewModel.updateRecord.runAsync((
        record: updated,
        oldIp: oldIp,
      ));
      if (!mounted) return false;
      process.close();
      showSuccessSnackBar(
        context: context,
        appConfigViewModel: appConfigViewModel,
        label: locale.localDnsUpdateSuccess,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      process.close();
      showErrorSnackBar(
        context: context,
        appConfigViewModel: appConfigViewModel,
        label: locale.localDnsUpdateFailed,
      );
      return false;
    }
  }

  Future<bool> _onRemoveLocalDns(LocalDns item) async {
    final locale = AppLocalizations.of(context)!;
    final appConfigViewModel = context.read<AppConfigViewModel>();
    final process = ProcessModal(context: context)..open(locale.deleting);

    try {
      await widget.viewModel.deleteRecord.runAsync(item);
      if (!mounted) return false;
      process.close();
      context.pop();
      if (!mounted) return true;
      showSuccessSnackBar(
        context: context,
        appConfigViewModel: appConfigViewModel,
        label: locale.localDnsDeleteSuccess,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      process.close();
      showErrorSnackBar(
        context: context,
        appConfigViewModel: appConfigViewModel,
        label: locale.localDnsDeleteFailed,
      );
      return false;
    }
  }

  Future<bool> _onAddCname(CnameRecord record) async {
    try {
      await widget.viewModel.addCnameRecord.runAsync(record);
      return true;
    } catch (_) {
      if (!mounted) return false;
      _showCnameError();
      return false;
    }
  }

  Future<bool> _onUpdateCname(
    CnameRecord oldRecord,
    CnameRecord record,
  ) async {
    try {
      await widget.viewModel.updateCnameRecord.runAsync((
        oldRecord: oldRecord,
        record: record,
      ));
      return true;
    } catch (_) {
      if (!mounted) return false;
      _showCnameError();
      return false;
    }
  }

  Future<bool> _onDeleteCname(CnameRecord record) async {
    try {
      await widget.viewModel.deleteCnameRecord.runAsync(record);
      return true;
    } catch (_) {
      if (!mounted) return false;
      _showCnameError();
      return false;
    }
  }

  void _showCnameError() {
    final locale = AppLocalizations.of(context)!;
    showErrorSnackBar(
      context: context,
      appConfigViewModel: context.read<AppConfigViewModel>(),
      label: '${locale.error}: CNAME',
    );
  }

  void _openAddModal() {
    if (_mode == _LocalDnsMode.cname) {
      _openCnameEditor();
      return;
    }

    final mediaQuery = MediaQuery.of(context);
    final isSmallLandscape =
        mediaQuery.size.width > mediaQuery.size.height &&
        mediaQuery.size.height < ResponsiveConstants.medium;
    final devices = widget.viewModel.data.deviceOptions;

    if (MediaQuery.of(context).size.width > ResponsiveConstants.medium) {
      showDialog(
        context: context,
        useSafeArea: !isSmallLandscape,
        useRootNavigator: false,
        builder: (ctx) => AddLocalDnsModal(
          addLocalDns: _onAddLocalDns,
          window: true,
          devices: devices,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => AddLocalDnsModal(
          addLocalDns: _onAddLocalDns,
          window: false,
          devices: devices,
        ),
        isScrollControlled: true,
      );
    }
  }

  void _openCnameEditor([CnameRecord? record]) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => CnameEditorDialog(
        record: record,
        onSave: (updated) => record == null
            ? _onAddCname(updated)
            : _onUpdateCname(record, updated),
        onDelete: record == null ? null : _onDeleteCname,
      ),
    );
  }

  Widget _buildModeSelector(AppLocalizations locale) {
    if (!widget.viewModel.supportsCname) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_LocalDnsMode>(
          segments: [
            ButtonSegment(
              value: _LocalDnsMode.hosts,
              label: Text(locale.host),
              icon: const Icon(Icons.dns_rounded),
            ),
            const ButtonSegment(
              value: _LocalDnsMode.cname,
              label: Text('CNAME'),
              icon: Icon(Icons.alt_route_rounded),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) {
            setState(() => _mode = selection.first);
          },
        ),
      ),
    );
  }

  Widget _buildRecords(LocalDnsData data) {
    final locale = AppLocalizations.of(context)!;

    if (_mode == _LocalDnsMode.cname && widget.viewModel.supportsCname) {
      if (data.cnameRecords.isEmpty) {
        return EmptyDataScreen(message: locale.noData);
      }
      return CnameListView(
        records: data.cnameRecords,
        onRecordTap: _openCnameEditor,
      );
    }

    if (data.records.isEmpty) {
      return EmptyDataScreen(message: locale.localDnsEmptyDescription);
    }

    return LocalDnsListView(
      localDnsInfo: data.records,
      onDeviceTap: (localDns) {
        context.pushNamed(
          Routes.settingsServerAdvancedLocalDnsDetails,
          extra: LocalDnsDetailsExtra(
            localDns: localDns,
            devices: data.deviceOptions,
            onDelete: (LocalDns ld) async => _onRemoveLocalDns(ld),
            onUpdate: _onUpdateLocalDns,
          ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    final records = _mode == _LocalDnsMode.cname
        ? CnameListView(records: _fakeCnameInfo, onRecordTap: (_) {})
        : LocalDnsListView(
            localDnsInfo: _fakeLocalDnsInfo,
            onDeviceTap: (_) {},
          );

    return Skeletonizer(
      effect: ShimmerEffect(
        baseColor: Theme.of(context).colorScheme.secondaryContainer,
        highlightColor: Theme.of(context).colorScheme.surface,
      ),
      child: records,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final viewModel = widget.viewModel;
        final isLoading = viewModel.loadRecords.isRunning.value;
        final hasError = viewModel.loadRecords.errors.value != null;
        final data = viewModel.data;

        return ScrollConfiguration(
          behavior: CustomScrollBehavior(),
          child: Scaffold(
            appBar: AppBar(
              title: Text(locale.localDns),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => viewModel.loadRecords.run(),
                    tooltip: locale.refresh,
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  try {
                    await viewModel.loadRecords.runAsync();
                  } catch (_) {
                    // Error handled by command.errors
                  }
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildModeSelector(locale),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              if (isLoading) return _buildSkeleton();
                              if (hasError) {
                                return ErrorMessage(
                                  message: locale.dataFetchFailed,
                                );
                              }
                              return _buildRecords(data);
                            },
                          ),
                        ),
                      ],
                    ),
                    Selector<AppConfigViewModel, bool>(
                      selector: (_, a) => a.showingSnackbar,
                      builder: (_, showingSnackbar, _) {
                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeInOut,
                          bottom: showingSnackbar ? 70 : 20,
                          right: 20,
                          child: FloatingActionButton(
                            onPressed: _openAddModal,
                            child: const Icon(Icons.add),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
