import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyBgEV6EKE6zuyyb-tcbsEh9HAZx_-mgViw',
    appId: '1:36326457292:web:08286c6810f512be28a769',
    messagingSenderId: '36326457292',
    projectId: 'meu-rebanho-leiteiro',
    authDomain: 'meu-rebanho-leiteiro.firebaseapp.com',
    storageBucket: 'meu-rebanho-leiteiro.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXCQBqn_I_WyXT5AnSAhDQY4-1QSRdB-E',
    appId: '1:36326457292:android:2931cf47866c6e9528a769',
    messagingSenderId: '36326457292',
    projectId: 'meu-rebanho-leiteiro',
    storageBucket: 'meu-rebanho-leiteiro.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDFxy6vqqoW2Lju1MyD1PETKZRrUWgKJyc',
    appId: '1:36326457292:ios:ebcd9d0655841bab28a769',
    messagingSenderId: '36326457292',
    projectId: 'meu-rebanho-leiteiro',
    storageBucket: 'meu-rebanho-leiteiro.firebasestorage.app',
    iosBundleId: 'com.example.untitled',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDFxy6vqqoW2Lju1MyD1PETKZRrUWgKJyc',
    appId: '1:36326457292:ios:ebcd9d0655841bab28a769',
    messagingSenderId: '36326457292',
    projectId: 'meu-rebanho-leiteiro',
    storageBucket: 'meu-rebanho-leiteiro.firebasestorage.app',
    iosBundleId: 'com.example.untitled',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBgEV6EKE6zuyyb-tcbsEh9HAZx_-mgViw',
    appId: '1:36326457292:web:3097e803d5e24e4b28a769',
    messagingSenderId: '36326457292',
    projectId: 'meu-rebanho-leiteiro',
    authDomain: 'meu-rebanho-leiteiro.firebaseapp.com',
    storageBucket: 'meu-rebanho-leiteiro.firebasestorage.app',
  );
}