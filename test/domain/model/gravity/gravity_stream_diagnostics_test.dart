import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/domain/model/gravity/gravity_stream_diagnostics.dart';
import 'package:pi_hole_client/utils/exceptions.dart';

void main() {
  group('gravity stream proxy hint', () {
    test('suggests possible buffering only for no-progress timeout', () {
      expect(
        diagnoseGravityStreamFailure(
          TimeoutException('timeout'),
          hasProgress: false,
        ),
        GravityStreamHint.possibleProxyBuffering,
      );
      expect(
        diagnoseGravityStreamFailure(
          HttpStatusCodeException(504, 'timeout'),
          hasProgress: false,
        ),
        GravityStreamHint.possibleProxyBuffering,
      );
    });

    test('suppresses hint after output or for unrelated errors', () {
      for (final error in <Object>[
        TimeoutException('timeout'),
        HttpStatusCodeException(504, 'timeout'),
      ]) {
        expect(
          diagnoseGravityStreamFailure(error, hasProgress: true),
          isNull,
        );
      }
      for (final error in <Object>[
        HttpStatusCodeException(401, 'expired session'),
        HttpStatusCodeException(495, 'certificate'),
        HttpStatusCodeException(500, 'server error'),
        HttpStatusCodeException(503, 'network unavailable'),
        Exception('generic failure'),
      ]) {
        expect(
          diagnoseGravityStreamFailure(error, hasProgress: false),
          isNull,
        );
      }
    });
  });
}
