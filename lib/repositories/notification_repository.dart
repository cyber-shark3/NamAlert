import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/user_notification.dart';

/// Access to per-user in-app notification records. Users can read and update
/// only their own documents (enforced by Firestore rules).
class NotificationRepository {
  NotificationRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.userNotificationsCollection);

  Stream<List<UserNotification>> watchForUser(String uid, {int limit = 50}) {
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(UserNotification.fromDoc).toList());
  }

  Stream<int> watchUnreadCount(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .where('readAt', isNull: true)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> markRead(String notificationId) async {
    await _col.doc(notificationId).update(<String, dynamic>{
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllRead(String uid) async {
    final snap = await _col
        .where('userId', isEqualTo: uid)
        .where('readAt', isNull: true)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }
}
