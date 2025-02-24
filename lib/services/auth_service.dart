import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static String get userEmail => _auth.currentUser?.email ?? 'Unknown';

  static void signUserOut() {
    _auth.signOut();
  }
}
