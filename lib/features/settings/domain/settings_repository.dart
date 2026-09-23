import 'app_settings.dart';

/// 设置的读写接口。
abstract class SettingsRepository {
  /// 读取设置，未设置时返回默认值。
  Future<AppSettings> load();

  /// 实时监听设置。
  Stream<AppSettings> watch();

  /// 保存设置。
  Future<void> save(AppSettings settings);
}
