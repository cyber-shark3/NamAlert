import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/app_user.dart';

/// Direct user-profile access (used by the profile screen and preferences).
class UserRepository {
  UserRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  Future<AppUser?> fetch(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return AppUser.fromDoc(snap);
  }

  Stream<AppUser?> watch(String uid) {
    return _users.doc(uid).snapshots().map((s) => s.exists ? AppUser.fromDoc(s) : null);
  }

  /// Writes only client-editable fields. `role` and `accountStatus` are never
  /// included here — security rules reject any attempt to change them.
  Future<void> updatePreferences({
    required String uid,
    String? displayName,
    String? preferredTown,
    String? preferredArea,
    Set<AlertCategory>? selectedCategories,
    bool? notificationEnabled,
  }) async {
    final payload = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (displayName != null) payload['displayName'] = displayName.trim();
    if (preferredTown != null) payload['preferredTown'] = preferredTown.trim();
    if (preferredArea != null) payload['preferredArea'] = preferredArea.trim();
    if (selectedCategories != null) {
      payload['selectedCategories'] =
          selectedCategories.map((c) => c.wireName).toList();
    }
    if (notificationEnabled != null) {
      payload['notificationEnabled'] = notificationEnabled;
    }
    await _users.doc(uid).update(payload);
  }
}
