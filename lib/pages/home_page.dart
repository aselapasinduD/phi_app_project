import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phi_app/components/app_drawer.dart';
import 'package:phi_app/components/home_page_list.dart';
import 'package:phi_app/components/my_colors.dart';
import 'package:phi_app/pages/about_page.dart';
import 'package:phi_app/pages/task_management_page.dart';
import 'package:phi_app/pages/analytics_dashboard_page.dart';
import 'package:phi_app/pages/data_reporting_page.dart';
import 'package:phi_app/pages/fumigation_management_page.dart';
import 'package:phi_app/pages/gis_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // List of main pages
  final List<Map<String, dynamic>> homePageItems = [
    {
      "title": "Task Management",
      "icon": Icons.task,
      "page": const TaskManagementPage()
    },
    {
      "title": "Analytics Dashboard",
      "icon": Icons.analytics,
      "page": const AnalyticsDashboardPage()
    },
    {
      "title": "Data Reporting",
      "icon": Icons.bar_chart,
      "page": DataReportingPage()
    },
    {
      "title": "Fumigation Management",
      "icon": Icons.bug_report,
      "page": const FumigationManagementPage()
    },
    {
      "title": "Geographic Information System",
      "icon": Icons.map,
      "page": const GISPage()
    },
  ];

  void _navigateToPage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => homePageItems[index]["page"]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: Icon(Icons.menu),
              color: MyColors.mainColor,
            );
          },
        ),
        title: Text(
          'PHI Assistant',
          style:
              TextStyle(color: MyColors.mainColor, fontWeight: FontWeight.bold),
        ),
      ),

      //drawer
      drawer: const AppDrawer(),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: HomePageList(
          items: homePageItems,
          onTap: _navigateToPage,
        ),
      ),
    );
  }
}