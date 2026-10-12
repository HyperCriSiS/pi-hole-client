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
        if (server == serverA) {
          throw StateError('confidential authentication error');
        }
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

  test('timestamps are per-server and remain tied to successful snapshots', () async {
    var failA = true;
    var failB = false;
    var successfulReads = 0;
    final controller = MultiServerOverviewController(
      servers: const [serverA, serverB],
      reader: (server) async {
        if ((server == serverA && failA) || (server == serverB && failB)) {
          throw StateError('authentication token must not appear in the UI');
        }
        return metrics;
      },
      now: () => DateTime.utc(2026, 10, 12, 10, successfulReads++),
    );
    addTearDown(controller.dispose);

    expect(controller.entryFor(serverA).updatedAt, isNull);
    expect(controller.entryFor(serverB).updatedAt, isNull);
    await controller.refreshAll();
    expect(controller.entryFor(serverA).updatedAt, isNull);
    expect(
      controller.entryFor(serverB).updatedAt,
      DateTime.utc(2026, 10, 12, 10),
    );

    failA = false;
    await controller.refreshOne(serverA);
    expect(
      controller.entryFor(serverA).updatedAt,
      DateTime.utc(2026, 10, 12, 10, 1),
    );
    // A refresh of another server does not change this successful snapshot.
    expect(
      controller.entryFor(serverB).updatedAt,
      DateTime.utc(2026, 10, 12, 10),
    );

    failB = true;
    await controller.refreshOne(serverB);
    expect(controller.entryFor(serverB).state, ServerOverviewLoadState.failed);
    expect(
      controller.entryFor(serverB).updatedAt,
      DateTime.utc(2026, 10, 12, 10),
    );
    expect(controller.entryFor(serverB).metrics, same(metrics));
    expect(
      controller.entryFor(serverA).updatedAt,
      DateTime.utc(2026, 10, 12, 10, 1),
    );
  });


  test('manual refresh retains real cache during pending, failure and recovery', () async {
    final gate = Completer<ServerOverviewMetrics>();
    const replacement = ServerOverviewMetrics(
      queries: 300, blocked: 60, blockedPercentage: 20,
    );
    var reads = 0;
    var clock = 0;
    final controller = MultiServerOverviewController(
      servers: const [serverA, serverB],
      reader: (_) {
        reads++;
        if (reads == 1) return Future.value(metrics);
        if (reads == 2) return gate.future;
        return Future.value(replacement);
      },
      now: () => DateTime.utc(2026, 10, 12, 12, clock++),
    );
    addTearDown(controller.dispose);

    await controller.refreshOne(serverA);
    final captured = controller.entryFor(serverA).updatedAt;
    expect(captured, DateTime.utc(2026, 10, 12, 12));
    expect(controller.entryFor(serverA).metrics, same(metrics));

    final pending = controller.refreshOne(serverA);
    expect(controller.busy, isTrue);
    expect(controller.entryFor(serverA).state, ServerOverviewLoadState.loading);
    expect(controller.entryFor(serverA).metrics, same(metrics));
    expect(controller.entryFor(serverA).updatedAt, captured);
    expect(controller.entryFor(serverB).state, ServerOverviewLoadState.notRequested);

    gate.completeError(StateError('private session diagnostic'));
    await pending;
    expect(controller.busy, isFalse);
    expect(controller.entryFor(serverA).state, ServerOverviewLoadState.failed);
    expect(controller.entryFor(serverA).metrics, same(metrics));
    expect(controller.entryFor(serverA).updatedAt, captured);

    await controller.refreshOne(serverA);
    expect(controller.entryFor(serverA).state, ServerOverviewLoadState.loaded);
    expect(controller.entryFor(serverA).metrics, same(replacement));
    expect(
      controller.entryFor(serverA).updatedAt,
      DateTime.utc(2026, 10, 12, 12, 1),
    );
    expect(controller.entryFor(serverB).state, ServerOverviewLoadState.notRequested);
    expect(reads, 3);
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