import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/alert_constants.dart' show AlertStatus, SourceType;

/// A material change recorded against an alert. Stored as a subcollection:
/// `alerts/{alertId}/updates/{updateId}` for clean access control and reads.
class AlertUpdate {
  const AlertUpdate({
    required this.id,
    required this.alertId,
    required this.message,
    required this.createdAt,
    required this.createdBy,
    required this.sourceType,
    this.previousStatus,
    this.newStatus,
  });

  final String id;
  final String alertId;
  final String message;
  final AlertStatus? previousStatus;
  final AlertStatus? newStatus;
  final DateTime createdAt;
  final String createdBy;
  final SourceType sourceType;

  static AlertUpdate fromMap(String alertId, String id, Map<String, dynamic> map) {
    return AlertUpdate(
      id: id,
      alertId: alertId,
      message: (map['message'] as String?) ?? '',
      previousStatus: map['previousStatus'] == null
          ? null
          : AlertStatus.fromWire(map['previousStatus'] as String?),
      newStatus: map['newStatus'] == null
          ? null
          : AlertStatus.fromWire(map['newStatus'] as String?),
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      createdBy: (map['createdBy'] as String?) ?? '',
      sourceType: SourceType.fromWire(map['sourceType'] as String?),
    );
  }

  Map<String, dynamic> toDocument() => <String, dynamic>{
        'alertId': alertId,
        'message': message,
        'previousStatus': previousStatus?.wireName,
        'newStatus': newStatus?.wireName,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
        'sourceType': sourceType.name,
      };

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
