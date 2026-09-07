import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAyr11RAmmgEsTkb49pZJQhxeWPN7niFoY',
    appId: '1:135465818327:web:30dd94ef2b70796970f892',
    messagingSenderId: '135465818327',
    projectId: 'bbs-gold',
    storageBucket: 'bbs-gold.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyr11RAmmgEsTkb49pZJQhxeWPN7niFoY',
    appId: '1:135465818327:android:30dd94ef2b70796970f892',
    messagingSenderId: '135465818327',
    projectId: 'bbs-gold',
    storageBucket: 'bbs-gold.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDu6mp83RFS8cPIjSzM80HZDBMQzSL2JOg',
    appId: '1:135465818327:ios:ea6a2de79614b80c70f892',
    messagingSenderId: '135465818327',
    projectId: 'bbs-gold',
    storageBucket: 'bbs-gold.firebasestorage.app',
    iosBundleId: 'com.shrisinnovations.bbsgold',
  );
}
