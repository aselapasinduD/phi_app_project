import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/userModel.dart';
import '../models/fumigationTaskModel.dart';
import '../services/fumigationTaskService.dart';
import '../functionality/fumigatioTaskFunctions.dart';
import '../components/my_colors.dart';

class FumigationManagementPage extends StatelessWidget {
  const FumigationManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel>(context);
    final fumigationTaskService = FumigationTaskService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fumigation Management'),
      ),
      body: StreamBuilder<List<FumigationTaskModel>>(
          stream: fumigationTaskService.getFumigationTasks(currentUser),
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.waiting){
              return const Center(child: CircularProgressIndicator());
            }
            if(!snapshot.hasData || snapshot.data!.isEmpty){
              return const Center(
                child: Text('No fumigation tasks found.'),
              );
            }

            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final task = snapshot.data![index];
                  return FumigationTaskListCard(
                    fumigationTask: task,
                    currentUser: currentUser
                  );
                }
            );
          }
      ),
      floatingActionButton: currentUser.role == UserRole.admin
          ? FloatingActionButton(
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FumigatioTaskFunctions()
                )
              );
            },
            backgroundColor: MyColors.secondaryColor,
            child: Icon(Icons.add),
          )
          : null,
    );
  }
}

class FumigationTaskListCard extends StatelessWidget{
  final FumigationTaskModel fumigationTask;
  final UserModel currentUser;

  const FumigationTaskListCard({
    Key? key,
    required this.fumigationTask,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    final fumigationTaskService = FumigationTaskService();

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
                    fumigationTask.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17.0,
                      color: MyColors.mainColor,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async{
                        await fumigationTaskService.markFumigationTaskCompleted(
                          currentUser,
                          fumigationTask.id!,
                          !fumigationTask.isCompleted,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(10.0, 30.0),
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        side: BorderSide(color: fumigationTask.isCompleted ? Colors.red : Colors.green),
                        foregroundColor:  fumigationTask.isCompleted ? Colors.red : Colors.green,
                      ),
                      icon: fumigationTask.isCompleted ? Icon(Icons.close) : Icon(Icons.done),
                      label: fumigationTask.isCompleted ? Text("Undone", style: TextStyle(fontSize: 12)) : Text("Done", style: TextStyle(fontSize: 12)),
                    )
                  ],
                ),
              ]
            ),
            Divider(height: 8.0),
          ],
        ),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 80.0,
                        child: Text(
                          'Address:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(fumigationTask.address),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 80.0,
                        child: Text(
                          'Scheduled:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text('${fumigationTask.scheduledDateTime}'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 80.0,
                        child: Text(
                          'Status:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(fumigationTask.isCompleted ? 'Completed' : 'Pending'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>  FumigationTaskDetail(existingTask: fumigationTask, isCurrentUserAdmin: currentUser.canManageTasks)
            ),
          );
        },
        trailing: currentUser.canUpdateAndDeleteReports
            ? PopupMenuButton<String>(
              onSelected: (value) async{
                switch(value) {
                  case 'view':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>  FumigationTaskDetail(existingTask: fumigationTask, isCurrentUserAdmin: currentUser.canManageTasks)
                      ),
                    );
                    break;
                  case 'edit':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>  FumigatioTaskFunctions(existingTask: fumigationTask)
                      ),
                    );
                    break;
                  case 'delete':
                    await fumigationTaskService.deleteFumigationTask(currentUser, fumigationTask.id!);
                    break;
                  case 'complete':
                    await fumigationTaskService.markFumigationTaskCompleted(currentUser, fumigationTask.id!, !fumigationTask.isCompleted);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'view',
                    child: Text('View Details')
                ),
                const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit')
                ),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete')
                ),
                PopupMenuItem(
                    value: 'complete',
                    child: Text(
                      fumigationTask.isCompleted ? 'Mark Undone' : 'Mark Done'
                    ),
                ),
              ],
            )
            : null,
      ),
    );
  }
}