/// Global application constants for NamALERT.
class AppConstants {
  AppConstants._();

  static const String appName = 'NamALERT';
  static const String appTagline = 'Namibian Public Alert System';

  /// Firestore collection names.
  static const String usersCollection = 'users';
  static const String alertsCollection = 'alerts';
  static const String alertUpdatesSubcollection = 'updates';
  static const String deviceTokensCollection = 'device_tokens';
  static const String userNotificationsCollection = 'user_notifications';
  static const String adminAuditLogsCollection = 'admin_audit_logs';

  /// SharedPreferences keys.
  static const String prefsOnboardingComplete = 'onboarding_complete';
  static const String prefsNotificationEnabled = 'notification_enabled';

  /// Validation limits.
  static const int minPasswordLength = 8;
  static const int maxTitleLength = 120;
  static const int maxDescriptionLength = 2000;
  static const int maxDisplayNameLength = 60;
  static const int maxLocationNameLength = 160;

  /// Query page size for alert lists.
  static const int alertPageSize = 25;

  /// Namibian towns offered as subscription options (non-exhaustive).
  static const List<String> namibianTowns = <String>[
    'Windhoek',
    'Swakopmund',
    'Walvis Bay',
    'Oshakati',
    'Rundu',
    'Katima Mulilo',
    'Otjiwarongo',
    'Outjo',
    'Rehoboth',
    'Keetmanshoop',
    'Gobabis',
    'Ondangwa',
    'Lüderitz',
    'Opuwo',
    'Ruacana',
    'EPRA / Nationwide',
  ];
}
