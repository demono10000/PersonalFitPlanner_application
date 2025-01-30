import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

class EditTrainingPlanScreen extends StatefulWidget {
  final int trainingPlanId;

  const EditTrainingPlanScreen({super.key, required this.trainingPlanId});

  @override
  _EditTrainingPlanScreenState createState() => _EditTrainingPlanScreenState();
}

class _EditTrainingPlanScreenState extends State<EditTrainingPlanScreen> {
  Map<String, dynamic> trainingPlan = {};
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> allExercises = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    fetchTrainingPlanDetail();
    fetchAllExercises();
  }

  Future<void> fetchTrainingPlanDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/training-plans/${widget.trainingPlanId}/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          trainingPlan = data;
          nameController.text = trainingPlan['name'] ?? '';
          descriptionController.text = trainingPlan['description'] ?? '';
          exercises =
              (trainingPlan['exercises'] as List<dynamic>).map((exercise) {
            return {
              'id': exercise['id'] ?? Random().nextInt(1000000),
              'exercise_id': exercise['exercise']['id'],
              'name': exercise['exercise']['name'],
              'repetitions': exercise['repetitions'],
              'order': exercise['order'],
              'is_timed': exercise['exercise']['is_timed'] ?? false,
            };
          }).toList();
          exercises.sort((a, b) => a['order'].compareTo(b['order']));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać szczegółów planu treningowego'),
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
          content: Text('Wystąpił błąd podczas pobierania planu treningowego'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchAllExercises() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/exercises/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(() {
          allExercises = data
              .map((exercise) => {
                    'exercise_id': exercise['id'],
                    'name': exercise['name'],
                    'is_timed': exercise['is_timed'] ?? false,
                  })
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać listy ćwiczeń'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania listy ćwiczeń'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateTrainingPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final List<Map<String, dynamic>> exercisesData = exercises
        .map((exercise) => {
              'exercise_id': exercise['exercise_id'],
              'repetitions': exercise['repetitions'],
              'order': exercise['order']
            })
        .toList();

    try {
      final response = await http.put(
        Uri.parse('${Config.apiUrl}/training-plans/${widget.trainingPlanId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'name': nameController.text,
          'description': descriptionController.text,
          'exercises': exercisesData,
        }),
      );

      if (response.statusCode == 200) {
        final updatedData =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          trainingPlan = updatedData;
          exercises =
              (updatedData['exercises'] as List<dynamic>).map((exercise) {
            return {
              'id': exercise['id'] ?? Random().nextInt(1000000),
              'exercise_id': exercise['exercise']['id'],
              'name': exercise['exercise']['name'],
              'repetitions': exercise['repetitions'],
              'order': exercise['order'],
              'is_timed': exercise['exercise']['is_timed'] ?? false,
            };
          }).toList();
          exercises.sort((a, b) => a['order'].compareTo(b['order']));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan treningowy zaktualizowany pomyślnie'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Nie udało się zaktualizować planu treningowego: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Wystąpił błąd podczas aktualizacji planu treningowego'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, item);
      for (int i = 0; i < exercises.length; i++) {
        exercises[i]['order'] = i;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edytuj plan treningowy'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.w),
              child: EditTrainingPlanForm(
                formKey: _formKey,
                nameController: nameController,
                descriptionController: descriptionController,
                exercises: exercises,
                allExercises: allExercises,
                onReorder: reorderExercises,
                onUpdateRepetitions: (index, value) => setState(() {
                  exercises[index]['repetitions'] =
                      int.tryParse(value) ?? exercises[index]['repetitions'];
                }),
                onSave: updateTrainingPlan,
              ),
            ),
    );
  }
}

class EditTrainingPlanForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> allExercises;
  final Function(int, int) onReorder;
  final Function(int, String) onUpdateRepetitions;
  final VoidCallback onSave;

  const EditTrainingPlanForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.exercises,
    required this.allExercises,
    required this.onReorder,
    required this.onUpdateRepetitions,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nazwa',
              prefixIcon: Icon(Icons.fitness_center),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Proszę podać nazwę';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Opis',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Proszę podać opis';
              }
              return null;
            },
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ćwiczenia:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddExerciseDialog(
                      allExercises: allExercises,
                      alreadyAddedExerciseIds: exercises
                          .map<int>((e) => e['exercise_id'] as int)
                          .toList(),
                      onAdd: (exercise) {
                        final newExercise = {
                          'id': Random().nextInt(1000000),
                          'exercise_id': exercise['exercise_id'],
                          'name': exercise['name'],
                          'repetitions': 1,
                          'order': exercises.length,
                          'is_timed': exercise['is_timed'],
                        };
                        exercises.add(newExercise);
                        Navigator.pop(context);
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  );
                },
                tooltip: 'Dodaj ćwiczenie',
              ),
            ],
          ),
          SizedBox(height: 8.h),
          exercises.isEmpty
              ? const Center(child: Text('Brak ćwiczeń'))
              : Expanded(
                  child: ReorderableListView.builder(
                    onReorder: onReorder,
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      final isTimed = exercise['is_timed'] == true;

                      return SelectedExerciseCard(
                        key: ValueKey(exercise['id']),
                        exercise: exercise,
                        isTimed: isTimed,
                        onUpdateRepetitions: (value) =>
                            onUpdateRepetitions(index, value),
                        onRemove: () {
                          exercises.removeAt(index);
                          for (int i = 0; i < exercises.length; i++) {
                            exercises[i]['order'] = i;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ćwiczenie zostało usunięte'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Zapisz',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final bool isTimed;
  final Function(String) onUpdateRepetitions;
  final VoidCallback onRemove;

  const SelectedExerciseCard({
    super.key,
    required this.exercise,
    required this.isTimed,
    required this.onUpdateRepetitions,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.drag_handle, color: Colors.grey),
        title: Text(
          exercise['name'] ?? 'Ćwiczenie',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: TextFormField(
          initialValue: exercise['repetitions'].toString(),
          decoration: InputDecoration(
            labelText: isTimed ? 'Czas w sekundach' : 'Powtórzenia',
            prefixIcon:
                isTimed ? const Icon(Icons.timer) : const Icon(Icons.repeat),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          keyboardType: TextInputType.number,
          onChanged: onUpdateRepetitions,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return isTimed
                  ? 'Proszę podać czas'
                  : 'Proszę podać liczbę powtórzeń';
            }
            if (int.tryParse(value) == null || int.parse(value) <= 0) {
              return isTimed
                  ? 'Proszę podać poprawny czas'
                  : 'Proszę podać poprawną liczbę powtórzeń';
            }
            return null;
          },
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onRemove,
          tooltip: 'Usuń ćwiczenie',
        ),
      ),
    );
  }
}

class AddExerciseDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allExercises;
  final List<int> alreadyAddedExerciseIds;
  final Function(Map<String, dynamic>) onAdd;

  const AddExerciseDialog({
    super.key,
    required this.allExercises,
    required this.alreadyAddedExerciseIds,
    required this.onAdd,
  });

  @override
  _AddExerciseDialogState createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  List<Map<String, dynamic>> filteredExercises = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filteredExercises = widget.allExercises;
  }

  void filterExercises(String query) {
    setState(() {
      searchQuery = query;
      filteredExercises = widget.allExercises
          .where((exercise) =>
              exercise['name'].toLowerCase().contains(query.toLowerCase()) &&
              !widget.alreadyAddedExerciseIds.contains(exercise['exercise_id']))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj Ćwiczenie'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Wyszukaj ćwiczenie',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: filterExercises,
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: filteredExercises.isEmpty
                  ? const Center(child: Text('Brak dostępnych ćwiczeń'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = filteredExercises[index];
                        return ListTile(
                          title: Text(exercise['name']),
                          trailing: exercise['is_timed']
                              ? const Icon(Icons.timer, color: Colors.red)
                              : const Icon(Icons.repeat, color: Colors.green),
                          onTap: () {
                            widget.onAdd(exercise);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
      ],
    );
  }
}
