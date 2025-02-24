import 'package:flutter/material.dart';
import 'package:phi_app/components/my_colors.dart';

class HomePageList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const HomePageList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          color: const Color.fromARGB(255, 225, 240, 255),
          elevation: 0,
          margin: EdgeInsets.symmetric(vertical: 8),

          child: SizedBox(
            height: 80,
            child: Center(
              child: ListTile(
                leading: Icon(
                  items[index]['icon'], 
                  size: 34,
                  color: MyColors.mainColor
                  ),
              
                title: Text(
                  items[index]['title'],
                  style: TextStyle(fontSize: 17, 
                  fontWeight: FontWeight.bold),
                ),
              
                trailing: Icon(
                  Icons.arrow_forward_ios,
                    size: 16, 
                    color: MyColors.mainColor
                    ),
                    
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${items[index]['title']} clicked"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
