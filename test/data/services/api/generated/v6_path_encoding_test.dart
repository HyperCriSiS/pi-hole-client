import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.requests);

  final List<RequestOptions> requests;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('generated v6 path encoding', () {
    late Dio dio;
    late List<RequestOptions> requests;

    setUp(() {
      requests = <RequestOptions>[];
      dio = Dio(BaseOptions(baseUrl: 'https://pi.hole/api'));
      dio.httpClientAdapter = _RecordingAdapter(requests);
    });

    tearDown(() {
      dio.close(force: true);
    });

    test('keeps a full adlist URL inside one generated path segment', () async {
      const address = 'https://example.com/lists/main.txt?source=a#fragment';

      await ListManagementApi(dio).deleteLists(list: address, type: 'block');

      expect(requests, hasLength(1));
      expect(
        requests.single.path,
        '/lists/https%3A%2F%2Fexample.com%2Flists%2Fmain.txt%3Fsource%3Da%23fragment',
      );
      expect(
        requests.single.uri.toString(),
        contains(
          '/lists/https%3A%2F%2Fexample.com%2Flists%2Fmain.txt%3Fsource%3Da%23fragment',
        ),
      );
    });

    test(
      'encodes config element and value as independent path segments',
      () async {
        await PiHoleConfigurationApi(dio).addArrayItem(
          element: 'dns/hosts',
          value: '192.0.2.10 host/name',
          restart: false,
        );

        expect(requests, hasLength(1));
        expect(
          requests.single.path,
          '/config/dns%2Fhosts/192.0.2.10%20host%2Fname',
        );
        expect(
          requests.single.uri.toString(),
          contains('/config/dns%2Fhosts/192.0.2.10%20host%2Fname'),
        );
      },
    );
  });
}
