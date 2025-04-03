import 'package:flutter/material.dart';
import 'package:phi_app/components/my_colors.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/taskModel.dart';
import '../models/userModel.dart';
import '../services/taskManagementService.dart';
import '../functionality/taskFunctions.dart';

class TaskManagementPage extends StatelessWidget {
  const TaskManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final taskService = TaskService();

    print('User Role: ${user.role}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
      ),
      body: StreamBuilder<List<TaskModel>>(
          stream: taskService.getTasks(user),
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.waiting){
              return Center(child: CircularProgressIndicator());
            }

            if(!snapshot.hasData || snapshot.data!.isEmpty){
              return Center(child: Text("No Task Found."));
            }

            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index){
                  TaskModel task = snapshot.data![index];
                  return TaskListTile(
                    task: task,
                    currentUser: user,
                  );
                });
          }),
      floatingActionButton: user.canManageTasks ? FloatingActionButton(
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TaskFunctions(),
              )
            );
          },
          backgroundColor: MyColors.secondaryColor,
          child: Icon(Icons.add),
      ) : null,
    );
  }
}

class TaskListTile extends StatelessWidget{
  final TaskModel task;
  final UserModel currentUser;

  const TaskListTile({
    Key? key,
    required this.task,
    required this.currentUser
  }) : super(key: key);

  void openGoogleMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskService = TaskService();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 2,
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyColors.mainColor),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text('Due Date: ${DateFormat.yMd().format(task.dueDate)}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
            if(task.address != "")
            Row(
              children: [
                Expanded(
                  child: Text('${task.address}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(task.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed:
              (currentUser.canManageTasks || task.assignedMembers.contains(currentUser.id))
                  ? () async  {
                    await taskService.markTaskCompleted(currentUser, task.id!, !task.isCompleted);
                }
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(10.0, 30.0),
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                side: BorderSide(color: task.isCompleted ? Colors.red : Colors.green),
                foregroundColor:  task.isCompleted ? Colors.red : Colors.green,
              ),
              icon: task.isCompleted ? Icon(Icons.close) : Icon(Icons.done),
              label: task.isCompleted ? Text("Undone", style: TextStyle(fontSize: 12)) : Text("Done", style: TextStyle(fontSize: 12)),
            ),
            if (currentUser.canManageTasks)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                taskService.deleteTask(currentUser, task.id!);
              },
            ),
          ],
        ),
        onTap: () {
          if (currentUser.canManageTasks) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskFunctions(existingTask: task),
              ),
            );
          } else {
            openGoogleMaps(task.location!.latitude, task.location!.longitude);
          }
        },
      ),
    );
  }
}
