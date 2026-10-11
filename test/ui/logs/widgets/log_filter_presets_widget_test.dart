import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/data/model/local/saved_log_filter_preset.dart';
import 'package:pi_hole_client/data/repositories/local/saved_log_filters_repository.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/ui/core/view_models/app_config_viewmodel.dart';
import 'package:pi_hole_client/ui/logs/view_models/logs_viewmodel.dart';
import 'package:pi_hole_client/ui/logs/widgets/logs_filters_modal.dart';

import '../../../../testing/fakes/repositories/local/fake_app_config_repository.dart';
import '../../../../testing/test_app.dart';

class _PresetStore implements SavedLogFiltersRepository {
  SavedLogFilterPreset? item;

  @override
  Future<List<SavedLogFilterPreset>> list(String address, String api) async =>
      item == null ? [] : [item!];

  @override
  Future<void> save(String address, SavedLogFilterPreset value) async {
    item = value;
  }

  @override
  Future<void> delete(String address, String api, String name) async {
    item = null;
  }
}

void main() async {
  await initTestApp();

  testWidgets('filter dialog saves and restores a named filter', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = _PresetStore();
    final vm = LogsViewModel(savedLogFiltersRepository: store)
      ..update(apiVersion: 'v6', selectedServerAddress: 'http://pi.hole')
      ..setClients(['host-a', 'host-b'])
      ..setRequestStatus(RequestStatus.blocked)
      ..setSelectedDomain('example.com');
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      buildTestApp(
        const LogsFiltersModal(
          statusBarHeight: 24,
          bottomNavBarHeight: 48,
          filterLogs: _doNothing,
          window: true,
        ),
        logsViewModel: vm,
        appConfigViewModel: AppConfigViewModel(FakeAppConfigRepository()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save filter'));
    await tester.pumpAndSettle();
    expect(find.text('Filter name'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Blocked DNS');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(store.item?.name, 'Blocked DNS');

    vm.resetFilters();
    expect(vm.selectedDomain, isNull);
    await tester.tap(find.byTooltip('Saved filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blocked DNS'));
    await tester.pumpAndSettle();
    expect(vm.selectedDomain, 'example.com');
    expect(vm.requestStatus, RequestStatus.blocked);
  });

  testWidgets('saved filter picker deletes a preset', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = _PresetStore()
      ..item = const SavedLogFilterPreset(
        name: 'Delete me', apiVersion: 'v6',
        statusKeys: ['GRAVITY'], requestStatus: 'blocked',
        selectedClients: null,
      );
    final vm = LogsViewModel(savedLogFiltersRepository: store)
      ..update(apiVersion: 'v6', selectedServerAddress: 'http://pi.hole');
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      buildTestApp(
        const LogsFiltersModal(
          statusBarHeight: 24, bottomNavBarHeight: 48,
          filterLogs: _doNothing, window: true,
        ),
        logsViewModel: vm,
        appConfigViewModel: AppConfigViewModel(FakeAppConfigRepository()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Saved filters'));
    await tester.pumpAndSettle();
    expect(find.text('Delete me'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete').last);
    await tester.pumpAndSettle();
    expect(store.item, isNull);
    expect(find.text('Delete me'), findsNothing);
  });
}

void _doNothing() {}
