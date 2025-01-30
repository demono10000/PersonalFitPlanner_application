import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String email = '';
  String password = '';

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      email = _emailController.text;
      password = _passwordController.text;

      final Map<String, String> bodyData = {
        'grant_type': 'password',
        'username': email,
        'password': password,
      };

      try {
        final response = await http.post(
          Uri.parse('${Config.apiUrl}/token'),
          headers: <String, String>{
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: bodyData,
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          final accessToken = responseData['access_token'];
          final role = responseData['role'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);
          await prefs.setString('role', role);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pomyślnie zalogowano'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Błąd logowania'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd. Spróbuj ponownie.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void quickLogin(String roleEmail, String rolePassword) {
    setState(() {
      email = roleEmail;
      password = rolePassword;

      _emailController.text = roleEmail;
      _passwordController.text = rolePassword;
    });

    login();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logowanie'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                children: [
                  Text(
                    'Personal Fit Planner',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zaloguj się, aby kontynuować',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wprowadź adres email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Wprowadź poprawny adres email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Hasło',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wprowadź hasło';
                      }
                      if (value.length < 6) {
                        return 'Hasło powinno mieć co najmniej 6 znaków';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login,
                      child: const Text('Zaloguj'),
                    ),
                  ),
                  // const SizedBox(height: 16),
                  // Column(
                  //   children: [
                  //     ElevatedButton(
                  //       onPressed: () =>
                  //           quickLogin('user@gmail.com', 'qwerty123'),
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Colors.green,
                  //         textStyle: const TextStyle(fontSize: 14),
                  //       ),
                  //       child: const Text('Testowy użytkownik'),
                  //     ),
                  //     const SizedBox(height: 8),
                  //     ElevatedButton(
                  //       onPressed: () =>
                  //           quickLogin('trener@example.com', 'qwerty123'),
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Colors.green,
                  //         textStyle: const TextStyle(fontSize: 14),
                  //       ),
                  //       child: const Text('Testowy trener'),
                  //     ),
                  //     const SizedBox(height: 8),
                  //     ElevatedButton(
                  //       onPressed: () =>
                  //           quickLogin('klub@example.com', 'qwerty123'),
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Colors.green,
                  //         textStyle: const TextStyle(fontSize: 14),
                  //       ),
                  //       child: const Text('Testowy klub'),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text("Nie masz konta? Zarejestruj się"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
