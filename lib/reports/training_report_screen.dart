import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_fit_planner/reports/user_training_report_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';

class TrainingReportScreen extends StatefulWidget {
  final int trainingId;
  final int groupId;
  final String groupName;

  const TrainingReportScreen({super.key,
    required this.trainingId,
    required this.groupId,
    required this.groupName,
  });

  @override
  _TrainingReportScreenState createState() => _TrainingReportScreenState();
}

class _TrainingReportScreenState extends State<TrainingReportScreen> {
  bool isLoading = true;
  Map<String, dynamic>? trainingReport;

  @override
  void initState() {
    super.initState();
    fetchTrainingReport();
  }

  Future<void> fetchTrainingReport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/reports/training/${widget.trainingId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          trainingReport = jsonDecode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać raportu treningu'),
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
          content: Text('Błąd podczas pobierania raportu treningu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildReportContent() {
    if (trainingReport == null) {
      return const Center(child: Text('Brak danych'));
    }

    final totalCount = trainingReport!['total_count'] as int;
    final performedCount = trainingReport!['performed_count'] as int;
    final averageRating = trainingReport!['average_rating'];
    final ratings = trainingReport!['ratings'] as List<dynamic>;
    final noRatings = trainingReport!['no_ratings'] as List<dynamic>;
    final ratingCounts = Map<String, int>.from(trainingReport!['rating_counts']);

    final notPerformedCount = totalCount - performedCount;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Raport Treningu: ${trainingReport!['training_id']}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text('Liczba ocen: $performedCount / $totalCount'),
          SizedBox(height: 8.h),
          Text('Średnia ocena: ${averageRating != null ? averageRating.toStringAsFixed(2) : 'Brak'}'),
          SizedBox(height: 16.h),

          Text(
            'Ukończono trening:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 200.h,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: performedCount.toDouble(),
                    title: 'Tak: ${(performedCount / totalCount * 100).toStringAsFixed(0)}%',
                    color: Colors.green,
                    radius: 50,
                    titleStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  PieChartSectionData(
                    value: notPerformedCount.toDouble(),
                    title: 'Nie: ${(notPerformedCount / totalCount * 100).toStringAsFixed(0)}%',
                    color: Colors.red,
                    radius: 50,
                    titleStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          Text(
            'Rozkład ocen:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 200.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: _getMaxCount(ratingCounts)*1.0,
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, getTitlesWidget: (double value, TitleMeta meta) {
                      int ratingIndex = value.toInt();
                      if (ratingIndex < 1 || ratingIndex > 10) return const SizedBox();
                      return Text(ratingIndex.toString(), style: const TextStyle(fontSize: 12));
                    }),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                    }),
                  ),
                ),
                barGroups: List.generate(10, (index) {
                  final rating = (index + 1).toString();
                  final count = ratingCounts[rating] ?? 0;

                  return BarChartGroupData(
                    x: index + 1,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: _getColorForRating(index + 1),
                        borderRadius: BorderRadius.circular(2),
                      )
                    ],
                  );
                }),
              ),
            ),
          ),

          SizedBox(height: 16.h),
          Text(
            'Oceny:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          ...ratings.map((r) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              child: ListTile(
                title: Text('Użytkownik: ${r['username']} - Ocena: ${r['rating']}'),
                subtitle: Text('Komentarz: ${r['comment'] ?? ''}\nMnożnik: ${r['multiplier'] ?? ''}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserTrainingReportScreen(
                        groupId: widget.groupId,
                        userId: r['user_id'],
                        username: r['username'],
                        groupName: widget.groupName,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
          SizedBox(height: 16.h),
          Text(
            'Brak ocen od:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          ...noRatings.map((nr) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              child: ListTile(
                title: Text('Użytkownik: ${nr['username']}'),
                subtitle: const Text('Nie wystawił oceny'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserTrainingReportScreen(
                        groupId: widget.groupId,
                        userId: nr['user_id'],
                        username: nr['username'],
                        groupName: widget.groupName,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  int _getMaxCount(Map<String, int> ratingCounts) {
    if (ratingCounts.isEmpty) return 0;
    return ratingCounts.values.reduce((a, b) => a > b ? a : b);
  }

  Color _getColorForRating(int rating) {
    if (rating <= 3) {
      return Colors.red;
    } else if (rating <= 6) {
      return Colors.orange;
    } else if (rating <= 8) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raport Treningu'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildReportContent(),
    );
  }
}
