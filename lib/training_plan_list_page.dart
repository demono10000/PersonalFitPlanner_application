import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_fit_planner/training_plan_detail_page.dart';
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'create_training_plan_page.dart';

class TrainingPlanListPage extends StatefulWidget {
  const TrainingPlanListPage({super.key});

  @override
  _TrainingPlanListPageState createState() => _TrainingPlanListPageState();
}

class _TrainingPlanListPageState extends State<TrainingPlanListPage> {
  List trainingPlans = [];

  @override
  void initState() {
    super.initState();
    fetchTrainingPlans();
  }

  Future<void> fetchTrainingPlans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/training_plans/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        trainingPlans = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch training plans')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Plans'),
      ),
      body: ListView.builder(
        itemCount: trainingPlans.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(trainingPlans[index]['name']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainingPlanDetailPage(trainingPlanId: trainingPlans[index]['id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTrainingPlanPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
