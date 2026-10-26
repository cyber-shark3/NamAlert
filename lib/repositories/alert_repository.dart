import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/alert_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/alert.dart';
import '../models/alert_update.dart';

/// Firestore data access for alerts, reports and alert updates.
class AlertRepository {
  AlertRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _alerts =>
      _db.collection(AppConstants.alertsCollection);

  CollectionReference<Map<String, dynamic>> _updatesFor(String alertId) =>
      _alerts.doc(alertId).collection(AppConstants.alertUpdatesSubcollection);

  /// Stream of public alerts (published/investigating/resolved), newest
  /// first, optionally filtered by category and town. Uses pagination.
  Stream<List<Alert>> watchPublicAlerts({
    AlertCategory? category,
    String? town,
    int limit = AppConstants.alertPageSize,
  }) {
    Query<Map<String, dynamic>> q = _alerts;
    if (category != null) {
      q = q.where('category', isEqualTo: category.wireName);
    }
    if (town != null && town.trim().isNotEmpty) {
      q = q.where('town', isEqualTo: town.trim());
    }
    // Public feed excludes pending_review and rejected via client-side filter
    // after fetching; a single-value status index would otherwise be needed.
    return q
        .orderBy('createdAt', descending: true)
        .limit(limit * 2)
        .snapshots()
        .map((snap) => snap.docs
            .map(Alert.fromDoc)
            .where((a) => a.status.isPublicVisible)
            .take(limit)
            .toList());
  }

  /// Paginated history fetch (all public statuses including resolved).
  Future<List<Alert>> fetchPublicPage({
    AlertCategory? category,
    String? town,
    DateTime? beforeCreatedAt,
    int limit = AppConstants.alertPageSize,
  }) async {
    Query<Map<String, dynamic>> q = _alerts;
    if (category != null) {
      q = q.where('category', isEqualTo: category.wireName);
    }
    if (town != null && town.trim().isNotEmpty) {
      q = q.where('town', isEqualTo: town.trim());
    }
    q = q.orderBy('createdAt', descending: true).limit(limit + 1);
    if (beforeCreatedAt != null) {
      q = q.startAfter([Timestamp.fromDate(beforeCreatedAt)]);
    }
    final snap = await q.get();
    final alerts = snap.docs.map(Alert.fromDoc).toList();
    return alerts.where((a) => a.status.isPublicVisible).toList();
  }

  Future<Alert?> fetchAlert(String id) async {
    try {
      final snap = await _alerts.doc(id).get(const GetOptions(source: Source.serverAndCache));
      if (!snap.exists || snap.data() == null) return null;
      return Alert.fromDoc(snap);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unavailable') {
        throw PermissionException('This alert is not available to you.', detail: e.code);
      }
      rethrow;
    }
  }

  Stream<Alert?> watchAlert(String id) {
    return _alerts.doc(id).snapshots().map((s) => s.exists ? Alert.fromDoc(s) : null);
  }

  /// Submits a user report. Enforces schema and length limits locally as the
  /// first line of defence; Firestore rules enforce the same server-side.
  Future<String> submitReport({
    required String title,
    required String description,
    required AlertCategory category,
    required String locationName,
    String? town,
    String? area,
    double? latitude,
    double? longitude,
    DateTime? incidentStartAt,
    String? imageUrl,
    required String reportedByUid,
  }) async {
    _validateLengths(title, description, locationName);

    // Duplicate detection: warn-free soft check — count very similar recent
    // reports by this user. We do NOT discard potentially important incidents
    // automatically; we only block an exact duplicate within 5 minutes.
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    final dupSnap = await _alerts
        .where('reportedBy', isEqualTo: reportedByUid)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .get();
    final normalizedTitle = title.trim().toLowerCase();
    final isDuplicate = dupSnap.docs.any((d) {
      final data = d.data();
      return (data['title'] as String? ?? '').trim().toLowerCase() == normalizedTitle &&
          (data['locationName'] as String? ?? '').trim().toLowerCase() ==
              locationName.trim().toLowerCase();
    });
    if (isDuplicate) {
      throw const ValidationException(
          'You already submitted a very similar report moments ago. Please wait for it to be reviewed.');
    }

    final doc = _alerts.doc();
    await doc.set(Alert.reportToDocument(
      title: title,
      description: description,
      category: category,
      locationName: locationName,
      town: town,
      area: area,
      latitude: latitude,
      longitude: longitude,
      incidentStartAt: incidentStartAt,
      imageUrl: imageUrl,
      reportedByUid: reportedByUid,
    ));
    return doc.id;
  }

  /// Streams reports awaiting review. Only administrators may read these
  /// documents; security rules reject non-admin queries with permission-denied.
  Stream<List<Alert>> watchPendingReports({int limit = 50}) {
    return _alerts
        .where('status', isEqualTo: AlertStatus.pendingReview.wireName)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .catchError((Object error, StackTrace st) {
      if (error is FirebaseException && error.code == 'permission-denied') {
        throw const PermissionException(
            'Only administrators can view pending reports.');
      }
      throw AppException('Could not load pending reports.', detail: '$error');
    }).map((snap) => snap.docs.map(Alert.fromDoc).toList()));
  }

  /// Administrative update of core alert fields. Trusted clients are admins;
  /// in production this should route through a Cloud Function which also
  /// writes the audit log. This method performs the Firestore operations
  /// inside a batch so an alert update and its update-note stay consistent.
  Future<void> adminUpdateAlert({
    required String alertId,
    required Map<String, dynamic> changedFields,
    required AlertStatus newStatus,
    required String message,
    required String adminUid,
    VerificationStatus? verificationStatus,
    DateTime? publishedAt,
    DateTime? resolvedAt,
  }) async {
    final ref = _alerts.doc(alertId);
    final current = await ref.get();
    if (!current.exists) {
      throw const NotFoundException('That alert no longer exists.');
    }
    final previous = Alert.fromDoc(current);

    final batch = _db.batch();
    final payload = <String, dynamic>{
      ...changedFields,
      'status': newStatus.wireName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (verificationStatus != null) {
      payload['verificationStatus'] = verificationStatus.name;
    }
    if (newStatus == AlertStatus.published) {
      payload['publishedBy'] = adminUid;
      payload['publishedAt'] = publishedAt != null
          ? Timestamp.fromDate(publishedAt)
          : FieldValue.serverTimestamp();
    }
    if (newStatus == AlertStatus.resolved) {
      payload['resolvedAt'] = resolvedAt != null
          ? Timestamp.fromDate(resolvedAt)
          : FieldValue.serverTimestamp();
    }
    batch.update(ref, payload);

    final updateRef = _updatesFor(alertId).doc();
    batch.set(updateRef, AlertUpdate(
      id: updateRef.id,
      alertId: alertId,
      message: message,
      previousStatus: previous.status,
      newStatus: newStatus,
      createdAt: DateTime.now(),
      createdBy: adminUid,
      sourceType: SourceType.official,
    ).toDocument());

    // Audit record — readable only by admins / trusted backend per rules.
    final auditRef = _db.collection(AppConstants.adminAuditLogsCollection).doc();
    batch.set(auditRef, <String, dynamic>{
      'actorUid': adminUid,
      'action': 'alert_update_$newStatus',
      'targetType': 'alert',
      'targetId': alertId,
      'timestamp': FieldValue.serverTimestamp(),
      'details': {'message': message, 'fields': changedFields.keys.toList()},
    });

    await batch.commit();
  }

  Stream<List<AlertUpdate>> watchAlertUpdates(String alertId) {
    return _updatesFor(alertId)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => AlertUpdate.fromMap(alertId, d.id, d.data()))
            .toList());
  }

  /// Alerts with coordinates for the map screen (public statuses only).
  Future<List<Alert>> fetchMappedAlerts({int limit = 100}) async {
    final snap = await _alerts
        .where('latitude', isNotEqualTo: null)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map(Alert.fromDoc)
        .where((a) => a.status.isPublicVisible && a.hasCoordinates)
        .toList();
  }

  void _validateLengths(String title, String description, String location) {
    if (title.trim().isEmpty ||
        title.trim().length > AppConstants.maxTitleLength) {
      throw ValidationException(
          'Title must be 1–${AppConstants.maxTitleLength} characters.');
    }
    if (description.trim().length < 10 ||
        description.trim().length > AppConstants.maxDescriptionLength) {
      throw ValidationException(
          'Description must be 10–${AppConstants.maxDescriptionLength} characters.');
    }
    if (location.trim().isEmpty ||
        location.trim().length > AppConstants.maxLocationNameLength) {
      throw ValidationException(
          'Location must be 1–${AppConstants.maxLocationNameLength} characters.');
    }
  }
}
