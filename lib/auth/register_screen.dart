import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String role = 'User';

  final List<Map<String, String>> roles = [
    {'label': 'Użytkownik', 'value': 'User'},
    {'label': 'Trener', 'value': 'Trainer'},
    {'label': 'Klub Fitness', 'value': 'Fitness Club'},
  ];

  Future<void> register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('${Config.apiUrl}/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'username': username,
            'email': email,
            'password': password,
            'role': role,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zarejestrowano pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else if (response.statusCode == 422) {
          final errors = jsonDecode(utf8.decode(response.bodyBytes))['detail'];
          String errorMessage = 'Błędy w formularzu:\n';
          for (var error in errors) {
            if (error['loc'].contains('email')) {
              errorMessage += '• Niepoprawny adres email\n';
            }
            if (error['loc'].contains('password')) {
              errorMessage += '• Hasło musi mieć co najmniej 8 znaków\n';
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } else if (response.statusCode == 400) {
          final error = jsonDecode(response.body)['detail'];
          if (error == 'Email already registered') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Adres email jest już zarejestrowany')),
            );
          } else if (error == 'Username already taken') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Nazwa użytkownika jest już zajęta')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rejestracja nie powiodła się')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd. Spróbuj ponownie.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejestracja'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Personal Fit Planner',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Załóż konto, aby rozpocząć',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nazwa użytkownika',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) {
                      setState(() {
                        username = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wprowadź nazwę użytkownika';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      setState(() {
                        email = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wprowadź swój adres email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Wprowadź poprawny adres email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Hasło',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {
                        password = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wprowadź hasło';
                      }
                      if (value.length < 8) {
                        return 'Hasło musi mieć co najmniej 8 znaków';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Potwierdź hasło',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {
                        confirmPassword = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wprowadź hasło ponownie';
                      }
                      if (value != password) {
                        return 'Hasła nie są takie same';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Wybierz rolę',
                      prefixIcon: Icon(Icons.assignment_ind),
                      border: OutlineInputBorder(),
                    ),
                    value: role,
                    items: roles.map((roleItem) {
                      return DropdownMenuItem<String>(
                        value: roleItem['value'],
                        child: Text(roleItem['label']!,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        role = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wybierz rolę';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: register,
                      child: const Text('Zarejestruj'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text('Masz już konto? Zaloguj się'),
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
