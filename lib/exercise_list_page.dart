// lib/exercise_list_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_exercise_page.dart';
import 'exercise_detail_page.dart';

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({super.key});

  @override
  _ExerciseListPageState createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  List exercises = [];

  @override
  void initState() {
    super.initState();
    fetchExercises();
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

  Future<void> _navigateToAddExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExercisePage()),
    );

    if (result == true) {
      fetchExercises();
    }
  }

  void _navigateToExerciseDetail(int exerciseId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExerciseDetailPage(exerciseId: exerciseId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
      ),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(exercises[index]['name']),
            onTap: () => _navigateToExerciseDetail(exercises[index]['id']),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExercise,
        child: const Icon(Icons.add),
      ),
    );
  }
}
