import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'group_reports_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> myGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyGroups();
  }

  Future<void> fetchMyGroups() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final myGroupsResponse = await http.get(
        Uri.parse('${Config.apiUrl}/groups/my-groups/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (myGroupsResponse.statusCode == 200) {
        setState(() {
          myGroups = jsonDecode(utf8.decode(myGroupsResponse.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać danych o grupach'),
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
          content: Text('Wystąpił błąd podczas pobierania grup'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildGroupList(List<dynamic> groups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groups.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              'Twoje Grupy',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ...groups.map((group) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 4,
            child: ListTile(
              contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              title: Text(
                group['name'],
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Właściciel: ${group['owner']['username']}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupReportsScreen(
                      groupId: group['id'],
                      groupName: group['name'],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporty'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchMyGroups,
        child: ListView(
          children: [
            buildGroupList(myGroups),
            if (myGroups.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const Text('Nie jesteś trenerem lub właścicielem żadnej grupy.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
