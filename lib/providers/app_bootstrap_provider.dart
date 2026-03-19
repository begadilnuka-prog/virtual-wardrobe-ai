import 'package:flutter/foundation.dart';

import '../services/firebase_service.dart';

class AppBootstrapProvider extends ChangeNotifier {
  bool isInitializing = true;
  bool firebaseEnabled = false;

  Future<void> initialize() async {
    firebaseEnabled = await FirebaseService.initialize();
    isInitializing = false;
    notifyListeners();
  }
}
