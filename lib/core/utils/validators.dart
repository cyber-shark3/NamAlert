import '../constants/app_constants.dart';

/// Pure input-validation helpers used by forms and services.
class Validators {
  Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$');

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required.';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address.';
    if (v.length > 254) return 'Email address is too long.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (v.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static String? displayName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Display name is required.';
    if (v.length < 2) return 'Display name must be at least 2 characters.';
    if (v.length > AppConstants.maxDisplayNameLength) {
      return 'Display name must be under ${AppConstants.maxDisplayNameLength} characters.';
    }
    return null;
  }

  static String? alertTitle(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Title is required.';
    if (v.length < 5) return 'Title must be at least 5 characters.';
    if (v.length > AppConstants.maxTitleLength) {
      return 'Title must be under ${AppConstants.maxTitleLength} characters.';
    }
    return null;
  }

  static String? alertDescription(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Description is required.';
    if (v.length < 10) return 'Please describe the incident in at least 10 characters.';
    if (v.length > AppConstants.maxDescriptionLength) {
      return 'Description must be under ${AppConstants.maxDescriptionLength} characters.';
    }
    return null;
  }

  static String? locationName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Location is required.';
    if (v.length > AppConstants.maxLocationNameLength) {
      return 'Location must be under ${AppConstants.maxLocationNameLength} characters.';
    }
    return null;
  }

  static String? optionalLatitude(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final d = double.tryParse(v);
    if (d == null || d < -90 || d > 90) return 'Latitude must be between -90 and 90.';
    return null;
  }

  static String? optionalLongitude(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final d = double.tryParse(v);
    if (d == null || d < -180 || d > 180) return 'Longitude must be between -180 and 180.';
    return null;
  }

  /// Namibia spans roughly latitude -18 to -29 and longitude 11 to 25.
  /// Used only as a soft sanity hint, never a hard rejection.
  static bool looksLikeNamibia(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -29.5 && lat <= -16.5 && lng >= 10.5 && lng <= 25.5;
  }
}
