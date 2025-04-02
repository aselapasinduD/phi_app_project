import 'package:cloud_firestore/cloud_firestore.dart';

class GISMapData {
  final String id;
  final String title;
  final String address;
  final GeoPoint location;
  final String type; // 'patient', 'fumigation', 'breeding'
  final DateTime date;
  final Map<String, dynamic> additionalData;

  GISMapData({
    required this.id,
    required this.title,
    required this.address,
    required this.location,
    required this.type,
    required this.date,
    this.additionalData = const {},
  });
}

class GeographicInformationSystemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all dengue patient locations
  Future<List<GISMapData>> getDenguePatientLocations(DateTime? startDate, DateTime? endDate) async {
    try {
      Query query = _firestore.collection('denguePatientReports');

      if (startDate != null && endDate != null) {
        query = query
            .where('reportedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('reportedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GISMapData(
          id: doc.id,
          title: 'Dengue Patient(s)',
          address: data['address'] ?? 'Unknown location',
          location: data['location'] as GeoPoint,
          type: 'patient',
          date: (data['reportedDate'] as Timestamp).toDate(),
          additionalData: {
            'numberOfPatients': data['numberOfPatients'] ?? 1,
            'hospitalized': data['hospitalized'] ?? 0,
            'notes': data['notes'] ?? '',
          },
        );
      }).toList();
    } catch (e) {
      print('Error getting dengue patient locations: $e');
      return [];
    }
  }

  // Get all fumigation locations
  Future<List<GISMapData>> getFumigationLocations(DateTime? startDate, DateTime? endDate) async {
    try {
      Query query = _firestore.collection('fumigations');

      if (startDate != null && endDate != null) {
        query = query
            .where('scheduledDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('scheduledDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GISMapData(
          id: doc.id,
          title: data['title'] ?? 'Fumigation Task',
          address: data['address'] ?? 'Unknown location',
          location: data['location'] as GeoPoint,
          type: 'fumigation',
          date: (data['scheduledDateTime'] as Timestamp).toDate(),
          additionalData: {
            'isCompleted': data['isCompleted'] ?? false,
            'notes': data['notes'] ?? '',
            'weatherForecast': data['weatherForecast'] ?? '',
          },
        );
      }).toList();
    } catch (e) {
      print('Error getting fumigation locations: $e');
      return [];
    }
  }

  // Get all breeding site locations
  Future<List<GISMapData>> getBreedingSiteLocations(DateTime? startDate, DateTime? endDate) async {
    try {
      Query query = _firestore.collection('mosquitoBreedingSiteReports');

      if (startDate != null && endDate != null) {
        query = query
            .where('reportedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('reportedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GISMapData(
          id: doc.id,
          title: 'Breeding Site - ${data['headName'] ?? 'Unknown'}',
          address: data['address'] ?? 'Unknown location',
          location: data['location'] as GeoPoint,
          type: 'breeding',
          date: (data['reportedDate'] as Timestamp).toDate(),
          additionalData: {
            'headName': data['headName'] ?? '',
            'legalAction': data['legalAction'] ?? false,
            'notes': data['notes'] ?? '',
            'hasPhotos': (data['photoUrls'] as List<dynamic>?)?.isNotEmpty ?? false,
          },
        );
      }).toList();
    } catch (e) {
      print('Error getting breeding site locations: $e');
      return [];
    }
  }

  // Get all map data (all types) filtered by date range
  Future<Map<String, List<GISMapData>>> getAllMapData(DateTime? startDate, DateTime? endDate) async {
    final patients = await getDenguePatientLocations(startDate, endDate);
    final fumigations = await getFumigationLocations(startDate, endDate);
    final breedingSites = await getBreedingSiteLocations(startDate, endDate);

    return {
      'patients': patients,
      'fumigations': fumigations,
      'breeding': breedingSites,
    };
  }

  // Get heatmap data for dengue cases
  Future<List<Map<String, dynamic>>> getDengueCasesHeatMap(DateTime? startDate, DateTime? endDate) async {
    try {
      Query query = _firestore.collection('denguePatientReports');

      if (startDate != null && endDate != null) {
        query = query
            .where('reportedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('reportedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final GeoPoint location = data['location'] as GeoPoint;
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'weight': data['numberOfPatients'] ?? 1,
        };
      }).toList();
    } catch (e) {
      print('Error getting dengue heatmap data: $e');
      return [];
    }
  }
}