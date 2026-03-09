import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }

      // Initialize local notifications for foreground
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(initializationSettings);

      // Setup foreground notification handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'mess_updates',
                'Mess Updates',
                channelDescription: 'Notifications for meal and expense updates',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Save token to Firestore to target this user later
  static Future<void> saveTokenToDatabase(String userId) async {
    String? token = await getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Logic to subscribe to mess-specific topics
  static Future<void> subscribeToMess(String messId) async {
    await _messaging.subscribeToTopic('mess_$messId');
  }

  static Future<void> unsubscribeFromMess(String messId) async {
    await _messaging.unsubscribeFromTopic('mess_$messId');
  }
}
