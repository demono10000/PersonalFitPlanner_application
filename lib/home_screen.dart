import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:personal_fit_planner/reports/reports_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'auth/login_screen.dart';
import 'group/list_group_screen.dart';
import 'training/list_training_screen.dart';
import 'training_plan/list_training_plan_screen.dart';
import 'invitation/list_invitation_screen.dart';
import 'exercise/list_exercise_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/me'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
      } else if (response.statusCode == 404 || response.statusCode == 401) {
        _navigateToLogin();
      } else {
        _showErrorAndLogout();
      }
    } catch (e) {
      _showErrorAndLogout();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showErrorAndLogout() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wystąpił błąd podczas sprawdzania sesji.')),
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    _navigateToLogin();
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  final List<_MenuItem> menuItems = [
    _MenuItem(
      title: 'Lista ćwiczeń',
      icon: Icons.fitness_center,
      screen: const ListExerciseScreen(),
    ),
    _MenuItem(
      title: 'Plany treningowe',
      icon: Icons.list_alt,
      screen: const ListTrainingPlanScreen(),
    ),
    _MenuItem(
      title: 'Treningi',
      icon: Icons.accessibility_new,
      screen: const ListTrainingScreen(),
    ),
    _MenuItem(
      title: 'Grupy',
      icon: Icons.group,
      screen: const ListGroupScreen(),
    ),
    _MenuItem(
      title: 'Zaproszenia',
      icon: Icons.mail_outline,
      screen: const ListInvitationScreen(),
    ),
    _MenuItem(
      title: 'Raporty',
      icon: Icons.bar_chart,
      screen: const ReportsScreen(),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Ustawienia',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Wyloguj',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                itemCount: menuItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => item.screen),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: item.title,
                            child: Icon(
                              item.icon,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget screen;

  _MenuItem({
    required this.title,
    required this.icon,
    required this.screen,
  });
}
