import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/alert_constants.dart';

/// A public alert or user-submitted report stored in `alerts/{id}`.
class Alert {
  const Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.locationName,
    required this.status,
    required this.severity,
    required this.verificationStatus,
    required this.sourceType,
    this.town,
    this.area,
    this.latitude,
    this.longitude,
    this.sourceReference,
    this.reportedBy,
    this.publishedBy,
    this.imageUrl,
    this.incidentStartAt,
    this.publishedAt,
    this.expectedResolutionAt,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final AlertCategory category;
  final String locationName;
  final String? town;
  final String? area;
  final double? latitude;
  final double? longitude;
  final AlertStatus status;
  final AlertSeverity severity;
  final VerificationStatus verificationStatus;
  final SourceType sourceType;
  final String? sourceReference;
  final String? reportedBy;
  final String? publishedBy;
  final String? imageUrl;
  final DateTime? incidentStartAt;
  final DateTime? publishedAt;
  final DateTime? expectedResolutionAt;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Whether this is presented as confirmed official information.
  bool get isOfficial =>
      verificationStatus == VerificationStatus.official && status.isPublicVisible;

  bool get isResolved => status == AlertStatus.resolved;

  Alert copyWith({
    String? title,
    String? description,
    AlertCategory? category,
    String? locationName,
    String? town,
    String? area,
    double? latitude,
    double? longitude,
    AlertStatus? status,
    AlertSeverity? severity,
    VerificationStatus? verificationStatus,
    SourceType? sourceType,
    String? sourceReference,
    String? publishedBy,
    String? imageUrl,
    DateTime? incidentStartAt,
    DateTime? publishedAt,
    DateTime? expectedResolutionAt,
    DateTime? resolvedAt,
    DateTime? updatedAt,
  }) {
    return Alert(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      locationName: locationName ?? this.locationName,
      town: town ?? this.town,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      sourceType: sourceType ?? this.sourceType,
      sourceReference: sourceReference ?? this.sourceReference,
      reportedBy: reportedBy,
      publishedBy: publishedBy ?? this.publishedBy,
      imageUrl: imageUrl ?? this.imageUrl,
      incidentStartAt: incidentStartAt ?? this.incidentStartAt,
      publishedAt: publishedAt ?? this.publishedAt,
      expectedResolutionAt: expectedResolutionAt ?? this.expectedResolutionAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Alert fromMap(String id, Map<String, dynamic> map) {
    return Alert(
      id: id,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      category: AlertCategory.fromWire(map['category'] as String?),
      locationName: (map['locationName'] as String?) ?? '',
      town: map['town'] as String?,
      area: map['area'] as String?,
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      status: AlertStatus.fromWire(map['status'] as String?),
      severity: AlertSeverity.fromWire(map['severity'] as String?),
      verificationStatus:
          VerificationStatus.fromWire(map['verificationStatus'] as String?),
      sourceType: SourceType.fromWire(map['sourceType'] as String?),
      sourceReference: map['sourceReference'] as String?,
      reportedBy: map['reportedBy'] as String?,
      publishedBy: map['publishedBy'] as String?,
      imageUrl: map['imageUrl'] as String?,
      incidentStartAt: _toDate(map['incidentStartAt']),
      publishedAt: _toDate(map['publishedAt']),
      expectedResolutionAt: _toDate(map['expectedResolutionAt']),
      resolvedAt: _toDate(map['resolvedAt']),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  factory Alert.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Alert.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  /// Document written when an authenticated user submits a report.
  /// Status is fixed to pending_review and verification to communityReported.
  static Map<String, dynamic> reportToDocument({
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
  }) {
    return <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'category': category.wireName,
      'locationName': locationName.trim(),
      'town': town?.trim(),
      'area': area?.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'status': AlertStatus.pendingReview.wireName,
      'severity': AlertSeverity.medium.name, // default until reviewed
      'verificationStatus': VerificationStatus.communityReported.name,
      'sourceType': SourceType.userReport.name,
      'sourceReference': null,
      'reportedBy': reportedByUid,
      'publishedBy': null,
      'imageUrl': imageUrl,
      'incidentStartAt': incidentStartAt == null
          ? null
          : Timestamp.fromDate(incidentStartAt),
      'publishedAt': null,
      'expectedResolutionAt': null,
      'resolvedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse(value.toString());
  }
}
