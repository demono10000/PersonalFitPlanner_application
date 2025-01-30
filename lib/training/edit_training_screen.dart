import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class EditTrainingScreen extends StatefulWidget {
  final int trainingId;

  const EditTrainingScreen({super.key, required this.trainingId});

  @override
  _EditTrainingScreenState createState() => _EditTrainingScreenState();
}

class _EditTrainingScreenState extends State<EditTrainingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController timeController;
  DateTime selectedDate = DateTime.now();
  int? trainingPlanId;
  int? groupId;
  List<dynamic> trainingPlans = [];
  List<dynamic> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    timeController = TextEditingController();
    fetchTrainingDetail();
    fetchTrainingPlans();
    fetchGroups();
  }

  @override
  void dispose() {
    timeController.dispose();
    super.dispose();
  }

  Future<void> fetchTrainingDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/trainings/${widget.trainingId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          selectedDate = DateTime.parse(data['date']);
          timeController.text = DateFormat('HH:mm').format(selectedDate);
          trainingPlanId = data['training_plan_id'];
          groupId = data['group_id'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać szczegółów treningu'),
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
          content: Text('Wystąpił błąd podczas pobierania treningu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchTrainingPlans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/training-plans/'),
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

  Future<void> updateTraining() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.put(
          Uri.parse('${Config.apiUrl}/trainings/${widget.trainingId}'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'date': selectedDate.toIso8601String(),
            'training_plan_id': trainingPlanId,
            'group_id': groupId,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trening zaktualizowany pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Nie udało się zaktualizować treningu: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd podczas aktualizacji treningu'),
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
        timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edytuj trening'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.w),
              child: EditTrainingForm(
                formKey: _formKey,
                selectedDate: selectedDate,
                timeController: timeController,
                trainingPlanId: trainingPlanId,
                groupId: groupId,
                trainingPlans: trainingPlans,
                groups: groups,
                onSelectDate: _selectDate,
                onSelectTime: _selectTime,
                onSave: updateTraining,
                onTrainingPlanChanged: (value) {
                  setState(() {
                    trainingPlanId = value;
                  });
                },
                onGroupChanged: (value) {
                  setState(() {
                    groupId = value;
                  });
                },
              ),
            ),
    );
  }
}

class EditTrainingForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final DateTime selectedDate;
  final TextEditingController timeController;
  final int? trainingPlanId;
  final int? groupId;
  final List<dynamic> trainingPlans;
  final List<dynamic> groups;
  final Function(BuildContext) onSelectDate;
  final Function(BuildContext) onSelectTime;
  final VoidCallback onSave;
  final Function(int?) onTrainingPlanChanged;
  final Function(int?) onGroupChanged;

  const EditTrainingForm({
    super.key,
    required this.formKey,
    required this.selectedDate,
    required this.timeController,
    required this.trainingPlanId,
    required this.groupId,
    required this.trainingPlans,
    required this.groups,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onSave,
    required this.onTrainingPlanChanged,
    required this.onGroupChanged,
  });

  @override
  _EditTrainingFormState createState() => _EditTrainingFormState();
}

class _EditTrainingFormState extends State<EditTrainingForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildDateTimePicker(context),
            SizedBox(height: 16.h),
            _buildDropdownTrainingPlan(context),
            SizedBox(height: 16.h),
            _buildDropdownGroup(context),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: widget.onSave,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Zapisz',
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
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
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
                onTap: () => widget.onSelectDate(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    DateFormat('dd-MM-yyyy').format(widget.selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onSelectTime(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    widget.timeController.text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownTrainingPlan(BuildContext context) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Plan treningowy',
        prefixIcon: const Icon(Icons.fitness_center),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      value: widget.trainingPlanId,
      items: widget.trainingPlans.map<DropdownMenuItem<int>>((plan) {
        return DropdownMenuItem<int>(
          value: plan['id'] as int,
          child: Text(
            plan['name'] as String,
            style: TextStyle(fontSize: 16.sp),
          ),
        );
      }).toList(),
      onChanged: widget.onTrainingPlanChanged,
      validator: (value) {
        if (value == null) {
          return 'Wybierz plan treningowy';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownGroup(BuildContext context) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Grupa',
        prefixIcon: const Icon(Icons.group),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      value: widget.groupId,
      items: widget.groups.map<DropdownMenuItem<int>>((group) {
        return DropdownMenuItem<int>(
          value: group['id'] as int,
          child: Text(
            group['name'] as String,
            style: TextStyle(fontSize: 16.sp),
          ),
        );
      }).toList(),
      onChanged: widget.onGroupChanged,
      validator: (value) {
        if (value == null) {
          return 'Wybierz grupę';
        }
        return null;
      },
    );
  }
}
