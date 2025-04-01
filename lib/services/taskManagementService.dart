import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/taskModel.dart';
import '../models/userModel.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new task (only for admin/users)
  Future<void> createTask(UserModel currentUser, TaskModel task) async {
    if (!currentUser.canManageTasks) {
      throw Exception('Only admin users can create tasks');
    }

    try {
      task.createdBy = currentUser.id;

      await _firestore.collection('tasks').add(task.toFirestore());
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    }
  }

  // Get tasks based on user role
  Stream<List<TaskModel>> getTasks(UserModel currentUser) {
    Query tasksQuery = _firestore.collection('tasks');

    // If user is not an admin, only show tasks assigned to them
    if (currentUser.role == UserRole.user) {
      tasksQuery = tasksQuery.where('assignedMembers', arrayContains: currentUser.id);
    }

    return tasksQuery
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TaskModel.fromFirestore(doc))
        .toList());
  }

  // Update a task (only for admin)
  Future<void> updateTask(UserModel currentUser, TaskModel task) async {
    if (!currentUser.canManageTasks) {
      throw Exception('Only admins can update tasks');
    }

    try {
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestore());
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  // Delete a task (only for admin/users)
  Future<void> deleteTask(UserModel currentUser, String taskId) async {
    if (!currentUser.canManageTasks) {
      throw Exception('Only admins can delete tasks');
    }

    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // Mark task as completed
  Future<void> markTaskCompleted(UserModel currentUser, String taskId, bool isCompleted) async {
    try {
      DocumentSnapshot taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      TaskModel task = TaskModel.fromFirestore(taskDoc);

      if (currentUser.role == UserRole.admin ||
          task.assignedMembers.contains(currentUser.id)) {
        await _firestore
            .collection('tasks')
            .doc(taskId)
            .update({
          'isCompleted': isCompleted,
          'updatedAt': Timestamp.now()
        });
      } else {
        throw Exception('You are not authorized to update this task');
      }
    } catch (e) {
      debugPrint('Error marking task completed: $e');
      rethrow;
    }
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