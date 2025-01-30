import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../invitation/send_invitation_screen.dart';
import 'user_ratings_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GroupMembersScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupMembersScreen(
      {super.key, required this.groupId, required this.groupName});

  @override
  _GroupMembersScreenState createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  List<GroupMember> members = [];
  String? currentUserRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGroupMembers();
  }

  Future<void> fetchGroupMembers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/groups/${widget.groupId}/members'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        currentUserRole = data['current_user_role'];
        members = [];

        if (data['owner'] != null) {
          members.add(GroupMember.fromJson(data['owner']));
        }

        if (data['trainers'] != null) {
          for (var trainer in data['trainers']) {
            members.add(GroupMember.fromJson(trainer));
          }
        }

        if (data['members'] != null) {
          for (var member in data['members']) {
            members.add(GroupMember.fromJson(member));
          }
        }

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się pobrać członków grupy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> removeTrainer(int trainerId, String trainerUsername) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse(
          '${Config.apiUrl}/groups/${widget.groupId}/trainers/$trainerId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trener $trainerUsername został usunięty z grupy.'),
          backgroundColor: Colors.green,
        ),
      );
      fetchGroupMembers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się usunąć trenera: ${response.body}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> removeMember(int memberId, String memberUsername) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/groups/${widget.groupId}/members/$memberId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Członek $memberUsername został usunięty z grupy.'),
          backgroundColor: Colors.green,
        ),
      );
      fetchGroupMembers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się usunąć członka: ${response.body}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _translateRole(String role) {
    switch (role) {
      case 'owner':
        return 'Właściciel';
      case 'trainer':
        return 'Trener';
      case 'member':
        return 'Członek';
      default:
        return 'Nieznany';
    }
  }

  Widget _buildRemoveButton(GroupMember member) {
    if (currentUserRole == 'owner') {
      if (member.role == 'trainer') {
        return IconButton(
          icon: Icon(Icons.remove_circle, color: Colors.red, size: 24.sp),
          onPressed: () {
            _showRemoveTrainerConfirmation(member);
          },
          tooltip: 'Usuń trenera',
        );
      } else if (member.role == 'member') {
        return IconButton(
          icon: Icon(Icons.remove_circle, color: Colors.red, size: 24.sp),
          onPressed: () {
            _showRemoveMemberConfirmation(member);
          },
          tooltip: 'Usuń członka',
        );
      }
    } else if (currentUserRole == 'trainer') {
      if (member.role == 'member') {
        return IconButton(
          icon: Icon(Icons.remove_circle, color: Colors.red, size: 24.sp),
          onPressed: () {
            _showRemoveMemberConfirmation(member);
          },
          tooltip: 'Usuń członka',
        );
      }
    }
    return SizedBox.shrink();
  }

  void _showRemoveTrainerConfirmation(GroupMember member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Usuń trenera'),
          content: Text(
              'Czy na pewno chcesz usunąć trenera ${member.username} z grupy?'),
          actions: [
            TextButton(
              child: Text('Anuluj', style: TextStyle(fontSize: 14.sp)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Usuń',
                  style: TextStyle(color: Colors.red, fontSize: 14.sp)),
              onPressed: () {
                Navigator.of(context).pop();
                removeTrainer(member.id, member.username);
              },
            ),
          ],
        );
      },
    );
  }

  void _showRemoveMemberConfirmation(GroupMember member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Usuń członka'),
          content: Text(
              'Czy na pewno chcesz usunąć członka ${member.username} z grupy?'),
          actions: [
            TextButton(
              child: Text('Anuluj', style: TextStyle(fontSize: 14.sp)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Usuń',
                  style: TextStyle(color: Colors.red, fontSize: 14.sp)),
              onPressed: () {
                Navigator.of(context).pop();
                removeMember(member.id, member.username);
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.star;
      case 'trainer':
        return Icons.fitness_center;
      case 'member':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.orange;
      case 'trainer':
        return Colors.blue;
      case 'member':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _navigateToSendInvitation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SendInvitationScreen(preselectedGroupId: widget.groupId),
      ),
    );

    if (result == true) {
      fetchGroupMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Członkowie grupy: ${widget.groupName}'),
        centerTitle: true,
        actions: [
          if (currentUserRole != 'User')
            IconButton(
              icon: Icon(Icons.person_add, size: 24.sp),
              onPressed: _navigateToSendInvitation,
              tooltip: 'Wyślij zaproszenie',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? Center(
                  child: Text(
                    'Brak członków w tej grupie',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchGroupMembers,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          leading: Icon(
                            _getRoleIcon(member.role),
                            color: _getRoleColor(member.role),
                            size: 30.sp,
                          ),
                          title: Text(
                            member.username,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _translateRole(member.role),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          trailing: _buildRemoveButton(member),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserRatingsScreen(
                                  groupId: widget.groupId,
                                  userId: member.id,
                                  username: member.username,
                                  groupName: widget.groupName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class GroupMember {
  final int id;
  final String username;
  final String role;

  GroupMember({required this.id, required this.username, required this.role});

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      username: json['username'],
      role: json['role'],
    );
  }
}
