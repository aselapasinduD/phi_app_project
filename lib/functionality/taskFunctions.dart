import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phi_app/components/map_preview.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:phi_app/components/my_colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/taskModel.dart';
import '../models/userModel.dart';
import '../services/taskManagementService.dart';
import '../components/location_picker.dart';

class TaskFunctions extends StatefulWidget {
  final TaskModel? existingTask;

  const TaskFunctions({Key? key, this.existingTask}) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<TaskFunctions> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  DateTime? _selectedDate;
  GeoPoint? _selectedLocation;
  List<String> _selectedMembers = [];
  List<UserModel> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: widget.existingTask?.title ?? '');
    _descriptionController = TextEditingController(
        text: widget.existingTask?.description ?? '');
    _addressController = TextEditingController(
        text: widget.existingTask?.address ?? '');
    _selectedDate = widget.existingTask?.dueDate;
    _selectedLocation = widget.existingTask?.location;
    _selectedMembers = widget.existingTask?.assignedMembers ?? [];

    // Fetch users for assignment
    _fetchAvailableUsers();
  }

  void _fetchAvailableUsers() async {
    final currentUser = Provider.of<UserModel>(context, listen: false);
    final taskService = TaskService();

    try {
      final users = await taskService.getUsersForTaskAssignment(currentUser);
      setState(() {
        _availableUsers = users;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
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

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = Provider.of<UserModel>(context, listen: false);
      final taskService = TaskService();

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a due date')),
        );
        return;
      }

      final task = TaskModel(
        id: widget.existingTask?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate!,
        location: _selectedLocation,
        address: _addressController.text,
        assignedMembers: _selectedMembers,
        createdBy: currentUser.id,
      );

      try {
        if (widget.existingTask == null) {
          await taskService.createTask(currentUser, task);
        } else {
          await taskService.updateTask(currentUser, task);
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel>(context);

    if (!currentUser.canManageTasks) {
      return Scaffold(
        appBar: AppBar(title: Text('Unauthorized')),
        body: Center(
          child: Text('You are not authorized to add or edit tasks'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask == null
            ? 'Add New Task'
            : 'Edit Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
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
              validator: (value) => value!.isEmpty
                  ? 'Please enter a task title'
                  : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
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
              validator: (value) => value!.isEmpty
                  ? 'Please enter a description'
                  : null,
            ),
            SizedBox(height: 16),
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
            ),
            Divider(height: 22.0),
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
            SizedBox(height: 8.0),
            ListTile(
              title: Text('Choose Date'),
              onTap: _selectDate,
              subtitle: Text(
                _selectedDate == null
                    ? 'No date chosen'
                    : 'Due Date: ${DateFormat.yMd().format(_selectedDate!)}',
              ),
              trailing: Icon(Icons.calendar_today, color: MyColors.mainColor),
              tileColor: MyColors.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            Divider(height: 22.0),
            const Text(
                "Assign Members",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            Wrap(
              spacing: 10,
              children: _availableUsers.map((user) {
                final isAssigned = _selectedMembers.contains(user.id);
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
                        _selectedMembers.add(user.id);
                      } else {
                        _selectedMembers.remove(user.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveTask,
              child: Text(widget.existingTask == null
                  ? 'Create Task'
                  : 'Update Task',
                style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.mainColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
