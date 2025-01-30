import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'create_exercise_screen.dart';
import 'detail_exercise_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ListExerciseScreen extends StatefulWidget {
  const ListExerciseScreen({super.key});

  @override
  _ListExerciseScreenState createState() => _ListExerciseScreenState();
}

class _ListExerciseScreenState extends State<ListExerciseScreen>
    with WidgetsBindingObserver {
  List exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchExercises();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
        exercises = jsonDecode(utf8.decode(response.bodyBytes));
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się pobrać ćwiczeń')),
      );
    }
  }

  Future<void> _navigateToAddExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateExerciseScreen()),
    );

    if (result == true) {
      fetchExercises();
    }
  }

  Future<void> _navigateToExerciseDetail(int exerciseId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DetailExerciseScreen(exerciseId: exerciseId)),
    );

    if (result == true) {
      fetchExercises();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ćwiczenia'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchExercises,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
              ? Center(
                  child: Text(
                    'Brak dostępnych ćwiczeń.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchExercises,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 4,
                        margin: EdgeInsets.only(bottom: 16.h),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          leading: Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.primary,
                            size: 40.sp,
                          ),
                          title: Text(
                            exercise['name'],
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          // subtitle: Text(
                          //   exercise['description'] ?? 'Brak opisu',
                          //   style: Theme.of(context).textTheme.bodyLarge,
                          // ),
                          subtitle: Text(
                            (exercise['description'] != null && exercise['description']!.length > 50)
                                ? '${exercise['description']!.substring(0, 50)}...'
                                : exercise['description'] ?? 'Brak opisu',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20.sp,
                          ),
                          onTap: () =>
                              _navigateToExerciseDetail(exercise['id']),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExercise,
        tooltip: 'Dodaj ćwiczenie',
        child: const Icon(Icons.add),
      ),
    );
  }
}
