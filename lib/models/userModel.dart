import 'package:flutter/foundation.dart';

enum UserRole {
  user,
  admin
}

class UserModel extends ChangeNotifier {
  String id;
  String email;
  String name;
  UserRole role;
  DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.user,
    this.createdAt
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: parseUserRole(data['role'] ?? 'user'),
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : null
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  // Helper method to parse user roles
  static UserRole parseUserRole(String roleString) {
    switch (roleString) {
      case 'user':
        return UserRole.user;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  // Permissions methods
  bool get canManageTasks => role == UserRole.admin;
  bool get canViewFumigationTasks => role == UserRole.admin || role == UserRole.user;
  bool get canCreateDengueReports => role == UserRole.admin || role == UserRole.user;
  bool get canCreateBreedingReports => role == UserRole.admin || role == UserRole.user;
  bool get canCreateBreedingAndDengueReports => role == UserRole.admin || role == UserRole.user;
  bool get canUpdateReports => role == UserRole.admin;
  bool get canDeleteReports => role == UserRole.admin;
  bool get canUpdateAndDeleteReports => role == UserRole.admin;
}