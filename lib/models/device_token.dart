import 'package:cloud_firestore/cloud_firestore.dart';

/// FCM device token association stored in `device_tokens/{tokenHash}`.
/// The document ID is a sanitised form of the token so registration is
/// idempotent (re-registering the same device updates, not duplicates).
class DeviceToken {
  const DeviceToken({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    this.createdAt,
    this.updatedAt,
    this.lastSeenAt,
    this.active = true,
  });

  final String id;
  final String userId;
  final String token;
  final String platform;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeenAt;
  final bool active;

  /// Deterministic document id from the raw FCM token.
  static String idFor(String token) {
    // FCM tokens are alphanumeric plus '-' and '_'. Firestore doc IDs cannot
    // contain '/', so replace and keep length manageable via a simple hash mix.
    final sanitized = token.replaceAll('/', '~');
    if (sanitized.length <= 120) return sanitized;
    return '${sanitized.substring(0, 80)}_${sanitized.hashCode.abs()}';
  }

  static DeviceToken fromMap(String id, Map<String, dynamic> map) {
    return DeviceToken(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      // Token may be hidden by security rules for non-owners; tolerate absence.
      token: (map['token'] as String?) ?? _recoverFromId(id),
      platform: (map['platform'] as String?) ?? 'android',
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
      lastSeenAt: _toDate(map['lastSeenAt']),
      active: (map['active'] as bool?) ?? true,
    );
  }

  factory DeviceToken.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      DeviceToken.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  static String _recoverFromId(String id) => id.replaceAll('~', '/');

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
