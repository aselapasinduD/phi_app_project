import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phi_app/components/my_colors.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/reportDenguePatientsModel.dart';
import '../services/reportDenguePatientsService.dart';
import '../models/userModel.dart';
import '../components/location_picker.dart';
import '../components/map_preview.dart';

class ReportDenguePatientsFunctions extends StatelessWidget {
  final ReportDenguePatientModel? report;
  final bool isEditing;

  const ReportDenguePatientsFunctions({
    Key? key,
    this.report,
    this.isEditing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Update Dengue Patient Report' : 'Add Dengue Patient Report'),
      ),
      body: ReportDenguePatientsForm(report: report, isEditing: isEditing),
    );
  }
}

class ReportDenguePatientsForm extends StatefulWidget {
  final ReportDenguePatientModel? report;
  final bool isEditing;

  const ReportDenguePatientsForm({
    Key? key,
    this.report,
    required this.isEditing,
  }) : super(key: key);

  @override
  _ReportDenguePatientsFormState createState() => _ReportDenguePatientsFormState();
}

class _ReportDenguePatientsFormState extends State<ReportDenguePatientsForm> {
  final _formKey = GlobalKey<FormState>();
  final ReportDenguePatientsService _reportService = ReportDenguePatientsService();

  late TextEditingController _addressController;
  late TextEditingController _numberOfPatientsController;
  late TextEditingController _hospitalizedController;
  late TextEditingController _notesController;
  late DateTime _reportedDate;
  GeoPoint? _selectedLocation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _addressController = TextEditingController(text: widget.report?.address ?? '');
    _numberOfPatientsController = TextEditingController(text: widget.report?.numberOfPatients.toString() ?? '0');
    _hospitalizedController = TextEditingController(text: widget.report?.hospitalized.toString() ?? '0');
    _notesController = TextEditingController(text: widget.report?.notes ?? '');
    _reportedDate = widget.report?.reportedDate ?? DateTime.now();
    _selectedLocation = widget.report?.location;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _numberOfPatientsController.dispose();
    _hospitalizedController.dispose();
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = Provider.of<UserModel>(context, listen: false);
        final int numberOfPatients = int.parse(_numberOfPatientsController.text);
        final int hospitalized = int.parse(_hospitalizedController.text);

        // Default location if none is selected
        final location = _selectedLocation ?? GeoPoint(0, 0);

        if (widget.isEditing && widget.report != null) {
          // Update existing report
          final updatedReport = widget.report!.copyWith(
            address: _addressController.text,
            location: location,
            numberOfPatients: numberOfPatients,
            reportedDate: _reportedDate,
            hospitalized: hospitalized,
            notes: _notesController.text,
          );

          await _reportService.updateReport(updatedReport);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report updated successfully')),
          );
        } else {
          // Create new report
          final newReport = ReportDenguePatientModel(
            address: _addressController.text,
            location: location,
            numberOfPatients: numberOfPatients,
            reportedDate: _reportedDate,
            hospitalized: hospitalized,
            notes: _notesController.text,
            reportedBy: user.id,
            createdAt: Timestamp.now(),
          );

          await _reportService.addReport(newReport);
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
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address of Patients',
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
            SizedBox(height: 16.0),
            TextFormField(
              controller: _numberOfPatientsController,
              decoration: InputDecoration(
                labelText: 'Number of Patients',
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
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the number of patients';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _hospitalizedController,
              decoration: InputDecoration(
                labelText: 'How Many Hospitalized',
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
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the number of hospitalized patients';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
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

// Detail view for dengue patient report
class DenguePatientReportDetail extends StatelessWidget {
  final String reportId;
  final ReportDenguePatientsService _reportService = ReportDenguePatientsService();

  DenguePatientReportDetail({Key? key, required this.reportId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dengue Patient Report'),
        actions: [
          FutureBuilder<bool>(
            future: _reportService.canModifyReport(reportId, currentUser.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              final canModify = snapshot.data ?? false;

              if (canModify) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final report = await _reportService.getReport(reportId);
                      if (report != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportDenguePatientsFunctions(
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
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit Report'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
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
      body: FutureBuilder<ReportDenguePatientModel?>(
        future: _reportService.getReport(reportId),
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
                _buildInfoCard('Address', report.address),
                SizedBox(height: 4),
                MapPreview(location: report.location, elevation: 2,),
                SizedBox(height: 4),
                _buildInfoCard('Number of Patients', report.numberOfPatients.toString()),
                SizedBox(height: 4),
                _buildInfoCard('Reported Date', DateFormat('yyyy-MM-dd').format(report.reportedDate)),
                SizedBox(height: 4),
                _buildInfoCard('Hospitalized', report.hospitalized.toString()),
                SizedBox(height: 4),
                _buildInfoCard('Notes', report.notes ?? 'No notes provided'),
                SizedBox(height: 4),
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
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 16),
            ),
          ],
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

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Report'),
          content: Text('Are you sure you want to delete this report? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _reportService.deleteReport(reportId);
                  Navigator.of(context).pop(); // Go back to the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report deleted successfully')),
                  );
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