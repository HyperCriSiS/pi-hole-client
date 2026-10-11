import 'package:flutter/material.dart';
import 'package:pi_hole_client/data/model/local/saved_log_filter_preset.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/formats.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/responsive.dart';
import 'package:pi_hole_client/ui/logs/view_models/logs_viewmodel.dart';
import 'package:pi_hole_client/ui/logs/widgets/clients_filters_modal.dart';
import 'package:pi_hole_client/ui/logs/widgets/status_filters_modal.dart';
import 'package:pi_hole_client/utils/format.dart';
import 'package:provider/provider.dart';

class LogsFiltersModal extends StatefulWidget {
  const LogsFiltersModal({
    required this.statusBarHeight,
    required this.bottomNavBarHeight,
    required this.filterLogs,
    required this.window,
    super.key,
  });

  final double statusBarHeight;
  final double bottomNavBarHeight;
  final void Function() filterLogs;
  final bool window;

  @override
  State<LogsFiltersModal> createState() => _LogsFiltersModalState();
}

class _LogsFiltersModalState extends State<LogsFiltersModal> {
  String? timeError;

  void _showPresetError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.error)),
    );
  }

  Future<void> _savePreset(LogsViewModel vm) async {
    final labels = AppLocalizations.of(context)!;
    String name = '';
    final chosen = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text(labels.saveFilter),
          content: TextField(
            autofocus: true,
            maxLength: 64,
            decoration: InputDecoration(labelText: labels.filterName),
            onChanged: (text) => update(() => name = text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(labels.cancel),
            ),
            TextButton(
              onPressed: name.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, name),
              child: Text(labels.save),
            ),
          ],
        ),
      ),
    );
    if (!mounted || chosen == null) return;
    try {
      await vm.saveCurrentFilterPreset(chosen);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(labels.saved)),
      );
    } catch (_) {
      _showPresetError();
    }
  }

  Future<void> _choosePreset(LogsViewModel vm) async {
    final labels = AppLocalizations.of(context)!;
    final ownerAddress = vm.selectedServerAddress;
    final ownerApi = vm.apiVersion;
    late List<SavedLogFilterPreset> presets;
    try {
      presets = await vm.loadFilterPresets();
    } catch (_) {
      _showPresetError();
      return;
    }
    if (!mounted) return;

    final chosen = await showDialog<SavedLogFilterPreset>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text(labels.savedFilters),
          content: SizedBox(
            width: 380,
            child: presets.isEmpty
                ? Text(labels.noSavedFilters)
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final preset in presets)
                            ListTile(
                              title: Text(preset.name),
                              onTap: () => Navigator.pop(dialogContext, preset),
                              trailing: IconButton(
                                tooltip: labels.delete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  try {
                                    await vm.deleteFilterPreset(preset.name);
                                    if (!dialogContext.mounted) return;
                                    update(() => presets.remove(preset));
                                  } catch (_) {
                                    _showPresetError();
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(labels.close),
            ),
          ],
        ),
      ),
    );
    if (!mounted || chosen == null) return;
    if (ownerAddress != vm.selectedServerAddress || ownerApi != vm.apiVersion) {
      _showPresetError();
      return;
    }
    try {
      await vm.applyFilterPreset(chosen);
      if (mounted) await Navigator.maybePop(context);
    } catch (_) {
      _showPresetError();
    }
  }


  @override
  Widget build(BuildContext context) {
    final logsViewModel = Provider.of<LogsViewModel>(context);

    final width = MediaQuery.of(context).size.width;

    void openStatusModal() {
      if (width > ResponsiveConstants.medium) {
        showDialog(
          context: context,
          useRootNavigator:
              false, // Prevents unexpected app exit on mobile when pressing back
          builder: (context) => StatusFiltersModal(
            statusBarHeight: widget.statusBarHeight,
            bottomNavBarHeight: widget.bottomNavBarHeight,
            statusSelected: logsViewModel.statusSelected,
            window: true,
          ),
        );
      } else {
        showModalBottomSheet(
          context: context,
          builder: (context) => StatusFiltersModal(
            statusBarHeight: widget.statusBarHeight,
            bottomNavBarHeight: widget.bottomNavBarHeight,
            statusSelected: logsViewModel.statusSelected,
            window: false,
          ),
          isScrollControlled: true,
        );
      }
    }

    void openClientsModal() {
      logsViewModel.refreshClients();
      if (width > ResponsiveConstants.medium) {
        showDialog(
          context: context,
          useRootNavigator:
              false, // Prevents unexpected app exit on mobile when pressing back
          builder: (context) => ClientsFiltersModal(
            statusBarHeight: widget.statusBarHeight,
            bottomNavBarHeight: widget.bottomNavBarHeight,
            selectedClients: logsViewModel.selectedClients,
            window: true,
          ),
        );
      } else {
        showModalBottomSheet(
          context: context,
          builder: (context) => ClientsFiltersModal(
            statusBarHeight: widget.statusBarHeight,
            bottomNavBarHeight: widget.bottomNavBarHeight,
            selectedClients: logsViewModel.selectedClients,
            window: false,
          ),
          isScrollControlled: true,
        );
      }
    }

    String statusText(items, maxItems) {
      if (items == 0) {
        return AppLocalizations.of(context)!.noItemsSelected;
      } else if (items == maxItems) {
        return AppLocalizations.of(context)!.allItemsSelected;
      } else {
        return '$items ${AppLocalizations.of(context)!.itemsSelected}';
      }
    }

    Future<void> selectTime(String time) async {
      final now = DateTime.now();
      final dateValue = await showDatePicker(
        context: context,
        useRootNavigator:
            false, // Prevents unexpected app exit on mobile when pressing back
        initialDate: now,
        firstDate: DateTime(now.year, now.month - 1, now.day),
        lastDate: now,
      );
      if (!context.mounted) return;

      if (dateValue != null) {
        final timeValue = await showTimePicker(
          context: context,
          useRootNavigator:
              false, // Prevents unexpected app exit on mobile when pressing back
          initialTime: TimeOfDay.now(),
          helpText: time == 'from'
              ? AppLocalizations.of(context)!.selectStartTime
              : AppLocalizations.of(context)!.selectEndTime,
        );
        if (timeValue != null) {
          final value = DateTime(
            dateValue.year,
            dateValue.month,
            dateValue.day,
            timeValue.hour,
            timeValue.minute,
            dateValue.second,
          );
          if (time == 'from') {
            if (logsViewModel.endTime != null &&
                value.isAfter(logsViewModel.endTime!)) {
              setState(() {
                timeError = AppLocalizations.of(
                  context,
                )!.startTimeNotBeforeEndTime;
              });
            } else {
              logsViewModel.setStartTime(value);
              setState(() {
                timeError = null;
              });
            }
          } else {
            if (logsViewModel.startTime != null &&
                value.isBefore(logsViewModel.startTime!)) {
              setState(() {
                timeError = AppLocalizations.of(
                  context,
                )!.endTimeNotAfterStartTime;
              });
            } else {
              logsViewModel.setEndTime(value);
              setState(() {
                timeError = null;
              });
            }
          }
        }
      }
    }

    bool isFilteringValid() {
      if (timeError == null && logsViewModel.statusSelected.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    }

    void resetFilters() {
      logsViewModel.resetFilters();
    }

    Widget content() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Icon(
                          Icons.filter_list,
                          size: 24,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          AppLocalizations.of(context)!.filters,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.time,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        child: InkWell(
                                          onTap: () => selectTime('from'),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          splashColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          highlightColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.fromTime,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  logsViewModel.startTime !=
                                                          null
                                                      ? formatTimestamp(
                                                          logsViewModel
                                                              .startTime!,
                                                          kUnifiedDateTimeFormat,
                                                        )
                                                      : AppLocalizations.of(
                                                          context,
                                                        )!.notSelected,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        '-',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        child: InkWell(
                                          onTap: () => selectTime('to'),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          splashColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          highlightColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.toTime,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  logsViewModel.endTime != null
                                                      ? formatTimestamp(
                                                          logsViewModel
                                                              .endTime!,
                                                          kUnifiedDateTimeFormat,
                                                        )
                                                      : AppLocalizations.of(
                                                          context,
                                                        )!.notSelected,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (timeError != null) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    timeError!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.status,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        width: double.maxFinite,
                        child: SegmentedButton<RequestStatus>(
                          segments: [
                            ButtonSegment(
                              value: RequestStatus.all,
                              label: Text(AppLocalizations.of(context)!.all),
                            ),
                            ButtonSegment(
                              value: RequestStatus.allowed,
                              label: Text(
                                AppLocalizations.of(context)!.allowed,
                              ),
                            ),
                            ButtonSegment(
                              value: RequestStatus.blocked,
                              label: Text(
                                AppLocalizations.of(context)!.blocked,
                              ),
                            ),
                          ],
                          selected: <RequestStatus>{
                            logsViewModel.requestStatus,
                          },
                          onSelectionChanged: (value) => setState(
                            () => logsViewModel.setRequestStatus(value.first),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: openStatusModal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.advancedStatusFiltering,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        statusText(
                                          logsViewModel.statusSelected.length,
                                          logsViewModel.defaultSelected.length,
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: openClientsModal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.clients,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        statusText(
                                          logsViewModel.selectedClients.length,
                                          logsViewModel.totalClients.length,
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: AppLocalizations.of(context)!.saveFilter,
                        onPressed: () => _savePreset(logsViewModel),
                        icon: const Icon(Icons.bookmark_add_outlined),
                      ),
                      IconButton(
                        tooltip: AppLocalizations.of(context)!.savedFilters,
                        onPressed: () => _choosePreset(logsViewModel),
                        icon: const Icon(Icons.bookmarks_outlined),
                      ),
                      TextButton(
                        onPressed: resetFilters,
                        child: Text(AppLocalizations.of(context)!.reset),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: Text(AppLocalizations.of(context)!.close),
                      ),
                      const SizedBox(width: 20),
                      TextButton(
                        onPressed: isFilteringValid() == true
                            ? () {
                                widget.filterLogs();
                                Navigator.maybePop(context);
                              }
                            : null,
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(
                            isFilteringValid() == true
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          overlayColor: WidgetStateProperty.all(
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.apply),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (widget.window == true) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: content(),
        ),
      );
    } else {
      return SafeArea(child: content());
    }
  }
}
