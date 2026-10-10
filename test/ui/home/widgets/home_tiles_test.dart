import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/ui/home/widgets/home_tiles.dart';
import 'package:pi_hole_client/utils/conversions.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../testing/fakes/viewmodels/fake_status_viewmodel.dart';
import '../../../../testing/models/v5/realtime_status.dart' as fixture;
import '../../../../testing/test_app.dart';

// Skeletonizer is an abstract factory widget; the mounted widget is a
// concrete subtype, so an exact-type finder does not match it.
bool _skeletonEnabled(WidgetTester tester) {
  final matches = find.byWidgetPredicate((widget) => widget is Skeletonizer);
  return tester.widget<Skeletonizer>(matches).enabled;
}

void main() async {
  await initTestApp();

  group('HomeTiles status metrics', () {
    late FakeStatusViewModel statusViewModel;

    setUp(() {
      statusViewModel = FakeStatusViewModel();
    });

    testWidgets('loaded without realtime data never displays example metrics', (
      tester,
    ) async {
      // Overtime data can resolve first and mark the view loaded even if
      // fetching realtime status failed.
      statusViewModel
        ..realtimeStatus = null
        ..statusLoading = LoadStatus.loaded;

      await tester.pumpWidget(
        buildTestApp(
          const HomeTiles(width: 1080),
          statusViewModel: statusViewModel,
        ),
      );

      expect(find.text('—'), findsNWidgets(4));
      expect(_skeletonEnabled(tester), isFalse);
      expect(find.text('12345'), findsNothing);
      expect(find.text('1234'), findsNothing);
      expect(find.text('12.34%'), findsNothing);
      expect(find.text('123456'), findsNothing);
    });

    testWidgets('initial loading uses skeleton placeholders', (tester) async {
      statusViewModel
        ..realtimeStatus = null
        ..statusLoading = LoadStatus.loading;

      await tester.pumpWidget(
        buildTestApp(
          const HomeTiles(width: 1080),
          statusViewModel: statusViewModel,
        ),
      );

      expect(_skeletonEnabled(tester), isTrue);
    });

    testWidgets('refresh retains real cached metrics without skeleton', (
      tester,
    ) async {
      final cached = fixture.kRepoFetchRealTimeStatus;
      statusViewModel
        ..realtimeStatus = cached
        ..statusLoading = LoadStatus.loading;

      await tester.pumpWidget(
        buildTestApp(
          const HomeTiles(width: 1080),
          statusViewModel: statusViewModel,
        ),
      );

      expect(_skeletonEnabled(tester), isFalse);
      expect(find.text('—'), findsNothing);
      expect(
        find.text(intFormat(cached.summary.dnsQueriesToday, Platform.localeName)),
        findsOneWidget,
      );

      // A refresh that finishes without changing data must keep the value.
      statusViewModel.statusLoading = LoadStatus.loaded;
      await tester.pump();
      expect(_skeletonEnabled(tester), isFalse);
      expect(
        find.text(intFormat(cached.summary.dnsQueriesToday, Platform.localeName)),
        findsOneWidget,
      );
    });

    testWidgets('first-load failure retains the existing error indication', (
      tester,
    ) async {
      statusViewModel
        ..realtimeStatus = null
        ..statusLoading = LoadStatus.error;

      await tester.pumpWidget(
        buildTestApp(
          const HomeTiles(width: 1080),
          statusViewModel: statusViewModel,
        ),
      );

      expect(find.text('—'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(4));
      expect(_skeletonEnabled(tester), isFalse);
    });
  });
}
