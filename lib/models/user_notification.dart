import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/alert_constants.dart';

/// In-app notification record stored in `user_notifications/{id}`.
/// One document per intended recipient per alert event.
class UserNotification {
  const UserNotification({
    required this.id,
    required this.userId,
    required this.alertId,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.readAt,
    this.deliveryStatus = NotificationDeliveryStatus.pending,
  });

  final String id;
  final String userId;
  final String alertId;
  final String title;
  final String body;
  final AlertCategory category;
  final DateTime createdAt;
  final DateTime? readAt;
  final NotificationDeliveryStatus deliveryStatus;

  bool get isRead => readAt != null;

  static UserNotification fromMap(String id, Map<String, dynamic> map) {
    return UserNotification(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      alertId: (map['alertId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      category: AlertCategory.fromWire(map['category'] as String?),
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      readAt: _toDate(map['readAt']),
      deliveryStatus: NotificationDeliveryStatus.fromWire(
          map['deliveryStatus'] as String?),
    );
  }

  factory UserNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserNotification.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

enum NotificationDeliveryStatus {
  pending,
  pushed,
  pushFailed,
  skipped;

  static NotificationDeliveryStatus fromWire(String? value) =>
      NotificationDeliveryStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => NotificationDeliveryStatus.pending,
      );
}
