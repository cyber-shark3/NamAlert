/// Application-level exception types with user-safe messages.
class AppException implements Exception {
  const AppException(this.message, {this.detail});

  /// Message safe to show to an end user.
  final String message;

  /// Optional developer-facing detail (never contains secrets).
  final String? detail;

  @override
  String toString() => 'AppException: $message${detail != null ? ' ($detail)' : ''}';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.detail});
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection. Check your network and try again.', super.detail]);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'You do not have permission to perform this action.', super.detail]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested item was not found.', super.detail]);
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.detail});
}

class FirebaseConfigException extends AppException {
  const FirebaseConfigException([
    super.message = 'Firebase is not configured on this build. Run "flutterfire configure" for the real project.',
    super.detail,
  ]);
}

/// Maps raw FirebaseAuth/Firestore error strings into user-safe messages.
String friendlyAuthError(String code, [String? fallback]) {
  switch (code) {
    case 'weak-password':
      return 'The password is too weak. Use at least 8 characters.';
    case 'email-already-in-use':
      return 'An account already exists for that email address.';
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'requires-recent-login':
      return 'Please sign in again before changing this setting.';
    default:
      return fallback ?? 'Authentication failed. Please try again.';
  }
}
