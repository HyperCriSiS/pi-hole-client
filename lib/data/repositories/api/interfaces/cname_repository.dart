import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:result_dart/result_dart.dart';

abstract interface class CnameRepository {
  Future<Result<List<CnameRecord>>> fetchCnameRecords();

  Future<Result<Unit>> addCnameRecord({required CnameRecord record});

  Future<Result<Unit>> updateCnameRecord({
    required CnameRecord oldRecord,
    required CnameRecord record,
  });

  Future<Result<Unit>> deleteCnameRecord({required CnameRecord record});
}
