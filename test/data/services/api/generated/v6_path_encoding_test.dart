import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pihole_v6_api/pihole_v6_api.dart';

void main() {
  group('generated v6 path encoding', () {
    late Dio dio;
    late List<RequestOptions> requests;

    setUp(() {
      requests = <RequestOptions>[];
      dio = Dio(BaseOptions(baseUrl: 'https://pi.hole/api'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<void>(requestOptions: options, statusCode: 204),
            );
          },
        ),
      );
    });

    test('keeps a full adlist URL inside one generated path segment', () async {
      const address = 'https://example.com/lists/main.txt?source=a#fragment';

      await ListManagementApi(dio).deleteLists(
        list: address,
        type: 'block',
      );

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

    test('encodes config element and value as independent path segments', () async {
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
    });
  });
}
