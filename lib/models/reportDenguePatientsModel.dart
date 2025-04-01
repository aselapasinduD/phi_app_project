import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDenguePatientModel {
  String? id;
  String address;
  GeoPoint location;
  int numberOfPatients;
  DateTime reportedDate;
  int hospitalized;
  String notes;
  String reportedBy;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  ReportDenguePatientModel({
    this.id,
    required this.address,
    required this.location,
    required this.numberOfPatients,
    required this.reportedDate,
    required this.hospitalized,
    this.notes = '',
    required this.reportedBy,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Firestore document to ReportDenguePatientModel
  factory ReportDenguePatientModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReportDenguePatientModel(
      id: doc.id,
      address: data['address'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      numberOfPatients: data['numberOfPatients'] ?? 0,
      reportedDate: (data['reportedDate'] as Timestamp).toDate(),
      hospitalized: data['hospitalized'] ?? 0,
      notes: data['notes'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Convert ReportDenguePatientModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'address': address,
      'location': location,
      'numberOfPatients': numberOfPatients,
      'reportedDate': Timestamp.fromDate(reportedDate),
      'hospitalized': hospitalized,
      'notes': notes,
      'reportedBy': reportedBy,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  // Method to create a copy with optional updates
  ReportDenguePatientModel copyWith({
    String? id,
    String? address,
    GeoPoint? location,
    int? numberOfPatients,
    DateTime? reportedDate,
    int? hospitalized,
    String? notes,
    String? reportedBy,
  }) {
    return ReportDenguePatientModel(
      id: id ?? this.id,
      address: address ?? this.address,
      location: location ?? this.location,
      numberOfPatients: numberOfPatients ?? this.numberOfPatients,
      reportedDate: reportedDate ?? this.reportedDate,
      hospitalized: hospitalized ?? this.hospitalized,
      notes: notes ?? this.notes,
      reportedBy: reportedBy ?? this.reportedBy,
      createdAt: this.createdAt,
      updatedAt: Timestamp.now(),
    );
  }
}