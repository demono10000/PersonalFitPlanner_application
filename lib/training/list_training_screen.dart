import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_fit_planner/training/execution_training_screen.dart';
import 'package:personal_fit_planner/training/detail_training_screen.dart';
import 'package:personal_fit_planner/training/create_training_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ListTrainingScreen extends StatefulWidget {
  const ListTrainingScreen({super.key});

  @override
  _ListTrainingScreenState createState() => _ListTrainingScreenState();
}

class _ListTrainingScreenState extends State<ListTrainingScreen> {
  List<dynamic> trainings = [];
  bool isLoading = true;
  List<String> completedTrainings = [];

  @override
  void initState() {
    super.initState();
    fetchTrainings();
    loadCompletedTrainings();
  }

  Future<void> loadCompletedTrainings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      completedTrainings = prefs.getStringList('completedTrainings') ?? [];
    });
  }

  Future<void> fetchTrainings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/trainings/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          trainings =
              jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
          trainings.sort((a, b) =>
              DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać treningów'),
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
          content: Text('Wystąpił błąd podczas pobierania treningów'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToAddTraining() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTrainingScreen()),
    );

    if (result == true) {
      fetchTrainings();
    }
  }

  Future<void> _navigateToTrainingDetails(int trainingId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DetailTrainingScreen(trainingId: trainingId)),
    );

    if (result == true) {
      fetchTrainings();
    }
  }

  Future<void> _navigateToTrainingExecution(
      int trainingPlanId, int trainingId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExecutionTrainingScreen(
            trainingPlanId: trainingPlanId, trainingId: trainingId),
      ),
    );
    loadCompletedTrainings();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final futureTrainings = trainings
        .where((training) => DateTime.parse(training['date']).isAfter(now))
        .toList();
    final pastTrainings = trainings
        .where((training) => DateTime.parse(training['date']).isBefore(now))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista treningów'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchTrainings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (futureTrainings.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          child: Text(
                            'Zaplanowane treningi',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ...futureTrainings.map((training) {
                        final isCompleted = completedTrainings
                            .contains(training['id'].toString());
                        return TrainingCard(
                          training: training,
                          isCompleted: isCompleted,
                          onStartTraining: () => _navigateToTrainingExecution(
                              training['training_plan_id'], training['id']),
                          onTap: () =>
                              _navigateToTrainingDetails(training['id']),
                        );
                      }),
                      if (pastTrainings.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          child: Text(
                            'Zrealizowane treningi',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ...pastTrainings.map((training) {
                        final isCompleted = completedTrainings
                            .contains(training['id'].toString());
                        return TrainingCard(
                          training: training,
                          isCompleted: isCompleted,
                          onStartTraining: () => _navigateToTrainingExecution(
                              training['training_plan_id'], training['id']),
                          onTap: () =>
                              _navigateToTrainingDetails(training['id']),
                        );
                      }),
                      if (futureTrainings.isEmpty && pastTrainings.isEmpty)
                        SizedBox(
                          height: 300.h,
                          child: Center(
                            child: Text(
                              'Brak treningów',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTraining,
        tooltip: 'Dodaj trening',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TrainingCard extends StatelessWidget {
  final dynamic training;
  final bool isCompleted;
  final VoidCallback onStartTraining;
  final VoidCallback onTap;

  const TrainingCard({
    super.key,
    required this.training,
    required this.isCompleted,
    required this.onStartTraining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trainingDate = DateFormat('yyyy-MM-dd – kk:mm')
        .format(DateTime.parse(training['date']));
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trainingDate,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'Plan: ${training['training_plan_name']}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (training['group_name'] != null &&
                  training['group_name'].isNotEmpty)
                Text(
                  'Grupa: ${training['group_name']}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              Text(
                'Trener: ${training['trainer_name']}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 8.h),
              if (isCompleted)
                Text(
                  'Trening wykonany',
                  style: TextStyle(color: Colors.green, fontSize: 16.sp),
                ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: onStartTraining,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Rozpocznij trening',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
