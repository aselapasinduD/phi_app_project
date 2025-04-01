import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/userModel.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'users';

  static Future<String?> getUserNameById(String userId) async {
    try {
      final DocumentSnapshot snapshot = await _firestore.collection(_collectionName).doc(userId).get();

      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final user = UserModel.fromFirestore(userData, snapshot.id);
        return user.name;
      }
      return null;
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }

  static Future<String?> getUserNameByIdOptimized(String userId) async {
    try {
      final DocumentSnapshot snapshot = await _firestore.collection(_collectionName).doc(userId).get(const GetOptions(source: Source.serverAndCache));

      return snapshot.get('name') as String?;
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }
}