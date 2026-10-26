import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/constants/alert_constants.dart';
import '../models/alert.dart';
import '../repositories/device_token_repository.dart';

/// Top-level background/terminated handler. Must be a top-level function and
/// is registered via FirebaseMessaging.onBackgroundMessage in main.dart.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase core is initialised by the plugin in the background isolate.
  debugPrint('[FCM] background message received id=${message.messageId}');
}

/// Handles FCM token registration, permission prompts, foreground display of
/// notifications and tap-to-alert navigation.
class FcmService {
  FcmService({
    FirebaseMessaging? messaging,
    DeviceTokenRepository? tokens,
    FlutterLocalNotificationsPlugin? local,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _tokens = tokens ?? DeviceTokenRepository(),
        _local = local ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final DeviceTokenRepository _tokens;
  final FlutterLocalNotificationsPlugin _local;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<NotificationResponse>? _tapSub;

  String? _currentToken;

  /// Callback invoked when the user taps a notification that contains an
  /// alert id. Wired to the router by the app layer.
  void Function(String alertId)? onNotificationTap;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'namalert_alerts',
    'Service Alerts',
    description: 'Water, electricity, internet and road alerts for Namibia.',
    importance: Importance.high,
  );

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Registers push handling and stores the device token against [userId].
  Future<void> initForUser(String userId) async {
    if (!isSupported) return;

    await _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _local.initialize(init, onDidReceiveNotificationResponse: _onResponse);

    _foregroundSub ??=
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _tapSub ??= FirebaseMessaging.onMessageOpenedApp
        .listen((m) => _dispatchTap(m.data['alertId']?.toString()));

    final token = await _messaging.getToken();
    if (token != null) {
      _currentToken = token;
      try {
        await _tokens.register(
          userId: userId,
          token: token,
          platform: Platform.isAndroid ? 'android' : 'ios',
        );
      } catch (e) {
        debugPrint('[FCM] token registration failed: $e');
      }
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      _currentToken = newToken;
      try {
        await _tokens.register(
          userId: userId,
          token: newToken,
          platform: Platform.isAndroid ? 'android' : 'ios',
        );
      } catch (e) {
        debugPrint('[FCM] token refresh registration failed: $e');
      }
    });

    // Handle cold-start tap (app opened from a terminated state).
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _dispatchTap(initial.data['alertId']?.toString());
    }
  }

  /// Removes this device's token association on logout.
  Future<void> unregister() async {
    final token = _currentToken;
    if (token != null) {
      try {
        await _tokens.removeToken(token);
      } catch (e) {
        debugPrint('[FCM] unregister failed: $e');
      }
    }
    try {
      await _messaging.deleteToken();
    } catch (_) {}
    _currentToken = null;
  }

  void dispose() {
    _foregroundSub?.cancel();
    _tapSub?.cancel();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    // Android does not always display pushes while foregrounded; present
    // them through the local-notification plugin on the configured channel.
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'namalert_alerts',
          'Service Alerts',
          channelDescription: 'Water, electricity, internet and road alerts.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['alertId']?.toString(),
    );
  }

  void _onResponse(NotificationResponse response) {
    _dispatchTap(response.payload);
  }

  void _dispatchTap(String? alertId) {
    if (alertId == null || alertId.isEmpty) return;
    onNotificationTap?.call(alertId);
  }

  /// Marks the current token inactive after an FCM send failure such as
  /// Unregistered or InvalidArgument (used by cleanup flows/tests).
  Future<void> markCurrentTokenInvalid() async {
    final token = _currentToken;
    if (token == null) return;
    try {
      await _tokens.markInactive(token);
    } catch (e) {
      debugPrint('[FCM] could not mark token inactive: $e');
    }
  }
}

/// Convenience for building notification copy from an alert.
String notificationTitleFor(Alert alert) =>
    '${alert.category.notificationPrefix} — ${alert.locationName}';

String notificationBodyFor(Alert alert) => switch (alert.category) {
      AlertCategory.water =>
        'Water supply interruption reported in ${alert.locationName}.',
      AlertCategory.electricity =>
        'A verified electricity outage affects ${alert.locationName}.',
      AlertCategory.internet =>
        'An internet service interruption has been reported in ${alert.locationName}.',
      AlertCategory.roads =>
        'A road closure or obstruction affects ${alert.locationName}.',
    };
