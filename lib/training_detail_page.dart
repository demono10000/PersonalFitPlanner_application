import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_fit_planner/update_training_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'package:intl/intl.dart';

class TrainingDetailPage extends StatefulWidget {
  final int trainingId;

  const TrainingDetailPage({super.key, required this.trainingId});

  @override
  _TrainingDetailPageState createState() => _TrainingDetailPageState();
}

class _TrainingDetailPageState extends State<TrainingDetailPage> {
  Map training = {};
  Map trainingPlan = {};

  @override
  void initState() {
    super.initState();
    fetchTrainingDetail();
  }

  Future<void> fetchTrainingDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/trainings/${widget.trainingId}/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        training = jsonDecode(response.body);
      });
      fetchTrainingPlanDetail(training['training_plan']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch training details')),
      );
    }
  }

  Future<void> fetchTrainingPlanDetail(int trainingPlanId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/training_plans/$trainingPlanId/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        trainingPlan = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch training plan details')),
      );
    }
  }

  Future<void> deleteTraining() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/trainings/${widget.trainingId}/delete/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training deleted successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete training')),
      );
    }
  }

  String formatDateTime(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Details'),
        actions: training['is_trainer'] == true
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpdateTrainingPage(trainingId: training['id']),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteTraining,
          ),
        ]
            : null,
      ),
      body: training.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              formatDateTime(training['date']),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Training Plan: ${trainingPlan['name'] ?? training['training_plan']}'),
            const SizedBox(height: 10),
            const Text('Exercises:'),
            ...?trainingPlan['exercises']?.map<Widget>((exercise) {
              return ListTile(
                title: Text(exercise['exercise']['name'] ?? ''),
                subtitle: Text(exercise['is_timed'] == true
                    ? 'Time: ${exercise['repetitions']} seconds'
                    : 'Repetitions: ${exercise['repetitions']}'),
              );
            })?.toList(),
            if (training['group'] != null)
              Text('Group: ${training['group']}'),
          ],
        ),
      ),
    );
  }
}
