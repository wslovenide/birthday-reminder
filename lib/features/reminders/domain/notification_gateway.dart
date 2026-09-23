import 'reminder_plan.dart';

/// 本地通知的抽象网关，便于在测试中替换。
abstract class NotificationGateway {
  /// 初始化通知渠道与回调。
  Future<void> initialize();

  /// 请求通知权限，返回是否已授予。
  Future<bool> requestPermission();

  /// 取消全部已安排的通知。
  Future<void> cancelAll();

  /// 安排一条通知。
  Future<void> schedule(ReminderPlan plan);

  /// 用户点击通知后，推送对应联系人 id。
  Stream<int> get selectedPersonIds;
}
