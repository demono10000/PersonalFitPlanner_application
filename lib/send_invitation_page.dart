import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class SendInvitationPage extends StatefulWidget {
  const SendInvitationPage({super.key});

  @override
  _SendInvitationPageState createState() => _SendInvitationPageState();
}

class _SendInvitationPageState extends State<SendInvitationPage> {
  final _formKey = GlobalKey<FormState>();
  String recipientEmail = '';
  String groupType = 'group_member';
  int? selectedGroup;
  List groups = [];

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/groups/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        groups = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch groups')),
      );
    }
  }

  Future<void> sendInvitation() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/invitations/send/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(<String, dynamic>{
          'recipient_email': recipientEmail,
          'type': groupType,
          'group': selectedGroup,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send invitation'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Invitation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Recipient Email'),
                onChanged: (value) {
                  setState(() {
                    recipientEmail = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the recipient\'s email';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Invitation Type'),
                value: groupType,
                items: const [
                  DropdownMenuItem(value: 'group_member', child: Text('Group Member')),
                  DropdownMenuItem(value: 'group_trainer', child: Text('Group Trainer')),
                ],
                onChanged: (value) {
                  setState(() {
                    groupType = value!;
                  });
                },
              ),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Select Group'),
                value: selectedGroup,
                items: groups.map<DropdownMenuItem<int>>((group) {
                  return DropdownMenuItem<int>(
                    value: group['id'],
                    child: Text(group['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGroup = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: sendInvitation,
                child: const Text('Send Invitation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
