import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_fit_planner/reports/training_report_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class UserTrainingReportScreen extends StatefulWidget {
  final int groupId;
  final int userId;
  final String username;
  final String groupName;

  const UserTrainingReportScreen({
    super.key,
    required this.groupId,
    required this.userId,
    required this.username,
    required this.groupName,
  });

  @override
  _UserTrainingReportScreenState createState() => _UserTrainingReportScreenState();
}

class _UserTrainingReportScreenState extends State<UserTrainingReportScreen> {
  bool isLoading = true;
  List<dynamic> userTrainings = [];

  @override
  void initState() {
    super.initState();
    fetchUserLastTrainings();
  }

  Future<void> fetchUserLastTrainings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/reports/group/${widget.groupId}/user/${widget.userId}/last-trainings'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userTrainings = jsonDecode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać treningów użytkownika'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Błąd podczas pobierania treningów użytkownika'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildUserTrainingsList() {
    if (userTrainings.isEmpty) {
      return Center(
        child: Text(
          'Brak treningów do wyświetlenia.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchUserLastTrainings,
      child: ListView.builder(
        itemCount: userTrainings.length,
        itemBuilder: (context, index) {
          final tr = userTrainings[index];
          String dateStr = tr['date'];
          DateTime dt = DateTime.parse(dateStr);
          String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dt);

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainingReportScreen(trainingId: tr['training_id'], groupId: widget.groupId, groupName: widget.groupName),
                ),
              );
            },
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data: $formattedDate',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text('Plan: ${tr['training_plan_name'] ?? 'Brak'}'),
                    SizedBox(height: 8.h),
                    Text('Wykonany: ${tr['performed'] ? 'Tak' : 'Nie'}'),
                    if (tr['performed'])
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),
                          Text('Ocena: ${tr['rating'] ?? '-'} / 10'),
                          Text('Mnożnik: ${tr['multiplier'] ?? '-'}'),
                        ],
                      ),
                  ],
                ),
              ),
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
        title: Text('Raport: ${widget.username} w ${widget.groupName}'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildUserTrainingsList(),
    );
  }
}
