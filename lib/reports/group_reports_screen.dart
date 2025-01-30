import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'training_report_screen.dart';
import 'user_training_report_screen.dart';

class GroupReportsScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupReportsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  _GroupReportsScreenState createState() => _GroupReportsScreenState();
}

class _GroupReportsScreenState extends State<GroupReportsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<dynamic> trainings = [];
  List<dynamic> members = [];
  bool isLoadingTrainings = true;
  bool isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchTrainings();
    fetchMembers();
  }

  Future<void> fetchTrainings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/trainings/group/${widget.groupId}/trainings'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          trainings = jsonDecode(utf8.decode(response.bodyBytes));
          isLoadingTrainings = false;
        });
      } else {
        setState(() {
          isLoadingTrainings = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać treningów grupy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoadingTrainings = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Błąd podczas pobierania treningów grupy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchMembers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/groups/${widget.groupId}/members'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> loadedMembers = [];
        if (data['owner'] != null) {
          loadedMembers.add(data['owner']);
        }
        if (data['trainers'] != null) {
          for (var t in data['trainers']) {
            loadedMembers.add(t);
          }
        }
        if (data['members'] != null) {
          for (var m in data['members']) {
            loadedMembers.add(m);
          }
        }

        setState(() {
          members = loadedMembers;
          isLoadingMembers = false;
        });
      } else {
        setState(() {
          isLoadingMembers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać członków grupy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoadingMembers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Błąd podczas pobierania członków grupy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildTrainingsList() {
    if (isLoadingTrainings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (trainings.isEmpty) {
      return Center(
        child: Text(
          'Brak treningów w tej grupie.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchTrainings,
      child: ListView.builder(
        itemCount: trainings.length,
        itemBuilder: (context, index) {
          final training = trainings[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 4,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              title: Text(
                'Plan: ${training['training_plan_name']}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Data: ${training['date']}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingReportScreen(trainingId: training['id'], groupId: widget.groupId, groupName: widget.groupName),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildMembersList() {
    if (isLoadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (members.isEmpty) {
      return Center(
        child: Text(
          'Brak członków w tej grupie.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    String _translateRole(String role) {
      switch (role) {
        case 'owner':
          return 'Właściciel';
        case 'trainer':
          return 'Trener';
        case 'member':
          return 'Członek';
        default:
          return 'Nieznany';
      }
    }
    
    return RefreshIndicator(
      onRefresh: fetchMembers,
      child: ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 4,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              title: Text(
                member['username'],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Rola: ${_translateRole(member['role'])}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserTrainingReportScreen(
                      groupId: widget.groupId,
                      userId: member['id'],
                      username: member['username'],
                      groupName: widget.groupName,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Raporty grupy: ${widget.groupName}'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Treningi'),
            Tab(text: 'Użytkownicy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTrainingsList(),
          buildMembersList(),
        ],
      ),
    );
  }
}
