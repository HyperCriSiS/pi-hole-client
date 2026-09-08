import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

class _RecordingDio extends Mock implements Dio {
  final List<String> paths = <String>[];

  @override
  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    paths.add(path);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 204,
    );
  }
}

void main() {
  group('generated v6 path encoding', () {
    late _RecordingDio dio;

    setUp(() {
      dio = _RecordingDio();
    });

    test('keeps a full adlist URL inside one generated path segment', () async {
      const address = 'https://example.com/lists/main.txt?source=a#fragment';

      await ListManagementApi(dio).deleteLists(list: address, type: 'block');

      expect(dio.paths, hasLength(1));
      expect(
        dio.paths.single,
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

        expect(dio.paths, hasLength(1));
        expect(
          dio.paths.single,
          '/config/dns%2Fhosts/192.0.2.10%20host%2Fname',
        );
      },
    );
  });
}
