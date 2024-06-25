import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String role = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'user';
    });
  }

  Future<void> _changeRoleToTrainer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.patch(
      Uri.parse('${Config.apiUrl}/update-role-to-trainer/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'role': 'trainer'}),
    );

    if (response.statusCode == 200) {
      await prefs.remove('accessToken');
      await prefs.remove('role');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role updated to trainer successfully. Please log in again.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update role')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Current Role: $role', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              if (role == 'user')
                ElevatedButton(
                  onPressed: _changeRoleToTrainer,
                  child: const Text('Change Role to Trainer'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
