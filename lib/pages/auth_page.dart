import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phi_app/components/login_or_register.dart';
import 'package:phi_app/pages/home_page.dart';
import 'package:provider/provider.dart';
import '../models/userModel.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Future<UserModel?> _fetchUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return UserModel(
          id: userDoc.id,
          email: userDoc['email'] ?? '',
          name: userDoc['name'] ?? '',
          role: UserModel.parseUserRole(userDoc['role'] ?? 'user'),
          createdAt: userDoc['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(userDoc['createdAt'])
              : null,
        );
      } else {
        throw Exception('User document does not exist.');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //if user logged in
          if (snapshot.hasData) {
            final firebaseUser = snapshot.data;

            return FutureBuilder<UserModel?>(
              future: _fetchUserData(firebaseUser!.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasData) {
                  final user = Provider.of<UserModel>(context, listen: false);
                  final fetchedUser = userSnapshot.data!;
                  user.id = fetchedUser.id;
                  user.email = fetchedUser.email;
                  user.name = fetchedUser.name;
                  user.role = fetchedUser.role;
                  user.createdAt = fetchedUser.createdAt;

                  user.notifyListeners();

                  return HomePage();
                } else {
                  return const Center(
                    child: Text('Error fetching user data.'),
                  );
                }
              },
            );
          } else {
            // if user not logged in
            return LoginOrRegister();
          }
        },
      ),
    );
  }
}
