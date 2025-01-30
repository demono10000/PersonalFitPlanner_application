import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_fit_planner/invitation/send_invitation_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ListInvitationScreen extends StatefulWidget {
  const ListInvitationScreen({super.key});

  @override
  _ListInvitationScreenState createState() => _ListInvitationScreenState();
}

class _ListInvitationScreenState extends State<ListInvitationScreen> {
  List<dynamic> sentInvitations = [];
  List<dynamic> receivedInvitations = [];
  String? userRole;
  bool isLoading = true;

  final Map<String, String> invitationTypeTranslations = {
    'group_member': 'Członek Grupy',
    'group_trainer': 'Trener Grupy',
  };

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    fetchInvitations();
  }

  Future<void> fetchUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role') ?? 'User';
    });
  }

  Future<void> fetchInvitations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/invitations'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          sentInvitations = data['sent'] ?? [];
          receivedInvitations = data['received'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać zaproszeń'),
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
          content: Text('Wystąpił błąd podczas pobierania zaproszeń'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteInvitation(int invitationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/invitations/$invitationId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poprawnie usunięto zaproszenie'),
          backgroundColor: Colors.green,
        ),
      );
      fetchInvitations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się usunąć zaproszenia'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> acceptInvitation(int invitationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('${Config.apiUrl}/invitations/$invitationId/accept'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zaproszenie zostało zaakceptowane'),
          backgroundColor: Colors.green,
        ),
      );
      fetchInvitations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się zaakceptować zaproszenia'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmRejectInvitation(int invitationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie odrzucenia'),
        content: const Text('Czy na pewno chcesz odrzucić to zaproszenie?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Odrzuć',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      rejectInvitation(invitationId);
    }
  }

  Future<void> rejectInvitation(int invitationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('${Config.apiUrl}/invitations/$invitationId/reject'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zaproszenie zostało odrzucone'),
          backgroundColor: Colors.green,
        ),
      );
      fetchInvitations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się odrzucić zaproszenia: ${response.body}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToSendInvitation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SendInvitationScreen()),
    );

    if (result == true) {
      fetchInvitations();
    }
  }

  Widget _buildSentInvitations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sentInvitations.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              'Wysłane zaproszenia',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ...sentInvitations.map((invitation) {
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
                'Do: ${invitation['recipient_username']}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grupa: ${invitation['group_name']}'),
                  Text(
                    'Typ zaproszenia: ${invitationTypeTranslations[invitation['type']] ?? invitation['type']}',
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Usuń zaproszenie',
                onPressed: () => _confirmDeleteSentInvitation(invitation['id']),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReceivedInvitations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (receivedInvitations.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              'Otrzymane zaproszenia',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ...receivedInvitations.map((invitation) {
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
                'Od: ${invitation['sender_username']}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grupa: ${invitation['group_name']}'),
                  Text(
                    'Typ zaproszenia: ${invitationTypeTranslations[invitation['type']] ?? invitation['type']}',
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    tooltip: 'Akceptuj zaproszenie',
                    onPressed: () => acceptInvitation(invitation['id']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    tooltip: 'Odrzuć zaproszenie',
                    onPressed: () => confirmRejectInvitation(invitation['id']),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _confirmDeleteSentInvitation(int invitationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia'),
        content: const Text('Czy na pewno chcesz usunąć to zaproszenie?'),
        actions: [
          TextButton(
            child: const Text('Anuluj'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text(
              'Usuń',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      deleteInvitation(invitationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zaproszenia'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchInvitations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSentInvitations(),
                    _buildReceivedInvitations(),
                    if (sentInvitations.isEmpty && receivedInvitations.isEmpty)
                      SizedBox(
                        height: 300.h,
                        child: Center(
                          child: Text(
                            'Brak zaproszeń',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: userRole != 'User'
          ? FloatingActionButton(
              onPressed: _navigateToSendInvitation,
              tooltip: 'Wyślij zaproszenie',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
