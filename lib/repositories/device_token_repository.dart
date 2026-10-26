import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/device_token.dart';

/// Client-side registration of FCM device tokens. Rules restrict writes so a
/// user may only manage token documents that reference their own uid.
class DeviceTokenRepository {
  DeviceTokenRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.deviceTokensCollection);

  /// Idempotent upsert keyed by the token itself.
  Future<void> register({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final id = DeviceToken.idFor(token);
    await _col.doc(id).set(<String, dynamic>{
      'userId': userId,
      'token': token,
      'platform': platform,
      'active': true,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markInactive(String token) async {
    await _col.doc(DeviceToken.idFor(token)).update(<String, dynamic>{
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeToken(String token) async {
    await _col.doc(DeviceToken.idFor(token)).delete();
  }

  /// Lists this device/user's own tokens (for settings display).
  Future<List<DeviceToken>> listForUser(String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    return snap.docs.map(DeviceToken.fromDoc).toList();
  }
}
