/// 設定（SPEC.md「データモデル > settings」）。
class AppSettings {
  const AppSettings({
    this.plan = 'free',
    this.notifyTime = '07:00',
    this.eveningNotifyTime = '20:00',
    this.homeLocationId,
    this.selectedLocationId,
  });

  /// `free` または `premium`
  final String plan;

  /// 朝の通知時刻（HH:MM）
  final String notifyTime;

  /// 夕方の振り返り通知の時刻（HH:MM）
  final String eveningNotifyTime;

  /// 自宅として使う場所
  final int? homeLocationId;

  /// 今日タブに表示している場所（端末内だけで使う表示状態）
  final int? selectedLocationId;

  AppSettings copyWith({
    String? plan,
    String? notifyTime,
    String? eveningNotifyTime,
    int? Function()? homeLocationId,
    int? Function()? selectedLocationId,
  }) {
    return AppSettings(
      plan: plan ?? this.plan,
      notifyTime: notifyTime ?? this.notifyTime,
      eveningNotifyTime: eveningNotifyTime ?? this.eveningNotifyTime,
      homeLocationId: homeLocationId != null
          ? homeLocationId()
          : this.homeLocationId,
      selectedLocationId: selectedLocationId != null
          ? selectedLocationId()
          : this.selectedLocationId,
    );
  }

  Map<String, Object?> toRow() => {
    'id': 1,
    'plan': plan,
    'notify_time': notifyTime,
    'evening_notify_time': eveningNotifyTime,
    'home_location_id': homeLocationId,
    'selected_location_id': selectedLocationId,
  };

  factory AppSettings.fromRow(Map<String, Object?> row) => AppSettings(
    plan: row['plan'] as String,
    notifyTime: row['notify_time'] as String,
    eveningNotifyTime: row['evening_notify_time'] as String,
    homeLocationId: row['home_location_id'] as int?,
    selectedLocationId: row['selected_location_id'] as int?,
  );
}
