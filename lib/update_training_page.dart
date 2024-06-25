import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class UpdateTrainingPage extends StatefulWidget {
  final int trainingId;

  const UpdateTrainingPage({super.key, required this.trainingId});

  @override
  _UpdateTrainingPageState createState() => _UpdateTrainingPageState();
}

class _UpdateTrainingPageState extends State<UpdateTrainingPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  int trainingPlanId = 0;
  int? groupId;
  List trainingPlans = [];
  List groups = [];

  @override
  void initState() {
    super.initState();
    fetchTrainingPlans();
    fetchGroups();
    fetchTrainingDetail();
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

  Future<void> fetchGroups() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/groups/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        groups = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch groups')),
      );
    }
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
      final data = jsonDecode(response.body);
      setState(() {
        selectedDate = DateTime.parse(data['date']);
        trainingPlanId = data['training_plan'];
        groupId = data['group'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch training details')),
      );
    }
  }

  Future<void> updateTraining() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      final response = await http.put(
        Uri.parse('${Config.apiUrl}/trainings/${widget.trainingId}/update/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'date': selectedDate.toIso8601String(),
          'training_plan': trainingPlanId,
          'group': groupId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update training')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          selectedDate.hour,
          selectedDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Training'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              ListTile(
                title: const Text("Date"),
                subtitle: Text("${selectedDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: const Text("Time"),
                subtitle: Text("${selectedDate.toLocal()}".split(' ')[1].substring(0, 5)),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _selectTime(context),
              ),
              DropdownButtonFormField(
                value: trainingPlanId,
                decoration: const InputDecoration(labelText: 'Training Plan'),
                items: trainingPlans.map<DropdownMenuItem<int>>((plan) {
                  return DropdownMenuItem<int>(
                    value: plan['id'],
                    child: Text(plan['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    trainingPlanId = value as int;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a training plan';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField(
                value: groupId,
                decoration: const InputDecoration(labelText: 'Group'),
                items: groups.map<DropdownMenuItem<int>>((group) {
                  return DropdownMenuItem<int>(
                    value: group['id'],
                    child: Text(group['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    groupId = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateTraining,
                child: const Text('Update Training'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
