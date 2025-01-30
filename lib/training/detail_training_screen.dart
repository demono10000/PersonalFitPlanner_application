import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

import 'edit_training_screen.dart';
import '../exercise/detail_exercise_screen.dart';
import '../training_plan/detail_training_plan_screen.dart';

class DetailTrainingScreen extends StatefulWidget {
  final int trainingId;

  const DetailTrainingScreen({super.key, required this.trainingId});

  @override
  _DetailTrainingScreenState createState() => _DetailTrainingScreenState();
}

class _DetailTrainingScreenState extends State<DetailTrainingScreen> {
  Map<String, dynamic> training = {};
  Map<String, dynamic> trainingPlan = {};
  DateTime selectedDate = DateTime.now();
  TextEditingController timeController = TextEditingController();
  int? trainingPlanId;
  int? groupId;
  List<dynamic> trainingPlans = [];
  List<dynamic> groups = [];
  bool isLoading = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchTrainingDetail();
    fetchTrainingPlans();
    fetchGroups();
  }

  @override
  void dispose() {
    timeController.dispose();
    super.dispose();
  }

  Event _createEvent() {
    final event = Event(
      title: training['training_plan_name'] ?? 'Trening',
      description: trainingPlan['description'] ?? 'Brak opisu',
      startDate: selectedDate,
      endDate: selectedDate.add(Duration(hours: 1)),
    );
    return event;
  }

  void _addToCalendar() {
    final Event event = _createEvent();
    Add2Calendar.addEvent2Cal(event).then((success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Dodano do kalendarza' : 'Nie udało się dodać do kalendarza'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    });
  }

  Future<void> fetchTrainingDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/trainings/${widget.trainingId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          training = data;
          selectedDate = DateTime.parse(training['date']);
          timeController.text = DateFormat('HH:mm').format(selectedDate);
          trainingPlanId = training['training_plan_id'];
          groupId = training['group_id'];
          isLoading = false;
        });
        fetchTrainingPlanDetail(training['training_plan_id']);
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać szczegółów treningu'),
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
          content: Text('Wystąpił błąd podczas pobierania treningu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchTrainingPlanDetail(int trainingPlanId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/training-plans/$trainingPlanId'),
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
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać szczegółów planu treningowego'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania planu treningowego'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchTrainingPlans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/training-plans/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(() {
          trainingPlans = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać planów treningowych'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania planów treningowych'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchGroups() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/groups/my-groups'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(() {
          groups = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać grup'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania grup'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmDeleteTraining() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia'),
        content: const Text('Czy na pewno chcesz usunąć ten trening?'),
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
      deleteTraining();
    }
  }

  Future<void> deleteTraining() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/trainings/${widget.trainingId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trening został usunięty pomyślnie'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się usunąć treningu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas usuwania treningu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToExerciseDetail(int exerciseId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DetailExerciseScreen(exerciseId: exerciseId)),
    );

    if (result == true) {
      fetchTrainingDetail();
    }
  }

  Future<void> _navigateToTrainingPlanDetails(int trainingPlanId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailTrainingPlanScreen(trainingPlanId: trainingPlanId),
      ),
    );

    if (result == true) {
      fetchTrainingPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły treningu'),
        centerTitle: true,
        actions: [
          if (training['is_trainer'] == true) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTrainingScreen(trainingId: widget.trainingId),
                  ),
                ).then((value) {
                  if (value == true) {
                    fetchTrainingDetail();
                  }
                });
              },
              tooltip: 'Edytuj trening',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: confirmDeleteTraining,
              tooltip: 'Usuń trening',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _addToCalendar,
            tooltip: 'Dodaj do kalendarza',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.w),
        child: _buildTrainingDetails(),
      ),
    );
  }

  Widget _buildTrainingDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Text(
              formatDateTime(training['date']),
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          InkWell(
            onTap: () {
              if (trainingPlan['id'] != null) {
                _navigateToTrainingPlanDetails(trainingPlan['id']);
              }
            },
            child: _buildDetailRow(
              'Plan treningowy',
              trainingPlan['name'] ?? training['training_plan_name'] ?? 'N/A',
              hasNavigation: trainingPlan['id'] != null,
            ),
          ),
          SizedBox(height: 8.h),
          if (training['group_name'] != null &&
              training['group_name'].isNotEmpty)
            _buildDetailRow('Grupa', training['group_name']),
          SizedBox(height: 8.h),
          _buildDetailRow('Trener', training['trainer_name'] ?? 'N/A'),
          SizedBox(height: 16.h),
          Text(
            'Ćwiczenia:',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          ...?trainingPlan['exercises']?.map<Widget>((exercise) {
                return ListTile(
                  leading: Icon(Icons.fitness_center,
                      color: Colors.deepPurple, size: 24.sp),
                  title: Text(
                    exercise['exercise']['name'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    exercise['is_timed'] == true
                        ? 'Czas: ${exercise['repetitions']} sekund'
                        : 'Powtórzenia: ${exercise['repetitions']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () =>
                      _navigateToExerciseDetail(exercise['exercise']['id']),
                );
              })?.toList() ??
              [const Text('Brak ćwiczeń')],
          if (training['group'] != null)
            _buildDetailRow('Grupa', training['group']),
          SizedBox(height: 24.h),
          Center(
            child: ElevatedButton.icon(
              onPressed: _addToCalendar,
              icon: Icon(Icons.calendar_today),
              label: Text('Dodaj do kalendarza'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                textStyle: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value,
      {bool hasNavigation = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: hasNavigation
                ? Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                  )
                : Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
          ),
        ],
      ),
    );
  }

  String formatDateTime(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }
}
