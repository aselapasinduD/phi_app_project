import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import '../models/reportMosquitoBreedingSitesModel.dart';
import 'userService.dart';

class ReportMosquitoBreedingSitesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryPublic _cloudinary;
  final String _collectionPath = 'mosquitoBreedingSiteReports';
  final String _cloudName;
  final String _uploadPreset;

  ReportMosquitoBreedingSitesService({
    required String cloudinaryCloudName,
    required String uploadPreset,
  }) : _cloudName = cloudinaryCloudName,
        _uploadPreset = uploadPreset,
        _cloudinary = CloudinaryPublic(cloudinaryCloudName, uploadPreset);

  // Get all reports
  Stream<List<ReportMosquitoBreedingSiteModel>> getReports() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportMosquitoBreedingSiteModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get reports by user
  Stream<List<ReportMosquitoBreedingSiteModel>> getUserReports(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('reportedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportMosquitoBreedingSiteModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get single report
  Future<ReportMosquitoBreedingSiteModel?> getReport(String reportId) async {
    DocumentSnapshot report = await _firestore.collection(_collectionPath).doc(reportId).get();
    if (report.exists) {
      // String? userName = await UserService.getUserNameById(report['reportedBy']);

      return ReportMosquitoBreedingSiteModel.fromFirestore(report);
    }
    return null;
  }

  // Upload a single image to Cloudinary and return URL
  Future<String?> uploadImage(File imageFile, String reportId) async {
    try {
      final folder = 'breeding_site_images/$reportId';

      // Create Cloudinary file with appropriate parameters
      final cloudinaryFile = CloudinaryFile.fromFile(
        imageFile.path,
        resourceType: CloudinaryResourceType.Image,
        tags: ['mosquito_breeding_site', 'report'],
        folder: folder,
      );

      // Upload file - using unsigned upload with proper upload preset
      final response = await _cloudinary.uploadFile(cloudinaryFile);

      return response.secureUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Cloudinary upload error: $e');
      }
      return null;
    }
  }

  // Upload multiple images and return list of URLs
  Future<List<String>> uploadImages(List<File> imageFiles, String reportId) async {
    List<String> photoUrls = [];

    for (File imageFile in imageFiles) {
      String? url = await uploadImage(imageFile, reportId);
      if (url != null) {
        photoUrls.add(url);
      }
    }

    return photoUrls;
  }

  // Add report with multiple images
  Future<String> addReport(ReportMosquitoBreedingSiteModel report, List<File>? imageFiles) async {
    final docRef = await _firestore.collection(_collectionPath).add(report.toFirestore());

    if (imageFiles != null && imageFiles.isNotEmpty) {
      final photoUrls = await uploadImages(imageFiles, docRef.id);
      if (photoUrls.isNotEmpty) {
        await docRef.update({'photoUrls': photoUrls});
      }
    }

    return docRef.id;
  }

  // Add images to an existing report
  Future<void> addImagesToReport(String reportId, List<File> imageFiles) async {
    ReportMosquitoBreedingSiteModel? report = await getReport(reportId);
    if (report == null) {
      throw Exception("Report not found");
    }

    List<String> newUrls = await uploadImages(imageFiles, reportId);

    List<String> updatedUrls = List.from(report.photoUrls);
    updatedUrls.addAll(newUrls);

    await _firestore.collection(_collectionPath).doc(reportId).update({'photoUrls': updatedUrls});
  }

  // Update report with optional new images
  Future<void> updateReport(ReportMosquitoBreedingSiteModel report, List<File>? newImageFiles) async {
    if (report.id == null) {
      throw Exception("Report ID cannot be null for update operation");
    }

    // If there are new images, upload them
    if (newImageFiles != null && newImageFiles.isNotEmpty) {
      List<String> newUrls = await uploadImages(newImageFiles, report.id!);
      if (newUrls.isNotEmpty) {
        List<String> updatedUrls = List.from(report.photoUrls);
        updatedUrls.addAll(newUrls);
        report = report.copyWith(photoUrls: updatedUrls);
      }
    }

    return await _firestore.collection(_collectionPath).doc(report.id).update(report.toFirestore());
  }

  // Delete a specific image from a report
  Future<void> deleteImageFromReport(String reportId, String photoUrl) async {
    ReportMosquitoBreedingSiteModel? report = await getReport(reportId);
    if (report == null) {
      throw Exception("Report not found");
    }

    List<String> updatedUrls = List.from(report.photoUrls);
    updatedUrls.remove(photoUrl);

    await _firestore.collection(_collectionPath).doc(reportId).update({'photoUrls': updatedUrls});
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

  // Extract public ID from Cloudinary URL (for reference)
  String? extractPublicIdFromUrl(String url) {
    try {
      final Uri uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      int versionIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i].startsWith('v') && RegExp(r'^v\d+$').hasMatch(pathSegments[i])) {
          versionIndex = i;
          break;
        }
      }

      if (versionIndex >= 0 && versionIndex < pathSegments.length - 1) {
        final publicId = pathSegments.sublist(versionIndex + 1).join('/');
        return publicId.replaceAll(RegExp(r'\.[^.]+$'), '');
      }
      return null;
    } catch (e) {
      print('Error extracting public ID: $e');
      return null;
    }
  }
}