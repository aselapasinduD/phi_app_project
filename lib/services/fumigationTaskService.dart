import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/fumigationTaskModel.dart';
import '../models/userModel.dart';

class FumigationTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new fumigation task (only for admin)
  Future<void> createFumigationTask(UserModel currentUser, FumigationTaskModel fumigationTask) async {
    if (currentUser.role != UserRole.admin) {
      throw Exception('Only admin users can create fumigation tasks');
    }

    try {
      fumigationTask.createdBy = currentUser.id;
      await _firestore.collection('fumigations').add(fumigationTask.toFirestore());
    } catch (e) {
      debugPrint('Error creating fumigation task: $e');
      rethrow;
    }
  }

  // Get fumigation tasks based on user role
  Stream<List<FumigationTaskModel>> getFumigationTasks(UserModel currentUser) {
    Query fumigationQuery = _firestore.collection('fumigations');

    // If user is not an admin, only show tasks assigned to them
    if (currentUser.role == UserRole.user) {
      fumigationQuery = fumigationQuery.where('assignedMembers', arrayContains: currentUser.id);
    }

    return fumigationQuery
        .orderBy('scheduledDateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FumigationTaskModel.fromFirestore(doc))
        .toList());
  }

  // Update a fumigation task (only for admin)
  Future<void> updateFumigationTask(UserModel currentUser, FumigationTaskModel fumigationTask) async {
    if (currentUser.role != UserRole.admin) {
      throw Exception('Only admin users can update fumigation tasks');
    }

    try {
      await _firestore
          .collection('fumigations')
          .doc(fumigationTask.id)
          .update(fumigationTask.toFirestore());
    } catch (e) {
      debugPrint('Error updating fumigation task: $e');
      rethrow;
    }
  }

  // Delete a fumigation task (only for admin)
  Future<void> deleteFumigationTask(UserModel currentUser, String fumigationTaskId) async {
    if (currentUser.role != UserRole.admin) {
      throw Exception('Only admin users can delete fumigation tasks');
    }

    try {
      await _firestore.collection('fumigations').doc(fumigationTaskId).delete();
    } catch (e) {
      debugPrint('Error deleting fumigation task: $e');
      rethrow;
    }
  }

  // Mark fumigation task as completed
  Future<void> markFumigationTaskCompleted(UserModel currentUser, String fumigationTaskId, bool isCompleted) async {
    try {
      // Allow both admin and assigned members to mark as completed
      DocumentSnapshot fumigationDoc = await _firestore.collection('fumigations').doc(fumigationTaskId).get();
      FumigationTaskModel fumigationTask = FumigationTaskModel.fromFirestore(fumigationDoc);

      if (currentUser.role == UserRole.admin ||
          fumigationTask.assignedMembers.contains(currentUser.id)) {
        await _firestore
            .collection('fumigations')
            .doc(fumigationTaskId)
            .update({
          'isCompleted': isCompleted,
          'updatedAt': Timestamp.now()
        });
      } else {
        throw Exception('You are not authorized to update this fumigation task');
      }
    } catch (e) {
      debugPrint('Error marking fumigation task completed: $e');
      rethrow;
    }
  }

  // Fetch weather forecast (placeholder method - you'll need to integrate a weather API)
  Future<String> getWeatherForecast(GeoPoint location, DateTime dateTime) async {
    // Implement weather API integration here
    // For now, return a placeholder
    return 'Partly cloudy, Wind: 10 km/h, No rain expected';
  }

  // Get list of all users for task assignment (admin)
  Future<List<UserModel>> getUsersForTaskAssignment(UserModel currentUser) async {
    if (!currentUser.canManageTasks) {
      throw Exception('Only admin users can assign tasks');
    }

    try {
      QuerySnapshot userSnapshot = await _firestore.collection('users').get();
      return userSnapshot.docs
          .map((doc) => UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      rethrow;
    }
  }
}