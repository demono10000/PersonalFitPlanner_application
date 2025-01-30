import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../exercise/detail_exercise_screen.dart';
import 'edit_training_plan_screen.dart';

class DetailTrainingPlanScreen extends StatefulWidget {
  final int trainingPlanId;

  const DetailTrainingPlanScreen({super.key, required this.trainingPlanId});

  @override
  _DetailTrainingPlanScreenState createState() =>
      _DetailTrainingPlanScreenState();
}

class _DetailTrainingPlanScreenState extends State<DetailTrainingPlanScreen> {
  Map<String, dynamic> trainingPlan = {};
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTrainingPlanDetail();
  }

  Future<void> fetchTrainingPlanDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/training-plans/${widget.trainingPlanId}/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          trainingPlan = data;
          exercises =
              (trainingPlan['exercises'] as List<dynamic>).map((exercise) {
                return {
                  'id': exercise['id'] ?? Random().nextInt(1000000),
                  'exercise_id': exercise['exercise']['id'],
                  'name': exercise['exercise']['name'],
                  'repetitions': exercise['repetitions'],
                  'order': exercise['order'],
                  'is_timed': exercise['exercise']['is_timed'] ?? false,
                };
              }).toList();
          exercises.sort((a, b) => a['order'].compareTo(b['order']));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać szczegółów planu treningowego'),
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
          content: Text('Wystąpił błąd podczas pobierania planu treningowego'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatDateTime(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }

  Future<void> confirmDeleteTrainingPlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia'),
        content: const Text('Czy na pewno chcesz usunąć ten plan treningowy?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Usuń',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      deleteTrainingPlan();
    }
  }

  Future<void> deleteTrainingPlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/training-plans/${widget.trainingPlanId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan treningowy został usunięty'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się usunąć planu treningowego'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas usuwania planu treningowego'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToExerciseDetail(int exerciseId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailExerciseScreen(exerciseId: exerciseId),
      ),
    );

    if (result == true) {
      fetchTrainingPlanDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły planu treningowego'),
        centerTitle: true,
        actions: trainingPlan['is_owner'] == true
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTrainingPlanScreen(
                    trainingPlanId: widget.trainingPlanId,
                  ),
                ),
              ).then((updated) {
                if (updated == true) {
                  fetchTrainingPlanDetail();
                }
              });
            },
            tooltip: 'Edytuj plan',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: confirmDeleteTrainingPlan,
            tooltip: 'Usuń plan',
          ),
        ]
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.w),
        child: ViewTrainingPlanDetails(
          trainingPlan: trainingPlan,
          exercises: exercises,
          formatDateTime: formatDateTime,
          onExerciseTap: _navigateToExerciseDetail,
        ),
      ),
    );
  }
}

class ViewTrainingPlanDetails extends StatelessWidget {
  final Map<String, dynamic> trainingPlan;
  final List<Map<String, dynamic>> exercises;
  final String Function(String) formatDateTime;
  final Function(int) onExerciseTap;

  const ViewTrainingPlanDetails({
    super.key,
    required this.trainingPlan,
    required this.exercises,
    required this.formatDateTime,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> sortedExercises = List.from(exercises)
      ..sort((a, b) => a['order'].compareTo(b['order']));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trainingPlan['name'] ?? 'Brak nazwy',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            trainingPlan['description'] ?? 'Brak opisu',
            style: TextStyle(
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Ćwiczenia:',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          sortedExercises.isEmpty
              ? const Text('Brak ćwiczeń w planie.')
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedExercises.length,
            itemBuilder: (context, index) {
              final exercise = sortedExercises[index];
              return ExerciseDetailTile(
                exercise: exercise,
                onTap: () => onExerciseTap(exercise['exercise_id']),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ExerciseDetailTile extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onTap;

  const ExerciseDetailTile({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTimed = exercise['is_timed'] == true;
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: isTimed
            ? Icon(Icons.timer, color: Colors.red, size: 24.sp)
            : Icon(Icons.repeat, color: Colors.green, size: 24.sp),
        title: Text(
          exercise['name'] ?? 'Ćwiczenie',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isTimed
              ? 'Czas: ${exercise['repetitions']} sekund'
              : 'Powtórzenia: ${exercise['repetitions']}',
          style: TextStyle(
            fontSize: 14.sp,
            color: isTimed ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }
}
