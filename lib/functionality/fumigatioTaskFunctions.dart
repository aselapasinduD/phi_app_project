import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phi_app/components/my_colors.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/userModel.dart';
import '../models/fumigationTaskModel.dart';
import '../services/fumigationTaskService.dart';
import '../components/location_picker.dart';
import '../components/map_preview.dart';
import '../services/weatherService.dart';

class FumigatioTaskFunctions extends StatefulWidget{
  final FumigationTaskModel? existingTask;

  const FumigatioTaskFunctions({Key? key, this.existingTask}) : super(key: key);

  @override
  _FumigatioTaskFunctionsState createState() => _FumigatioTaskFunctionsState();
}

class _FumigatioTaskFunctionsState extends State<FumigatioTaskFunctions>{
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressControllar = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDateTime;
  GeoPoint? _selectedLocation;
  List<String> _assignedMembers = [];
  List<UserModel> _availableUsers = [];

  final FumigationTaskService _fumigationTaskService = FumigationTaskService();

  @override
  void initState(){
    super.initState();
    if(widget.existingTask != null){
      _initializeExistingTask();
    }
    _loadAvailableUsers();
  }

  void _initializeExistingTask() {
    final task = widget.existingTask!;
    _titleController.text = task.title;
    _addressControllar.text = task.address;
    _selectedDateTime = task.scheduledDateTime;
    _selectedLocation = task.location;
    _assignedMembers = task.assignedMembers;
    _notesController.text = task.notes ?? '';
  }

  Future<void> _loadAvailableUsers() async {
    final currentUser = Provider.of<UserModel>(context, listen: false);
    try{
      final users = await _fumigationTaskService.getUsersForTaskAssignment(currentUser);
      setState(() {
        _availableUsers = users;
      });
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error Loading Users: $e'))
      );
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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

    if (pickedDate != null){
      final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
            _selectedDateTime ?? DateTime.now()
          ),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData(
                colorScheme: ColorScheme.light(
                  primary: MyColors.mainColor,
                  onPrimary: MyColors.bgColor,
                  onSurface: Colors.black,
                  onSecondary: MyColors.bgColor,
                  secondary: MyColors.mainColor,
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

      if (pickedTime != null){
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute
          );
        });
      }
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

  void _submitTask() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = Provider.of<UserModel>(context, listen: false);

      try{
        final fumigationTask = FumigationTaskModel(
            id: widget.existingTask?.id,
            title: _titleController.text,
            address: _addressControllar.text,
            location: _selectedLocation ?? const GeoPoint(0, 0),
            scheduledDateTime: _selectedDateTime!,
            assignedMembers: _assignedMembers,
            notes: _notesController.text,
            createdBy: currentUser.id
        );

        if(widget.existingTask == null){
          await _fumigationTaskService.createFumigationTask(currentUser, fumigationTask);
        } else {
          await _fumigationTaskService.updateFumigationTask(currentUser, fumigationTask);
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving fumigation task: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingTask == null ? 'Add Fumigation Task' : 'Edit Fumigation Task',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration:  const InputDecoration(
                  labelText: 'Task Title',
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
                validator: (value) => value!.isEmpty? 'Please enter a task title' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressControllar,
                decoration: const InputDecoration(
                  labelText: "Address",
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
                validator: (value) => value!.isEmpty ? 'Please enter an address' : null,
              ),
              Divider(height: 22.0),
              ListTile(
                title: Text('Select Date and Time'),
                onTap: _selectDateTime,
                subtitle: Text(
                  _selectedDateTime == null
                      ? 'No Date and Time chosen'
                      : 'Due Date: ${DateFormat("yyyy-MM-dd HH:mm").format(_selectedDateTime!)}',
                ),
                trailing: Icon(Icons.calendar_today, color: MyColors.mainColor),
                tileColor: MyColors.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              SizedBox(height: 8),
              ListTile(
                title: Text('Location (as coordinates)'),
                onTap: _selectLocation,
                subtitle: _selectedLocation != null
                    ? Text('Lat: ${_selectedLocation!.latitude}, Lng: ${_selectedLocation!.longitude}')
                    : Text('No location selected'),
                trailing: Icon(Icons.location_on, color: MyColors.mainColor),
                tileColor: MyColors.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              if(_selectedLocation != null) MapPreview(key: mapPreviewKey, location: _selectedLocation, elevation: 1),
              Divider(height: 22.0),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
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
              Divider(height: 22.0),
              Text(
                  "Assign Members",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              Wrap(
                spacing: 8,
                children: _availableUsers.map((user) {
                  final isAssigned = _assignedMembers.contains(user.id);
                  return ChoiceChip(
                    label: Text(
                      user.name,
                      style: TextStyle(color: isAssigned ? MyColors.mainColor : null),
                    ),
                    selected: isAssigned,
                    selectedColor: MyColors.secondaryColor,
                    checkmarkColor: MyColors.mainColor,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _assignedMembers.add(user.id);
                        } else {
                          _assignedMembers.remove(user.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitTask,
                child: Text(widget.existingTask == null
                    ? 'Create Task'
                    : 'Update Task',
                  style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.mainColor),
                ),
              ),
            ]
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressControllar.dispose();
    _notesController.dispose();
    super.dispose();
  }

}

// Detail view for Fumigation Tasks
class FumigationTaskDetail extends StatefulWidget {
  final FumigationTaskModel existingTask;
  final bool isCurrentUserAdmin;

  const FumigationTaskDetail({
    Key? key,
    required this.existingTask,
    this.isCurrentUserAdmin = false,
  }) : super(key: key);

  @override
  _FumigationTaskDetailState createState() => _FumigationTaskDetailState();
}

class _FumigationTaskDetailState extends State<FumigationTaskDetail> {
  final FumigationTaskService _fumigationTaskService = FumigationTaskService();
  List<UserModel> _assignedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  WeatherData? _WeatherInfo;

  @override
  void initState() {
    super.initState();
    _loadAssignedUsers();

  }

  Future<void> _loadAssignedUsers() async {
    final currentUser = Provider.of<UserModel>(context, listen: false);
    WeatherData weatherInfo = await widget.existingTask.getWeatherInfo();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _WeatherInfo = weatherInfo;
    });

    try {
      final allUsers = await _fumigationTaskService.getUsersForTaskAssignment(currentUser);

      final List<UserModel> assignedUsersList = allUsers.where((user) =>
          widget.existingTask.assignedMembers.contains(user.id)
      ).toList();

      setState(() {
        _assignedUsers = assignedUsersList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load assigned users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this fumigation task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
            style: TextButton.styleFrom(
              foregroundColor: MyColors.mainColor,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
            style: TextButton.styleFrom(
              foregroundColor: MyColors.mainColor,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteTask();
    }
  }

  Future<void> _deleteTask() async {
    final currentUser = Provider.of<UserModel>(context, listen: false);

    try {
      await _fumigationTaskService.deleteFumigationTask(currentUser, widget.existingTask.id!);
      Navigator.pop(context, true); // Return true to indicate task was deleted
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FumigatioTaskFunctions(existingTask: widget.existingTask),
      ),
    ).then((value) {
      // Refresh if task was updated
      if (value == true) {
        _loadAssignedUsers();
      }
    });
  }

  Widget _buildMapPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            widget.existingTask.location.latitude,
            widget.existingTask.location.longitude,
          ),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('taskLocation'),
            position: LatLng(
              widget.existingTask.location.latitude,
              widget.existingTask.location.longitude,
            ),
          ),
        },
        scrollGesturesEnabled: false,
        zoomControlsEnabled: false,
        zoomGesturesEnabled: false,
        liteModeEnabled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fumigation Task Details'),
        actions: [
          if (widget.isCurrentUserAdmin || widget.existingTask.createdBy == Provider.of<UserModel>(context).id)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEdit,
            ),
          if (widget.isCurrentUserAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDeleteTask,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.existingTask.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a')
                              .format(widget.existingTask.scheduledDateTime),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.existingTask.address),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.air, size: 16),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 250,
                          child:  Expanded(
                              child: Text('${_WeatherInfo?.windSpeed ?? 'Loading...'}')
                          ),
                        ),
                        Icon(_getCardinalDirection(_WeatherInfo!.windDirectionDegrees), size: 16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(_WeatherInfo!.isRaining ? Icons.cloud : Icons.sunny, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_WeatherInfo?.rainStatus ?? 'Loading...')
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Location',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            MapPreview(location: widget.existingTask.location, elevation: 2),
            const SizedBox(height: 16),
            Text(
              'Assigned Team Members',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _assignedUsers.length,
                itemBuilder: (context, index) {
                  final user = _assignedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: MyColors.secondaryColor,
                      child: Text(user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                  );
                },
              ),
            ),
            if (widget.existingTask.notes != null && widget.existingTask.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(widget.existingTask.notes!),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static IconData _getCardinalDirection(double degrees) {
    const List<IconData> directions = [Icons.north, Icons.north_east, Icons.east, Icons.south_east, Icons.south, Icons.south_west, Icons.west, Icons.north_west];
    int index = ((degrees + 11.25) % 360 / 44).floor();
    return directions[index];
  }
}