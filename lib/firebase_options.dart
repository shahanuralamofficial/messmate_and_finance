import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCrHYb--3qb8DUctbG-NlK_1QfOaGKAg2M',
    appId: '1:284024850519:android:225bf2f10539876280bb12',
    messagingSenderId: '284024850519',
    projectId: 'finance-manager-b3e38',
    storageBucket: 'finance-manager-b3e38.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrHYb--3qb8DUctbG-NlK_1QfOaGKAg2M',
    appId: '1:284024850519:ios:your_ios_app_id', // Update this if you have iOS config
    messagingSenderId: '284024850519',
    projectId: 'finance-manager-b3e38',
    storageBucket: 'finance-manager-b3e38.firebasestorage.app',
    iosBundleId: 'com.example.financeManager',
  );
}
