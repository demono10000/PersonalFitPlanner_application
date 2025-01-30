import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateTrainingScreen extends StatefulWidget {
  const CreateTrainingScreen({super.key});

  @override
  _CreateTrainingScreenState createState() => _CreateTrainingScreenState();
}

class _CreateTrainingScreenState extends State<CreateTrainingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  int? trainingPlanId;
  int? groupId;
  List<dynamic> trainingPlans = [];
  List<dynamic> groups = [];
  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkUserRoleAndFetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> checkUserRoleAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role') ?? 'User';
    });

    await fetchTrainingPlans();
    if (userRole != 'User') {
      await fetchGroups();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchTrainingPlans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/training-plans'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(() {
          trainingPlans = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać planów treningowych'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania planów treningowych'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(() {
          groups = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać grup'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania grup'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> addTraining() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      try {
        final response = await http.post(
          Uri.parse('${Config.apiUrl}/trainings/'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'date': selectedDate.toIso8601String(),
            'training_plan_id': trainingPlanId,
            'group_id': userRole == 'User' ? null : groupId,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trening stworzony pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie udało się stworzyć treningu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd podczas tworzenia treningu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          selectedDate.hour,
          selectedDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stwórz trening'),
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
                    _buildDateTimePicker(),
                    SizedBox(height: 16.h),
                    _buildDropdownTrainingPlan(),
                    SizedBox(height: 16.h),
                    if (userRole != 'User') _buildDropdownGroup(),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: addTraining,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          'Stwórz trening',
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

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data i godzina',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd-MM-yyyy').format(selectedDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(selectedDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Icon(Icons.access_time),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownTrainingPlan() {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Plan treningowy',
        prefixIcon: const Icon(Icons.fitness_center),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      value: trainingPlanId,
      items: trainingPlans.map<DropdownMenuItem<int>>((plan) {
        return DropdownMenuItem<int>(
          value: plan['id'] as int,
          child: Text(
            plan['name'] as String,
            style: TextStyle(fontSize: 16.sp),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          trainingPlanId = value!;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Proszę wybrać plan treningowy';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownGroup() {
    return DropdownButtonFormField<int?>(
      decoration: InputDecoration(
        labelText: 'Grupa',
        prefixIcon: const Icon(Icons.group),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      value: groupId,
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(
            'Brak grupy',
            style: TextStyle(fontSize: 16.sp),
          ),
        ),
        ...groups.map<DropdownMenuItem<int?>>((group) {
          return DropdownMenuItem<int?>(
            value: group['id'] as int,
            child: Text(
              group['name'] as String,
              style: TextStyle(fontSize: 16.sp),
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          groupId = value;
        });
      },
      validator: (value) {
        if (userRole == 'Fitness Club' && value == null) {
          return 'Proszę wybrać grupę';
        }
        return null;
      },
    );
  }
}
