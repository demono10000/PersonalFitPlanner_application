import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateTrainingPlanScreen extends StatefulWidget {
  const CreateTrainingPlanScreen({super.key});

  @override
  _CreateTrainingPlanScreenState createState() =>
      _CreateTrainingPlanScreenState();
}

class _CreateTrainingPlanScreenState extends State<CreateTrainingPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  List<dynamic> exercises = [];
  List<Map<String, dynamic>> selectedExercises = [];
  Map<int, TextEditingController> controllers = {};
  TextEditingController restTimeController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
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
          // posortuj alfabetycznie
          data.sort((a, b) => a['name'].compareTo(b['name']));
          exercises = data;
        });
      } else {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać ćwiczeń'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania ćwiczeń'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void addExerciseToPlan(int exerciseId, String exerciseName) {
    setState(() {
      final uniqueId = Random().nextInt(1000000);
      selectedExercises.add({
        'id': uniqueId,
        'exercise': exerciseId,
        'name': exerciseName,
        'repetitions': 1,
        'order': selectedExercises.length,
      });
      controllers[uniqueId] = TextEditingController(text: '1');
    });
  }

  void removeExerciseFromPlan(int index) {
    setState(() {
      final exerciseId = selectedExercises[index]['id'];
      controllers.remove(exerciseId);
      selectedExercises.removeAt(index);
      for (int i = 0; i < selectedExercises.length; i++) {
        selectedExercises[i]['order'] = i;
      }
    });
  }

  void reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = selectedExercises.removeAt(oldIndex);
      selectedExercises.insert(newIndex, item);
      for (int i = 0; i < selectedExercises.length; i++) {
        selectedExercises[i]['order'] = i;
      }
    });
  }

  void addRestBetweenExercises() {
    int restTime = int.tryParse(restTimeController.text) ?? 30;
    setState(() {
      List<Map<String, dynamic>> updatedExercises = [];
      int orderCounter = 0;
      for (int i = 0; i < selectedExercises.length; i++) {
        updatedExercises.add({
          'id': selectedExercises[i]['id'],
          'exercise': selectedExercises[i]['exercise'],
          'name': selectedExercises[i]['name'],
          'repetitions': selectedExercises[i]['repetitions'],
          'order': orderCounter++,
        });

        if (i < selectedExercises.length - 1 &&
            selectedExercises[i]['exercise'] != -1 &&
            selectedExercises[i + 1]['exercise'] != -1) {
          Map<String, dynamic>? restExercise = exercises.firstWhere(
            (exercise) => exercise['id'] == -1,
            orElse: () => {},
          );

          if (restExercise!.isNotEmpty) {
            final uniqueRestId = Random().nextInt(1000000);
            updatedExercises.add({
              'id': uniqueRestId,
              'exercise': restExercise['id'],
              'name': restExercise['name'],
              'repetitions': restTime,
              'order': orderCounter++,
            });
          }
        }
      }
      selectedExercises = updatedExercises;
    });
  }

  Future<void> createTrainingPlan() async {
    if (_formKey.currentState!.validate()) {
      if (selectedExercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proszę dodać przynajmniej jedno ćwiczenie'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      final List<Map<String, dynamic>> exercisesData = selectedExercises
          .map((exercise) => {
                'exercise_id': exercise['exercise'],
                'repetitions':
                    int.tryParse(controllers[exercise['id']]!.text) ?? 1,
                'order': exercise['order']
              })
          .toList();

      try {
        final response = await http.post(
          Uri.parse('${Config.apiUrl}/training-plans/'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'name': name,
            'description': description,
            'exercises': exercisesData,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan treningowy został pomyślnie utworzony'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Nie udało się utworzyć planu treningowego: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd podczas tworzenia planu treningowego'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    restTimeController.dispose();
    controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stwórz plan treningowy'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nazwa',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                onChanged: (value) {
                  setState(() {
                    name = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać nazwę';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  prefixIcon: Icon(Icons.description),
                ),
                onChanged: (value) {
                  setState(() {
                    description = value;
                  });
                },
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać opis';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              Text(
                'Wybierz ćwiczenia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8.h),
              exercises.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        return ExerciseListTile(
                          exercise: exercises[index],
                          onAdd: () => addExerciseToPlan(
                              exercises[index]['id'], exercises[index]['name']),
                        );
                      },
                    ),
              SizedBox(height: 24.h),
              Text(
                'Wybrane ćwiczenia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8.h),
              selectedExercises.isEmpty
                  ? Text(
                      'Brak wybranych ćwiczeń.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: reorderExercises,
                      itemCount: selectedExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = selectedExercises[index];
                        final isTimed = (exercises.firstWhere(
                                  (e) => e['id'] == exercise['exercise'],
                                  orElse: () => {},
                                )['is_timed'] ??
                                false) ==
                            true;

                        if (!controllers.containsKey(exercise['id'])) {
                          controllers[exercise['id']] = TextEditingController(
                              text: exercise['repetitions'].toString());
                        }

                        return SelectedExerciseCard(
                          key: ValueKey(exercise['id']),
                          exercise: exercise,
                          isTimed: isTimed,
                          controller: controllers[exercise['id']]!,
                          onRemove: () => removeExerciseFromPlan(index),
                        );
                      },
                    ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: restTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Czas odpoczynku w sekundach',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Proszę podać czas odpoczynku';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) < 0) {
                          return 'Proszę podać poprawny czas odpoczynku';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton(
                    onPressed: addRestBetweenExercises,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Dodaj odpoczynki',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: createTrainingPlan,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Stwórz plan treningowy',
                    style: TextStyle(
                      fontSize: 16.sp,
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
}

class ExerciseListTile extends StatelessWidget {
  final dynamic exercise;
  final VoidCallback onAdd;

  const ExerciseListTile({
    super.key,
    required this.exercise,
    required this.onAdd,
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
        title: Text(
          exercise['name'] ?? 'Ćwiczenie',
          style: TextStyle(fontSize: 16.sp),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: onAdd,
          tooltip: 'Dodaj ćwiczenie',
        ),
      ),
    );
  }
}

class SelectedExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final bool isTimed;
  final TextEditingController controller;
  final VoidCallback onRemove;

  const SelectedExerciseCard({
    super.key,
    required this.exercise,
    required this.isTimed,
    required this.controller,
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
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        subtitle: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: isTimed ? 'Czas w sekundach' : 'Powtórzenia',
            prefixIcon:
                isTimed ? const Icon(Icons.timer) : const Icon(Icons.repeat),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          keyboardType: TextInputType.number,
          onFieldSubmitted: (value) {},
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onRemove,
              tooltip: 'Usuń ćwiczenie',
            ),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
