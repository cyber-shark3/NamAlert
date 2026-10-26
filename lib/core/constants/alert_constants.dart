/// Controlled enumerations and metadata for alert categories, severity,
/// status, verification state and source types.

enum AlertCategory {
  water,
  electricity,
  internet,
  roads;

  String get wireName => name;

  static AlertCategory fromWire(String? value) =>
      AlertCategory.values.firstWhere(
        (c) => c.name == value,
        orElse: () => AlertCategory.water,
      );

  String get label => switch (this) {
        AlertCategory.water => 'Water',
        AlertCategory.electricity => 'Electricity',
        AlertCategory.internet => 'Internet & Telecom',
        AlertCategory.roads => 'Roads & Transport',
      };

  /// Icon code point (Material). Kept as IconData in UI layer via helpers.
  String get iconId => switch (this) {
        AlertCategory.water => 'water_drop',
        AlertCategory.electricity => 'bolt',
        AlertCategory.internet => 'wifi_off',
        AlertCategory.roads => 'road',
      };

  String get notificationPrefix => switch (this) {
        AlertCategory.water => 'Water Alert',
        AlertCategory.electricity => 'Power Alert',
        AlertCategory.internet => 'Internet Alert',
        AlertCategory.roads => 'Road Alert',
      };
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical;

  static AlertSeverity fromWire(String? value) =>
      AlertSeverity.values.firstWhere(
        (s) => s.name == value,
        orElse: () => AlertSeverity.medium,
      );

  String get label => switch (this) {
        AlertSeverity.low => 'Low',
        AlertSeverity.medium => 'Medium',
        AlertSeverity.high => 'High',
        AlertSeverity.critical => 'Critical',
      };
}

enum AlertStatus {
  pendingReview,
  published,
  investigating,
  resolved,
  rejected;

  String get wireName => switch (this) {
        AlertStatus.pendingReview => 'pending_review',
        AlertStatus.published => 'published',
        AlertStatus.investigating => 'investigating',
        AlertStatus.resolved => 'resolved',
        AlertStatus.rejected => 'rejected',
      };

  static AlertStatus fromWire(String? value) =>
      AlertStatus.values.firstWhere(
        (s) => s.wireName == value,
        orElse: () => AlertStatus.pendingReview,
      );

  String get label => switch (this) {
        AlertStatus.pendingReview => 'Pending review',
        AlertStatus.published => 'Published',
        AlertStatus.investigating => 'Investigating',
        AlertStatus.resolved => 'Resolved',
        AlertStatus.rejected => 'Rejected',
      };

  /// Statuses that are visible in the public feed.
  bool get isPublicVisible => this != AlertStatus.pendingReview && this != AlertStatus.rejected;

  /// Statuses an administrator may transition a pending report into.
  static const List<AlertStatus> allowedTransitionsFromPending = [
    AlertStatus.published,
    AlertStatus.rejected,
  ];
}

enum VerificationStatus {
  unverified,
  official,
  communityReported;

  static VerificationStatus fromWire(String? value) =>
      VerificationStatus.values.firstWhere(
        (v) => v.name == value,
        orElse: () => VerificationStatus.unverified,
      );

  String get label => switch (this) {
        VerificationStatus.unverified => 'Unverified',
        VerificationStatus.official => 'Official — verified',
        VerificationStatus.communityReported => 'Community reported',
      };
}

enum SourceType {
  official,
  userReport,
  utilityFeed;

  static SourceType fromWire(String? value) =>
      SourceType.values.firstWhere(
        (s) => s.name == value,
        orElse: () => SourceType.userReport,
      );

  String get label => switch (this) {
        SourceType.official => 'Official source',
        SourceType.userReport => 'User report',
        SourceType.utilityFeed => 'Utility / provider feed',
      };
}
