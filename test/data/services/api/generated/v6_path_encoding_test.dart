import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

class _RecordingInterceptor extends Interceptor {
  final List<String> paths = <String>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    paths.add(options.path);
    handler.resolve(
      Response<void>(
        requestOptions: options,
        statusCode: 204,
      ),
    );
  }
}

void main() {
  group('generated v6 path encoding', () {
    late Dio dio;
    late _RecordingInterceptor recorder;

    setUp(() {
      dio = Dio();
      recorder = _RecordingInterceptor();
      dio.interceptors.add(recorder);
    });

    tearDown(() {
      dio.close(force: true);
    });

    test('keeps a full adlist URL inside one generated path segment', () async {
      const address = 'https://example.com/lists/main.txt?source=a#fragment';

      await ListManagementApi(dio).deleteLists(list: address, type: 'block');

      expect(recorder.paths, hasLength(1));
      expect(
        recorder.paths.single,
        '/lists/https%3A%2F%2Fexample.com%2Flists%2Fmain.txt%3Fsource%3Da%23fragment',
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

        expect(recorder.paths, hasLength(1));
        expect(
          recorder.paths.single,
          '/config/dns%2Fhosts/192.0.2.10%20host%2Fname',
        );
      },
    );
  });
}
