import 'dart:math' as math;

/// 場所（SPEC.md「データモデル > locations」）。
class Location {
  const Location({
    this.id,
    required this.name,
    required this.admin1,
    required this.country,
    required this.lat,
    required this.lon,
    required this.timezone,
    required this.createdAt,
  });

  final int? id;

  /// 表示名（例: 名古屋市）
  final String name;

  /// 都道府県、州などの広域名
  final String admin1;
  final String country;
  final double lat;
  final double lon;

  /// IANAタイムゾーン（例: Asia/Tokyo）
  final String timezone;
  final DateTime createdAt;

  Location copyWith({int? id}) => Location(
    id: id ?? this.id,
    name: name,
    admin1: admin1,
    country: country,
    lat: lat,
    lon: lon,
    timezone: timezone,
    createdAt: createdAt,
  );

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'name': name,
    'admin1': admin1,
    'country': country,
    'lat': lat,
    'lon': lon,
    'timezone': timezone,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory Location.fromRow(Map<String, Object?> row) => Location(
    id: row['id'] as int,
    name: row['name'] as String,
    admin1: row['admin1'] as String,
    country: row['country'] as String,
    lat: (row['lat'] as num).toDouble(),
    lon: (row['lon'] as num).toDouble(),
    timezone: row['timezone'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  /// 同じ場所とみなすか。名前・広域名・国が一致するか、
  /// 座標が2km以内なら同じ場所として扱い、重複登録しない。
  bool isSamePlaceAs(Location other) {
    if (name == other.name &&
        admin1 == other.admin1 &&
        country == other.country) {
      return true;
    }
    return distanceKm(other) < 2.0;
  }

  double distanceKm(Location other) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(other.lat - lat);
    final dLon = rad(other.lon - lon);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat)) *
            math.cos(rad(other.lat)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }
}
