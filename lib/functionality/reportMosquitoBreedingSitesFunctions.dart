import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phi_app/components/my_colors.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/reportMosquitoBreedingSitesModel.dart';
import '../services/reportMosquitoBreedingSitesService.dart';
import '../models/userModel.dart';
import '../components/Image_gallery_viewer.dart';
import '../components/location_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../components/map_preview.dart';

class ReportMosquitoBreedingSitesFunctions extends StatelessWidget {
  final ReportMosquitoBreedingSiteModel? report;
  final bool isEditing;

  const ReportMosquitoBreedingSitesFunctions({
    Key? key,
    this.report,
    this.isEditing = false,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Update Breeding Site Report' : 'Add Breeding Site Report'),
      ),
      body: ReportMosquitoBreedingSitesForm(report: report, isEditing: isEditing),
    );
  }
}

class ReportMosquitoBreedingSitesForm extends StatefulWidget {
  final ReportMosquitoBreedingSiteModel? report;
  final bool isEditing;

  const ReportMosquitoBreedingSitesForm({
    Key? key,
    this.report,
    required this.isEditing,
  }) : super(key: key);

  @override
  _ReportMosquitoBreedingSitesFormState createState() => _ReportMosquitoBreedingSitesFormState();
}

class _ReportMosquitoBreedingSitesFormState extends State<ReportMosquitoBreedingSitesForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Initialize with Cloudinary configuration
  final ReportMosquitoBreedingSitesService _reportService = ReportMosquitoBreedingSitesService(
    cloudinaryCloudName: 'dmo8sh4hq',
    uploadPreset: 'phi_app_reports_evidence',
  );

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late DateTime _reportedDate;
  GeoPoint? _selectedLocation;
  bool _legalAction = false;
  List<File> _imageFiles = [];
  List<String> _existingPhotoUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.report?.headName ?? '');
    _addressController = TextEditingController(text: widget.report?.address ?? '');
    _notesController = TextEditingController(text: widget.report?.notes ?? '');
    _reportedDate = widget.report?.reportedDate ?? DateTime.now();
    _selectedLocation = widget.report?.location;
    _legalAction = widget.report?.legalAction ?? false;
    if (widget.report != null) {
      _existingPhotoUrls = List.from(widget.report!.photoUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reportedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: MyColors.mainColor,
              onPrimary: MyColors.bgColor,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: MyColors.mainColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reportedDate) {
      setState(() {
        _reportedDate = picked;
      });
    }
  }

  final mapPreviewKey = GlobalKey<MapPreviewState>();

  Future<void> _selectLocation() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLocation: _selectedLocation != null
              ? LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude)
              : null,
          onLocationSelected: (LatLng location, String? address) {},
        ),
      ),
    );

    if (pickedLocation != null) {

      setState(() {
        _selectedLocation = GeoPoint(pickedLocation.latitude, pickedLocation.longitude);
      });
      if(mapPreviewKey.currentState != null){
        mapPreviewKey.currentState!.updateLocation(_selectedLocation!);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFiles.add(File(image.path));
      });
    }
  }

  Future<void> _pickImagesFromGallery() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(images.map((image) => File(image.path)).toList());
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingPhotoUrls.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = Provider.of<UserModel>(context, listen: false);

        // Default location if none is selected
        final location = _selectedLocation ?? GeoPoint(0, 0);

        if (widget.isEditing && widget.report != null) {
          final updatedReport = widget.report!.copyWith(
            headName: _nameController.text,
            address: _addressController.text,
            reportedDate: _reportedDate,
            location: location,
            legalAction: _legalAction,
            notes: _notesController.text,
            photoUrls: _existingPhotoUrls,
          );

          await _reportService.updateReport(updatedReport, _imageFiles.isNotEmpty ? _imageFiles : null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report updated successfully')),
          );
        } else {
          final newReport = ReportMosquitoBreedingSiteModel(
            headName: _nameController.text,
            address: _addressController.text,
            reportedDate: _reportedDate,
            location: location,
            legalAction: _legalAction,
            notes: _notesController.text,
            reportedBy: user.id,
            photoUrls: [],
          );

          await _reportService.addReport(newReport, _imageFiles.isNotEmpty ? _imageFiles : null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report added successfully')),
          );
        }

        // Navigate back after successful operation
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name of Head of Household/Business Place',
                border: OutlineInputBorder(),
                floatingLabelStyle: TextStyle(
                  color: MyColors.mainColor,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: MyColors.mainColor,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the name';
                }
                return null;
              },
            ),
            SizedBox(height: 8.0),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                floatingLabelStyle: TextStyle(
                  color: MyColors.mainColor,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: MyColors.mainColor,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the address';
                }
                return null;
              },
            ),
            Divider(height: 22.0),
            ListTile(
              title: Text('Reported Date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_reportedDate)),
              onTap: () => _selectDate(context),
              trailing: Icon(Icons.calendar_today, color: MyColors.mainColor),
              tileColor: MyColors.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            SizedBox(height: 8.0),
            ListTile(
              title: Text('Location (as coordinates)'),
              subtitle: _selectedLocation != null
                  ? Text('Lat: ${_selectedLocation!.latitude}, Lng: ${_selectedLocation!.longitude}')
                  : Text('No location selected'),
              onTap: _selectLocation,
              trailing: Icon(Icons.location_on, color: MyColors.mainColor),
              tileColor: MyColors.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            if(_selectedLocation != null)MapPreview(key: mapPreviewKey, location: _selectedLocation, elevation: 2),
            Divider(height: 22.0),
            SwitchListTile(
              title: Text('Legal Action Taken?'),
              value: _legalAction,
              onChanged: (bool value) {
                setState(() {
                  _legalAction = value;
                });
              },
              activeColor: MyColors.mainColor,
              inactiveThumbColor: Colors.blueGrey[300],
              inactiveTrackColor: Colors.lightBlue[50], // Color of the track when the switch is off
              tileColor: MyColors.secondaryColor, // Tile background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            Divider(height: 22.0),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evidence Photos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Existing photos section
                    if (_existingPhotoUrls.isNotEmpty) ...[
                      Text(
                        'Existing Photos',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingPhotoUrls.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(_existingPhotoUrls[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: GestureDetector(
                                      onTap: () => _removeExistingImage(index),
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Newly selected photos section
                    if (_imageFiles.isNotEmpty) ...[
                      Text(
                        'New Photos',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageFiles.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(_imageFiles[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Add photo buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.camera_alt),
                            label: Text('Camera'),
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: MyColors.mainColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.photo_library),
                            label: Text('Gallery'),
                            onPressed: _pickImagesFromGallery,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: MyColors.mainColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 22.0),

            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                floatingLabelStyle: TextStyle(
                  color: MyColors.mainColor,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: MyColors.mainColor,
                  ),
                ),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitForm,
                child: Text(
                  widget.isEditing ? 'Update Report' : 'Submit Report',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: MyColors.mainColor,
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Detail view for mosquito breeding site report
class MosquitoBreedingSiteReportDetail extends StatelessWidget {
  final String reportId;
  final ReportMosquitoBreedingSitesService _reportMosquitoBreedingSitesService = ReportMosquitoBreedingSitesService(
    cloudinaryCloudName: 'dmo8sh4hq',
    uploadPreset: 'phi_app_reports_evidence',
  );

  MosquitoBreedingSiteReportDetail({Key? key, required this.reportId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Breeding Site Report'),
        actions: [
          FutureBuilder<bool>(
            future: _reportMosquitoBreedingSitesService.canModifyReport(reportId, currentUser.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              final canModify = snapshot.data ?? false;

              if (canModify) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final report = await _reportMosquitoBreedingSitesService.getReport(reportId);

                      if (report != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportMosquitoBreedingSitesFunctions(
                              report: report,
                              isEditing: true,
                            ),
                          ),
                        );
                      }
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(context);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.black),
                            SizedBox(width: 8),
                            Text('Edit Report'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.black),
                            SizedBox(width: 8),
                            Text('Delete Report'),
                          ],
                        ),
                      ),
                    ];
                  },
                );
              }
              return Container();
            },
          ),
        ],
      ),
      body: FutureBuilder<ReportMosquitoBreedingSiteModel?>(
        future: _reportMosquitoBreedingSitesService.getReport(reportId),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final report = snapshot.data;
          if (report == null) {
            return Center(child: Text('Report not found'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard('Reported Date', DateFormat('yyyy-MM-dd').format(report.reportedDate)),
                SizedBox(height: 4),
                _buildInfoCard('Head Name', report.headName),
                SizedBox(height: 4),
                _buildInfoCard('Address', report.address),
                SizedBox(height: 4),
                MapPreview(location: report.location, elevation: 2),
                SizedBox(height: 4),
                _buildInfoCard('Legal Action',
                    report.legalAction ? 'Yes' : 'No'),
                SizedBox(height: 4),

                if (report.notes.isNotEmpty)
                  _buildInfoCard('Notes', report.notes),

                SizedBox(height: 4),

                if (report.photoUrls.isNotEmpty)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Evidence Photos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${report.photoUrls.length} photos',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              // Open the image gallery viewer with all images
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageGalleryViewer(
                                    imageUrls: report.photoUrls,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 120,
                              child: _buildImageThumbnails(report.photoUrls),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 4),

                // Metadata section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Metadata',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildMetadataItem('Reported by', "--No Name--"),
                        _buildMetadataItem('Created at', DateFormat('yyyy-MM-dd HH:mm').format(report.createdAt!.toDate())),
                        if (report.updatedAt != null)
                          _buildMetadataItem('Last updated', DateFormat('yyyy-MM-dd HH:mm').format(report.updatedAt!.toDate())
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // New method to build the thumbnail view
  Widget _buildImageThumbnails(List<String> imageUrls) {
    // Show at most 3 images in the thumbnail view
    final displayCount = imageUrls.length > 3 ? 3 : imageUrls.length;
    final hasMore = imageUrls.length > 3;

    return Row(
      children: [
        // Display thumbnails
        for (int i = 0; i < displayCount; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < displayCount - 1 ? 8 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrls[i]),
                  fit: BoxFit.cover,
                ),
              ),
              // If this is the last thumbnail and there are more images, show count
              child: i == displayCount - 1 && hasMore
                  ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.4),
                ),
                child: Center(
                  child: Text(
                    '+${imageUrls.length - 2}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              )
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreview(GeoPoint location) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  location.latitude,
                  location.longitude,
                ),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('taskLocation'),
                  position: LatLng(
                    location.latitude,
                    location.longitude,
                  ),
                ),
              },
              scrollGesturesEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
              liteModeEnabled: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 92.0,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                ),
            ),
          ),
          Expanded(
            child: Text(value),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this report? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _reportMosquitoBreedingSitesService.deleteReport(reportId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report deleted successfully')),
                  );
                  Navigator.of(context).pop(); // Go back to previous screen
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting report: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}