import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pi_hole_client/data/repositories/local/interfaces/app_config_repository.dart';
import 'package:pi_hole_client/domain/model/app/app_config.dart';
import 'package:pi_hole_client/domain/model/app/app_log.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/services/app_log_service.dart';
import 'package:pi_hole_client/ui/core/l10n/languages.dart';
import 'package:pi_hole_client/ui/core/themes/theme.dart';
import 'package:pi_hole_client/utils/logger.dart';

class AppConfigViewModel with ChangeNotifier {
  AppConfigViewModel(
    this._repository, {
    AppLogService? appLogService,
  }) : _appLogService = appLogService ?? AppLogService() {
    _appLogService.addListener(_onAppLogChanged);
  }

  bool _showingSnackbar = false;
  bool _detailScreenOpen = false;
  int _selectedTab = 0;
  AndroidDeviceInfo? _androidDeviceInfo;
  IosDeviceInfo? _iosDeviceInfo;
  PackageInfo? _appInfo;
  int? _autoRefreshTime = 2; // secounds
  AppThemeMode _selectedTheme = AppThemeMode.system;
  int _reducedDataCharts = 0;
  double _logsPerQuery = 2; //hours
  String? _passCode;
  bool _biometricsSupport = false;
  int _useBiometrics = 0;
  bool _appUnlocked = true;
  bool _validVibrator = false;
  int _importantInfoReaden = 0;
  int _hideZeroValues = 0;
  int _loadingAnimation = 1;
  StatisticsVisualizationMode _statisticsVisualizationMode =
      StatisticsVisualizationMode.list;
  HomeVisualizationMode _homeVisualizationMode = HomeVisualizationMode.lineArea;
  int _sendCrashReports = 0;
  String _selectedLanguage = 'en';
  int _logAutoRefreshTime = 5;
  bool _liveLog = true;
  bool _isLivelogPaused = true;

  final AppLogService _appLogService;
  final AppConfigRepository _repository;

  AppColors get colors =>
      selectedTheme == ThemeMode.light ? lightAppColors : darkAppColors;

  bool get showingSnackbar {
    return _showingSnackbar;
  }

  int get selectedTab {
    return _selectedTab;
  }

  PackageInfo? get getAppInfo {
    return _appInfo;
  }

  int? get getAutoRefreshTime {
    return _autoRefreshTime;
  }

  ThemeMode get selectedTheme {
    switch (_selectedTheme) {
      case AppThemeMode.system:
        return SchedulerBinding
                    .instance
                    .platformDispatcher
                    .platformBrightness ==
                Brightness.light
            ? ThemeMode.light
            : ThemeMode.dark;

      case AppThemeMode.light:
        return ThemeMode.light;

      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  String get selectedLanguage {
    return _selectedLanguage;
  }

  AppThemeMode get appThemeMode {
    return _selectedTheme;
  }

  int get selectedLanguageNumber {
    final selectedLanguageOption = languageOptions.firstWhere(
      (option) => option.key == _selectedLanguage,
      orElse: () => languageOptions.firstWhere((option) => option.key == 'en'),
    );
    return selectedLanguageOption.index;
  }

  bool get reducedDataCharts {
    return _reducedDataCharts == 0 ? false : true;
  }

  double get logsPerQuery {
    return _logsPerQuery;
  }

  AndroidDeviceInfo? get androidDeviceInfo {
    return _androidDeviceInfo;
  }

  IosDeviceInfo? get iosDeviceInfo {
    return _iosDeviceInfo;
  }

  bool get biometricsSupport {
    return _biometricsSupport;
  }

  bool get validVibrator {
    return _validVibrator;
  }

  String? get passCode {
    return _passCode;
  }

  bool get useBiometrics {
    return _useBiometrics == 0 ? false : true;
  }

  bool get appUnlocked {
    return _appUnlocked;
  }

  int get importantInfoReaden {
    return _importantInfoReaden;
  }

  bool get hideZeroValues {
    return _hideZeroValues == 0 ? false : true;
  }

  bool get loadingAnimation {
    return _loadingAnimation == 1 ? true : false;
  }

  StatisticsVisualizationMode get statisticsVisualizationMode {
    return _statisticsVisualizationMode;
  }

  HomeVisualizationMode get homeVisualizationMode {
    return _homeVisualizationMode;
  }

  bool get sendCrashReports {
    return _sendCrashReports == 1;
  }

  List<AppLog> get logs {
    return _appLogService.logs;
  }

  int get logAutoRefreshTime {
    return _logAutoRefreshTime;
  }

  bool get liveLog {
    return _liveLog;
  }

  bool get isLivelogPaused {
    return _isLivelogPaused;
  }

  void setShowingSnackbar(bool showing) {
    _showingSnackbar = showing;
    notifyListeners();
  }

  void setDetailScreenOpen(bool open) {
    _detailScreenOpen = open;
    notifyListeners();
  }

  void setSelectedTab(int tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  void setAndroidInfo(AndroidDeviceInfo info) {
    _androidDeviceInfo = info;
    notifyListeners();
  }

  void setIosInfo(IosDeviceInfo info) {
    _iosDeviceInfo = info;
    notifyListeners();
  }

  void setAppInfo(PackageInfo info) {
    _appInfo = info;
    notifyListeners();
  }

  void setBiometricsSupport(bool support) {
    _biometricsSupport = support;
    notifyListeners();
  }

  void setAppUnlocked(bool unlocked) {
    _appUnlocked = unlocked;
    notifyListeners();
  }

  void setValidVibrator(bool valid) {
    _validVibrator = valid;
    notifyListeners();
  }

  void _onAppLogChanged() => notifyListeners();

  void addLog(AppLog log) {
    _appLogService.addLog(log);
  }

  Future<bool> setUseBiometrics(bool biometrics) async {
    final updated = await _repository.updateUseBiometricAuth(biometrics);
    if (updated.isSuccess()) {
      _useBiometrics = biometrics == true ? 1 : 0;
      notifyListeners();
      return true;
    } else {
      logger.w(
        'Failed to set biometrics: ${updated.exceptionOrNull()}',
      );
      return false;
    }
  }

  Future<bool> setPassCode(String? code) async {
    final updated = await _repository.updatePassCode(code);
    if (updated.isSuccess()) {
      _passCode = code;
      notifyListeners();
      return true;
    } else {
      logger.w(
        'Failed to set passcode: ${updated.exceptionOrNull()}',
      );
      return false;
    }
  }

  Future<bool> setAutoRefreshTime(int? time) async {
    final updated = await _repository.updateAutoRefreshTime(time);
    if (updated.isSuccess()) {
      _autoRefreshTime = time;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setTheme(AppThemeMode theme) async {
    final updated = await _repository.updateTheme(theme);
    if (updated.isSuccess()) {
      _selectedTheme = theme;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setReducedDataCharts(bool reduced) async {
    final updated = await _repository.updateReducedDataCharts(reduced);
    if (updated.isSuccess()) {
      _reducedDataCharts = reduced ? 1 : 0;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setLogsPerQuery(double time) async {
    final updated = await _repository.updateLogsPerQuery(time);
    if (updated.isSuccess()) {
      _logsPerQuery = time;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setLogAutoRefreshTime(int time) async {
    final updated = await _repository.updateLogAutoRefreshTime(time);
    if (updated.isSuccess()) {
      _logAutoRefreshTime = time;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setLiveLog(bool live) async {
    final updated = await _repository.updateLiveLog(live);
    if (updated.isSuccess()) {
      _liveLog = live;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setIsLivelogPaused(bool paused) async {
    final updated = await _repository.updateIsLivelogPaused(paused);
    if (updated.isSuccess()) {
      _isLivelogPaused = paused;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setSelectedLanguage(String language) async {
    final updated = await _repository.updateLanguage(language);
    if (updated.isSuccess()) {
      _selectedLanguage = language;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setImportantInfoReaden(int readen) async {
    final updated = await _repository.updateImportantInfoReaden(readen);
    if (updated.isSuccess()) {
      _importantInfoReaden = readen;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setHideZeroValues(bool hide) async {
    final updated = await _repository.updateHideZeroValues(hide);
    if (updated.isSuccess()) {
      _hideZeroValues = hide ? 1 : 0;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setLoadingAnimation(bool loading) async {
    final updated = await _repository.updateLoadingAnimation(loading);
    if (updated.isSuccess()) {
      _loadingAnimation = loading ? 1 : 0;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setStatisticsVisualizationMode(
    StatisticsVisualizationMode mode,
  ) async {
    final updated = await _repository.updateStatisticsVisualizationMode(mode);
    if (updated.isSuccess()) {
      _statisticsVisualizationMode = mode;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setHomeVisualizationMode(HomeVisualizationMode mode) async {
    final updated = await _repository.updateHomeVisualizationMode(mode);
    if (updated.isSuccess()) {
      _homeVisualizationMode = mode;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setSendCrashReports(bool send) async {
    final updated = await _repository.updateSendCrashReports(send);
    if (updated.isSuccess()) {
      _sendCrashReports = send ? 1 : 0;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> restoreAppConfig() async {
    final result = await _repository.fetchAppConfig();
    if (result.isSuccess()) {
      saveFromDb(result.getOrNull());
      return true;
    } else {
      logger.w(
        'Failed to restore app config: ${result.exceptionOrNull()}',
      );
      return false;
    }
  }

  void saveFromDb(AppConfig? config) {
    if (config == null) return;
    _autoRefreshTime = config.autoRefreshTime;
    _selectedTheme = config.theme;
    _selectedLanguage = config.language;
    _reducedDataCharts = config.reducedDataCharts ? 1 : 0;
    _logsPerQuery = config.logsPerQuery;
    _logAutoRefreshTime = config.logAutoRefreshTime;
    _liveLog = config.liveLog;
    _isLivelogPaused = config.isLivelogPaused;
    _passCode = config.passCode;
    _useBiometrics = config.useBiometricAuth ? 1 : 0;
    _importantInfoReaden = config.importantInfoReaden;
    _hideZeroValues = config.hideZeroValues ? 1 : 0;
    _loadingAnimation = config.loadingAnimation ? 1 : 0;
    _statisticsVisualizationMode = config.statisticsVisualizationMode;
    _homeVisualizationMode = config.homeVisualizationMode;
    _sendCrashReports = config.sendCrashReports ? 1 : 0;
    notifyListeners();
  }

  Future<bool> resetApp() async {
    final result = await _repository.resetApp();
    if (result.isSuccess()) {
      _showingSnackbar = false;
      _detailScreenOpen = false;
      _selectedTab = 0;
      _androidDeviceInfo = null;
      _iosDeviceInfo = null;
      _appInfo = null;
      _autoRefreshTime = 2;
      _selectedTheme = AppThemeMode.system;
      _selectedLanguage = 'en';
      _reducedDataCharts = 0;
      _logsPerQuery = 2;
      _logAutoRefreshTime = 5;
      _liveLog = true;
      _isLivelogPaused = true;
      _passCode = null;
      _useBiometrics = 0;
      _importantInfoReaden = 0;
      _hideZeroValues = 0;
      _loadingAnimation = 1;
      _statisticsVisualizationMode = StatisticsVisualizationMode.list;
      _homeVisualizationMode = HomeVisualizationMode.lineArea;
      _sendCrashReports = 0;

      notifyListeners();

      return true;
    } else {
      return false;
    }
  }

  @override
  void dispose() {
    _appLogService.removeListener(_onAppLogChanged);
    super.dispose();
  }
}
