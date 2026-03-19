import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<bool> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
