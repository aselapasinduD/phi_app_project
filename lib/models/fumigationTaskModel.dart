import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/weatherService.dart';

class FumigationTaskModel {
  String? id;
  String title;
  String address;
  GeoPoint location;
  DateTime scheduledDateTime;
  List<String> assignedMembers;
  bool isCompleted;
  String createdBy;
  String? notes;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  FumigationTaskModel({
    this.id,
    required this.title,
    required this.address,
    required this.location,
    required this.scheduledDateTime,
    this.assignedMembers = const [],
    this.isCompleted = false,
    required this.createdBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Firestore document to FumigationTaskModel
  factory FumigationTaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FumigationTaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      scheduledDateTime: (data['scheduledDateTime'] as Timestamp).toDate(),
      assignedMembers: List<String>.from(data['assignedMembers'] ?? []),
      isCompleted: data['isCompleted'] ?? false,
      createdBy: data['createdBy'] ?? '',
      notes: data['notes'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Convert FumigationTaskModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'address': address,
      'location': location,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'assignedMembers': assignedMembers,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'notes': notes,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  // Method to get weather info for every fumigation task
  Future<WeatherData> getWeatherInfo() async {
    final weatherData = await WeatherService.getWeatherForecast(location, scheduledDateTime);
    return weatherData;
  }

  // Method to create a copy with optional updates
  FumigationTaskModel copyWith({
    String? id,
    String? title,
    String? address,
    GeoPoint? location,
    DateTime? scheduledDateTime,
    String? weatherForecast,
    List<String>? assignedMembers,
    bool? isCompleted,
    String? createdBy,
    String? notes,
  }) {
    return FumigationTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      location: location ?? this.location,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      assignedMembers: assignedMembers ?? this.assignedMembers,
      isCompleted: isCompleted ?? this.isCompleted,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      createdAt: this.createdAt,
    );
  }
}