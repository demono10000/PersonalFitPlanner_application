import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingPlanDetailPage extends StatefulWidget {
  final int trainingPlanId;

  const TrainingPlanDetailPage({super.key, required this.trainingPlanId});

  @override
  _TrainingPlanDetailPageState createState() => _TrainingPlanDetailPageState();
}

class _TrainingPlanDetailPageState extends State<TrainingPlanDetailPage> {
  Map trainingPlan = {};
  bool isEditing = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTrainingPlanDetail();
  }

  Future<void> fetchTrainingPlanDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/training_plans/${widget.trainingPlanId}/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        trainingPlan = jsonDecode(response.body);
        nameController.text = trainingPlan['name'];
        descriptionController.text = trainingPlan['description'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch training plan details')),
      );
    }
  }

  Future<void> updateTrainingPlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.put(
      Uri.parse('${Config.apiUrl}/training_plans/${widget.trainingPlanId}/update/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'name': nameController.text,
        'description': descriptionController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        trainingPlan = jsonDecode(response.body);
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training plan updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update training plan')),
      );
    }
  }

  Future<void> deleteTrainingPlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/training_plans/${widget.trainingPlanId}/delete/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training plan deleted successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete training plan')),
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
        title: const Text('Training Plan Details'),
        actions: trainingPlan['is_owner'] == true
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteTrainingPlan,
          ),
        ]
            : null,
      ),
      body: trainingPlan.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEditing
            ? Column(
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            ElevatedButton(
              onPressed: updateTrainingPlan,
              child: const Text('Save'),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              trainingPlan['name'] ?? 'No name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(trainingPlan['description'] ?? 'No description'),
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
          ],
        ),
      ),
    );
  }
}
