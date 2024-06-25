import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateTrainingPlanPage extends StatefulWidget {
  final int trainingPlanId;

  const UpdateTrainingPlanPage({super.key, required this.trainingPlanId});

  @override
  _UpdateTrainingPlanPageState createState() => _UpdateTrainingPlanPageState();
}

class _UpdateTrainingPlanPageState extends State<UpdateTrainingPlanPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  List exercises = [];
  List<Map> selectedExercises = [];

  @override
  void initState() {
    super.initState();
    fetchTrainingPlanDetail();
    fetchExercises();
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
      final data = jsonDecode(response.body);
      setState(() {
        name = data['name'];
        description = data['description'];
        selectedExercises = List<Map>.from(data['exercises']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch training plan details')),
      );
    }
  }

  Future<void> fetchExercises() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/exercises/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        exercises = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch exercises')),
      );
    }
  }

  void addExerciseToPlan(int exerciseId, String exerciseName) {
    setState(() {
      selectedExercises.add({'exercise': exerciseId, 'name': exerciseName, 'repetitions': 1, 'order': selectedExercises.length});
    });
  }

  Future<void> updateTrainingPlan() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      final List<Map<String, dynamic>> exercisesData = selectedExercises
          .map((exercise) => {
        'exercise': exercise['exercise'],
        'repetitions': exercise['repetitions'],
        'order': exercise['order']
      })
          .toList();

      final response = await http.put(
        Uri.parse('${Config.apiUrl}/training_plans/${widget.trainingPlanId}/update/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'exercises': exercisesData,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training plan updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update training plan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Training Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) {
                  setState(() {
                    name = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  setState(() {
                    description = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Select Exercises', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(exercises[index]['name']),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => addExerciseToPlan(exercises[index]['id'], exercises[index]['name']),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Selected Exercises', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                itemCount: selectedExercises.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(selectedExercises[index]['name']),
                    subtitle: TextFormField(
                      initialValue: selectedExercises[index]['repetitions'].toString(),
                      decoration: const InputDecoration(labelText: 'Repetitions'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          selectedExercises[index]['repetitions'] = int.parse(value);
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateTrainingPlan,
                child: const Text('Update Training Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
