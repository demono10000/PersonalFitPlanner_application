import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  _InvitationsPageState createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  List sentInvitations = [];
  List receivedInvitations = [];

  @override
  void initState() {
    super.initState();
    fetchInvitations();
  }

  Future<void> fetchInvitations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/invitations/list/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        sentInvitations = data['sent'];
        receivedInvitations = data['received'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch invitations')),
      );
    }
  }

  Future<void> deleteInvitation(int invitationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/invitations/$invitationId/delete/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation deleted successfully')),
      );
      fetchInvitations();  // Refresh the invitations list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete invitation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitations'),
      ),
      body: ListView(
        children: [
          if (sentInvitations.isNotEmpty)
            const ListTile(
              title: Text('Sent Invitations', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ...sentInvitations.map((invitation) {
            return ListTile(
              title: Text('To: ${invitation['recipient']}'),
              subtitle: Text('Group: ${invitation['group']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => deleteInvitation(invitation['id']),
              ),
            );
          }).toList(),
          if (receivedInvitations.isNotEmpty)
            const ListTile(
              title: Text('Received Invitations', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ...receivedInvitations.map((invitation) {
            return ListTile(
              title: Text('From: ${invitation['sender']}'),
              subtitle: Text('Group: ${invitation['group']}'),
            );
          }).toList(),
        ],
      ),
    );
  }
}
