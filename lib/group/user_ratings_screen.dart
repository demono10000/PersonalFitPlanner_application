import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_fit_planner/group/training_rating_detail.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../training/detail_training_screen.dart';

class UserRatingsScreen extends StatefulWidget {
  final int groupId;
  final int userId;
  final String username;
  final String groupName;

  const UserRatingsScreen({
    super.key,
    required this.groupId,
    required this.userId,
    required this.username,
    required this.groupName,
  });

  @override
  _UserRatingsScreenState createState() => _UserRatingsScreenState();
}

class _UserRatingsScreenState extends State<UserRatingsScreen> {
  List<TrainingRatingDetail> ratings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserRatings();
  }

  Future<void> fetchUserRatings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse(
            '${Config.apiUrl}/trainings/group/${widget.groupId}/user/${widget.userId}/ratings'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          ratings =
              data.map((json) => TrainingRatingDetail.fromJson(json)).toList();
          isLoading = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brak uprawnień do przeglądania ocen.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 404) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Nie znaleziono ocen dla tego użytkownika w tej grupie.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać ocen użytkownika.'),
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
          content: Text('Wystąpił błąd podczas pobierania ocen użytkownika.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToTrainingDetails(int trainingId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailTrainingScreen(trainingId: trainingId),
      ),
    );
  }

  Widget _buildRatingCard(TrainingRatingDetail rating) {
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm')
        .format(DateTime.parse(rating.trainingDate));
    return GestureDetector(
      onTap: () => _navigateToTrainingDetails(rating.trainingId),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data: $formattedDate',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Plan: ${rating.trainingPlanName}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 24.sp),
                  SizedBox(width: 4.w),
                  Text(
                    '${rating.rating}/10',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Komentarz:',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.h),
              Text(
                rating.comment ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 8.h),
              Text(
                'Mnożnik: ${rating.multiplier}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Oceny użytkownika: ${widget.username} w grupie ${widget.groupName}'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUserRatings,
              child: ratings.isEmpty
                  ? Center(
                      child: Text(
                        'Brak ocen dla tego użytkownika.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: ratings.length,
                      itemBuilder: (context, index) {
                        final rating = ratings[index];
                        return _buildRatingCard(rating);
                      },
                    ),
            ),
    );
  }
}
