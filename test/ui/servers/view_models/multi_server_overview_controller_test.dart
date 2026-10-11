import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/server/server.dart';
import 'package:pi_hole_client/ui/servers/view_models/multi_server_overview_controller.dart';

const serverA = Server(address: 'http://server-a', alias: 'A', apiVersion: 'v5');
const serverB = Server(address: 'http://server-b', alias: 'B', apiVersion: 'v6');
const metrics = ServerOverviewMetrics(queries: 200, blocked: 50, blockedPercentage: 25);

void main() {
  test('opening and reading state never triggers a request', () {
    var calls = 0;
    final controller = MultiServerOverviewController(
      servers: const [serverA, serverB],
      reader: (_) async {
        calls++;
        return metrics;
      },
    );
    expect(calls, 0);
    expect(controller.entryFor(serverA).state, ServerOverviewLoadState.notRequested);
    expect(controller.entryFor(serverB).state, ServerOverviewLoadState.notRequested);
    controller.dispose();
  });

  test('manual refresh reads v5/v6 independently and isolates failures', () async {
    final calls = <String>[];
    final controller = MultiServerOverviewController(
      servers: const [serverA, serverB],
      reader: (server) async {
        calls.add(server.address);
        if (server == serverA) throw StateError('confidential authentication error');
        return metrics;
      },
    );
    await controller.refreshAll();
    expect(calls, [serverA.address, serverB.address]);
    expect(controller.entryFor(serverA).state, ServerOverviewLoadState.failed);
    expect(controller.entryFor(serverA).metrics, isNull);
    expect(controller.entryFor(serverB).state, ServerOverviewLoadState.loaded);
    expect(controller.entryFor(serverB).metrics?.blockedPercentage, 25);
    controller.dispose();
  });

  test('overlapping button presses cannot trigger duplicate reads', () async {
    final gate = Completer<ServerOverviewMetrics>();
    var calls = 0;
    final controller = MultiServerOverviewController(
      servers: const [serverA],
      reader: (_) {
        calls++;
        return gate.future;
      },
    );
    final first = controller.refreshAll();
    expect(controller.busy, isTrue);
    await controller.refreshAll();
    await controller.refreshOne(serverA);
    expect(calls, 1);
    gate.complete(metrics);
    await first;
    expect(controller.busy, isFalse);
    expect(controller.entryFor(serverA).state, ServerOverviewLoadState.loaded);
    controller.dispose();
  });

  test('closing during an in-flight batch prevents further server queries', () async {
    final gate = Completer<ServerOverviewMetrics>();
    final calls = <String>[];
    final controller = MultiServerOverviewController(
      servers: const [serverA, serverB],
      reader: (server) {
        calls.add(server.address);
        return gate.future;
      },
    );
    final pending = controller.refreshAll();
    expect(calls, [serverA.address]);
    controller.dispose();
    gate.complete(metrics);
    await pending;
    expect(calls, [serverA.address]);
  });

  test('manual per-server refresh does not query other servers', () async {
    final calls = <String>[];
    final controller = MultiServerOverviewController(
      servers: const [serverA, serverB],
      reader: (server) async {
        calls.add(server.address);
        return metrics;
      },
    );
    await controller.refreshOne(serverB);
    expect(calls, [serverB.address]);
    expect(controller.entryFor(serverA).state, ServerOverviewLoadState.notRequested);
    expect(controller.entryFor(serverB).state, ServerOverviewLoadState.loaded);
    controller.dispose();
  });
}
