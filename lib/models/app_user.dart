import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/alert_constants.dart';

/// User role. Only trusted backend operations (Cloud Functions / console)
/// may grant [UserRole.admin]. Clients cannot self-promote; this is enforced
/// by Firestore Security Rules.
enum UserRole {
  user,
  admin;

  static UserRole fromWire(String? value) =>
      value == 'admin' ? UserRole.admin : UserRole.user;
}

enum AccountStatus {
  active,
  suspended;

  static AccountStatus fromWire(String? value) =>
      value == 'suspended' ? AccountStatus.suspended : AccountStatus.active;
}

/// Application user profile stored in `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.preferredTown,
    this.preferredArea,
    this.selectedCategories = const <AlertCategory>{},
    this.notificationEnabled = true,
    this.role = UserRole.user,
    this.accountStatus = AccountStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? preferredTown;
  final String? preferredArea;
  final Set<AlertCategory> selectedCategories;
  final bool notificationEnabled;
  final UserRole role;
  final AccountStatus accountStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == UserRole.admin && accountStatus == AccountStatus.active;

  AppUser copyWith({
    String? displayName,
    String? email,
    String? preferredTown,
    String? preferredArea,
    Set<AlertCategory>? selectedCategories,
    bool? notificationEnabled,
    UserRole? role,
    AccountStatus? accountStatus,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      preferredTown: preferredTown ?? this.preferredTown,
      preferredArea: preferredArea ?? this.preferredArea,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static AppUser fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      displayName: (map['displayName'] as String?) ?? 'Namibia resident',
      email: (map['email'] as String?) ?? '',
      preferredTown: map['preferredTown'] as String?,
      preferredArea: map['preferredArea'] as String?,
      selectedCategories: ((map['selectedCategories'] as List<dynamic>?) ?? const <dynamic>[])
          .map((e) => AlertCategory.fromWire(e as String?))
          .toSet(),
      notificationEnabled: (map['notificationEnabled'] as bool?) ?? true,
      role: UserRole.fromWire(map['role'] as String?),
      accountStatus: AccountStatus.fromWire(map['accountStatus'] as String?),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  /// Fields writable by the client itself. Note the deliberate absence of
  /// `role` and `accountStatus` — those are protected by security rules.
  Map<String, dynamic> toWritableClientFields() {
    return <String, dynamic>{
      'displayName': displayName,
      'preferredTown': preferredTown,
      'preferredArea': preferredArea,
      'selectedCategories': selectedCategories.map((c) => c.wireName).toList(),
      'notificationEnabled': notificationEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Full document shape, used when creating the profile at registration.
  Map<String, dynamic> toCreateDocument() {
    return <String, dynamic>{
      'displayName': displayName,
      'email': email,
      'preferredTown': preferredTown,
      'preferredArea': preferredArea,
      'selectedCategories': selectedCategories.map((c) => c.wireName).toList(),
      'notificationEnabled': notificationEnabled,
      'role': role.name, // always 'user' at creation; enforced again by rules
      'accountStatus': accountStatus.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse(value.toString());
  }
}
