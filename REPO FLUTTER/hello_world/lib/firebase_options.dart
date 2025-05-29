import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnDDDYqNpz2xYc8hhlnGIGEIDJ7pIx7rE',
    appId: '1:712174296076:android:f4d92ff59e0eb391afe229',
    messagingSenderId: '712174296076',
    projectId: 'iot-growing-app',
    storageBucket: 'iot-growing-app.firebasestorage.app',
    authDomain: 'iot-growing-app.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDnDDDYqNpz2xYc8hhlnGIGEIDJ7pIx7rE',
    appId: '1:712174296076:android:f4d92ff59e0eb391afe229',
    messagingSenderId: '712174296076',
    projectId: 'iot-growing-app',
    storageBucket: 'iot-growing-app.firebasestorage.app',
  );
}
