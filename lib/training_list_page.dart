import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_fit_planner/training_detail_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_training_page.dart';
import 'config.dart';
import 'package:intl/intl.dart';

class TrainingListPage extends StatefulWidget {
  const TrainingListPage({super.key});

  @override
  _TrainingListPageState createState() => _TrainingListPageState();
}

class _TrainingListPageState extends State<TrainingListPage> {
  List trainings = [];

  @override
  void initState() {
    super.initState();
    fetchTrainings();
  }

  Future<void> fetchTrainings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/trainings/list/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        trainings = jsonDecode(response.body);
        trainings.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch trainings')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final futureTrainings = trainings.where((training) => DateTime.parse(training['date']).isAfter(now)).toList();
    final pastTrainings = trainings.where((training) => DateTime.parse(training['date']).isBefore(now)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training List'),
      ),
      body: ListView(
        children: [
          if (futureTrainings.isNotEmpty)
            const ListTile(
              title: Text('Future Trainings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ...futureTrainings.map((training) {
            return ListTile(
              title: Text(DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(training['date']))),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingDetailPage(trainingId: training['id']),
                  ),
                );
              },
            );
          }).toList(),
          if (pastTrainings.isNotEmpty)
            const ListTile(
              title: Text('Past Trainings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ...pastTrainings.map((training) {
            return ListTile(
              title: Text(DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(training['date']))),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingDetailPage(trainingId: training['id']),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTrainingPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
