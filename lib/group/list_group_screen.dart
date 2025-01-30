import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_group_screen.dart';
import 'edit_group_screen.dart';
import 'group_members_screen.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ListGroupScreen extends StatefulWidget {
  const ListGroupScreen({super.key});

  @override
  _ListGroupScreenState createState() => _ListGroupScreenState();
}

class _ListGroupScreenState extends State<ListGroupScreen> {
  List<dynamic> memberGroups = [];
  List<dynamic> myGroups = [];
  bool isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');
    userRole = prefs.getString('role');

    try {
      final memberResponse = await http.get(
        Uri.parse('${Config.apiUrl}/groups/member-of/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final myGroupsResponse = await http.get(
        Uri.parse('${Config.apiUrl}/groups/my-groups/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (memberResponse.statusCode == 200 &&
          myGroupsResponse.statusCode == 200) {
        setState(() {
          memberGroups = jsonDecode(utf8.decode(memberResponse.bodyBytes));
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

  Future<void> confirmLeaveGroup(int groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie opuszczenia grupy'),
        content: const Text('Czy na pewno chcesz opuścić tę grupę?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Opuść'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      leaveGroup(groupId);
    }
  }

  Future<void> confirmDeleteGroup(int groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia grupy'),
        content: const Text('Czy na pewno chcesz usunąć tę grupę?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      deleteGroup(groupId);
    }
  }

  Future<void> leaveGroup(int groupId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/groups/leave/$groupId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opuszczono grupę'),
            backgroundColor: Colors.green,
          ),
        );
        fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się opuścić grupy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas opuszczania grupy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteGroup(int groupId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/groups/$groupId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupa została usunięta'),
            backgroundColor: Colors.green,
          ),
        );
        fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się usunąć grupy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas usuwania grupy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToCreateGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
    );

    if (result == true) {
      fetchGroups();
    }
  }

  Future<void> _navigateToEditGroup(int groupId, String groupName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditGroupScreen(groupId: groupId, groupName: groupName),
      ),
    );

    if (result == true) {
      fetchGroups();
    }
  }

  Future<void> _navigateToGroupMembers(int groupId, String groupName) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GroupMembersScreen(groupId: groupId, groupName: groupName),
      ),
    );
  }

  Widget buildGroupList(List<dynamic> groups, {bool isMyGroup = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groups.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              isMyGroup ? 'Twoje Grupy' : 'Grupy, do których należysz',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ...groups.map((group) {
          bool isOwner = group['current_user_role'] == 'owner';

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
                isMyGroup ? group['name'] : group['group_name'],
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isMyGroup
                    ? 'Właściciel: ${group['owner']['username']}'
                    : 'Właściciel: ${group['owner_name']}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: isMyGroup
                  ? () => _navigateToGroupMembers(group['id'], group['name'])
                  : null,
              trailing: isOwner
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _navigateToEditGroup(group['id'], group['name']),
                          tooltip: 'Edytuj',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => confirmDeleteGroup(group['id']),
                          tooltip: 'Usuń',
                        ),
                      ],
                    )
                  : IconButton(
                      icon: const Icon(Icons.exit_to_app, color: Colors.orange),
                      onPressed: () => confirmLeaveGroup(group['id']),
                      tooltip: 'Opuść',
                    ),
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
        title: const Text('Moje Grupy'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchGroups,
              child: ListView(
                children: [
                  buildGroupList(memberGroups),
                  buildGroupList(myGroups, isMyGroup: true),
                ],
              ),
            ),
      floatingActionButton:
              (userRole != 'User')
          ? FloatingActionButton(
              onPressed: _navigateToCreateGroup,
              tooltip: 'Stwórz Grupę',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
