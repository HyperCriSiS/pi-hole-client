import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pi_hole_client/config/dependencies.dart';
import 'package:pi_hole_client/data/repositories/api/v6/v6_session_cache_store.dart';
import 'package:pi_hole_client/data/repositories/local/app_config_repository.dart';
import 'package:pi_hole_client/data/repositories/local/gravity_repository.dart';
import 'package:pi_hole_client/data/repositories/local/interfaces/app_config_repository.dart';
import 'package:pi_hole_client/data/repositories/local/server_repository.dart';
import 'package:pi_hole_client/data/services/local/database_service.dart';
import 'package:pi_hole_client/data/services/local/secure_storage_service.dart';
import 'package:pi_hole_client/domain/services/app_log_service.dart';
import 'package:pi_hole_client/pi_hole_client.dart';
import 'package:pi_hole_client/ui/core/view_models/app_config_viewmodel.dart';
import 'package:pi_hole_client/ui/core/view_models/servers_viewmodel.dart';
import 'package:pi_hole_client/ui/core/view_models/status_viewmodel.dart';
import 'package:pi_hole_client/ui/domains/view_models/domains_viewmodel.dart';
import 'package:pi_hole_client/ui/logs/view_models/logs_viewmodel.dart';
import 'package:pi_hole_client/ui/settings/server_settings/advanced_settings/gravity_update/view_models/gravity_update_viewmodel.dart';
import 'package:pi_hole_client/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vibration/vibration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureSqlite();

  final app = await bootstrapApp();
  runApp(app);
}

void _configureSqlite() {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

Future<void> initializeBiometrics(
  AppConfigViewModel configProvider,
  AppConfigRepository repository,
) async {
  try {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final localAuth = LocalAuthentication();
    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();
    final availableBiometrics = await localAuth.getAvailableBiometrics();

    final canUseBiometrics =
        canCheckBiometrics && isDeviceSupported && availableBiometrics.isNotEmpty;

    configProvider.setBiometricsSupport(canUseBiometrics);

    if (!canUseBiometrics && configProvider.useBiometrics) {
      await configProvider.setUseBiometrics(false);
    }
  } on PlatformException catch (e, st) {
    logger.w(
      'Biometric platform error: $e',
      error: e,
      stackTrace: st,
    );
    configProvider.setBiometricsSupport(false);
    await configProvider.setUseBiometrics(false);
  } catch (e, st) {
    logger.w(
      'Biometric initialization error: $e',
      error: e,
      stackTrace: st,
    );
    configProvider.setBiometricsSupport(false);
    await configProvider.setUseBiometrics(false);
  }
}

Future<void> initializeVibration(AppConfigViewModel configProvider) async {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final supported = await Vibration.hasCustomVibrationsSupport();
      configProvider.setValidVibrator(supported);
    }
  } catch (e) {
    logger.w('Error checking vibration support: $e');
    configProvider.setValidVibrator(false);
  }
}

Future<void> initializeDeviceInfo(AppConfigViewModel configProvider) async {
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await info.androidInfo;
      configProvider.setAndroidInfo(androidInfo);
    } else if (Platform.isIOS) {
      final iosInfo = await info.iosInfo;
      configProvider.setIosInfo(iosInfo);
    }
  } catch (e) {
    logger.w('Error loading device info: $e');
  }
}

Future<PackageInfo> loadAppInfo() async {
  return PackageInfo.fromPlatform();
}

Future<void> initializeSentry(AppConfigViewModel configProvider) async {
  if (configProvider.sendCrashReports == false) {
    logger.d('Send Crash Reports: OFF');
    await Sentry.close();
    return;
  }

  try {
    const dsn = String.fromEnvironment('SENTRY_DSN');
    if (dsn.isEmpty) {
      logger.w('Sentry DSN not configured');
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.tracesSampleRate = 0.1;
      options.profilesSampleRate = 0.1;
      options.attachScreenshot = true;
      options.sendDefaultPii = false;
      options.enableAutoSessionTracking = true;
    });
  } catch (e, st) {
    logger.e('Failed to initialize Sentry', error: e, stackTrace: st);
  }
}

Future<void> configurePlatformOptions() async {
  if (Platform.isAndroid) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}

Future<Widget> bootstrapApp({
  bool enableSentry = true,
  bool enableBiometrics = true,
  DatabaseService? databaseService,
  SecureStorageService? secureStorageService,
}) async {
  // Services & Repositories
  final dbService = databaseService ?? DatabaseService();
  await dbService.open();
  final appLogService = AppLogService();
  final storage =
      secureStorageService ?? SecureStorageService(appLogService: appLogService);
  final appConfigRepository = LocalAppConfigRepository(dbService, storage);
  final serverRepository = LocalServerRepository(dbService, storage);

  // ViewModels
  final gravityRepository = LocalGravityRepository(dbService);
  final sessionCacheStore = V6SessionCacheStore(appLogService: appLogService);
  final serversViewModel = ServersViewModel(
    serverRepository,
    sessionCacheStore: sessionCacheStore,
  );
  final configProvider = AppConfigViewModel(
    appConfigRepository,
    appLogService: appLogService,
  );
  final statusViewModel = StatusViewModel(appLogService: appLogService);
  final logsViewModel = LogsViewModel();
  final domainsViewModel = DomainsViewModel();
  final gravityUpdateViewModel = GravityUpdateViewModel(
    repository: gravityRepository,
  );

  // Load persisted data
  final appdata = await appConfigRepository.fetchAppConfig();
  final servers = await serverRepository.fetchServers();
  switch (appdata) {
    case Success():
      configProvider.saveFromDb(appdata.getOrNull());
    case Failure():
      logger.e('Failed to load app config: ${appdata.exceptionOrNull()}');
      throw appdata.exceptionOrNull();
  }
  switch (servers) {
    case Success():
      serversViewModel.loadFromDb(servers.getOrNull() ?? []);
    case Failure():
      logger.e('Failed to load servers: ${servers.exceptionOrNull()}');
      throw servers.exceptionOrNull();
  }

  if (enableBiometrics) {
    await initializeBiometrics(configProvider, appConfigRepository);
  }
  await initializeVibration(configProvider);
  await initializeDeviceInfo(configProvider);

  try {
    configProvider.setAppInfo(await loadAppInfo());
  } catch (e) {
    logger.w('Error loading package info: $e');
  }

  if (enableSentry) {
    await initializeSentry(configProvider);
  }
  await configurePlatformOptions();

  return MultiProvider(
    providers: buildAppProviders(
      appConfigRepository: appConfigRepository,
      serverRepository: serverRepository,
      secureStorageService: storage,
      serversViewModel: serversViewModel,
      appConfigViewModel: configProvider,
      statusViewModel: statusViewModel,
      logsViewModel: logsViewModel,
      domainsViewModel: domainsViewModel,
      gravityUpdateViewModel: gravityUpdateViewModel,
      sessionCacheStore: sessionCacheStore,
    ),
    child: SentryWidget(child: Phoenix(child: const PiHoleClient())),
  );
}
