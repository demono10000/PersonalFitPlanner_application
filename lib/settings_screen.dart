import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String role = 'Użytkownik';
  String rawRole = 'User';
  String username = '';
  bool showQRCode = false;

  final Map<String, String> roleTranslations = {
    'User': 'Użytkownik',
    'Trainer': 'Trener',
    'Fitness Club': 'Klub Fitness',
  };

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchUsername();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String serverRole = prefs.getString('role') ?? 'User';
      role = roleTranslations[serverRole] ?? serverRole;
      rawRole = serverRole;
    });
  }

  Future<void> _fetchUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          username = decodedData['username'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać nazwy użytkownika'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania nazwy użytkownika'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changeRoleToTrainer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.patch(
        Uri.parse('${Config.apiUrl}/user/to-trainer'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        await prefs.remove('accessToken');
        await prefs.remove('role');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Rola została zmieniona na Trenera. Zaloguj się ponownie.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zmienić roli na Trenera'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas zmiany roli'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                UserInfoCard(
                  role: role,
                  username: username,
                ),
                SizedBox(height: 20.h),
                if (rawRole == 'User')
                  ElevatedButton.icon(
                    onPressed: _changeRoleToTrainer,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Zmień rolę na Trenera'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: username.isNotEmpty
                      ? () {
                          setState(() {
                            showQRCode = !showQRCode;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.qr_code),
                  label: Text(
                    showQRCode ? 'Ukryj kod QR' : 'Pokaż kod QR',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                if (showQRCode) ...[
                  SizedBox(height: 20.h),
                  QrCodeCard(username: username),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  final String role;
  final String username;

  const UserInfoCard({
    super.key,
    required this.role,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRow(label: 'Rola:', value: role),
            SizedBox(height: 10.h),
            InfoRow(label: 'Nazwa użytkownika:', value: username),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class QrCodeCard extends StatelessWidget {
  final String username;

  const QrCodeCard({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              'Twój Kod QR',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            QrImageView(
              data: username,
              version: QrVersions.auto,
              size: 200.0.h,
              backgroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
