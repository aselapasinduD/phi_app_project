import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reportDenguePatientsModel.dart';

class ReportDenguePatientsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'denguePatientReports';

  // Get all reports
  Stream<List<ReportDenguePatientModel>> getReports() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportDenguePatientModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get reports by user
  Stream<List<ReportDenguePatientModel>> getUserReports(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('reportedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportDenguePatientModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get single report
  Future<ReportDenguePatientModel?> getReport(String reportId) async {
    DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(reportId).get();
    if (doc.exists) {
      return ReportDenguePatientModel.fromFirestore(doc);
    }
    return null;
  }

  // Add report
  Future<String> addReport(ReportDenguePatientModel report) async {
    DocumentReference docRef = await _firestore.collection(_collectionPath).add(report.toFirestore());
    return docRef.id;
  }

  // Update report
  Future<void> updateReport(ReportDenguePatientModel report) async {
    if (report.id == null) {
      throw Exception("Report ID cannot be null for update operation");
    }
    return await _firestore
        .collection(_collectionPath)
        .doc(report.id)
        .update(report.toFirestore());
  }

  // Delete report
  Future<void> deleteReport(String reportId) async {
    return await _firestore.collection(_collectionPath).doc(reportId).delete();
  }

  // Check if user can modify report
  Future<bool> canModifyReport(String reportId, String userId) async {
    DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(reportId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['reportedBy'] == userId;
    }
    return false;
  }
}