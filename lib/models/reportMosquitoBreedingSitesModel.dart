import 'package:cloud_firestore/cloud_firestore.dart';

class ReportMosquitoBreedingSiteModel {
  String? id;
  String headName;
  String address;
  DateTime reportedDate;
  GeoPoint location;
  bool legalAction;
  List<String> photoUrls;
  String notes;
  String reportedBy;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  ReportMosquitoBreedingSiteModel({
    this.id,
    required this.headName,
    required this.address,
    required this.reportedDate,
    required this.location,
    this.legalAction = false,
    this.photoUrls = const [],
    this.notes = '',
    required this.reportedBy,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Firestore document to ReportMosquitoBreedingSiteModel
  factory ReportMosquitoBreedingSiteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Conversion from single photoUrl to photoUrls list
    List<String> photos = [];
    if (data['photoUrls'] != null) {
      photos = List<String>.from(data['photoUrls']);
    } else if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
      photos = [data['photoUrl']];
    }

    return ReportMosquitoBreedingSiteModel(
      id: doc.id,
      headName: data['headName'] ?? '',
      address: data['address'] ?? '',
      reportedDate: (data['reportedDate'] as Timestamp).toDate(),
      location: data['location'] ?? GeoPoint(0, 0),
      legalAction: data['legalAction'] ?? false,
      photoUrls: photos,
      notes: data['notes'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Convert ReportMosquitoBreedingSiteModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'headName': headName,
      'address': address,
      'reportedDate': Timestamp.fromDate(reportedDate),
      'location': location,
      'legalAction': legalAction,
      'photoUrls': photoUrls, // Store as array in Firestore
      'notes': notes,
      'reportedBy': reportedBy,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  // Method to create a copy with optional updates
  ReportMosquitoBreedingSiteModel copyWith({
    String? id,
    String? headName,
    String? address,
    DateTime? reportedDate,
    GeoPoint? location,
    bool? legalAction,
    List<String>? photoUrls,
    String? notes,
    String? reportedBy,
  }) {
    return ReportMosquitoBreedingSiteModel(
      id: id ?? this.id,
      headName: headName ?? this.headName,
      address: address ?? this.address,
      reportedDate: reportedDate ?? this.reportedDate,
      location: location ?? this.location,
      legalAction: legalAction ?? this.legalAction,
      photoUrls: photoUrls ?? this.photoUrls,
      notes: notes ?? this.notes,
      reportedBy: reportedBy ?? this.reportedBy,
      createdAt: this.createdAt,
      updatedAt: Timestamp.now(),
    );
  }

  // Add a new image URL to the list
  ReportMosquitoBreedingSiteModel addPhotoUrl(String url) {
    List<String> newPhotoUrls = List.from(photoUrls);
    newPhotoUrls.add(url);
    return copyWith(photoUrls: newPhotoUrls);
  }

  // Remove an image URL from the list
  ReportMosquitoBreedingSiteModel removePhotoUrl(String url) {
    List<String> newPhotoUrls = List.from(photoUrls);
    newPhotoUrls.remove(url);
    return copyWith(photoUrls: newPhotoUrls);
  }
}