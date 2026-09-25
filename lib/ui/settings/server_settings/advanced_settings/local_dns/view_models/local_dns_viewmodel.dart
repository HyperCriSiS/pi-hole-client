import 'dart:io';

import 'package:command_it/command_it.dart';
import 'package:flutter/foundation.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/cname_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/local_dns_repository.dart';
import 'package:pi_hole_client/data/repositories/api/interfaces/network_repository.dart';
import 'package:pi_hole_client/domain/model/local_dns/cname_record.dart';
import 'package:pi_hole_client/domain/model/local_dns/local_dns.dart';
import 'package:pi_hole_client/domain/model/network/network.dart';
import 'package:pi_hole_client/utils/exceptions.dart';
import 'package:pi_hole_client/utils/validators.dart';
import 'package:result_dart/result_dart.dart';

class LocalDnsData {
  const LocalDnsData({
    required this.records,
    required this.deviceOptions,
    this.cnameRecords = const [],
  });

  final List<LocalDns> records;
  final List<DeviceOption> deviceOptions;
  final List<CnameRecord> cnameRecords;
}

class LocalDnsViewModel extends ChangeNotifier {
  LocalDnsViewModel({
    required LocalDnsRepository localDnsRepository,
    required NetworkRepository networkRepository,
    CnameRepository? cnameRepository,
  }) : _localDnsRepository = localDnsRepository,
       _networkRepository = networkRepository,
       _cnameRepository = cnameRepository {
    loadRecords = Command.createAsyncNoParam<void>(
      _loadRecords,
      initialValue: null,
    );
    addRecord = Command.createAsyncNoResult<LocalDns>(_addRecord);
    updateRecord =
        Command.createAsyncNoResult<({LocalDns oldRecord, LocalDns newRecord})>(
          _updateRecord,
        );
    deleteRecord = Command.createAsyncNoResult<LocalDns>(_deleteRecord);
    addCnameRecord = Command.createAsyncNoResult<CnameRecord>(_addCnameRecord);
    updateCnameRecord =
        Command.createAsyncNoResult<
          ({CnameRecord oldRecord, CnameRecord record})
        >(_updateCnameRecord);
    deleteCnameRecord = Command.createAsyncNoResult<CnameRecord>(
      _deleteCnameRecord,
    );

    loadRecords.addListener(notifyListeners);
    addRecord.addListener(notifyListeners);
    addRecord.errors.addListener(notifyListeners);
    updateRecord.addListener(notifyListeners);
    updateRecord.errors.addListener(notifyListeners);
    deleteRecord.addListener(notifyListeners);
    deleteRecord.errors.addListener(notifyListeners);
    addCnameRecord.addListener(notifyListeners);
    addCnameRecord.errors.addListener(notifyListeners);
    updateCnameRecord.addListener(notifyListeners);
    updateCnameRecord.errors.addListener(notifyListeners);
    deleteCnameRecord.addListener(notifyListeners);
    deleteCnameRecord.errors.addListener(notifyListeners);
  }

  final LocalDnsRepository _localDnsRepository;
  final NetworkRepository _networkRepository;
  final CnameRepository? _cnameRepository;

  late final Command<void, void> loadRecords;
  late final Command<LocalDns, void> addRecord;
  late final Command<({LocalDns oldRecord, LocalDns newRecord}), void>
  updateRecord;
  late final Command<LocalDns, void> deleteRecord;
  late final Command<CnameRecord, void> addCnameRecord;
  late final Command<({CnameRecord oldRecord, CnameRecord record}), void>
  updateCnameRecord;
  late final Command<CnameRecord, void> deleteCnameRecord;

  LocalDnsData _data = const LocalDnsData(records: [], deviceOptions: []);

  LocalDnsData get data => _data;
  bool get supportsCname => _cnameRepository != null;

  Future<void> _loadRecords() async {
    final dnsFuture = _localDnsRepository.fetchRecords();
    final devicesFuture = _networkRepository.fetchDevices();
    final cnameFuture = _cnameRepository?.fetchCnameRecords();

    final dnsResult = await dnsFuture;
    final devicesResult = await devicesFuture;
    final cnameResult = cnameFuture == null ? null : await cnameFuture;

    if (dnsResult case Failure()) throw dnsResult.exceptionOrNull();
    if (devicesResult case Failure()) throw devicesResult.exceptionOrNull();
    if (cnameResult case Failure()) throw cnameResult.exceptionOrNull();

    _data = LocalDnsData(
      records: dnsResult.getOrNull()!,
      deviceOptions: _devicesToOptions(devicesResult.getOrNull()!),
      cnameRecords: cnameResult?.getOrNull() ?? const [],
    );
    notifyListeners();
  }

  Future<void> _addRecord(LocalDns record) async {
    if (_data.records.any((r) => _isSameRecord(r, record))) {
      throw AlreadyExistsException('Local DNS record already exists.');
    }

    final result = await _localDnsRepository.addRecord(
      ip: record.ip,
      name: record.name,
    );
    switch (result) {
      case Success():
        _data = LocalDnsData(
          records: [..._data.records, record],
          deviceOptions: _data.deviceOptions,
          cnameRecords: _data.cnameRecords,
        );
        notifyListeners();
      case Failure():
        throw result.exceptionOrNull();
    }
  }

  Future<void> _updateRecord(
    ({LocalDns oldRecord, LocalDns newRecord}) params,
  ) async {
    final index = _data.records.indexOf(params.oldRecord);
    final others = [..._data.records];
    if (index != -1) others.removeAt(index);
    if (others.any((r) => _isSameRecord(r, params.newRecord))) {
      throw AlreadyExistsException('Local DNS record already exists.');
    }

    final result = await _localDnsRepository.updateRecord(
      oldRecord: params.oldRecord,
      newRecord: params.newRecord,
    );
    switch (result) {
      case Success():
        final records = [..._data.records];
        if (index != -1) records[index] = params.newRecord;
        _data = LocalDnsData(
          records: records,
          deviceOptions: _data.deviceOptions,
          cnameRecords: _data.cnameRecords,
        );
        notifyListeners();
      case Failure():
        throw result.exceptionOrNull();
    }
  }

  Future<void> _deleteRecord(LocalDns record) async {
    final result = await _localDnsRepository.deleteRecord(
      ip: record.ip,
      name: record.name,
    );
    switch (result) {
      case Success():
        final records = [..._data.records]..remove(record);
        _data = LocalDnsData(
          records: records,
          deviceOptions: _data.deviceOptions,
          cnameRecords: _data.cnameRecords,
        );
        notifyListeners();
      case Failure():
        throw result.exceptionOrNull();
    }
  }

  bool _isSameRecord(LocalDns a, LocalDns b) {
    return a.ip.trim() == b.ip.trim() &&
        normalizeLocalDnsNames(a.name) == normalizeLocalDnsNames(b.name);
  }

  Future<void> _addCnameRecord(CnameRecord record) async {
    final repository = _requireCnameRepository();
    final result = await repository.addCnameRecord(record: record);
    switch (result) {
      case Success():
        _data = LocalDnsData(
          records: _data.records,
          deviceOptions: _data.deviceOptions,
          cnameRecords: [..._data.cnameRecords, record],
        );
        notifyListeners();
      case Failure():
        throw result.exceptionOrNull();
    }
  }

  Future<void> _updateCnameRecord(
    ({CnameRecord oldRecord, CnameRecord record}) params,
  ) async {
    final repository = _requireCnameRepository();
    final result = await repository.updateCnameRecord(
      oldRecord: params.oldRecord,
      record: params.record,
    );
    switch (result) {
      case Success():
        _data = LocalDnsData(
          records: _data.records,
          deviceOptions: _data.deviceOptions,
          cnameRecords: [
            for (final record in _data.cnameRecords)
              if (record == params.oldRecord) params.record else record,
          ],
        );
        notifyListeners();
      case Failure():
        throw result.exceptionOrNull();
    }
  }

  Future<void> _deleteCnameRecord(CnameRecord record) async {
    final repository = _requireCnameRepository();
    final result = await repository.deleteCnameRecord(record: record);
    switch (result) {
      case Success():
        _data = LocalDnsData(
          records: _data.records,
          deviceOptions: _data.deviceOptions,
          cnameRecords: _data.cnameRecords.where((r) => r != record).toList(),
        );
        notifyListeners();
      case Failure():
        throw result.exceptionOrNull();
    }
  }

  CnameRepository _requireCnameRepository() {
    final repository = _cnameRepository;
    if (repository == null) {
      throw UnsupportedError('CNAME management requires Pi-hole API v6');
    }
    return repository;
  }

  List<DeviceOption> _devicesToOptions(List<Device> devices) {
    final list = devices
        .where((device) => device.lastQuery.millisecondsSinceEpoch != 0)
        .expand((device) {
          return device.ips
              .where(
                (addr) =>
                    addr.ip != '127.0.0.1' &&
                    addr.ip != '::' &&
                    addr.ip != '::1',
              )
              .map(
                (addr) => DeviceOption(
                  ip: addr.ip,
                  hwaddr: device.hwaddr,
                  macVendor: device.macVendor ?? '',
                ),
              );
        })
        .toList();

    list.sort((a, b) {
      final ipA = InternetAddress.tryParse(a.ip);
      final ipB = InternetAddress.tryParse(b.ip);

      if (ipA == null || ipB == null) return a.ip.compareTo(b.ip);
      if (ipA.type != ipB.type) {
        return ipA.type == InternetAddressType.IPv4 ? -1 : 1;
      }

      final bytesA = ipA.rawAddress;
      final bytesB = ipB.rawAddress;
      for (var i = 0; i < bytesA.length; i++) {
        final diff = bytesA[i].compareTo(bytesB[i]);
        if (diff != 0) return diff;
      }
      return 0;
    });

    return list;
  }

  @override
  void dispose() {
    loadRecords.removeListener(notifyListeners);
    addRecord.removeListener(notifyListeners);
    addRecord.errors.removeListener(notifyListeners);
    updateRecord.removeListener(notifyListeners);
    updateRecord.errors.removeListener(notifyListeners);
    deleteRecord.removeListener(notifyListeners);
    deleteRecord.errors.removeListener(notifyListeners);
    addCnameRecord.removeListener(notifyListeners);
    addCnameRecord.errors.removeListener(notifyListeners);
    updateCnameRecord.removeListener(notifyListeners);
    updateCnameRecord.errors.removeListener(notifyListeners);
    deleteCnameRecord.removeListener(notifyListeners);
    deleteCnameRecord.errors.removeListener(notifyListeners);
    loadRecords.dispose();
    addRecord.dispose();
    updateRecord.dispose();
    deleteRecord.dispose();
    addCnameRecord.dispose();
    updateCnameRecord.dispose();
    deleteCnameRecord.dispose();
    super.dispose();
  }
}
