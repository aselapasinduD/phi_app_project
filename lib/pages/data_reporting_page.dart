import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/userModel.dart';
import '../models/reportDenguePatientsModel.dart';
import '../models/reportMosquitoBreedingSitesModel.dart';
import '../services/reportDenguePatientsService.dart';
import '../services/reportMosquitoBreedingSitesService.dart';
import '../functionality/reportDenguePatientsFunctions.dart';
import '../functionality/reportMosquitoBreedingSitesFunctions.dart';
import 'package:intl/intl.dart';
import '../components/my_colors.dart';

class DataReportingPage extends StatefulWidget {
  @override
  _DataReportingPageState createState() => _DataReportingPageState();
}

class _DataReportingPageState extends State<DataReportingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportDenguePatientsService _dengueReportService = ReportDenguePatientsService();
  final ReportMosquitoBreedingSitesService _breedingMosquitoBreedingSiteService = ReportMosquitoBreedingSitesService(
    cloudinaryCloudName: 'dmo8sh4hq',
    uploadPreset: 'phi_app_reports_evidence',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserModel currentUser = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Reporting'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MyColors.mainColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: MyColors.mainColor,
          tabs: [
            Tab(text: 'Dengue Patients'),
            Tab(text: 'Breeding Sites'),
          ],
        ),
        actions: [
          if(currentUser.canCreateBreedingAndDengueReports)PopupMenuButton<String>(
            onSelected: (value){
              if(value == 'dengue'){
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => ReportDenguePatientsFunctions(),
                  )
                );
              } else if (value == 'breeding') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => ReportMosquitoBreedingSitesFunctions(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'dengue',
                  child: Text('Report Dengue Patients'),
              ),
              PopupMenuItem(
                  value: 'breeding',
                  child: Text('Report Breeding Site'),
              ),
            ],
            icon: Icon(Icons.add, color: MyColors.mainColor)
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<List<ReportDenguePatientModel>>(
            stream: _dengueReportService.getReports(),
            builder: (context, snapshot){
              if(snapshot.connectionState == ConnectionState.waiting){
                return Center(child: CircularProgressIndicator());
              }
              if(snapshot.hasError){
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if(!snapshot.hasData || snapshot.data!.isEmpty){
                return Center(child: Text('No dengue patient reports found.'));
              }
              final reports = snapshot.data!;
              return ListView.builder(
                itemCount: reports.length,
                padding: EdgeInsets.all(8.0),
                itemBuilder: (context, index){
                  final report = reports[index];
                  return _buildDengueReportCard(context, report, currentUser);
                }
              );
            },
          ),
          StreamBuilder<List<ReportMosquitoBreedingSiteModel>>(
            stream: _breedingMosquitoBreedingSiteService.getReports(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No breeding site reports found.'));
              }

              final reports = snapshot.data!;
              return ListView.builder(
                itemCount: reports.length,
                padding: EdgeInsets.all(8.0),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _buildBreedingSiteCard(context, report, currentUser);
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyColors.secondaryColor,
        child: Icon(Icons.add, color: MyColors.mainColor),
        tooltip: 'Create Report',
        onPressed: () => {
          if(_tabController.index == 0){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReportDenguePatientsFunctions(),
              )
            )
          } else if (_tabController.index == 1){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReportMosquitoBreedingSitesFunctions(),
              ),
            )
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   backgroundColor: MyColors.secondaryColor,
      //   child: PopupMenuButton(
      //     icon: Icon(Icons.add, color: MyColors.mainColor),
      //     tooltip: 'Create Report',
      //     itemBuilder: (BuildContext context) => [
      //       PopupMenuItem(
      //         value: 'denguePatients',
      //         child: Text('Create Report Dengue Patients'),
      //       ),
      //       PopupMenuItem(
      //         value: 'breedingSite',
      //         child: Text('Create Report Breeding Site'),
      //       ),
      //     ],
      //     onSelected: (value) {
      //       if (value == 'denguePatients') {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //             builder: (context) => ReportDenguePatientsFunctions(),
      //           ),
      //         );
      //       } else if (value == 'breedingSite') {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //             builder: (context) => ReportMosquitoBreedingSitesFunctions(),
      //           ),
      //         );
      //       }
      //     },
      //   ),
      // ),

    );
  }

  Widget _buildDengueReportCard(BuildContext context, ReportDenguePatientModel report, UserModel currentUser){
    final bool canModify = report.reportedBy == currentUser.id || currentUser.role == UserRole.admin;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dengue Patients Report',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            color: MyColors.mainColor,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          'Reported on: ${dateFormat.format(report.reportedDate)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        )
                      ],
                    ),
                ),
                if(canModify)PopupMenuButton<String>(
                  onSelected: (value){
                    if (value == 'edit'){
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => ReportDenguePatientsFunctions(report: report, isEditing: true),
                        ),
                      );
                    } else if (value == 'delete') {
                      _showDeleteDengueReportDialog(context, report.id!);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 20.0),
            _buildInfoRow('Address', report.address),
            _buildInfoRow('Patients', report.numberOfPatients.toString()),
            _buildInfoRow('Hospitalized', report.hospitalized.toString()),
            if (report.notes.isNotEmpty) _buildInfoRow('Notes', report.notes),
            SizedBox(height: 12.0),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DenguePatientReportDetail(reportId: report.id!),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: MyColors.mainColor),
                foregroundColor: MyColors.mainColor,
              ),
              icon: Icon(Icons.visibility),
              label: Text('View Details'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingSiteCard(BuildContext context, ReportMosquitoBreedingSiteModel report, UserModel currentUser) {
    final bool canModify = report.reportedBy == currentUser.id || currentUser.role == UserRole.admin;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Breeding Site Report',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                          color: MyColors.mainColor,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Reported on: ${dateFormat.format(report.reportedDate)}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (canModify)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ReportMosquitoBreedingSitesFunctions(report: report, isEditing: true),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteBreedingSiteReportDialog(context, report.id!);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),
            Divider(height: 20.0),
            _buildInfoRow('Name', report.headName),
            _buildInfoRow('Address', report.address),
            _buildInfoRow('Legal Action', report.legalAction ? 'Yes' : 'No'),
            if (report.notes.isNotEmpty) _buildInfoRow('Notes', report.notes),

            SizedBox(height: 5),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MosquitoBreedingSiteReportDetail(reportId: report.id!),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: MyColors.mainColor),
                foregroundColor: MyColors.mainColor,
              ),
              icon: Icon(Icons.visibility),
              label: Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.0,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeleteDengueReportDialog(BuildContext context, String reportId){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Report'),
        content: Text('Are you sure you want to delete this dengue patients report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _dengueReportService.deleteReport(reportId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report Deleted'))
              );
            },
            child: Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteBreedingSiteReportDialog(BuildContext context, String reportId){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Report'),
        content: Text('Are you sure you want to delete this breeding site report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel')
          ),
          TextButton(
            onPressed: () {
              _breedingMosquitoBreedingSiteService.deleteReport(reportId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Report deleted')),
              );
            },
            child: Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          )
        ],
      ),
    );
  }

}
