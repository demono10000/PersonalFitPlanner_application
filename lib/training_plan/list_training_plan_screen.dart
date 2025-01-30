import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'detail_training_plan_screen.dart';
import 'create_training_plan_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ListTrainingPlanScreen extends StatefulWidget {
  const ListTrainingPlanScreen({super.key});

  @override
  _ListTrainingPlanScreenState createState() => _ListTrainingPlanScreenState();
}

class _ListTrainingPlanScreenState extends State<ListTrainingPlanScreen> {
  List<dynamic> trainingPlans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTrainingPlans();
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
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać planów treningowych'),
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
          content: Text('Wystąpił błąd podczas pobierania planów treningowych'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToAddTrainingPlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTrainingPlanScreen()),
    );

    if (result == true) {
      fetchTrainingPlans();
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
        title: const Text('Plany treningowe'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trainingPlans.isEmpty
              ? Center(
                  child: Text(
                    'Brak dostępnych planów treningowych',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchTrainingPlans,
                  child: ListView.builder(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                    itemCount: trainingPlans.length,
                    itemBuilder: (context, index) {
                      return TrainingPlanCard(
                        trainingPlan: trainingPlans[index],
                        onTap: () => _navigateToTrainingPlanDetails(
                            trainingPlans[index]['id']),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTrainingPlan,
        tooltip: 'Dodaj plan treningowy',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TrainingPlanCard extends StatelessWidget {
  final dynamic trainingPlan;
  final VoidCallback onTap;

  const TrainingPlanCard({
    super.key,
    required this.trainingPlan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
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
                trainingPlan['name'] ?? 'Nazwa planu',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                trainingPlan['description'] ?? 'Brak opisu planu treningowego.',
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    ),
                    child: Text(
                      'Szczegóły',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
