import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class SendInvitationScreen extends StatefulWidget {
  final int? preselectedGroupId;

  const SendInvitationScreen({super.key, this.preselectedGroupId});

  @override
  _SendInvitationScreenState createState() => _SendInvitationScreenState();
}

class _SendInvitationScreenState extends State<SendInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  String recipientUsername = '';
  String groupType = 'group_member';
  int? selectedGroup;
  List<dynamic> groups = [];

  final TextEditingController _usernameController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
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
        setState(() {
          groups = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
          if (widget.preselectedGroupId != null) {
            selectedGroup = widget.preselectedGroupId;
          }
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

  Future<void> sendInvitation() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      try {
        final response = await http.post(
          Uri.parse('${Config.apiUrl}/invitations/'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(<String, dynamic>{
            'recipient_username': recipientUsername,
            'type': groupType,
            'group_id': selectedGroup,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zaproszenie wysłane pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie udało się wysłać zaproszenia'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd podczas wysyłania zaproszenia'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scanQRCode() async {
    try {
      var options = ScanOptions(
        restrictFormat: [BarcodeFormat.qr],
        autoEnableFlash: false,
      );

      var result = await BarcodeScanner.scan(options: options);

      if (result.type == ResultType.Barcode) {
        setState(() {
          recipientUsername = result.rawContent;
          _usernameController.text = result.rawContent;
        });
      } else if (result.type == ResultType.Error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas skanowania: ${result.formatNote ?? 'Nieznany błąd'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas skanowania'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyślij Zaproszenie'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nazwa użytkownika',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          recipientUsername = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wprowadź nazwę użytkownika';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      onPressed: _scanQRCode,
                      tooltip: 'Skanuj kod QR',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Typ zaproszenia',
                  prefixIcon: const Icon(Icons.group_add),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                value: groupType,
                items: [
                  DropdownMenuItem(
                    value: 'group_member',
                    child: Text(
                      'Członek Grupy',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'group_trainer',
                    child: Text(
                      'Trener Grupy',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    groupType = value!;
                  });
                },
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Wybierz grupę',
                  prefixIcon: const Icon(Icons.group),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                value: selectedGroup,
                items: groups.map<DropdownMenuItem<int>>((group) {
                  return DropdownMenuItem<int>(
                    value: group['id'] as int,
                    child: Text(
                      group['name'] as String,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGroup = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Wybierz grupę';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: sendInvitation,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Wyślij Zaproszenie',
                    style: TextStyle(
                      fontSize: 18.sp,
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
