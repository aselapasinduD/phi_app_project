import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String? id;
  String title;
  String description;
  DateTime dueDate;
  GeoPoint? location;
  String? address;
  List<String> assignedMembers;
  bool isCompleted;
  String createdBy;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.location,
    this.address,
    this.assignedMembers = const [],
    this.isCompleted = false,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Firestore document to TaskModel
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      location: data['location'] != null ? data['location'] as GeoPoint : null,
      address: data['address'],
      assignedMembers: List<String>.from(data['assignedMembers'] ?? []),
      isCompleted: data['isCompleted'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Convert TaskModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'location': location,
      'address': address,
      'assignedMembers': assignedMembers,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  // Method to create a copy with optional updates
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    GeoPoint? location,
    String? address,
    List<String>? assignedMembers,
    bool? isCompleted,
    String? createdBy,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      location: location ?? this.location,
      address: address ?? this.address,
      assignedMembers: assignedMembers ?? this.assignedMembers,
      isCompleted: isCompleted ?? this.isCompleted,
      createdBy: createdBy ?? this.createdBy,
      createdAt: this.createdAt,
    );
  }
}
