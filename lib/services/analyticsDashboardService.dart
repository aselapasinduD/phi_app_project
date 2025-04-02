import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get count of dengue patients within date range
  Future<int> getDenguePatientCount(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('denguePatientReports')
          .where('reportedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('reportedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int totalPatients = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalPatients += (data['numberOfPatients'] as int? ?? 1);
      }

      return totalPatients;
    } catch (e) {
      print('Error getting dengue patient count: $e');
      return 0;
    }
  }

  // Get count of hospitalized dengue patients within date range
  Future<int> getHospitalizedDenguePatientCount(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('denguePatientReports')
          .where('reportedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('reportedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('hospitalized', isGreaterThan: 0)
          .get();

      int hospitalizedPatients = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        hospitalizedPatients += (data['numberOfPatients'] as int? ?? 1);
      }

      return hospitalizedPatients;
    } catch (e) {
      print('Error getting hospitalized patient count: $e');
      return 0;
    }
  }

  // Get count of completed fumigations within date range
  Future<int> getCompletedFumigationsCount(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('fumigations')
          .where('scheduledDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('scheduledDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('isCompleted', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting completed fumigations count: $e');
      return 0;
    }
  }

  // Get count of reported breeding sites within date range
  Future<int> getBreedingSitesCount(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('mosquitoBreedingSiteReports')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting breeding sites count: $e');
      return 0;
    }
  }

  // Get dengue patients data for graph
  Future<List<Map<String, dynamic>>> getDenguePatientDataForGraph(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('denguePatientReports')
          .where('reportedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('reportedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('reportedDate')
          .get();

      Map<String, int> dailyCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime date = (data['reportedDate'] as Timestamp).toDate();
        final String dateKey = DateFormat('yyyy-MM-dd').format(date);
        final int patientCount = data['numberOfPatients'] as int? ?? 1;

        dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + patientCount;
      }

      List<Map<String, dynamic>> graphData = dailyCounts.entries.map((entry) {
        return {
          'date': entry.key,
          'count': entry.value,
        };
      }).toList();

      graphData.sort((a, b) => a['date'].compareTo(b['date']));

      return graphData;
    } catch (e) {
      print('Error getting dengue patient data for graph: $e');
      return [];
    }
  }

  // Get hospitalized dengue patients data for graph
  Future<List<Map<String, dynamic>>> getHospitalizedDataForGraph(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('denguePatientReports')
          .where('reportedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('reportedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('hospitalized', isGreaterThan: 0)
          .orderBy('reportedDate')
          .get();

      Map<String, Map<String, int>> dailyData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime date = (data['reportedDate'] as Timestamp).toDate();
        final String dateKey = DateFormat('yyyy-MM-dd').format(date);
        final int hospitalizedTimes = data['hospitalized'] as int? ?? 1;
        final int patientCount = data['numberOfPatients'] as int? ?? 1; // I want to include the number of patiens also to show as status not in the graph

        // dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + hospitalizedTimes;

        if (dailyData.containsKey(dateKey)) {
          dailyData[dateKey]!['hospitalized'] = (dailyData[dateKey]!['hospitalized'] ?? 0) + hospitalizedTimes;
          dailyData[dateKey]!['patients'] = (dailyData[dateKey]!['patients'] ?? 0) + patientCount;
        } else {
          dailyData[dateKey] = {
            'hospitalized': hospitalizedTimes,
            'patients': patientCount,
          };
        }      }

      List<Map<String, dynamic>> graphData = dailyData.entries.map((entry) {
        return {
          'date': entry.key,
          'hospitalized': entry.value['hospitalized'],
          'patients': entry.value['patients'],
        };
      }).toList();

      graphData.sort((a, b) => a['date'].compareTo(b['date']));

      return graphData;
    } catch (e) {
      print('Error getting hospitalized patient data for graph: $e');
      return [];
    }
  }

  // Get breeding sites data for graph
  Future<List<Map<String, dynamic>>> getBreedingSitesDataForGraph(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('mosquitoBreedingSiteReports')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt')
          .get();

      Map<String, int> dailyCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime date = (data['createdAt'] as Timestamp).toDate();
        final String dateKey = DateFormat('yyyy-MM-dd').format(date);

        dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
      }

      List<Map<String, dynamic>> graphData = dailyCounts.entries.map((entry) {
        return {
          'date': entry.key,
          'count': entry.value,
        };
      }).toList();

      graphData.sort((a, b) => a['date'].compareTo(b['date']));

      return graphData;
    } catch (e) {
      print('Error getting breeding sites data for graph: $e');
      return [];
    }
  }

  // Get fumigation data for graph
  Future<List<Map<String, dynamic>>> getFumigationDataForGraph(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('fumigations')  // Corrected collection name
          .where('scheduledDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('scheduledDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('isCompleted', isEqualTo: true)
          .orderBy('scheduledDateTime')
          .get();

      Map<String, int> dailyCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime date = (data['scheduledDateTime'] as Timestamp).toDate();
        final String dateKey = DateFormat('yyyy-MM-dd').format(date);

        dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
      }

      List<Map<String, dynamic>> graphData = dailyCounts.entries.map((entry) {
        return {
          'date': entry.key,
          'count': entry.value,
        };
      }).toList();

      graphData.sort((a, b) => a['date'].compareTo(b['date']));

      return graphData;
    } catch (e) {
      print('Error getting fumigation data for graph: $e');
      return [];
    }
  }

  // Get data for monthly trends
  Future<Map<String, List<Map<String, dynamic>>>> getMonthlyTrendData(int months) async {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month - months, 1);
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    List<Map<String, dynamic>> dengueData = await getDenguePatientDataForGraph(startDate, endDate);
    List<Map<String, dynamic>> hospitalizedData = await getHospitalizedDataForGraph(startDate, endDate);
    List<Map<String, dynamic>> breedingSitesData = await getBreedingSitesDataForGraph(startDate, endDate);
    List<Map<String, dynamic>> fumigationData = await getFumigationDataForGraph(startDate, endDate);

    Map<String, List<Map<String, dynamic>>> monthlyData = {
      'denguePatients': _aggregateToMonthly(dengueData),
      'hospitalizedPatients': _aggregateToMonthly(hospitalizedData),
      'breedingSites': _aggregateToMonthly(breedingSitesData),
      'fumigations': _aggregateToMonthly(fumigationData),
    };

    return monthlyData;
  }

  // Helper method to aggregate daily data to monthly
  List<Map<String, dynamic>> _aggregateToMonthly(List<Map<String, dynamic>> dailyData) {
    Map<String, int> monthlyCounts = {};

    for (var item in dailyData) {
      final String dateKey = item['date'];
      final String monthKey = dateKey.substring(0, 7);
      monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + (item['count'] as int);
    }

    List<Map<String, dynamic>> monthlyData = monthlyCounts.entries.map((entry) {
      return {
        'month': entry.key,
        'count': entry.value,
      };
    }).toList();

    monthlyData.sort((a, b) => a['month'].compareTo(b['month']));

    return monthlyData;
  }

  // Get location-based heat map data for breeding sites
  Future<List<Map<String, dynamic>>> getBreedingSitesHeatMapData(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('mosquitoBreedingSiteReports')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      List<Map<String, dynamic>> heatMapData = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('location') && data['location'] != null) {
          final GeoPoint location = data['location'] as GeoPoint;
          heatMapData.add({
            'latitude': location.latitude,
            'longitude': location.longitude,
            'weight': 1,
          });
        }
      }

      return heatMapData;
    } catch (e) {
      print('Error getting breeding sites heat map data: $e');
      return [];
    }
  }

  // Get location-based heat map data for dengue cases
  Future<List<Map<String, dynamic>>> getDengueCasesHeatMapData(DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('denguePatientReports')
          .where('reportedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('reportedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      List<Map<String, dynamic>> heatMapData = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('location') && data['location'] != null) {
          final GeoPoint location = data['location'] as GeoPoint;
          final int patientCount = data['numberOfPatients'] as int? ?? 1;

          heatMapData.add({
            'latitude': location.latitude,
            'longitude': location.longitude,
            'weight': patientCount,
          });
        }
      }

      return heatMapData;
    } catch (e) {
      print('Error getting dengue cases heat map data: $e');
      return [];
    }
  }
}